import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

import '../screens/auth/login_screen.dart';
import '../screens/profile/profile_setup_screen.dart';
import '../screens/main_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = context.watch<UserProvider>();

    // ⏳ GLOBAL LOADING (WAIT FOR BOTH PROVIDERS)
    if (auth.isLoading || user.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ❌ USER NOT LOGGED IN
    if (!auth.isLoggedIn) {
      return LoginScreen();
    }

    // 🧾 LOGGED IN BUT PROFILE NOT COMPLETED
    if (!user.profileCompleted) {
      return const ProfileSetupScreen();
    }

    // ✅ EVERYTHING OK → MAIN APP
    return const MainShell();
  }
}
