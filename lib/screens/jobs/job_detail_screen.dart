import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../services/meeting_service.dart';
import '../chat/chat_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _hasApplied = false;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _checkAlreadyApplied();
  }

  Future<void> _checkAlreadyApplied() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('job_applications')
        .where('jobId', isEqualTo: widget.jobId)
        .where('studentUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (mounted && snap.docs.isNotEmpty) {
      setState(() => _hasApplied = true);
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return "Recently";
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 0) return "${diff.inDays} days ago";
    if (diff.inHours > 0) return "${diff.inHours} hours ago";
    return "Just now";
  }

  Future<void> _openLinkedIn(BuildContext context, String rawUrl) async {
    final url = rawUrl.trim().replaceAll('"', '');
    if (url.isEmpty || !url.startsWith("http")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid LinkedIn URL")),
      );
      return;
    }
    try {
      final launched = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open LinkedIn link")),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open LinkedIn link")),
        );
      }
    }
  }

  Future<void> _saveJob() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance.collection('saved_jobs').add({
        'userId': uid,
        'jobId': widget.jobId,
        'savedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Job saved successfully")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to save job")));
      }
    }
  }

  /// In-app Apply Now flow:
  /// 1. Show confirmation dialog (reuses cached resume URL if available)
  /// 2. Write to job_applications/{auto-id}
  Future<void> _applyNow(Map<String, dynamic> jobData) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Fetch resume URL from user's Firestore profile (if previously stored)
    String resumeUrl = '';
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final userData = userDoc.data() ?? {};
      resumeUrl = userData['resumeUrl']?.toString() ??
          userData['cvUrl']?.toString() ??
          userData['resumePdfUrl']?.toString() ?? '';
    } catch (_) {}

    final designation = jobData['designation']?.toString() ?? 'this role';
    final company = jobData['company']?.toString() ?? '';

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.work_outline, color: AppColors.primaryNeon, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Apply Now', style: TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apply to $designation${company.isNotEmpty ? ' at $company' : ''}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            resumeUrl.isNotEmpty
                ? const Text(
                    '✅ Your uploaded resume will be attached automatically.',
                    style: TextStyle(fontSize: 12, color: AppColors.accentEmerald),
                  )
                : Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      '⚠️ No resume uploaded yet. Upload your resume in the AI Hub → '
                      'Career Twin or Alumni Skill Matcher before applying to improve '
                      'your chances. You can still apply now without one.',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNeon,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(dlgCtx, true),
            icon: const Icon(Icons.send, size: 14),
            label: const Text('Confirm Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _applying = true);
    try {
      await FirebaseFirestore.instance.collection('job_applications').add({
        'jobId': widget.jobId,
        'studentUid': uid,
        'jobTitle': designation,
        'company': company,
        'resumeUrl': resumeUrl,
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending_review',
      });

      if (mounted) {
        setState(() {
          _hasApplied = true;
          _applying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Applied to $designation${company.isNotEmpty ? ' at $company' : ''}!'),
            backgroundColor: AppColors.accentEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      dev.log('[JobDetail] Apply error: $e');
      if (mounted) {
        setState(() => _applying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

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
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Job Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final d = snap.data!.data() as Map<String, dynamic>;
          final imageUrl = d['imageUrl'] as String?;
          final ownerId = d['ownerId']?.toString() ?? '';
          final isOwner = currentUid == ownerId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── JOB IMAGE ──────────────────────────────────────────────
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
                      // ── DESIGNATION ────────────────────────────────────
                      Text(
                        d['designation'] ?? "",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "${d['company']} • ${d['location']}",
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Experience: ${d['experience']}",
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Posted by ${d['ownerName'] ?? 'Alumni'} • ${_timeAgo(d['createdAt'] as Timestamp?)}",
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text("Job Description",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      Text(
                        d['description'] ?? "",
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            height: 1.4),
                      ),

                      const SizedBox(height: 40),

                      // ── ACTION BUTTONS ────────────────────────────────
                      if (isOwner)
                        // Owner sees "View Applicants" instead of Apply
                        _ViewApplicantsButton(jobId: widget.jobId, jobTitle: d['designation'] ?? '')
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saveJob,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                ),
                                child: const Text("Save Job",
                                    style: TextStyle(color: AppColors.primary)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_hasApplied || _applying)
                                    ? null
                                    : () => _applyNow(d),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasApplied
                                      ? Colors.grey
                                      : AppColors.primaryNeon,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                ),
                                icon: _applying
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black))
                                    : Icon(
                                        _hasApplied
                                            ? Icons.check_circle
                                            : Icons.send,
                                        size: 16),
                                label: Text(_applying
                                    ? 'Applying...'
                                    : _hasApplied
                                        ? 'Applied ✓'
                                        : 'Apply Now'),
                              ),
                            ),
                          ],
                        ),

                      // LinkedIn link as secondary option (below main apply)
                      if (!isOwner && (d['linkedin'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () =>
                              _openLinkedIn(context, d['linkedin'] ?? ""),
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('Also apply via LinkedIn'),
                          style: TextButton.styleFrom(
                              foregroundColor:
                                  theme.textTheme.bodyMedium?.color),
                        ),
                      ],
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

// ── VIEW APPLICANTS BUTTON ────────────────────────────────────────────────────
class _ViewApplicantsButton extends StatelessWidget {
  final String jobId;
  final String jobTitle;
  const _ViewApplicantsButton(
      {required this.jobId, required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('job_applications')
          .where('jobId', isEqualTo: jobId)
          .snapshots(),
      builder: (_, snap) {
        final count = snap.data?.docs.length ?? 0;
        return ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  _ApplicantsScreen(jobId: jobId, jobTitle: jobTitle),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentEmerald,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.people_outline, size: 18),
          label: Text(
              'View Applicants${count > 0 ? ' ($count)' : ''}'),
        );
      },
    );
  }
}

// ── APPLICANTS SCREEN ─────────────────────────────────────────────────────────
class _ApplicantsScreen extends StatelessWidget {
  final String jobId;
  final String jobTitle;
  const _ApplicantsScreen(
      {required this.jobId, required this.jobTitle});

  Color _statusColor(String status) {
    switch (status) {
      case 'shortlisted':
        return AppColors.accentEmerald;
      case 'rejected':
        return Colors.redAccent;
      case 'reviewed':
        return AppColors.accentBlue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Applicants — $jobTitle',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('job_applications')
            .where('jobId', isEqualTo: jobId)
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No applicants yet',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final appId = docs[i].id;
              final studentUid = d['studentUid']?.toString() ?? '';
              final status = d['status']?.toString() ?? 'pending_review';
              final resumeUrl = d['resumeUrl']?.toString() ?? '';
              final appliedAt = d['appliedAt'] as Timestamp?;
              final timeStr = appliedAt != null
                  ? '${DateTime.now().difference(appliedAt.toDate()).inDays}d ago'
                  : 'Recently';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(studentUid)
                    .get(),
                builder: (_, userSnap) {
                  final userData = userSnap.data?.data()
                      as Map<String, dynamic>? ?? {};
                  final name =
                      userData['name']?.toString() ?? 'Student';
                  final photoUrl =
                      userData['photoURL']?.toString() ??
                          userData['profileImage']?.toString();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: photoUrl != null
                                    ? NetworkImage(photoUrl)
                                    : null,
                                backgroundColor: AppColors.primaryNeon
                                    .withValues(alpha: 0.15),
                                child: photoUrl == null
                                    ? Text(name[0].toUpperCase(),
                                        style: const TextStyle(
                                            color: AppColors.primaryNeon,
                                            fontWeight: FontWeight.bold))
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    Text('Applied $timeStr',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: theme.textTheme.bodyMedium
                                                ?.color)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _statusColor(status)
                                          .withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  status.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Resume link
                              if (resumeUrl.isNotEmpty)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final uri = Uri.parse(resumeUrl);
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    },
                                    icon: const Icon(Icons.picture_as_pdf,
                                        size: 14,
                                        color: Colors.redAccent),
                                    label: const Text('Resume',
                                        style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(
                                          color: Colors.redAccent),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.picture_as_pdf_outlined,
                                        size: 14),
                                    label: const Text('No Resume',
                                        style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8)),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              // Message student
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: studentUid.isEmpty
                                      ? null
                                      : () async {
                                          try {
                                            final chatId =
                                                await MeetingService.getOrCreateChat(
                                                    studentUid);
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
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Error: $e'),
                                                backgroundColor: Colors.red,
                                              ));
                                            }
                                          }
                                        },
                                  icon: const Icon(
                                      Icons.message_outlined,
                                      size: 14,
                                      color: AppColors.primaryNeon),
                                  label: const Text('Message',
                                      style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryNeon,
                                    side: const BorderSide(
                                        color: AppColors.primaryNeon),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Shortlist / Reject
                              PopupMenuButton<String>(
                                onSelected: (action) async {
                                  final newStatus = action == 'shortlist'
                                      ? 'shortlisted'
                                      : action == 'reject'
                                          ? 'rejected'
                                          : 'reviewed';
                                  await FirebaseFirestore.instance
                                      .collection('job_applications')
                                      .doc(appId)
                                      .update({'status': newStatus});
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'shortlist',
                                    child: Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: AppColors.accentEmerald,
                                            size: 16),
                                        SizedBox(width: 8),
                                        Text('Shortlist'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'reviewed',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility,
                                            color: AppColors.accentBlue,
                                            size: 16),
                                        SizedBox(width: 8),
                                        Text('Mark Reviewed'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'reject',
                                    child: Row(
                                      children: [
                                        Icon(Icons.close,
                                            color: Colors.redAccent,
                                            size: 16),
                                        SizedBox(width: 8),
                                        Text('Reject'),
                                      ],
                                    ),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert, size: 20),
                                tooltip: 'Update status',
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
      ),
    );
  }

  static Future<String> _getOrCreateChat(String peerId) async {
    return MeetingService.getOrCreateChat(peerId);
  }
}
