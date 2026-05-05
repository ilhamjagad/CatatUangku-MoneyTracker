import 'package:flutter/material.dart';

/// Konstanta aplikasi untuk fitur login
class AppConstants {
  // App Info
  static const String appName = 'CatatUangku!';

  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String categoriesCollection = 'categories';

  // Route Names
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String mainNavigationRoute = '/main';
  static const String categoryRoute = '/category';
  static const String graphRoute = '/graph';
  static const String transactionFormRoute = '/transaction-form';
}

/// Color palette modern untuk aplikasi dengan gradasi biru premium
class AppColors {
  // Primary Colors - Gradasi Biru Premium
  static const Color primaryDark = Color(0xFF0D47A1); // Biru Tua
  static const Color primaryMid = Color(0xFF1565C0); // Biru Utama
  static const Color primaryLight = Color(0xFF42A5F5); // Biru Muda
  static const Color primaryLighter = Color(0xFF64B5F6); // Biru Muda Terang
  static const Color primary = Color(0xFF1565C0); // Biru Utama
  static const Color secondary = Color(0xFF64B5F6); // Biru Muda Terang
  static const Color accent = Color(0xFFFFFFFF); // Putih

  // Status Colors - Modern
  static const Color error = Color(0xFFEF4444); // Red
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  // Background & Surface - Modern Gradient
  static const Color background = Color(0xFFF8FBFF); // Putih Biru Sangat Muda
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFE3F2FD); // Biru Sangat Muda
  static const Color surfaceLight = Color(0xFFF0F7FF); // Biru Sangat Muda Terang

  // Text Colors - Modern
  static const Color textPrimary = Color(0xFF0D47A1); // Biru Tua
  static const Color textSecondary = Color(0xFF1565C0); // Biru Utama
  static const Color textHint = Color(0xFF64B5F6); // Biru Muda
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White
  static const Color textMuted = Color(0xFF90CAF9); // Biru Muda

  // Border & Divider - Modern
  static const Color border = Color(0xFF90CAF9); // Biru Muda
  static const Color divider = Color(0xFFBBDEFB); // Biru Sangat Muda

  // Additional UI Colors
  static const Color shadow = Color(0x1A0D47A1); // Biru Tua 10%
  static const Color overlay = Color(0x800D47A1); // Biru Tua 50%
  
  // Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [primaryDark, primaryMid],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get secondaryGradient => const LinearGradient(
    colors: [primaryMid, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Theme data untuk aplikasi
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
