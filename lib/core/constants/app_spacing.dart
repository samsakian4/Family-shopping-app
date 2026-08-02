/// Spacing scale — base unit 4px (09_DESIGN_SYSTEM.md).
/// Never hardcode raw spacing numbers in widgets; use these tokens.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double smMd = 12;
  static const double md = 16;
  static const double mdLg = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
}

/// Border radius scale (09_DESIGN_SYSTEM.md).
class AppRadius {
  AppRadius._();

  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double extraLarge = 32;
}

/// Animation durations (09_DESIGN_SYSTEM.md / 25_UI_UX_DESIGN_SYSTEM.md).
/// Rule: 150-300ms, never long/distracting animations.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 300);
}
