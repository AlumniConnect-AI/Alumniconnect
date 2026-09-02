import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';
import '../chat/chat_screen.dart';

class UserListScreen extends StatefulWidget {
  final String uid;
  final String title; // Followers / Following
  final String collection; // followers / following

  const UserListScreen({
    super.key,
    required this.uid,
    required this.title,
    required this.collection,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final currentUid = FirebaseAuth.instance.currentUser!.uid;
  String search = "";

  String _chatId(String a, String b) {
    final ids = [a, b]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  Future<void> _openChat(String peerId) async {
    final chatId = _chatId(currentUid, peerId);

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [currentUid, peerId],
      'users': [currentUid, peerId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          peerId: peerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search ${widget.title.toLowerCase()}",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 👥 USER LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(widget.collection)
                  .doc(widget.uid)
                  .collection('users')
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  );
                }

                if (snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No users found",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: snap.data!.docs.map((doc) {
                    final userId = doc.id;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (_, userSnap) {
                        if (!userSnap.hasData) {
                          return const SizedBox();
                        }

                        final u =
                        userSnap.data!.data() as Map<String, dynamic>;
                        final name = u['name'] ?? "User";

                        if (search.isNotEmpty &&
                            !name.toLowerCase().contains(search)) {
                          return const SizedBox();
                        }

                        return _userTile(userId, name);
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _userTile(String userId, String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // 💬 MUTUAL FOLLOW CHAT
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('followers')
                .doc(currentUid)
                .collection('users')
                .doc(userId)
                .snapshots(),
            builder: (_, fSnap) {
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('following')
                    .doc(currentUid)
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
                builder: (_, foSnap) {
                  final mutual =
                      (fSnap.data?.exists ?? false) &&
                          (foSnap.data?.exists ?? false);

                  if (!mutual) return const SizedBox();

                  return IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.primary,
                    ),
                    onPressed: () => _openChat(userId),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
