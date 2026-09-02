import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  bool isLoading = true;
  bool profileCompleted = false;

  UserProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      // 🔴 USER LOGGED OUT
      if (user == null) {
        profileCompleted = false;
        isLoading = false;
        notifyListeners();
        return;
      }

      isLoading = true;
      notifyListeners();

      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snap.exists) {
          profileCompleted = snap.data()?['profileCompleted'] == true;
        } else {
          profileCompleted = false;
        }
      } catch (e) {
        profileCompleted = false;
      }

      isLoading = false;
      notifyListeners();
    });
  }

  // ================= PROFILE SETUP =================
  // Used during FIRST TIME profile creation
  Future<void> completeProfile(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        ...data,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    profileCompleted = true;
    notifyListeners();
  }

  // ================= STATE UPDATE ONLY =================
  // Used when profile already exists (no Firestore call)
  void setProfileCompleted(bool value) {
    profileCompleted = value;
    notifyListeners();
  }

  // ================= RESET (OPTIONAL SAFETY) =================
  void reset() {
    isLoading = false;
    profileCompleted = false;
    notifyListeners();
  }
}
