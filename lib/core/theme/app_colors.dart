import 'package:flutter/material.dart';

/// Central color tokens. Widgets must reference these — never hardcode
/// raw Color(...) values inline (09_DESIGN_SYSTEM.md - Color System).
class AppColors {
  AppColors._();

  // Brand / Primary
  static const Color primary = Color(0xFF3D7BFF);
  static const Color primaryDark = Color(0xFF6C97FF);

  // Secondary
  static const Color secondary = Color(0xFF00BFA6);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1A1C1E);
  static const Color lightBorder = Color(0xFFE5E7EB);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF121316);
  static const Color darkSurface = Color(0xFF1D1F23);
  static const Color darkOnSurface = Color(0xFFECEDEE);
  static const Color darkBorder = Color(0xFF2C2F34);
}
