import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../services/meeting_service.dart';
import '../../services/referral_service.dart';
import '../chat/chat_screen.dart';
import '../alumni/alumni_profile_screen.dart';
import '../alumni/post_referral_screen.dart';

class ReferralRequestsScreen extends StatefulWidget {
  const ReferralRequestsScreen({super.key});

  @override
  State<ReferralRequestsScreen> createState() => _ReferralRequestsScreenState();
}

class _ReferralRequestsScreenState extends State<ReferralRequestsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = (doc.data()?['role'] ?? 'student').toString().toLowerCase();
    if (mounted) {
      setState(() {
        _userRole = role;
        if (_userRole == 'alumni' || _userRole == 'staff') {
          _tabController = TabController(length: 2, vsync: this);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.accentEmerald;
      case 'referral_submitted':
        return AppColors.accentBlue;
      case 'declined':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'referral_submitted':
        return 'Referral Submitted';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isAlumniOrStaff = _userRole == 'alumni' || _userRole == 'staff';

    if (isAlumniOrStaff && _tabController != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Referral Requests',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryNeon,
            labelColor: AppColors.primaryNeon,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Received Requests'),
              Tab(text: 'My Sent Requests'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildReceivedRequests(context, uid),
            _buildSentRequests(context, uid),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryNeon,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Post Job', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PostReferralScreen(),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Referral Requests',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: _buildSentRequests(context, uid),
    );
  }

  // 1. RECEIVED REQUESTS (For Alumni/Staff)
  Widget _buildReceivedRequests(BuildContext context, String uid) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('referral_requests')
          .where('alumniUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final tA = (a.data() as Map<String, dynamic>)['requestedAt'] as Timestamp?;
            final tB = (b.data() as Map<String, dynamic>)['requestedAt'] as Timestamp?;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                const SizedBox(height: 12),
                Text('No students have requested referrals from you yet.',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final reqId = docs[i].id;
            final studentUid = data['studentUid']?.toString() ?? '';
            final studentName = data['studentName']?.toString() ?? 'Student';
            final jobTitle = data['jobTitle']?.toString() ?? 'Job';
            final company = data['company']?.toString() ?? '';
            final note = data['message'] ?? data['note'] ?? '';
            final status = data['status']?.toString() ?? 'pending';
            final resumeUrl = data['resumeUrl']?.toString() ?? '';
            final isInterested = data['isInterested'] ?? data['interested'] ?? true;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(studentUid)
                  .get(),
              builder: (_, userSnap) {
                final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                final photoUrl = userData['photoURL']?.toString() ?? userData['profileImage']?.toString();
                final studentResume = resumeUrl.isNotEmpty
                    ? resumeUrl
                    : (userData['resumeUrl']?.toString() ?? '');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (studentUid.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AlumniProfileScreen(userId: studentUid),
                                    ),
                                  );
                                }
                              },
                              child: CircleAvatar(
                                radius: 22,
                                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                backgroundColor: AppColors.primaryNeon.withOpacity(0.15),
                                child: (photoUrl == null || photoUrl.isEmpty)
                                    ? Text(
                                        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                                        style: const TextStyle(
                                            color: AppColors.primaryNeon,
                                            fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    'Requested referral for $jobTitle${company.isNotEmpty ? ' at $company' : ''}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodyMedium?.color),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isInterested ? AppColors.accentEmerald : Colors.orange)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isInterested ? 'Actively Interested' : 'Passively Exploring',
                                      style: TextStyle(
                                        color: isInterested ? AppColors.accentEmerald : Colors.orange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _statusColor(status).withOpacity(0.5)),
                              ),
                              child: Text(
                                _statusLabel(status).toUpperCase(),
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (note.toString().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '"$note"',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: theme.textTheme.bodyMedium?.color),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            if (studentResume.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(studentResume);
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  },
                                  icon: const Icon(Icons.picture_as_pdf,
                                      size: 14, color: Colors.redAccent),
                                  label: const Text('Resume', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(color: Colors.redAccent),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            if (studentResume.isNotEmpty) const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await ReferralService.updateReferralStatus(
                                    requestId: reqId,
                                    newStatus: 'accepted',
                                  );
                                  final chatId = await MeetingService.getOrCreateChat(studentUid);
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          chatId: chatId,
                                          peerId: studentUid,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 14),
                                label: const Text('Accept & Message', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryNeon,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              onSelected: (val) async {
                                if (val == 'submitted') {
                                  await ReferralService.updateReferralStatus(
                                    requestId: reqId,
                                    newStatus: 'referral_submitted',
                                  );
                                } else if (val == 'decline') {
                                  await ReferralService.updateReferralStatus(
                                    requestId: reqId,
                                    newStatus: 'declined',
                                  );
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'submitted',
                                  child: Row(
                                    children: [
                                      Icon(Icons.task_alt, color: AppColors.accentBlue, size: 16),
                                      SizedBox(width: 8),
                                      Text('Mark Submitted'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'decline',
                                  child: Row(
                                    children: [
                                      Icon(Icons.close, color: Colors.redAccent, size: 16),
                                      SizedBox(width: 8),
                                      Text('Decline'),
                                    ],
                                  ),
                                ),
                              ],
                              icon: const Icon(Icons.more_vert, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // 2. SENT REQUESTS (For Students or Sent Requests view)
  Widget _buildSentRequests(BuildContext context, String uid) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('referral_requests')
          .where('studentUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final tA = (a.data() as Map<String, dynamic>)['requestedAt'] as Timestamp?;
            final tB = (b.data() as Map<String, dynamic>)['requestedAt'] as Timestamp?;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium_outlined, size: 60, color: Colors.grey),
                const SizedBox(height: 12),
                Text('You have not requested any referrals yet.',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final alumniName = data['alumniName']?.toString() ?? 'Alumnus';
            final alumniUid = data['alumniUid']?.toString() ?? '';
            final jobTitle = data['jobTitle']?.toString() ?? 'Job';
            final company = data['company']?.toString() ?? '';
            final status = data['status']?.toString() ?? 'pending';
            final requestedAt = data['requestedAt'] as Timestamp?;
            final dateStr = requestedAt != null
                ? '${requestedAt.toDate().day}/${requestedAt.toDate().month}/${requestedAt.toDate().year}'
                : 'Recently';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(jobTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              if (company.isNotEmpty)
                                Text(company,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: theme.textTheme.bodyMedium?.color)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _statusColor(status).withOpacity(0.5)),
                          ),
                          child: Text(
                            _statusLabel(status).toUpperCase(),
                            style: TextStyle(
                              color: _statusColor(status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.primaryNeon),
                        const SizedBox(width: 6),
                        Text('Alumnus: $alumniName',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('Requested: $dateStr',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    if (alumniUid.isNotEmpty && status == 'accepted') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final chatId = await MeetingService.getOrCreateChat(alumniUid);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(chatId: chatId, peerId: alumniUid),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.message, size: 14),
                          label: const Text('Chat with Alumnus', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryNeon,
                            side: const BorderSide(color: AppColors.primaryNeon),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
