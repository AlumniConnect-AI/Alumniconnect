import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/career_gps_provider.dart';
import 'providers/alumni_skill_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/ai/ai_assistant_screen.dart';
import 'screens/ai/ai_hub_screen.dart';
import 'screens/ai/career_gps_screen.dart';
import 'screens/ai/alumni_skill_screen.dart';

// Theme
import 'config/theme.dart';

class AlumniConnectApp extends StatelessWidget {
  const AlumniConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => CareerGPSProvider()),
        ChangeNotifierProvider(create: (_) => AlumniSkillProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AlumniConnect',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            
            // Directly show SplashScreen as the home
            home: const SplashScreen(),
            
            routes: {
              '/login': (_) => LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/profile-setup': (_) => const ProfileSetupScreen(),
              '/home': (_) => const MainShell(),
              '/settings': (_) => const SettingsScreen(),
              '/ai-assistant': (_) => const AiAssistantScreen(),
              '/ai-hub': (_) => const AiHubScreen(),
              '/career-gps': (_) => const CareerGpsScreen(),
              '/alumni-skill': (_) => const AlumniSkillScreen(),
            },
          );
        },
      ),
    );
  }
}
