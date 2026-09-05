import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/upload_service.dart';
import 'job_detail_screen.dart';
import 'job_referral_application_screen.dart';

class JobsListScreen extends StatefulWidget {
  const JobsListScreen({super.key});

  @override
  State<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends State<JobsListScreen> {
  String search = "";
  String experienceFilter = "All";
  Timer? _debounce;

  final experiences = ["All", "Fresher", "0-1", "1-3", "3-5", "5+"];

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => search = value.toLowerCase());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // 🟢 POST JOB DIALOG
  void _openPostJobDialog() {
    final theme = Theme.of(context);
    final designationCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final linkCtrl = TextEditingController();

    String selectedExperience = "Fresher";
    File? jobImage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Post Job"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _dialogField("Designation", designationCtrl, context),
                  _dialogField("Company", companyCtrl, context),
                  _dialogField("Location", locationCtrl, context),

                  // ✅ EXPERIENCE DROPDOWN
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedExperience,
                      dropdownColor: theme.cardColor,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: experiences
                          .where((e) => e != "All")
                          .map(
                            (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedExperience = value!;
                        });
                      },
                    ),
                  ),

                  _dialogField("Job Description", descriptionCtrl, context,
                      maxLines: 3),
                  _dialogField("LinkedIn Job URL", linkCtrl, context),

                  const SizedBox(height: 10),

                  // 🖼️ IMAGE SELECTOR
                  InkWell(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setStateDialog(() => jobImage = File(picked.path));
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: jobImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                                SizedBox(height: 4),
                                Text("Add Job Image", style: TextStyle(fontSize: 12)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(jobImage!, fit: BoxFit.cover),
                            ),
                    ),
                  ),
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
                  if (designationCtrl.text.isEmpty ||
                      companyCtrl.text.isEmpty) {
                    return;
                  }

                  String? imageUrl;
                  if (jobImage != null) {
                    imageUrl = await UploadService.uploadImage(jobImage!);
                  }

                  await FirebaseFirestore.instance
                      .collection('jobs')
                      .add({
                    'designation': designationCtrl.text.trim(),
                    'company': companyCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'experience': selectedExperience,
                    'description': descriptionCtrl.text.trim(),
                    'link': linkCtrl.text.trim(),
                    'imageUrl': imageUrl,
                    'ownerId':
                    FirebaseAuth.instance.currentUser!.uid,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                },
                child: const Text(
                  "Post Job",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Jobs"), centerTitle: true),

      // ── Role-aware FAB: only alumni/staff may post jobs ─────────────────
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final data = snap.data?.data() as Map<String, dynamic>?;
          final role = (data?['role'] ?? 'student').toString().toLowerCase();
          final canPost = role == 'alumni' || role == 'staff';
          if (!canPost) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text(
              'Post Job',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            onPressed: _openPostJobDialog,
          );
        },
      ),

      body: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: "Search job or company",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 🎛 FILTERS
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(horizontal: 12),
              children: experiences.map((e) {
                final selected = experienceFilter == e;
                return Padding(
                  padding:
                  const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e),
                    selected: selected,
                    selectedColor:
                    AppColors.primary.withOpacity(0.2),
                    onSelected: (_) =>
                        setState(() => experienceFilter = e),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // 📋 JOB + REFERRAL LIST (merged)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (_, jobSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('referrals')
                      .orderBy('postedAt', descending: true)
                      .snapshots(),
                  builder: (_, referralSnap) {
                    if (!jobSnap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      );
                    }

                    // Filter jobs
                    final jobs = jobSnap.data!.docs.where((d) {
                      final m = d.data() as Map<String, dynamic>;
                      final matchesSearch = search.isEmpty ||
                          (m['designation'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(search) ||
                          (m['company'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(search);
                      final matchesExp = experienceFilter == 'All' ||
                          (m['experience'] ?? '') == experienceFilter;
                      return matchesSearch && matchesExp;
                    }).toList();

                    // Referrals (not filtered by experience)
                    final referrals = referralSnap.hasData
                        ? referralSnap.data!.docs.where((d) {
                            final m = d.data() as Map<String, dynamic>;
                            return search.isEmpty ||
                                (m['title'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains(search) ||
                                (m['companyName'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains(search);
                          }).toList()
                        : <QueryDocumentSnapshot>[];

                    // Unified list: jobs first, then referrals
                    final totalCount = jobs.length + referrals.length;

                    if (totalCount == 0) return const _EmptyState();

                    return ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: totalCount,
                      itemBuilder: (_, i) {
                        if (i < jobs.length) {
                          final d = jobs[i].data()
                              as Map<String, dynamic>;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration:
                                Duration(milliseconds: 300 + i * 50),
                            builder: (_, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 20),
                                child: child,
                              ),
                            ),
                            child: _JobCard(
                                data: d, jobId: jobs[i].id),
                          );
                        } else {
                          final ri = i - jobs.length;
                          final d = referrals[ri].data()
                              as Map<String, dynamic>;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration:
                                Duration(milliseconds: 300 + i * 50),
                            builder: (_, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 20),
                                child: child,
                              ),
                            ),
                            child: _ReferralCard(
                                data: d, referralId: referrals[ri].id),
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
      ),
    );
  }
}

/// 🧩 JOB CARD — All jobs featured with Referral Request capability
class _JobCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String jobId;

  const _JobCard({required this.data, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ownerName = data['ownerName']?.toString() ?? 'an alumnus';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailScreen(jobId: jobId),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.accentEmerald.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['designation'] ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentEmerald.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.accentEmerald.withOpacity(0.5)),
                    ),
                    child: Text(
                      (data['experience'] == 'Fresher' ||
                              (data['designation'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains('intern'))
                          ? 'INTERNSHIP'
                          : 'JOB',
                      style: const TextStyle(
                        color: AppColors.accentEmerald,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "${data['company'] ?? ""}${data['location'] != null && data['location'].toString().isNotEmpty ? ' • ${data['location']}' : ''}",
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Experience: ${data['experience'] ?? "Any"}",
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.workspace_premium,
                      size: 13, color: AppColors.accentEmerald),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Posted by $ownerName • Tap to view & request",
                      style: const TextStyle(
                        color: AppColors.accentEmerald,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "No jobs found",
        style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
    );
  }
}

/// 🎁 REFERRAL CARD — alumni-posted opportunities
class _ReferralCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String referralId;

  const _ReferralCard({required this.data, required this.referralId});

  Color get _typeColor {
    switch (data['type']) {
      case 'job':
        return AppColors.accentBlue;
      case 'internship':
        return AppColors.accentEmerald;
      default:
        return AppColors.accentPurple;
    }
  }

  String get _typeLabel {
    switch (data['type']) {
      case 'job':
        return 'JOB';
      case 'internship':
        return 'INTERNSHIP';
      default:
        return 'REFERRAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkedJobId = data['jobId']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (linkedJobId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobDetailScreen(jobId: linkedJobId),
              ),
            );
          } else {
            // Legacy referrals fallback
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobReferralApplicationScreen(
                  jobId: referralId,
                  jobData: {
                    'designation': data['title'] ?? 'Role',
                    'company': data['companyName'] ?? 'Company',
                    'description': data['description'] ?? '',
                    'ownerId': data['postedByUid'] ?? '',
                  },
                ),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _typeColor.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['title'] ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _typeColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      _typeLabel,
                      style: TextStyle(
                          color: _typeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                data['companyName'] ?? '',
                style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color, fontSize: 13),
              ),
              if ((data['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  data['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.workspace_premium,
                      size: 13, color: _typeColor),
                  const SizedBox(width: 4),
                  Text(
                    "Posted by an alumnus • Tap to view & request",
                    style: TextStyle(
                        color: _typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _dialogField(
    String hint,
    TextEditingController ctrl,
    BuildContext context, {
      int maxLines = 1,
    }) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}
