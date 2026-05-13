import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFFF59E0B); // Premium Amber/Orange
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFFEDD5);
  static const Color onPrimaryContainer = Color(0xFF7C2D12);

  // Secondary (Green verification/badges)
  static const Color secondary = Color(0xFF10B981);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD1FAE5);
  static const Color onSecondaryContainer = Color(0xFF065F46);

  // Surface and Background (Light Mode)
  static const Color surface = Color(0xFFF9FAFB);
  static const Color onSurface = Color(0xFF111827);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF7ED); // Light orange tint
  static const Color surfaceContainer = Color(0xFFFFEDD5);
  static const Color surfaceContainerHigh = Color(0xFFFED7AA);
  static const Color surfaceContainerHighest = Color(0xFFE5E7EB);
  static const Color surfaceVariant = Color(0xFFFFEDD5);
  static const Color onSurfaceVariant = Color(0xFF6B7280);

  // Dark Mode Surface and Background (Neon Nocturne Style)
  static const Color darkSurface = Color(0xFF0B0D11);      // Deep black-blue
  static const Color darkSurfaceContainer = Color(0xFF151921); // Card background
  static const Color darkOnSurface = Color(0xFFF9FAFB);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
  static const Color darkSurfaceContainerHighest = Color(0xFF1E242F);

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
      Color(0xFFF59E0B), 
      Color(0xFFEA580C),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
