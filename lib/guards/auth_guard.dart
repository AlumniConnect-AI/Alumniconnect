import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

// Screens
import '../screens/auth/login_screen.dart';
import '../screens/profile/profile_setup_screen.dart';
import '../screens/main_shell.dart';
import '../screens/splash/splash_screen.dart';

class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();

    // WHILE LOADING: Show static branding (SplashScreen) instead of blank screen
    if (auth.isLoading || userProvider.isLoading) {
      return const SplashScreen(isStatic: true);
    }

    // NOT LOGGED IN → LOGIN
    if (!auth.isLoggedIn) {
      return LoginScreen();
    }

    // LOGGED IN BUT PROFILE NOT COMPLETED → PROFILE SETUP
    if (!userProvider.profileCompleted) {
      return const ProfileSetupScreen();
    }

    // LOGGED IN + PROFILE COMPLETED → MAIN APP
    return const MainShell();
  }
}
