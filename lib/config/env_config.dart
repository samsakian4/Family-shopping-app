/// Environment configuration.
///
/// Rule (08_SECURITY.md / 30_PROJECT_RULES): secrets and environment values
/// must never be hardcoded in source. Values are injected at build time via
/// `--dart-define` (see docs/ENVIRONMENT.md for the exact commands).
///
/// Never commit real keys into this file or into version control.
enum AppFlavor { development, production }

class EnvConfig {
  EnvConfig._();

  static const AppFlavor flavor = String.fromEnvironment('FLAVOR') == 'production'
      ? AppFlavor.production
      : AppFlavor.development;

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Never call external AI/price providers directly from the app.
  /// These are provider *identifiers* only; actual keys live server-side
  /// inside Supabase Edge Functions (see 13_SUPABASE.md / 19_AI_INTEGRATION.md).
  static const String aiProviderId = String.fromEnvironment(
    'AI_PROVIDER_ID',
    defaultValue: 'default',
  );

  static const String priceProviderId = String.fromEnvironment(
    'PRICE_PROVIDER_ID',
    defaultValue: 'default',
  );

  static bool get isProduction => flavor == AppFlavor.production;
  static bool get isDevelopment => flavor == AppFlavor.development;

  static void assertValid() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Run with:\n'
        '  flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...\n'
        'See docs/ENVIRONMENT.md',
      );
    }
  }
}
