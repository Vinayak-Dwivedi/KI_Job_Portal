import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF1D4ED8); // deeper blue from mockups
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF3B82F6);
  static const Color onPrimaryContainer = Color(0xFFDBEAFE);

  // Secondary (Green verification/badges)
  static const Color secondary = Color(0xFF10B981);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD1FAE5);
  static const Color onSecondaryContainer = Color(0xFF065F46);

  // Surface and Background (Light Mode)
  static const Color surface = Color(0xFFF9FAFB);
  static const Color onSurface = Color(0xFF111827);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F3FF);
  static const Color surfaceContainer = Color(0xFFE8EEFF);
  static const Color surfaceContainerHigh = Color(0xFFE0E8FD);
  static const Color surfaceContainerHighest = Color(0xFFE5E7EB);
  static const Color surfaceVariant = Color(0xFFDBE2F8);
  static const Color onSurfaceVariant = Color(0xFF6B7280);

  // Dark Mode Surface and Background (Dark Theme based on Images 2,3,4)
  static const Color darkSurface = Color(0xFF0F1218);      // Very dark background
  static const Color darkSurfaceContainer = Color(0xFF1A1D24); // Card background
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
  static const Color darkSurfaceContainerHighest = Color(0xFF2C313C);

  // Outline
  static const Color outline = Color(0xFF4B5563);
  static const Color outlineVariant = Color(0xFF9CA3AF);

  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);
  
  // Custom Splash Gradient
  static const LinearGradient splashGradient = LinearGradient(
    colors: [
      Color(0xFF1D4ED8), 
      Color(0xFF10B981),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
