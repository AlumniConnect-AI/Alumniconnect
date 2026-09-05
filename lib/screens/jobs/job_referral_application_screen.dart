import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';
import '../../services/referral_service.dart';
import '../../services/upload_service.dart';

class JobReferralApplicationScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const JobReferralApplicationScreen({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  @override
  State<JobReferralApplicationScreen> createState() =>
      _JobReferralApplicationScreenState();
}

class _JobReferralApplicationScreenState
    extends State<JobReferralApplicationScreen> {
  PlatformFile? _selectedFile;
  String _existingResumeUrl = '';
  bool? _isInterested; // null = unselected, true = Yes, false = No

  List<Map<String, dynamic>> _alumniList = [];
  String? _selectedAlumniUid;
  String _selectedAlumniName = 'Alumnus';
  bool _loadingAlumni = true;
  bool _submitting = false;

  final _messageController = TextEditingController(
    text: "Hi, I am interested in this position and would appreciate a referral if you think my profile is suitable.",
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 1. Fetch profile resume URL
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      _existingResumeUrl = userData['resumeUrl']?.toString() ??
          userData['cvUrl']?.toString() ??
          userData['resumePdfUrl']?.toString() ??
          '';
    } catch (_) {}

    // 2. Fetch strictly the alumni who posted this job
    String ownerId = widget.jobData['ownerId']?.toString() ??
        widget.jobData['postedByUid']?.toString() ??
        widget.jobData['userId']?.toString() ??
        '';

    // If ownerId is not in jobData, fetch the job doc directly from Firestore
    if (ownerId.isEmpty && widget.jobId.isNotEmpty) {
      try {
        final jobDoc = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .get();
        if (jobDoc.exists) {
          final jData = jobDoc.data() ?? {};
          ownerId = jData['ownerId']?.toString() ??
              jData['postedByUid']?.toString() ??
              jData['userId']?.toString() ??
              '';
        }
      } catch (e) {
        dev.log('Error fetching job document: $e');
      }
    }

    final List<Map<String, dynamic>> fetchedAlumni = [];

    if (ownerId.isNotEmpty) {
      try {
        final ownerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerId)
            .get();

        if (ownerDoc.exists) {
          final uData = ownerDoc.data() ?? {};
          final role = (uData['role'] ?? '').toString().toLowerCase();

          // Ensure it's an alumni or job poster
          final name = uData['name']?.toString() ??
              widget.jobData['ownerName']?.toString() ??
              'Job Poster Alumnus';
          final company = uData['company']?.toString() ??
              widget.jobData['company']?.toString() ??
              '';

          fetchedAlumni.add({
            'id': ownerId,
            'name': name,
            'role': role,
            'matchReason': company.isNotEmpty ? 'Job Poster ($company)' : 'Job Poster',
          });
        }
      } catch (e) {
        dev.log('Error fetching job poster profile: $e');
      }
    }

    // Fallback: If no job poster doc found, fetch alumni from ReferralService
    if (fetchedAlumni.isEmpty) {
      final company = widget.jobData['company']?.toString() ?? '';
      final designation = widget.jobData['designation']?.toString() ?? '';

      final matches = await ReferralService.findSuitableAlumni(
        company: company,
        jobTitle: designation,
        ownerId: ownerId,
      );

      // Filter strictly to role == 'alumni' or priority == 1
      for (var m in matches) {
        final role = (m['role'] ?? '').toString().toLowerCase();
        if (role == 'alumni' || m['priority'] == 1) {
          fetchedAlumni.add(m);
        }
      }
    }

    if (mounted) {
      setState(() {
        _alumniList = fetchedAlumni;
        if (_alumniList.isNotEmpty) {
          _selectedAlumniUid = _alumniList.first['id']?.toString();
          _selectedAlumniName =
              _alumniList.first['name']?.toString() ?? 'Alumnus';
        }
        _loadingAlumni = false;
      });
    }
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (res != null && res.files.isNotEmpty) {
      final file = res.files.single;
      // Validate file size (max 10MB)
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("File size exceeds 10MB limit. Please select a smaller file."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      setState(() {
        _selectedFile = file;
      });
    }
  }

  Future<void> _submitReferralRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_isInterested == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select whether you are interested in this role."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedFile == null && _existingResumeUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload a resume or attach your profile resume."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedAlumniUid == null || _selectedAlumniUid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an alumnus to request a referral from."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check duplicate
    final hasDuplicate = await ReferralService.hasActiveReferralRequest(
      jobId: widget.jobId,
      alumniUid: _selectedAlumniUid!,
    );

    if (hasDuplicate && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You already have an active referral request with this alumnus for this role."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      String finalResumeUrl = _existingResumeUrl;

      // Upload new file if selected
      if (_selectedFile != null && _selectedFile!.path != null) {
        final uploaded =
            await UploadService.uploadDocument(File(_selectedFile!.path!));
        if (uploaded.isNotEmpty) {
          finalResumeUrl = uploaded;
        }
      }

      final designation = widget.jobData['designation']?.toString() ?? 'Role';
      final company = widget.jobData['company']?.toString() ?? 'Company';

      // 1. Send Referral Request
      await ReferralService.sendReferralRequest(
        jobId: widget.jobId,
        jobTitle: designation,
        company: company,
        alumniUid: _selectedAlumniUid!,
        alumniName: _selectedAlumniName,
        resumeUrl: finalResumeUrl,
        message: _messageController.text.trim(),
        isInterested: _isInterested!,
      );

      // 2. Also record in job_applications
      await FirebaseFirestore.instance.collection('job_applications').add({
        'jobId': widget.jobId,
        'studentUid': uid,
        'jobTitle': designation,
        'company': company,
        'resumeUrl': finalResumeUrl,
        'isInterested': _isInterested!,
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending_review',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Referral request sent to $_selectedAlumniName! Shown in Received Requests.'),
            backgroundColor: AppColors.accentEmerald,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit referral request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designation = widget.jobData['designation']?.toString() ?? 'Job Role';
    final company = widget.jobData['company']?.toString() ?? '';
    final location = widget.jobData['location']?.toString() ?? '';
    final experience = widget.jobData['experience']?.toString() ?? '';

    final isResumeReady = _selectedFile != null || _existingResumeUrl.isNotEmpty;
    final canSubmit = isResumeReady && _isInterested != null && !_submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply & Request Referral',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── JOB SUMMARY CARD ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryNeon.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    designation,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${company.isNotEmpty ? company : ''}${location.isNotEmpty ? ' • $location' : ''}',
                    style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  if (experience.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Experience: $experience',
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── STEP 1: UPLOAD / SELECT RESUME ─────────────────────────────
            Text(
              "1. Upload Resume",
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),

            if (_selectedFile != null)
              // File selected view with clear button (✕)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentEmerald.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentEmerald.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: AppColors.accentEmerald, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                      onPressed: () => setState(() => _selectedFile = null),
                    ),
                  ],
                ),
              )
            else
              // Default upload button box
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryNeon, size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        "Upload Resume",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "PDF / DOC / DOCX (Max 10MB)",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      if (_existingResumeUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNeon.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Profile resume is attached. Tap above to replace with a new file.",
                            style: TextStyle(fontSize: 10, color: AppColors.primaryNeon),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ── STEP 2: ARE YOU INTERESTED? (RADIO BUTTONS) ─────────────────
            Text(
              "2. Are you interested in this opportunity?",
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: const Text('Yes, I am actively interested in this role',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    value: true,
                    groupValue: _isInterested,
                    activeColor: AppColors.primaryNeon,
                    onChanged: (val) {
                      if (val != null) setState(() => _isInterested = val);
                    },
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  RadioListTile<bool>(
                    title: const Text('No, just exploring options passively',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    value: false,
                    groupValue: _isInterested,
                    activeColor: AppColors.primaryNeon,
                    onChanged: (val) {
                      if (val != null) setState(() => _isInterested = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── STEP 3: SELECT ALUMNUS FOR REFERRAL ─────────────────────────
            Text(
              "3. Select Alumnus for Referral",
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingAlumni)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_alumniList.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "No specific alumni found for this company yet. Your referral request will be posted globally.",
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAlumniUid,
                    isExpanded: true,
                    dropdownColor: theme.cardColor,
                    items: _alumniList.map((a) {
                      final name = a['name']?.toString() ?? 'Alumnus';
                      final reason = a['matchReason']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: a['id'].toString(),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            if (reason.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNeon.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(reason,
                                    style: const TextStyle(
                                        color: AppColors.primaryNeon,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final match = _alumniList
                            .firstWhere((element) => element['id'] == val);
                        setState(() {
                          _selectedAlumniUid = val;
                          _selectedAlumniName =
                              match['name']?.toString() ?? 'Alumnus';
                        });
                      }
                    },
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ── STEP 4: MESSAGE / NOTE TO ALUMNUS ───────────────────────────
            Text(
              "4. Message to Alumnus (Optional)",
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Add a note to the alumnus about your background...",
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── SUBMIT BUTTON: ASK FOR REFERRAL ─────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: canSubmit ? _submitReferralRequest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: canSubmit ? 4 : 0,
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.black))
                    : const Icon(Icons.workspace_premium, size: 20),
                label: Text(
                  _submitting ? "Submitting..." : "Ask for Referral",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
