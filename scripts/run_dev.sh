#!/usr/bin/env bash
# Convenience script for local development.
#
# The Supabase key below is the ANON/PUBLISHABLE key — by Supabase's own
# design this key is meant to live in client code (it's the equivalent of
# Stripe's pk_... key). Data safety comes from Row Level Security policies
# (see supabase/migrations/*.sql), NOT from hiding this key.
#
# The SERVICE ROLE key must NEVER appear in this repo, this script, or
# anywhere in the Flutter app — it stays only in Supabase Edge Function
# secrets (13_SUPABASE.md, 14_EDGE_FUNCTIONS.md).

set -e

SUPABASE_URL="https://ybzjwtyhvvqyrbfungdu.supabase.co"
SUPABASE_ANON_KEY="sb_publishable_QT157jLQT90SvWVt1v7s-g_SIyCJFw2"

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=FLAVOR=development
