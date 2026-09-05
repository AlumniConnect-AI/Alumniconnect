import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../services/upload_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final nameController = TextEditingController();
  final batchController = TextEditingController();
  final departmentController = TextEditingController();
  final designationController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final bioController = TextEditingController();
  final linkedinController = TextEditingController();

  String _selectedRole = "Student";
  String _rawRole = "student"; // Preserve original role from DB
  bool _isRoleLocked = false;
  File? _imageFile;
  String? _existingPhotoUrl;
  bool _isAvailableForMentoring = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    nameController.dispose();
    batchController.dispose();
    departmentController.dispose();
    designationController.dispose();
    companyController.dispose();
    locationController.dispose();
    bioController.dispose();
    linkedinController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final d = snap.data() ?? {};

      nameController.text = d['name'] ?? "";
      batchController.text = d['batch'] ?? "";
      departmentController.text = d['department'] ?? "";
      designationController.text = d['designation'] ?? "";
      companyController.text = d['company'] ?? "";
      locationController.text = d['location'] ?? "";
      bioController.text = d['bio'] ?? "";
      linkedinController.text = d['linkedin'] ?? "";
      _existingPhotoUrl = d['photoURL'];
      _isAvailableForMentoring = d['isMentor'] ?? false;
      _rawRole = d['role'] ?? "student";

      final roleLower = _rawRole.toString().toLowerCase();
      if (roleLower == 'staff') {
        _selectedRole = 'Staff';
        _isRoleLocked = true;
      } else if (roleLower == 'alumni' ||
          roleLower == 'pending_alumni_verification') {
        _selectedRole = 'Alumni';
      } else {
        _selectedRole = 'Student';
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => loading = true);

    try {
      String? photoUrl = _existingPhotoUrl;
      if (_imageFile != null) {
        photoUrl = await UploadService.uploadImage(_imageFile!);
      }

      String roleToSave = _selectedRole.toLowerCase();

      // Prevent bypassing alumni verification
      if (_rawRole == 'pending_alumni_verification' &&
          _selectedRole == 'Alumni') {
        roleToSave = 'pending_alumni_verification';
      }

      final Map<String, dynamic> updateData = {
        'name': nameController.text.trim(),
        'department': departmentController.text.trim(),
        'role': roleToSave,
        'bio': bioController.text.trim(),
        'photoURL': photoUrl,
      };

      // Conditional Data Sync
      if (_selectedRole == 'Staff') {
        updateData['batch'] = "";
        updateData['location'] = "";
        updateData['linkedin'] = "";
        updateData['designation'] = designationController.text.trim();
        updateData['company'] = companyController.text.trim();
        updateData['isMentor'] = _isAvailableForMentoring;
      } else if (_selectedRole == 'Alumni') {
        updateData['batch'] = batchController.text.trim();
        updateData['location'] = locationController.text.trim();
        updateData['linkedin'] = linkedinController.text.trim();
        updateData['designation'] = designationController.text.trim();
        updateData['company'] = companyController.text.trim();
        updateData['isMentor'] = false;
      } else {
        // Student
        updateData['batch'] = batchController.text.trim();
        updateData['location'] = locationController.text.trim();
        updateData['linkedin'] = linkedinController.text.trim();
        updateData['designation'] = "";
        updateData['company'] = "";
        updateData['isMentor'] = false;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: AppColors.accentEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving changes: $e"),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryNeon),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ── Profile Photo Selector ──────────────────────────────
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primaryNeon, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primaryNeon.withOpacity(0.25),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor:
                                AppColors.primaryNeon.withOpacity(0.15),
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_existingPhotoUrl != null &&
                                        _existingPhotoUrl!.isNotEmpty
                                    ? NetworkImage(_existingPhotoUrl!)
                                    : null) as ImageProvider?,
                            child: (_imageFile == null &&
                                    (_existingPhotoUrl == null ||
                                        _existingPhotoUrl!.isEmpty))
                                ? const Icon(Icons.person,
                                    size: 54, color: AppColors.primaryNeon)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNeon,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.black, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Form Inputs ──────────────────────────────────────────
                  _input(context, "Full Name", nameController, Icons.person_outline),

                  if (_selectedRole != 'Staff')
                    _input(context, "Batch (e.g. 2020-2024)", batchController,
                        Icons.school_outlined),

                  _input(context, "Department", departmentController,
                      Icons.domain_outlined),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: _inputDecoration(
                          context, "I am a...", Icons.badge_outlined),
                      dropdownColor: theme.cardColor,
                      onChanged: _isRoleLocked
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRole = value;
                                  if (_selectedRole != 'Staff') {
                                    _isAvailableForMentoring = false;
                                  }
                                });
                              }
                            },
                      items: ["Student", "Alumni", "Staff"]
                          .where((role) =>
                              _isRoleLocked ? role == 'Staff' : role != 'Staff')
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(label,
                                    style: TextStyle(
                                        color: theme.textTheme.bodyLarge?.color)),
                              ))
                          .toList(),
                    ),
                  ),

                  if (_isRoleLocked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14, top: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 14, color: AppColors.accentBlue),
                          const SizedBox(width: 6),
                          Text(
                            "Staff role is verified and cannot be changed.",
                            style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  if (_selectedRole != 'Student') ...[
                    _input(
                        context,
                        _selectedRole == "Staff" ? "Position" : "Designation",
                        designationController,
                        Icons.work_outline),
                    _input(
                        context,
                        _selectedRole == "Staff" ? "Office/Lab" : "Company",
                        companyController,
                        Icons.business_outlined),
                  ],

                  if (_selectedRole != 'Staff')
                    _input(context, "Location", locationController,
                        Icons.location_on_outlined),

                  _input(context, "Bio", bioController, Icons.format_quote_outlined,
                      maxLines: 4),

                  if (_selectedRole != 'Staff')
                    _input(context, "LinkedIn URL", linkedinController, Icons.link_outlined),

                  const SizedBox(height: 10),

                  // Mentorship Toggle (Staff only)
                  if (_selectedRole == 'Staff')
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: theme.dividerColor.withOpacity(0.5)),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          "Available for Mentoring",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: const Text(
                          "Users can reach out to you for guidance.",
                          style: TextStyle(fontSize: 12),
                        ),
                        activeColor: AppColors.primaryNeon,
                        value: _isAvailableForMentoring,
                        onChanged: (val) =>
                            setState(() => _isAvailableForMentoring = val),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Save Button ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppGradients.neonCyanPurple,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryNeon.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _input(
    BuildContext context,
    String hint,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: _inputDecoration(context, hint, icon),
      ),
    );
  }

  InputDecoration _inputDecoration(
      BuildContext context, String hint, IconData icon) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
      prefixIcon:
          Icon(icon, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryNeon, width: 1.5),
      ),
    );
  }
}
