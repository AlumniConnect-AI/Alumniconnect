import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  // ⏱️ TIME AGO FORMAT
  String _timeAgo(Timestamp? ts) {
    if (ts == null) return "Recently";
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 0) return "${diff.inDays} days ago";
    if (diff.inHours > 0) return "${diff.inHours} hours ago";
    return "Just now";
  }

  // 🔗 OPEN LINKEDIN
  Future<void> _openLinkedIn(BuildContext context, String rawUrl) async {
    final url = rawUrl.trim().replaceAll('"', '');

    if (url.isEmpty || !url.startsWith("http")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid LinkedIn URL")),
      );
      return;
    }

    final Uri uri = Uri.parse(url);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open LinkedIn link")),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open LinkedIn link")),
      );
    }
  }

  // ⭐ SAVE JOB FUNCTION
  Future<void> _saveJob(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('saved_jobs').add({
        'userId': uid,
        'jobId': jobId,
        'savedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save job")),
      );
    }
  }

  // 🖼️ FULL SCREEN IMAGE VIEWER
  void _openFullScreenImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Job Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('jobs')
            .doc(jobId)
            .get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final d = snap.data!.data() as Map<String, dynamic>;
          final imageUrl = d['imageUrl'] as String?;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼️ JOB IMAGE (Clickable for Full Screen)
                if (imageUrl != null && imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _openFullScreenImage(context, imageUrl),
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 DESIGNATION
                      Text(
                        d['designation'] ?? "",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 🔹 COMPANY + LOCATION
                      Text(
                        "${d['company']} • ${d['location']}",
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      ),

                      const SizedBox(height: 6),

                      // 🔹 EXPERIENCE
                      Text(
                        "Experience: ${d['experience']}",
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      ),

                      const SizedBox(height: 6),

                      // 🔹 POSTED BY
                      Text(
                        "Posted by ${d['ownerName'] ?? 'Alumni'} • ${_timeAgo(d['createdAt'] as Timestamp?)}",
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 🔹 DESCRIPTION
                      const Text(
                        "Job Description",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        d['description'] ?? "",
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 🔖 SAVE + APPLY
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _saveJob(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Save Job",
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _openLinkedIn(
                                context,
                                d['linkedin'] ?? "",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Apply via LinkedIn",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
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
          );
        },
      ),
    );
  }
}
