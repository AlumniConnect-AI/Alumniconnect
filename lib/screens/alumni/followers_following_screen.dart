import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';
import '../chat/chat_screen.dart';
import 'alumni_profile_screen.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final String profileUserId;
  final String title;
  final String collection;

  const FollowersFollowingScreen({
    super.key,
    required this.profileUserId,
    required this.title,
    required this.collection,
  });

  @override
  State<FollowersFollowingScreen> createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  String search = "";

  String _chatId(String a, String b) {
    final ids = [a, b]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search ${widget.title.toLowerCase()}",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(widget.collection)
                  .doc(widget.profileUserId)
                  .collection('users')
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }

                final ids = snap.data!.docs.map((e) => e.id).toList();

                if (ids.isEmpty) {
                  return Center(
                    child: Text(
                      "No ${widget.title.toLowerCase()} yet",
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ids.length,
                  itemBuilder: (_, i) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(ids[i])
                          .get(),
                      builder: (_, userSnap) {
                        if (!userSnap.hasData) return const SizedBox();

                        final u =
                        userSnap.data!.data() as Map<String, dynamic>? ?? {};
                        final name = u['name'] ?? "User";
                        final photoUrl = u['photoURL'] as String?;

                        if (search.isNotEmpty &&
                            !name.toLowerCase().contains(search)) {
                          return const SizedBox();
                        }

                        return _tile(ids[i], name, photoUrl);
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

  Widget _tile(String userId, String name, String? photoUrl) {
    final theme = Theme.of(context);
    final followingRef = FirebaseFirestore.instance
        .collection('following')
        .doc(uid)
        .collection('users')
        .doc(userId);

    final followerRef = FirebaseFirestore.instance
        .collection('followers')
        .doc(uid)
        .collection('users')
        .doc(userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlumniProfileScreen(userId: userId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: followingRef.snapshots(),
                builder: (_, f1) {
                  return StreamBuilder<DocumentSnapshot>(
                    stream: followerRef.snapshots(),
                    builder: (_, f2) {
                      final mutual =
                          (f1.data?.exists ?? false) &&
                              (f2.data?.exists ?? false);

                      if (!mutual) return const SizedBox();

                      return IconButton(
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: AppColors.primary),
                        onPressed: () async {
                          final chatId = _chatId(uid, userId);

                          await FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chatId)
                              .set({
                            'participants': [uid, userId],
                            'users': [uid, userId],
                            'lastMessage': '',
                            'lastMessageTime':
                            FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatScreen(chatId: chatId, peerId: userId),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
