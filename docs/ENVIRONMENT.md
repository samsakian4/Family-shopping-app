# Environment Setup

This project never hardcodes secrets or provider URLs (08_SECURITY.md,
30_PROJECT_RULES_AND_FINAL_INSTRUCTIONS.md). All configuration is injected
at build/run time via `--dart-define`.

## Required values

| Variable              | Description                                   |
|------------------------|-----------------------------------------------|
| `SUPABASE_URL`          | Your Supabase project URL                     |
| `SUPABASE_ANON_KEY`     | Your Supabase project anon/public key         |
| `FLAVOR`                | `development` (default) or `production`       |
| `AI_PROVIDER_ID`        | Identifier only — actual AI key stays server-side in an Edge Function |
| `PRICE_PROVIDER_ID`     | Identifier only — actual price-provider key stays server-side |

**Never put `SUPABASE_SERVICE_KEY`, AI keys, or price-provider keys in the
Flutter app.** Those belong exclusively inside Supabase Edge Functions
(13_SUPABASE.md, 14_EDGE_FUNCTIONS.md).

## Running locally

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=FLAVOR=development
```

## Building for production

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=FLAVOR=production

flutter build web --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=FLAVOR=production
```

In CI (GitHub Actions), store these as **GitHub Secrets** and pass them
into the `flutter build` step — never commit them
(22_GITHUB_WORKFLOW.md - Secrets Management).

## Code generation

This project uses Riverpod code generation, Freezed, and Isar generators:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run this after adding/changing any `@riverpod`, `@freezed`, or `@Collection`
(Isar) annotated class.

## This project's Supabase instance

Project URL and anon key are already wired into `scripts/run_dev.sh` and
`scripts/build_web.sh` — just run:

```bash
./scripts/run_dev.sh
```

Repository: https://github.com/samsakian4/Family-shopping-app

## Setting up Supabase

1. Create a project at https://supabase.com.
2. Copy the Project URL and anon key into the command above.
3. Apply migrations in `supabase/migrations/` in numeric order
   (26_DATABASE_MIGRATION_STRATEGY.md) — either via the Supabase CLI
   (`supabase db push`) or by running the SQL files through the SQL
   editor in order.
4. Deploy edge functions in `supabase/functions/` via
   `supabase functions deploy <name>` once they exist (Phase: Edge
   Functions).
