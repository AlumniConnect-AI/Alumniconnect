import 'package:flutter/material.dart';

// Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

// Main screens
import '../screens/splash/splash_screen.dart';
import '../screens/alumni/alumni_list_screen.dart';
import '../screens/jobs/jobs_list_screen.dart';
import '../screens/events/events_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/main_shell.dart';
import '../screens/ai/ai_assistant_screen.dart';
import '../screens/ai/ai_hub_screen.dart';
import '../screens/ai/career_gps_screen.dart';
import '../screens/ai/alumni_skill_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';   // fixed: was '/' (same as splash)
  static const String alumni = '/alumni';
  static const String jobs = '/jobs';
  static const String events = '/events';
  static const String profile = '/profile';
  static const String aiAssistant = '/ai-assistant';
  static const String aiHub = '/ai-hub';
  static const String careerGps = '/career-gps';
  static const String alumniSkill = '/alumni-skill';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const MainShell(),
    alumni: (context) => const AlumniListScreen(),
    jobs: (context) => const JobsListScreen(),
    events: (context) => const EventsListScreen(),
    profile: (context) => const ProfileScreen(),
    aiAssistant: (context) => const AiAssistantScreen(),
    aiHub: (context) => const AiHubScreen(),
    careerGps: (context) => const CareerGpsScreen(),
    alumniSkill: (context) => const AlumniSkillScreen(),
  };
}
