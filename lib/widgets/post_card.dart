import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';

class PostCard extends StatelessWidget {
  final QueryDocumentSnapshot post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = post.data() as Map<String, dynamic>;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final likes = List<String>.from(data['likes'] ?? []);
    final isLiked = likes.contains(uid);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: User Info
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                (data['authorName'] ?? "U")[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              data['authorName'] ?? "User",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _timeAgo(data['createdAt'] as Timestamp?),
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
            ),
          ),

          // CONTENT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              data['content'] ?? "",
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),

          // IMAGE (If any)
          if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ClipRRect(
                child: Image.network(
                  data['imageUrl'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // FOOTER: Likes & Comments
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : theme.textTheme.bodyMedium?.color,
                  ),
                  onPressed: () => _toggleLike(post.id, likes, uid),
                ),
                Text("${likes.length}"),
                const SizedBox(width: 20),
                Icon(Icons.chat_bubble_outline, color: theme.textTheme.bodyMedium?.color, size: 20),
                const SizedBox(width: 8),
                const Text("Comment"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLike(String postId, List<String> likes, String uid) {
    final ref = FirebaseFirestore.instance.collection('posts').doc(postId);
    if (likes.contains(uid)) {
      ref.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      ref.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return "Just now";
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }
}
