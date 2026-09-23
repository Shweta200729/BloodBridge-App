import 'package:flutter/material.dart';

/// BloodBridge Design System Semantic Color Tokens
/// Dominant visual language: Red, Green, Blue, and White
class AppColors {
  AppColors._();

  // Semantic Primary Colors
  static const Color primaryRed = Color(0xFFD32F2F);      // Primary Red / Action
  static const Color emergencyRed = Color(0xFFD50000);    // High-urgency SOS Emergency Red
  static const Color donorGreen = Color(0xFF2E7D32);      // Donor availability & verification
  static const Color healthcareBlue = Color(0xFF1976D2);  // Healthcare, trust, and information

  // Background & Surfaces
  static const Color backgroundWhite = Color(0xFFF8F9FA); // Clean medical background
  static const Color surfaceWhite = Color(0xFFFFFFFF);    // Card surface
  static const Color surfaceVariant = Color(0xFFF1F3F5);  // Subtle input & chip fill

  // Typography
  static const Color textPrimary = Color(0xFF1A1D20);     // Dark Slate high contrast
  static const Color textSecondary = Color(0xFF6C757D);   // Subtitle & secondary info text
  static const Color borderLight = Color(0xFFE9ECEF);     // Soft border divider

  // Semantic States
  static const Color success = Color(0xFF388E3C);        // Verified / Success green
  static const Color warning = Color(0xFFF57C00);        // Moderate urgency amber
  static const Color error = Color(0xFFD32F2F);          // Error state red
  static const Color info = Color(0xFF0288D1);           // Medical info blue

  // Preserved aliases for backwards compatibility
  static const Color primary = primaryRed;
  static const Color primaryDark = Color(0xFFB71C1C);
  static const Color primaryLight = Color(0xFFFF5252);
  static const Color primaryContainer = Color(0xFFFFEBEE);
  static const Color secondary = healthcareBlue;
  static const Color secondaryDark = Color(0xFF0D47A1);
  static const Color secondaryContainer = Color(0xFFE3F2FD);
  static const Color criticalEmergency = emergencyRed;
  static const Color urgent = warning;
  static const Color lightBackground = backgroundWhite;
  static const Color lightSurface = surfaceWhite;
  static const Color lightSurfaceVariant = surfaceVariant;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color lightBorder = borderLight;

  // Dark Theme surface tokens
  static const Color darkBackground = Color(0xFF121417);
  static const Color darkSurface = Color(0xFF1B1E23);
  static const Color darkSurfaceVariant = Color(0xFF242830);
  static const Color darkTextPrimary = Color(0xFFF8F9FA);
  static const Color darkTextSecondary = Color(0xFFA0AEC0);
  static const Color darkBorder = Color(0xFF2D3748);

  // Soft Card Shadow
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> emergencyGlow = [
    BoxShadow(
      color: emergencyRed.withValues(alpha: 0.35),
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 6),
    ),
  ];
}
