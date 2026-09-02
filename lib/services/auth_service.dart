import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔐 Register
  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user!.updateDisplayName(name);

    await _db.collection("users").doc(cred.user!.uid).set({
      "name": name,
      "email": email,
      "role": "alumni",
      "profileCompleted": false,
      "createdAt": DateTime.now(),
    });

    return cred.user;
  }

  // 🔐 Login
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // 🚪 Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 👤 Current user
  User? get currentUser => _auth.currentUser;
}
