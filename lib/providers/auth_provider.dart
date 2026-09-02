import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? user;
  bool isLoading = true;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((u) {
      user = u;
      isLoading = false; // 🔴 IMPORTANT: stop loader here
      notifyListeners();
    });
  }

  bool get isLoggedIn => user != null;

  // ================= LOGIN =================
  Future<void> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // authStateChanges will handle user + loading
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ================= REGISTER =================
  Future<void> register(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // authStateChanges will handle user + loading
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    try {
      isLoading = true;
      notifyListeners();

      await _auth.signOut();
      // authStateChanges will handle state
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
