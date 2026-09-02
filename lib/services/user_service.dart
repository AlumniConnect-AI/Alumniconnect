import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> completeProfile({
    required String batch,
    required String department,
    required String designation,
    required String company,
    required String linkedin,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _db.collection('users').doc(uid).update({
      'batch': batch,
      'department': department,
      'designation': designation,
      'company': company,
      'linkedin': linkedin,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
