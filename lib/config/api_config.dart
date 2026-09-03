import 'package:flutter/foundation.dart';

/// Centralized API configuration for AlumniConnect AI Backend.
///
/// Production URL (Render): https://alumniconnect-ai.onrender.com
/// Local Android emulator:  http://10.0.2.2:8000
/// Local Windows / Web / iOS: http://localhost:8000
///
/// Default environment is set to [ApiEnvironment.local] so local testing
/// using start_ai_server.bat works out of the box without timing out!
class ApiConfig {
  ApiConfig._(); // non-instantiable

  /// Switch between [ApiEnvironment.local] and [ApiEnvironment.production] (Render).
  static const ApiEnvironment environment = ApiEnvironment.production;

  /// Smart base URL that auto-adapts to Android emulator vs Windows/macOS/Web/iOS.
  static String get baseUrl {
    switch (environment) {
      case ApiEnvironment.production:
        return 'https://alumniconnect-jld0.onrender.com';
      case ApiEnvironment.local:
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          return 'http://10.0.2.2:8000'; // Android emulator Loopback IP
        }
        return 'http://localhost:8000'; // Windows / macOS / Linux / Web / iOS simulator
      case ApiEnvironment.localDevice:
        return 'http://192.168.1.100:8000'; // Physical device — update with your LAN IP
    }
  }

  // ── Endpoint paths ──────────────────────────────────────────────────────────
  static String get resumeUpload     => '$baseUrl/resume/upload';
  static String get careerTwin       => '$baseUrl/career-twin/analyze';
  static String get careerGps        => '$baseUrl/career-gps/analyze';
  static String get alumniSkill      => '$baseUrl/alumni-skill/analyze';
  static String get mentorMatch      => '$baseUrl/mentor-match/analyze';
  static String get health           => '$baseUrl/health';

  // ── Timeouts ─────────────────────────────────────────────────────────────────
  // 45s timeout to allow Render free-tier cold starts to wake up cleanly
  static const Duration uploadTimeout  = Duration(seconds: 45);
  static const Duration analyzeTimeout = Duration(seconds: 45);
  static const Duration healthTimeout  = Duration(seconds: 10);

  // ── Retry config ─────────────────────────────────────────────────────────────
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 1);
}

enum ApiEnvironment {
  local,       // Auto-resolves localhost (Windows/Web/iOS) or 10.0.2.2 (Android)
  production,  // Render online URL: https://alumniconnect-jld0.onrender.com
  localDevice, // Physical device: http://<YOUR-LAN-IP>:8000
}
