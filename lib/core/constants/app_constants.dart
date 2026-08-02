/// General application-wide constants that are NOT configuration
/// (configuration/secrets live in [EnvConfig]).
class AppConstants {
  AppConstants._();

  static const String appName = 'Family Shopping Assistant';

  // Password rules (08_SECURITY.md / 16_AUTH.md)
  static const int passwordMinLength = 8;

  // Sync retry policy (07_SYNC_ENGINE.md)
  static const List<Duration> syncRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];
  static const Duration syncMaxBackoff = Duration(minutes: 15);

  // Trash retention (03_FEATURE_LIST.md - FT-025)
  static const int trashRetentionDays = 30;

  // Default shopping categories (03_FEATURE_LIST.md - FT-022)
  static const List<String> defaultCategories = [
    'لبنیات',
    'نانوایی',
    'گوشت',
    'میوه',
    'سبزیجات',
    'نوشیدنی',
    'تنقلات',
    'نظافت',
    'بهداشت شخصی',
    'غذای منجمد',
  ];

  // Performance targets (04_SYSTEM_ARCHITECTURE.md)
  static const Duration searchDebounce = Duration(milliseconds: 300);
}
