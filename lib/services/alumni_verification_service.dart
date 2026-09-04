import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight alumni verification against verified_students collection.
/// Used at signup and via manual role-flip trigger.
///
/// On first run (demo), seeds sample records so the SIH demo is not blocked.
class AlumniVerificationService {
  static final _db = FirebaseFirestore.instance;

  /// Seeds sample verified_student records for demo purposes.
  /// Call once from register or admin init; idempotent.
  static Future<void> seedDemoData() async {
    final col = _db.collection('verified_students');
    final existing = await col.limit(1).get();
    if (existing.docs.isNotEmpty) return; // already seeded

    final sampleRecords = [
      {'collegeId': 'STU2021001', 'graduationYear': 2021, 'name': 'Priya Sharma'},
      {'collegeId': 'STU2021002', 'graduationYear': 2021, 'name': 'Rahul Gupta'},
      {'collegeId': 'STU2022001', 'graduationYear': 2022, 'name': 'Ananya Patel'},
      {'collegeId': 'STU2022002', 'graduationYear': 2022, 'name': 'Vikram Singh'},
      {'collegeId': 'STU2023001', 'graduationYear': 2023, 'name': 'Kavya Nair'},
      {'collegeId': 'STU2023002', 'graduationYear': 2023, 'name': 'Aditya Kumar'},
      {'collegeId': 'STU2024001', 'graduationYear': 2024, 'name': 'Neha Reddy'},
      {'collegeId': 'STU2024002', 'graduationYear': 2024, 'name': 'Arjun Mehta'},
    ];

    final batch = _db.batch();
    for (final r in sampleRecords) {
      final ref = col.doc(r['collegeId'] as String);
      batch.set(ref, r);
    }
    await batch.commit();
  }

  /// Checks if [collegeId] + [graduationYear] matches a record in
  /// verified_students collection.
  ///
  /// Returns "verified" on match, "pending" otherwise.
  static Future<String> verify({
    required String collegeId,
    required int graduationYear,
  }) async {
    final trimmedId = collegeId.trim().toUpperCase();
    if (trimmedId.isEmpty) return 'pending';

    try {
      final doc = await _db
          .collection('verified_students')
          .doc(trimmedId)
          .get();

      if (!doc.exists) return 'pending';

      final data = doc.data()!;
      final storedYear = data['graduationYear'] as int?;
      return storedYear == graduationYear ? 'verified' : 'pending';
    } catch (_) {
      return 'pending';
    }
  }
}
