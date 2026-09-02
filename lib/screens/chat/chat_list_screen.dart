import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';
import '../../services/chat_service.dart';
import 'chat_list_skeleton.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String search = "";

  String _formatTime(Timestamp? ts) {
    if (ts == null) return "";
    final d = ts.toDate();
    final now = DateTime.now();

    if (now.difference(d).inDays > 0) {
      return "${d.day}/${d.month}";
    }
    return "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  // 🔴 DELETE CHAT CONFIRMATION
  Future<void> _confirmDelete(String chatId) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Chat"),
        content: const Text("Are you sure you want to delete this conversation? All messages will be permanently removed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ChatService.deleteChat(chatId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chats",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search chats",
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: uid)
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const ChatListSkeleton();
                }

                if (!snap.hasData) return const SizedBox();

                final chats = snap.data!.docs;

                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: theme.dividerColor),
                        const SizedBox(height: 16),
                        Text(
                          "No chats yet",
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: chats.length,
                  itemBuilder: (_, i) {
                    final chat = chats[i];
                    final data = chat.data() as Map<String, dynamic>;

                    final participants = List<String>.from(data['participants'] ?? []);
                    final peerId = participants.firstWhere((e) => e != uid, orElse: () => "");

                    if (peerId.isEmpty) return const SizedBox();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(peerId).get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) return const SizedBox();

                        final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                        final name = userData['name'] ?? "User";
                        final photoUrl = userData['photoURL'] as String?;
                        final isMentor = userData['isMentor'] == true;
                        
                        final unreadCount = (data['unreadCount'] != null && data['unreadCount'][uid] != null) 
                            ? data['unreadCount'][uid] 
                            : 0;
                        final hasUnread = unreadCount > 0;

                        if (search.isNotEmpty && !name.toLowerCase().contains(search)) {
                          return const SizedBox();
                        }

                        final initials = name.isNotEmpty ? name[0].toUpperCase() : "U";

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onLongPress: () => _confirmDelete(chat.id),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatId: chat.id,
                                    peerId: peerId,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hasUnread 
                                      ? AppColors.primary 
                                      : theme.dividerColor.withOpacity(0.5),
                                  width: hasUnread ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.primary.withOpacity(0.15),
                                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                    child: (photoUrl == null || photoUrl.isEmpty)
                                      ? Text(
                                          initials,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        )
                                      : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                                        fontSize: 16,
                                                        color: hasUnread 
                                                            ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black)
                                                            : theme.textTheme.bodyLarge?.color,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isMentor) ...[
                                                    const SizedBox(width: 4),
                                                    const Icon(Icons.verified, color: AppColors.primary, size: 16),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTime(data['lastMessageTime']),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: hasUnread ? AppColors.primary : theme.textTheme.bodySmall?.color,
                                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                data['lastMessage'] != null && data['lastMessage'].toString().isNotEmpty 
                                                    ? data['lastMessage'] 
                                                    : "No messages yet",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: hasUnread 
                                                      ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black) 
                                                      : theme.textTheme.bodyMedium?.color,
                                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            if (hasUnread)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  "$unreadCount",
                                                  style: const TextStyle(
                                                    color: Colors.black, 
                                                    fontSize: 10, 
                                                    fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
