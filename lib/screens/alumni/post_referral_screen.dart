import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/theme.dart';

class PostReferralScreen extends StatefulWidget {
  const PostReferralScreen({super.key});

  @override
  State<PostReferralScreen> createState() => _PostReferralScreenState();
}

class _PostReferralScreenState extends State<PostReferralScreen> {
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _selectedType = 'referral';
  bool _loading = false;

  final _types = [
    _TypeOption('job', 'Full-Time Job', Icons.work),
    _TypeOption('internship', 'Internship', Icons.school),
    _TypeOption('referral', 'Referral', Icons.card_giftcard),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _companyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and Company are required")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Write to referrals collection
      await FirebaseFirestore.instance.collection('referrals').add({
        'postedByUid': uid,
        'title': _titleCtrl.text.trim(),
        'companyName': _companyCtrl.text.trim(),
        'type': _selectedType,
        'description': _descriptionCtrl.text.trim(),
        'postedAt': FieldValue.serverTimestamp(),
      });

      // Increment engagementStats.referralsPosted
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'engagementStats.referralsPosted': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Referral posted successfully! 🎉"),
            backgroundColor: AppColors.accentEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _titleCtrl.clear();
        _companyCtrl.clear();
        _descriptionCtrl.clear();
        setState(() => _selectedType = 'referral');
        Navigator.pop(context);
      }
    } catch (e) {
      dev.log('[PostReferral] Submit error: $e');
      if (mounted) {
        String msg = 'Failed to post referral. Please try again.';
        final raw = e.toString();
        if (raw.contains('permission-denied') || raw.contains('PERMISSION_DENIED')) {
          msg = 'Permission denied. Please log out and log back in, then try again.';
        } else if (raw.contains('network') || raw.contains('unavailable')) {
          msg = 'No internet connection. Please check your network.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post a Referral"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppGradients.blueViolet,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBlue.withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.white, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Share an Opportunity",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Help students at your alma mater get a foot in the door",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Type selector ──────────────────────────────────────────
            Text(
              "Opportunity Type",
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _types.map((t) {
                final selected = _selectedType == t.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = t.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: selected ? AppGradients.blueViolet : null,
                        color: selected ? null : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : theme.dividerColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(t.icon,
                              color: selected ? Colors.white : AppColors.primary,
                              size: 20),
                          const SizedBox(height: 4),
                          Text(
                            t.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Form fields ────────────────────────────────────────────
            _label(context, "Title / Role"),
            const SizedBox(height: 8),
            _input(context, "e.g. Backend Engineer Intern", _titleCtrl),

            const SizedBox(height: 16),

            _label(context, "Company Name"),
            const SizedBox(height: 8),
            _input(context, "e.g. Google, Infosys, My Startup", _companyCtrl),

            const SizedBox(height: 16),

            _label(context, "Description"),
            const SizedBox(height: 8),
            _input(
              context,
              "Share details about the role, skills needed, how to apply...",
              _descriptionCtrl,
              maxLines: 5,
            ),

            const SizedBox(height: 32),

            // ── Submit ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.blueViolet,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text(
                          "Post Opportunity",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
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

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  Widget _input(
    BuildContext context,
    String hint,
    TextEditingController ctrl, {
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
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
      ),
    );
  }
}

class _TypeOption {
  final String value;
  final String label;
  final IconData icon;
  _TypeOption(this.value, this.label, this.icon);
}
