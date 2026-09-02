import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';
import '../jobs/job_detail_screen.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  // 🔴 DELETE CONFIRM
  Future<bool> _confirmDelete(BuildContext context, String id) async {
    final theme = Theme.of(context);
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text(
          "Delete Job",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this job?",
        ),
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

    if (res == true) {
      await FirebaseFirestore.instance.collection('jobs').doc(id).delete();
      return true;
    }
    return false;
  }

  // ➕ ADD / ✏️ EDIT JOB
  void _openJobDialog(BuildContext context, {DocumentSnapshot? job}) async {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final d = job?.data() as Map<String, dynamic>?;

    final designation = TextEditingController(text: d?['designation'] ?? "");
    final company = TextEditingController(text: d?['company'] ?? "");
    final location = TextEditingController(text: d?['location'] ?? "");
    final experience = TextEditingController(text: d?['experience'] ?? "");
    final description = TextEditingController(text: d?['description'] ?? "");
    final linkedin = TextEditingController(text: d?['linkedin'] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          job == null ? "Add Job" : "Edit Job",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _input(context, "Designation", designation),
              _input(context, "Company", company),
              _input(context, "Location", location),
              _input(context, "Experience (0-1 / 1-3 / 3+)", experience),
              _input(context, "Description", description, max: 3),
              _input(context, "LinkedIn URL", linkedin),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () async {
              final userSnap = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get();

              final ownerName = userSnap.data()?['name'] ?? "Alumni";

              final data = {
                'designation': designation.text.trim(),
                'company': company.text.trim(),
                'location': location.text.trim(),
                'experience': experience.text.trim(),
                'description': description.text.trim(),
                'linkedin': linkedin.text.trim(),
                'ownerId': uid,
                'ownerName': ownerName,
                'createdAt':
                job == null ? FieldValue.serverTimestamp() : d?['createdAt'],
              };

              if (job == null) {
                await FirebaseFirestore.instance.collection('jobs').add(data);
              } else {
                await FirebaseFirestore.instance
                    .collection('jobs')
                    .doc(job.id)
                    .update(data);
              }

              Navigator.pop(context);
            },
            child: Text(
              job == null ? "Post Job" : "Update Job",
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _input(BuildContext context, String hint, TextEditingController c, {int max = 1}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: max,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: theme.scaffoldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // 🔹 STATUS LOGIC
  bool _isClosed(Timestamp? createdAt) {
    if (createdAt == null) return false;
    final created = createdAt.toDate();
    return DateTime.now().difference(created).inDays >= 30;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "My Jobs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('ownerId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snap.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "You haven’t posted any jobs yet",
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: snap.data!.docs.map((job) {
              final d = job.data() as Map<String, dynamic>;
              final closed = _isClosed(d['createdAt']);

              return Dismissible(
                key: ValueKey(job.id),
                confirmDismiss: (dir) async {
                  if (dir == DismissDirection.startToEnd) {
                    return await _confirmDelete(context, job.id);
                  } else {
                    _openJobDialog(context, job: job);
                    return false;
                  }
                },
                background:
                _bg(Icons.delete, Colors.red, Alignment.centerLeft),
                secondaryBackground:
                _bg(Icons.edit, AppColors.primary, Alignment.centerRight),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailScreen(jobId: job.id),
                    ),
                  ),
                  child: _card(
                    context,
                    title: d['designation'] ?? "",
                    subtitle: "${d['company']} • ${d['location']}",
                    isClosed: closed,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  static Widget _bg(IconData i, Color c, Alignment a) => Container(
    alignment: a,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    color: c.withOpacity(0.9),
    child: Icon(i, color: Colors.white),
  );

  static Widget _card(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isClosed,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isClosed
                  ? Colors.red.withOpacity(0.15)
                  : Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isClosed ? "CLOSED" : "OPEN",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isClosed ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
