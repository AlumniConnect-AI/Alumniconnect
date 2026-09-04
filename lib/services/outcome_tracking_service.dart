import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';

/// CRUD helpers for outcome_tracking/{uid} Firestore collection.
/// One document per user for their entire lifetime — never recreated on role flip.
///
/// ⚠️  FIRESTORE RULE: FieldValue.serverTimestamp() CANNOT be used inside
///     arrayUnion() elements or nested maps within arrays.
///     All timestamps inside checkIn objects use Timestamp.now() (client-side).
///     FieldValue.serverTimestamp() is ONLY used for top-level document fields
///     (e.g., placementDate, lastCheckInAt).
class OutcomeTrackingService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference _doc(String uid) =>
      _db.collection('outcome_tracking').doc(uid);

  /// Returns the current outcome tracking document, or null if none exists.
  static Future<Map<String, dynamic>?> getOutcome(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return snap.data() as Map<String, dynamic>?;
  }

  /// Initialises the outcome_tracking doc for a new user (called at registration).
  static Future<void> initOutcome(String uid) async {
    final snap = await _doc(uid).get();
    if (snap.exists) return; // preserve existing history on role flip
    await _doc(uid).set({
      'status': 'trained',
      'placementDate': null,
      'lastCheckInAt': null,
      'employmentType': null,
      'employerName': null,
      'nonPlacementReason': null,
      'checkIns': [],
    });
    dev.log('[OutcomeTracking] Initialised doc for uid=$uid');
  }

  /// Appends a new check-in to the checkIns array and updates the top-level
  /// status and related fields.
  ///
  /// FIX: Uses Timestamp.now() (client-side) inside the checkIn map,
  /// because FieldValue.serverTimestamp() is not allowed inside arrayUnion()
  /// elements. Top-level fields like [placementDate] and [lastCheckInAt]
  /// continue to use FieldValue.serverTimestamp() safely.
  static Future<void> submitCheckIn({
    required String uid,
    required String status,
    String? employmentType,
    String? employerName,
    String? nonPlacementReason,
    String? note,
  }) async {
    // ✅ Client-side timestamp — safe inside array elements
    final now = Timestamp.now();

    final checkIn = {
      'date': now,              // ← was FieldValue.serverTimestamp() — FIXED
      'status': status,
      'employmentType': employmentType,
      'employerName': employerName,
      'note': note,
      'verified': false,
    };

    final Map<String, dynamic> updates = {
      'status': status,
      'checkIns': FieldValue.arrayUnion([checkIn]),
      // ✅ Top-level field — serverTimestamp() is allowed here
      'lastCheckInAt': FieldValue.serverTimestamp(),
    };

    if (employmentType != null) updates['employmentType'] = employmentType;
    if (employerName != null) updates['employerName'] = employerName;
    if (nonPlacementReason != null) {
      updates['nonPlacementReason'] = nonPlacementReason;
    }
    // ✅ Top-level field — serverTimestamp() is allowed here
    if (status == 'placed') {
      updates['placementDate'] = FieldValue.serverTimestamp();
    }

    await _doc(uid).set(updates, SetOptions(merge: true));
    dev.log('[OutcomeTracking] Check-in submitted: uid=$uid status=$status');
  }

  /// Approves a specific check-in by index — sets verified: true on that entry.
  /// Re-reads, patches the list, and writes back (Firestore arrays don't support
  /// index updates natively).
  static Future<void> approveCheckIn({
    required String studentUid,
    required int checkInIndex,
  }) async {
    final snap = await _doc(studentUid).get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final checkIns = List<dynamic>.from(data['checkIns'] ?? []);
    if (checkInIndex >= checkIns.length) return;

    final entry =
        Map<String, dynamic>.from(checkIns[checkInIndex] as Map);
    entry['verified'] = true;
    entry['verifiedAt'] = Timestamp.now(); // client-side, inside array — safe
    checkIns[checkInIndex] = entry;

    await _doc(studentUid).update({'checkIns': checkIns});
    dev.log('[OutcomeTracking] CheckIn[$checkInIndex] approved for uid=$studentUid');
  }

  /// Returns a stream of the outcome tracking document for real-time updates.
  static Stream<DocumentSnapshot> outcomeStream(String uid) =>
      _doc(uid).snapshots();
}
