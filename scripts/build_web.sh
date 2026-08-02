#!/usr/bin/env bash
# Production/staging web build. See scripts/run_dev.sh for a note on why
# the anon key is safe to embed here.
set -e

SUPABASE_URL="https://hvgnlmcfpxkkblyjdvyw.supabase.co"
SUPABASE_ANON_KEY="sb_publishable_t52ZEeJqNJbFl-BKKRqe-A_bj-JOkWl"

flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=FLAVOR=production
