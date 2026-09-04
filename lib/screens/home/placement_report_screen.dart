import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/outcome_tracking_service.dart';
import '../../services/role_flip_service.dart';

class PlacementReportScreen extends StatefulWidget {
  final String uid;
  const PlacementReportScreen({super.key, required this.uid});

  @override
  State<PlacementReportScreen> createState() => _PlacementReportScreenState();
}

class _PlacementReportScreenState extends State<PlacementReportScreen> {
  String _selectedStatus = 'trained';
  String? _selectedNonPlacementReason;
  String? _selectedEmploymentType;
  final _employerCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _loading = false;

  final _statuses = [
    _StatusOption('trained', 'Trained', Icons.school, AppColors.primary),
    _StatusOption('placed', 'Placed', Icons.work, AppColors.accentEmerald),
    _StatusOption('self_employed', 'Self-Employed', Icons.store, AppColors.accentBlue),
    _StatusOption('apprenticeship', 'Apprenticeship', Icons.engineering, AppColors.accentPurple),
    _StatusOption('still_searching', 'Still Searching', Icons.search, AppColors.warning),
  ];

  final _nonPlacementReasons = [
    'No relevant openings',
    'Relocated',
    'Low wage offers',
    'Pursuing further studies',
    'Other',
  ];

  bool get _showNonPlacementReason {
    if (_selectedStatus != 'still_searching') return false;
    return true;
  }

  bool get _showEmployerField =>
      _selectedStatus == 'placed' || _selectedStatus == 'self_employed';

  @override
  void dispose() {
    _employerCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    try {
      // Map display status to Firestore status
      String firestoreStatus;
      String? employmentType;
      switch (_selectedStatus) {
        case 'placed':
          firestoreStatus = 'placed';
          employmentType = _selectedEmploymentType ?? 'formal';
          break;
        case 'self_employed':
          firestoreStatus = 'placed';
          employmentType = 'self_employed';
          break;
        case 'apprenticeship':
          firestoreStatus = 'placed';
          employmentType = 'apprenticeship';
          break;
        case 'still_searching':
          firestoreStatus = 'trained';
          employmentType = 'unemployed';
          break;
        default:
          firestoreStatus = 'trained';
      }

      await OutcomeTrackingService.submitCheckIn(
        uid: widget.uid,
        status: firestoreStatus,
        employmentType: employmentType,
        employerName: _employerCtrl.text.trim().isEmpty
            ? null
            : _employerCtrl.text.trim(),
        nonPlacementReason: _selectedNonPlacementReason,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      // Trigger A: auto-check for alumni eligibility
      await RoleFlipService.checkTriggerA(widget.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Placement status updated successfully! ✅"),
            backgroundColor: AppColors.accentEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // ── Log the EXACT Firestore error code for debugging ─────────────────
      dev.log('[PlacementReport] Submit error: ${e.runtimeType}: $e');
      if (e is FirebaseException) {
        dev.log('[PlacementReport] code=${e.code}  message=${e.message}  plugin=${e.plugin}');
      }
      if (mounted) {
        // Show a friendly message — never expose raw Firestore exception strings
        String friendlyMsg = 'Failed to update placement status. Please try again.';
        final raw = e.toString();
        if (raw.contains('network') || raw.contains('unavailable')) {
          friendlyMsg = 'No internet connection. Please check your network and retry.';
        } else if (raw.contains('permission') || raw.contains('PERMISSION_DENIED')) {
          friendlyMsg = 'Permission error (code: permission-denied). Rules not yet deployed — run: firebase deploy --only firestore:rules';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMsg),
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
        title: const Text("Update Placement Status"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Heading ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.emeraldCyan,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.track_changes, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Career Status Check-In",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Help us measure the impact of your training",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Current Employment Status",
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 14),

            // ── Status Selector ────────────────────────────────────────
            ..._statuses.map((s) => _statusTile(s, theme)),

            const SizedBox(height: 20),

            // ── Employer name (if placed/self-employed) ────────────────
            if (_showEmployerField) ...[
              Text(
                "Employer / Company Name",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              _inputField(context, "e.g. Infosys, TCS, My Own Startup",
                  _employerCtrl),
              const SizedBox(height: 20),
            ],

            // ── Non-placement reason (if still searching) ──────────────
            if (_showNonPlacementReason) ...[
              Text(
                "Reason for not being placed yet",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedNonPlacementReason,
                dropdownColor: theme.cardColor,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.cardColor,
                  hintText: "Select reason",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _nonPlacementReasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedNonPlacementReason = v),
              ),
              const SizedBox(height: 20),
            ],

            // ── Optional note ──────────────────────────────────────────
            Text(
              "Additional Note (optional)",
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            _inputField(context, "Any additional context...", _noteCtrl,
                maxLines: 3),

            const SizedBox(height: 32),

            // ── Submit ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.emeraldCyan,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentEmerald.withOpacity(0.3),
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
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text(
                          "Submit Status Update",
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

  Widget _statusTile(_StatusOption s, ThemeData theme) {
    final selected = _selectedStatus == s.value;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedStatus = s.value;
        _selectedNonPlacementReason = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? s.color.withOpacity(0.12) : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? s.color : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(s.icon, color: s.color, size: 22),
            const SizedBox(width: 14),
            Text(
              s.label,
              style: TextStyle(
                color: selected ? s.color : theme.textTheme.bodyLarge?.color,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? s.color : Colors.transparent,
                border: Border.all(color: s.color, width: 1.5),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
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

class _StatusOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  _StatusOption(this.value, this.label, this.icon, this.color);
}
