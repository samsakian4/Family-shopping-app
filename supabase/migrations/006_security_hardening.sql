-- 006_security_hardening.sql
-- Fixes found by Supabase's automated security advisor (get_advisors)
-- after 001-005 were applied to a real project. See
-- docs/LOOP_ENGINEERING_LOG.md, "Real Supabase testing" entry, for the
-- full story of how these were found.

-- 1. Pin search_path on the two functions that were missing it (prevents
--    search_path hijacking — an attacker-controlled schema earlier in the
--    resolution path could otherwise shadow trusted objects).
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.generate_invite_code()
returns text
language plpgsql
set search_path = public
as $$
declare
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := '';
  i int;
begin
  for i in 1..6 loop
    result := result || substr(chars, 1 + floor(random() * length(chars))::int, 1);
  end loop;
  return result;
end;
$$;

-- 2. Trigger-only functions must never be directly callable via the REST
--    API (they reference NEW/OLD, which only exist inside trigger
--    execution — calling them directly is useless at best, and exposing
--    them needlessly widens the public API surface). Revoking direct
--    EXECUTE does NOT break the triggers themselves: PostgreSQL trigger
--    firing is authorized by the caller's DML privilege on the table, not
--    by a separate EXECUTE check on the trigger function.
revoke execute on function public.handle_new_user() from anon, authenticated;
revoke execute on function public.recalc_list_estimated_total() from anon, authenticated;
revoke execute on function public.set_updated_at() from anon, authenticated;

-- 3. CRITICAL: purge_expired_trash() had NO caller restriction at all —
--    any signed-in (or possibly anonymous) client could call
--    /rest/v1/rpc/purge_expired_trash and force a system-wide delete of
--    every family's expired trash at once. It's meant to run only from a
--    future cron/Edge Function using the service_role key, which bypasses
--    GRANT/REVOKE entirely — so revoking from anon/authenticated closes
--    the hole with zero impact on its intended use.
revoke execute on function public.purge_expired_trash() from anon, authenticated;
