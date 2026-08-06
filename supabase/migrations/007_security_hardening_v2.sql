-- 007_security_hardening_v2.sql
-- Follow-up to 006. PostgreSQL grants EXECUTE to the PUBLIC pseudo-role
-- by default on every newly created function. Revoking from anon/
-- authenticated alone (006) was NOT enough — both roles still inherited
-- EXECUTE through PUBLIC. Confirmed by re-running the security advisor
-- after applying 006 and seeing the same three functions still flagged
-- as callable by anon/authenticated.
--
-- Lesson for future migrations: any REVOKE meant to lock a function down
-- must include `FROM PUBLIC`, not just the specific Supabase roles.

revoke execute on function public.handle_new_user() from public;
revoke execute on function public.recalc_list_estimated_total() from public;
revoke execute on function public.purge_expired_trash() from public;
revoke execute on function public.set_updated_at() from public;
