import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/upload_service.dart';
import 'job_detail_screen.dart';

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

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          "Post Job",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600),
        ),
        onPressed: _openPostJobDialog,
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

          // 📋 JOB LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .orderBy('createdAt',
                  descending: true)
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child:
                    CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                final jobs = snap.data!.docs.where((d) {
                  final m =
                  d.data() as Map<String, dynamic>;

                  final matchesSearch =
                      search.isEmpty ||
                          (m['designation'] ?? "")
                              .toString()
                              .toLowerCase()
                              .contains(search) ||
                          (m['company'] ?? "")
                              .toString()
                              .toLowerCase()
                              .contains(search);

                  final matchesExp =
                      experienceFilter == "All" ||
                          (m['experience'] ?? "") ==
                              experienceFilter;

                  return matchesSearch && matchesExp;
                }).toList();

                if (jobs.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) {
                    final d =
                    jobs[i].data()
                    as Map<String, dynamic>;

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(
                          milliseconds:
                          300 + i * 50),
                      builder: (_, value, child) =>
                          Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(
                                  0, (1 - value) * 20),
                              child: child,
                            ),
                          ),
                      child: _JobCard(
                        data: d,
                        jobId: jobs[i].id,
                      ),
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

/// 🧩 JOB CARD
class _JobCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String jobId;

  const _JobCard(
      {required this.data, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  JobDetailScreen(jobId: jobId),
            ),
          );
        },
        child: Container(
          padding:
          const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius:
            BorderRadius.circular(16),
            border:
            Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                data['designation'] ?? "",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${data['company'] ?? ""} • ${data['location'] ?? ""}",
                style: TextStyle(
                  color:
                  theme.textTheme.bodyMedium?.color,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Experience: ${data['experience'] ?? "Any"}",
                style: TextStyle(
                  color:
                  theme.textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
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
