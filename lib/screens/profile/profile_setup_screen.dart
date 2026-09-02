import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme.dart';
import '../../services/upload_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final batchController = TextEditingController();
  final departmentController = TextEditingController();
  final designationController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final bioController = TextEditingController();
  final linkedinController = TextEditingController();
  final verificationCodeController = TextEditingController(); // ✅ Staff verification code controller

  String _selectedRole = "Student";
  File? _imageFile;
  bool loading = false;

  // 🖼️ PICK & CROP IMAGE
  Future<void> _pickAndCropImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1080,
      maxHeight: 1080,
    );

    if (picked != null) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (cropped != null) {
        setState(() {
          _imageFile = File(cropped.path);
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (departmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Department required")),
      );
      return;
    }

    // ✅ VERIFY STAFF CODE
    if (_selectedRole == 'Staff') {
      if (verificationCodeController.text.trim() != "EMPDGVC") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid Staff Verification Code")),
        );
        return;
      }
    }

    setState(() => loading = true);

    try {
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await UploadService.uploadImage(_imageFile!);
      }

      final Map<String, dynamic> userData = {
        'department': departmentController.text.trim(),
        'role': _selectedRole,
        'bio': bioController.text.trim(),
        'photoURL': photoUrl,
        'profileCompleted': true,
      };

      if (_selectedRole != 'Staff') {
        userData['batch'] = batchController.text.trim();
        userData['location'] = locationController.text.trim();
        userData['linkedin'] = linkedinController.text.trim();
      }

      if (_selectedRole != 'Student') {
        userData['designation'] = designationController.text.trim();
        userData['company'] = companyController.text.trim();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickAndCropImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55, 
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? const Icon(Icons.person_rounded, size: 60, color: AppColors.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Complete Profile",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              if (_selectedRole != 'Staff')
                _input(context, "Batch", batchController),

              _input(context, "Department", departmentController),
              
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: _inputDecoration(context, "I am a..."),
                  items: ["Student", "Alumni", "Staff"]
                      .map((label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
              ),

              // ✅ STAFF VERIFICATION CODE INPUT
              if (_selectedRole == 'Staff')
                _input(context, "Staff Verification Code (Compulsory)", verificationCodeController),
              
              if (_selectedRole != 'Student') ...[
                _input(context, _selectedRole == "Staff" ? "Position" : "Designation", designationController),
                _input(context, _selectedRole == "Staff" ? "Office/Lab" : "Company", companyController),
              ],

              if (_selectedRole != 'Staff')
                _input(context, "Location", locationController),

              _input(context, "Bio", bioController, maxLines: 3),

              if (_selectedRole != 'Staff')
                _input(context, "LinkedIn URL", linkedinController),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: loading
                    ? Shimmer.fromColors(
                        baseColor: theme.dividerColor,
                        highlightColor: theme.cardColor,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Save & Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ],
          ),
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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
