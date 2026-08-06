#!/usr/bin/env bash
# Production/staging web build. See scripts/run_dev.sh for a note on why
# the anon key is safe to embed here.
set -e

SUPABASE_URL="https://ybzjwtyhvvqyrbfungdu.supabase.co"
SUPABASE_ANON_KEY="sb_publishable_QT157jLQT90SvWVt1v7s-g_SIyCJFw2"

flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=FLAVOR=production
