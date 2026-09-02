import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> isMutualFollow(String uid1, String uid2) async {
  final f1 = await FirebaseFirestore.instance
      .collection('following')
      .doc(uid1)
      .collection('users')
      .doc(uid2)
      .get();

  final f2 = await FirebaseFirestore.instance
      .collection('following')
      .doc(uid2)
      .collection('users')
      .doc(uid1)
      .get();

  return f1.exists && f2.exists;
}
