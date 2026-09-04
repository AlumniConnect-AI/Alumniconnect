import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';

class AlumniMenteesScreen extends StatefulWidget {
  const AlumniMenteesScreen({super.key});

  @override
  State<AlumniMenteesScreen> createState() => _AlumniMenteesScreenState();
}

class _AlumniMenteesScreenState extends State<AlumniMenteesScreen>
    with SingleTickerProviderStateMixin {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mentorship"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Requests"),
            Tab(text: "My Mentees"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RequestsTab(uid: uid),
          _MenteesTab(uid: uid),
        ],
      ),
    );
  }
}

// ── Pending Requests Tab ──────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  final String uid;
  const _RequestsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mentorship')
          .where('mentorUid', isEqualTo: uid)
          .where('requestStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptyState(
            context,
            icon: Icons.inbox_outlined,
            title: "No pending requests",
            subtitle: "When students request you as a mentor, they'll appear here",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final menteeUid = data['menteeUid'] ?? '';

            return _MentorshipRequestCard(
              docId: doc.id,
              menteeUid: menteeUid,
              data: data,
            );
          },
        );
      },
    );
  }
}

// ── My Mentees Tab ────────────────────────────────────────────────────────────

class _MenteesTab extends StatelessWidget {
  final String uid;
  const _MenteesTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mentorship')
          .where('mentorUid', isEqualTo: uid)
          .where('requestStatus', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptyState(
            context,
            icon: Icons.people_outline,
            title: "No active mentees",
            subtitle: "Accept mentorship requests to start guiding students",
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar row
            Container(
              height: 110,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppGradients.neonCyanPurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${docs.length} Active Mentee${docs.length > 1 ? 's' : ''}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 46,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final menteeUid = data['menteeUid'] ?? '';
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(menteeUid)
                              .get(),
                          builder: (context, snap) {
                            final d = snap.data?.data() as Map<String, dynamic>? ?? {};
                            final photo = d['photoURL'] as String?;
                            final name = d['name'] ?? 'User';
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white30,
                                backgroundImage: photo != null && photo.isNotEmpty
                                    ? NetworkImage(photo)
                                    : null,
                                child: (photo == null || photo.isEmpty)
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white),
                                      )
                                    : null,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final menteeUid = data['menteeUid'] ?? '';
                  return _MenteeCard(menteeUid: menteeUid);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Mentorship Request Card ───────────────────────────────────────────────────

class _MentorshipRequestCard extends StatelessWidget {
  final String docId;
  final String menteeUid;
  final Map<String, dynamic> data;

  const _MentorshipRequestCard({
    required this.docId,
    required this.menteeUid,
    required this.data,
  });

  Future<void> _respond(BuildContext context, String status) async {
    await FirebaseFirestore.instance
        .collection('mentorship')
        .doc(docId)
        .update({'requestStatus': status});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              status == 'accepted' ? "Request accepted! 🎉" : "Request declined"),
          backgroundColor: status == 'accepted'
              ? AppColors.accentEmerald
              : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(menteeUid).get(),
      builder: (context, snap) {
        final d = snap.data?.data() as Map<String, dynamic>? ?? {};
        final name = d['name'] ?? 'Student';
        final photo = d['photoURL'] as String?;
        final department = d['department'] ?? '';
        final batch = d['batch'] ?? '';
        final message = data['message'] as String? ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentPurple.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.purpleSoft,
                    backgroundImage: photo != null && photo.isNotEmpty
                        ? NetworkImage(photo)
                        : null,
                    child: (photo == null || photo.isEmpty)
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: AppColors.accentPurple,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (department.isNotEmpty || batch.isNotEmpty)
                          Text(
                            [if (department.isNotEmpty) department,
                              if (batch.isNotEmpty) "Batch $batch"]
                                .join(' • '),
                            style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.accentPurple.withOpacity(0.4)),
                    ),
                    child: const Text(
                      "Pending",
                      style: TextStyle(
                          color: AppColors.accentPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"$message"',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _respond(context, 'declined'),
                      icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                      label: const Text("Decline",
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respond(context, 'accepted'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("Accept"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Mentee Card ───────────────────────────────────────────────────────────────

class _MenteeCard extends StatelessWidget {
  final String menteeUid;
  const _MenteeCard({required this.menteeUid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(menteeUid).get(),
      builder: (context, snap) {
        final d = snap.data?.data() as Map<String, dynamic>? ?? {};
        final name = d['name'] ?? 'Student';
        final photo = d['photoURL'] as String?;
        final department = d['department'] ?? '';
        final designation = d['designation'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.primaryNeon.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySoft,
                backgroundImage:
                    photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                child: (photo == null || photo.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (department.isNotEmpty || designation.isNotEmpty)
                      Text(
                        department.isNotEmpty ? department : designation,
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 12),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentEmerald.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Active",
                  style: TextStyle(
                      color: AppColors.accentEmerald,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Empty state helper ────────────────────────────────────────────────────────
Widget _emptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  final theme = Theme.of(context);
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 48),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}
