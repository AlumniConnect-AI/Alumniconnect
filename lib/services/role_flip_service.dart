import 'package:cloud_firestore/cloud_firestore.dart';

import 'alumni_verification_service.dart';

/// Handles role-flip logic for the three trigger scenarios:
///
/// Trigger A (automatic): outcome_tracking.status == "placed" AND
///   users.consentGiven == true → sets role to "pending_alumni_verification",
///   prompting the user to complete verification.
///
/// Trigger B (manual): Profile screen button "I've graduated — become an alumnus"
///   → runs verification, sets role to "alumni" on success.
///
/// Trigger C (nudge only): graduationYear passed by 18+ months with no
///   placement report → returns a banner message string, does NOT auto-flip.
class RoleFlipService {
  static final _db = FirebaseFirestore.instance;

  // ── Trigger A ────────────────────────────────────────────────────────────

  /// Call after every placement check-in submission.
  /// If status is "placed" and user has consented, transitions to
  /// "pending_alumni_verification" so the UI can prompt verification.
  static Future<void> checkTriggerA(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final role = data['role'] ?? 'student';
    final consentGiven = data['consentGiven'] ?? false;

    if (role == 'alumni' || !consentGiven) return;

    final outcomeDoc = await _db.collection('outcome_tracking').doc(uid).get();
    if (!outcomeDoc.exists) return;

    final outcomeData = outcomeDoc.data()!;
    final status = outcomeData['status'] ?? '';

    if (status == 'placed') {
      await _db.collection('users').doc(uid).update({
        'role': 'pending_alumni_verification',
      });
    }
  }

  // ── Trigger B ────────────────────────────────────────────────────────────

  /// Manual role flip from profile screen.
  /// Runs verification check; sets role = "alumni" with correct verificationStatus.
  ///
  /// [collegeId] and [graduationYear] must be provided by the user or read
  /// from their existing profile.
  ///
  /// Returns a result message to display in the UI.
  static Future<RoleFlipResult> triggerManualFlip({
    required String uid,
    required String collegeId,
    required int graduationYear,
  }) async {
    final verificationStatus = await AlumniVerificationService.verify(
      collegeId: collegeId,
      graduationYear: graduationYear,
    );

    await _db.collection('users').doc(uid).update({
      'role': 'alumni',
      'verificationStatus': verificationStatus,
      'graduationYear': graduationYear,
    });

    return RoleFlipResult(
      success: true,
      verificationStatus: verificationStatus,
      message: verificationStatus == 'verified'
          ? 'Welcome to the alumni network! Your record has been verified. ✅'
          : 'You\'re now an alumnus! Verification is pending — your college hasn\'t confirmed this record yet.',
    );
  }

  // ── Trigger C ────────────────────────────────────────────────────────────

  /// Checks whether an in-app nudge banner should be shown on the home screen.
  ///
  /// Returns a non-null string if the nudge should be shown, null otherwise.
  static Future<String?> getNudgeBanner(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final data = userDoc.data()!;
    final role = data['role'] ?? 'student';
    final gradYear = data['graduationYear'] as int?;

    if (role != 'student' || gradYear == null) return null;

    // Check if graduation year passed by 18+ months
    final graduationDate = DateTime(gradYear, 6, 1); // approximate mid-year
    final monthsSinceGraduation =
        DateTime.now().difference(graduationDate).inDays ~/ 30;

    if (monthsSinceGraduation < 18) return null;

    // Check if they have any placement check-in
    final outcomeDoc = await _db.collection('outcome_tracking').doc(uid).get();
    if (outcomeDoc.exists) {
      final outcomeData = outcomeDoc.data()!;
      final checkIns = (outcomeData['checkIns'] as List?)?.length ?? 0;
      if (checkIns > 0) return null; // already reported
    }

    return 'It\'s been a while since your graduation! Update your placement status to help us measure our training impact.';
  }
}

/// Result of a role-flip operation (Trigger B).
class RoleFlipResult {
  final bool success;
  final String verificationStatus;
  final String message;

  RoleFlipResult({
    required this.success,
    required this.verificationStatus,
    required this.message,
  });
}
