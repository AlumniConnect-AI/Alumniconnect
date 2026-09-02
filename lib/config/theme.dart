import 'package:flutter/material.dart';

/// Cyberpunk + AI + Glassmorphism + Material 3 Design System
class AppColors {
  // ── 🌌 CYBERPUNK BACKGROUNDS ──────────────────────────────────────────────
  static const backgroundDark = Color(0xFF07070A); // Rich Black
  static const cardDark = Color(0xFF111118);       // Charcoal Deep
  static const surfaceDark = Color(0xFF181824);    // Glass Translucent Dark

  static const background = Color(0xFFF8FAFC);     // Light mode background
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF262636);

  // ── ⚡ NEON ACCENTS ───────────────────────────────────────────────────────
  static const primary = Color(0xFF00F5FF);        // Neon Cyan
  static const primaryDark = Color(0xFF047857);    // Deep Emerald
  static const primaryNeon = Color(0xFF00F5FF);    // Neon Cyan
  static const accentPurple = Color(0xFF8A2BE2);   // Electric Purple
  static const accentPink = Color(0xFFFF007F);     // Pink Glow
  static const accentEmerald = Color(0xFF00E676);  // Emerald Green
  static const accentBlue = Color(0xFF007AFF);     // Deep Blue

  static const jobAccent = Color(0xFF2563EB);
  static const eventAccent = Color(0xFF7C3AED);

  static const primarySoft = Color(0x1F00F5FF);
  static const purpleSoft = Color(0x1F8A2BE2);

  // ── 📝 TEXT COLORS ────────────────────────────────────────────────────────
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);

  // ── 🎯 STATUS COLORS ──────────────────────────────────────────────────────
  static const success = Color(0xFF00E676);
  static const warning = Color(0xFFFFB300);
  static const error = Color(0xFFFF2A6D);

  static final ThemeData lightTheme = AppTheme.lightTheme;
  static final ThemeData darkTheme = AppTheme.darkTheme;
}

class AppGradients {
  static const LinearGradient neonCyanPurple = LinearGradient(
    colors: [Color(0xFF00F5FF), Color(0xFF8A2BE2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purplePink = LinearGradient(
    colors: [Color(0xFF8A2BE2), Color(0xFFFF007F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldCyan = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00F5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueViolet = LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF8A2BE2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBanner = LinearGradient(
    colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    primaryColor: AppColors.primaryNeon,
    dividerColor: AppColors.borderDark,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryNeon,
      secondary: AppColors.accentPurple,
      surface: AppColors.cardDark,
      error: AppColors.error,
      onPrimary: Colors.black,
      onSurface: AppColors.textPrimaryDark,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimaryDark, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
      titleLarge: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryNeon,
        foregroundColor: Colors.black,
        elevation: 4,
        shadowColor: AppColors.primaryNeon.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryNeon, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    dividerColor: AppColors.border,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accentPurple,
      surface: AppColors.card,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
    ),
  );
}
