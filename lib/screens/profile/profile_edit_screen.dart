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
      _selectedRole = d['role'] ?? "Student";

      // ✅ Lock the role dropdown if the current role is Staff
      if (_selectedRole == 'Staff') {
        _isRoleLocked = true;
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

      final Map<String, dynamic> updateData = {
        'name': nameController.text.trim(),
        'department': departmentController.text.trim(),
        'role': _selectedRole,
        'bio': bioController.text.trim(),
        'photoURL': photoUrl,
      };

      // ✅ Conditional Data Sync
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

      await FirebaseFirestore.instance.collection('users').doc(uid).update(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving changes: $e")),
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
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                            ? NetworkImage(_existingPhotoUrl!)
                            : null) as ImageProvider?,
                    child: (_imageFile == null && (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 60, color: AppColors.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _input(context, "Full Name", nameController),
            
            if (_selectedRole != 'Staff')
              _input(context, "Batch", batchController),

            _input(context, "Department", departmentController),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: _inputDecoration(context, "I am a..."),
                dropdownColor: theme.cardColor,
                // ✅ Disable dropdown if role is Staff (Locked)
                onChanged: _isRoleLocked ? null : (value) {
                  setState(() {
                    _selectedRole = value!;
                    if (_selectedRole != 'Staff') _isAvailableForMentoring = false;
                  });
                },
                // ✅ HIDE STAFF OPTION FOR STUDENTS/ALUMNI
                items: ["Student", "Alumni", "Staff"]
                    .where((role) => _isRoleLocked ? role == 'Staff' : role != 'Staff')
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
              ),
            ),
            
            // ✅ Info message for Staff
            if (_isRoleLocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 14, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      "Staff role is verified and cannot be changed.",
                      style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                    ),
                  ],
                ),
              ),

            if (_selectedRole != 'Student') ...[
              _input(context, _selectedRole == "Staff" ? "Position" : "Designation", designationController),
              _input(context, _selectedRole == "Staff" ? "Office/Lab" : "Company", companyController),
            ],

            if (_selectedRole != 'Staff')
              _input(context, "Location", locationController),

            _input(context, "Bio", bioController, maxLines: 4),

            if (_selectedRole != 'Staff')
              _input(context, "LinkedIn URL", linkedinController),

            const SizedBox(height: 10),

            // ✅ MENTORSHIP TOGGLE (Only visible for Staff)
            if (_selectedRole == 'Staff')
              SwitchListTile(
                title: const Text(
                  "Available for Mentoring",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Users can reach out to you for guidance."),
                activeThumbColor: AppColors.primary,
                value: _isAvailableForMentoring,
                onChanged: (val) => setState(() => _isAvailableForMentoring = val),
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
      BuildContext context,
      String hint,
      TextEditingController controller, {
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: _inputDecoration(context, hint),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
