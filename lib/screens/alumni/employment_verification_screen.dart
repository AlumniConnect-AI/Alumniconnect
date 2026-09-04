import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';
import '../../services/outcome_tracking_service.dart';

class EmploymentVerificationScreen extends StatefulWidget {
  const EmploymentVerificationScreen({super.key});

  @override
  State<EmploymentVerificationScreen> createState() =>
      _EmploymentVerificationScreenState();
}

class _EmploymentVerificationScreenState
    extends State<EmploymentVerificationScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employment Verification"),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, alumniSnap) {
          if (!alumniSnap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final alumniData =
              alumniSnap.data!.data() as Map<String, dynamic>? ?? {};
          final myEmployer =
              (alumniData['company'] ?? '').toString().toLowerCase().trim();

          return Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppGradients.emeraldCyan,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Text(
                          "Verify Student Employment",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      myEmployer.isEmpty
                          ? "Review students who claim to work at your company"
                          : "Reviewing claims matching: ${alumniData['company']}",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // ── List ─────────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('outcome_tracking')
                      .snapshots(),
                  builder: (context, snap) {
                    // ── Error state (e.g., Firestore permission denied) ──────
                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'Could not load verification claims.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Check your internet connection or try again later.',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).textTheme.bodyMedium?.color,
                                    fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }

                    // Collect all pending check-ins that match alumni's employer
                    final verificationItems = <_VerificationItem>[];

                    for (final doc in snap.data!.docs) {
                      final studentUid = doc.id;
                      if (studentUid == uid) continue; // skip self

                      final data = doc.data() as Map<String, dynamic>;
                      final checkIns =
                          (data['checkIns'] as List<dynamic>?) ?? [];

                      for (int i = 0; i < checkIns.length; i++) {
                        final entry =
                            checkIns[i] as Map<String, dynamic>? ?? {};
                        final employerName =
                            (entry['employerName'] ?? '').toString().toLowerCase();
                        final verified = entry['verified'] ?? false;

                        // Match: same employer (fuzzy) and not yet verified
                        if (!verified &&
                            myEmployer.isNotEmpty &&
                            employerName.isNotEmpty &&
                            (employerName.contains(myEmployer) ||
                                myEmployer.contains(employerName))) {
                          verificationItems.add(_VerificationItem(
                            studentUid: studentUid,
                            checkInIndex: i,
                            employerName: entry['employerName'] ?? '',
                            status: entry['status'] ?? '',
                            employmentType: entry['employmentType'] ?? '',
                          ));
                        }
                      }
                    }

                    if (verificationItems.isEmpty) {
                      return _emptyState(context, myEmployer);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: verificationItems.length,
                      itemBuilder: (_, i) {
                        return _VerificationCard(
                          item: verificationItems[i],
                          onApprove: () async {
                            await OutcomeTrackingService.approveCheckIn(
                              studentUid: verificationItems[i].studentUid,
                              checkInIndex: verificationItems[i].checkInIndex,
                            );

                            // Increment alumni's verificationsCompleted
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                              'engagementStats.verificationsCompleted':
                                  FieldValue.increment(1),
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Employment verified ✅"),
                                  backgroundColor: AppColors.accentEmerald,
                                ),
                              );
                              setState(() {});
                            }
                          },
                          onReject: () {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Verification rejected"),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context, String myEmployer) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accentEmerald.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user,
                color: AppColors.accentEmerald, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            myEmployer.isEmpty
                ? "Add your company in profile first"
                : "No pending verifications",
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            myEmployer.isEmpty
                ? "We'll match students claiming your employer"
                : "No students have claimed employment at ${myEmployer} yet",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Verification list item ─────────────────────────────────────────────────

class _VerificationItem {
  final String studentUid;
  final int checkInIndex;
  final String employerName;
  final String status;
  final String employmentType;

  _VerificationItem({
    required this.studentUid,
    required this.checkInIndex,
    required this.employerName,
    required this.status,
    required this.employmentType,
  });
}

class _VerificationCard extends StatelessWidget {
  final _VerificationItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VerificationCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(item.studentUid)
          .get(),
      builder: (context, snap) {
        final studentData =
            snap.data?.data() as Map<String, dynamic>? ?? {};
        final studentName = studentData['name'] ?? "Student";
        final studentPhoto = studentData['photoURL'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.accentEmerald.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student info row
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primarySoft,
                    backgroundImage: studentPhoto != null &&
                            studentPhoto.isNotEmpty
                        ? NetworkImage(studentPhoto)
                        : null,
                    child: (studentPhoto == null || studentPhoto.isEmpty)
                        ? Text(
                            studentName.isNotEmpty
                                ? studentName[0].toUpperCase()
                                : "?",
                            style:
                                const TextStyle(color: AppColors.primary))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Claims: ${item.employerName} • ${item.employmentType}",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.warning.withOpacity(0.4)),
                    ),
                    child: const Text(
                      "Pending",
                      style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close,
                          size: 16, color: AppColors.error),
                      label: const Text("Reject",
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
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("Approve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentEmerald,
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
