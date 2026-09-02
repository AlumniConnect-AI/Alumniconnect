import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';

class FollowButton extends StatelessWidget {
  final String targetUserId;
  const FollowButton({required this.targetUserId, super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (uid == targetUserId) return const SizedBox();

    final followRef = FirebaseFirestore.instance
        .collection('following')
        .doc(uid)
        .collection('users')
        .doc(targetUserId);

    return StreamBuilder<DocumentSnapshot>(
      stream: followRef.snapshots(),
      builder: (_, snap) {
        final isFollowing = snap.data?.exists ?? false;

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isFollowing ? Colors.grey : AppColors.primary,
          ),
          onPressed: () async {
            if (isFollowing) {
              await followRef.delete();
              await FirebaseFirestore.instance
                  .collection('followers')
                  .doc(targetUserId)
                  .collection('users')
                  .doc(uid)
                  .delete();
            } else {
              await followRef.set({
                'followingId': targetUserId,
                'followedAt': FieldValue.serverTimestamp(),
              });

              await FirebaseFirestore.instance
                  .collection('followers')
                  .doc(targetUserId)
                  .collection('users')
                  .doc(uid)
                  .set({
                'followerId': uid,
                'followedAt': FieldValue.serverTimestamp(),
              });

              await FirebaseFirestore.instance.collection('notifications').add({
                'toUserId': targetUserId,
                'title': 'New Follower',
                'body': 'Someone started following you',
                'type': 'follow',
                'createdAt': FieldValue.serverTimestamp(),
                'isRead': false,
              });
            }
          },
          child: Text(
            isFollowing ? "Unfollow" : "Follow",
            style: const TextStyle(color: Colors.black),
          ),
        );
      },
    );
  }
}
