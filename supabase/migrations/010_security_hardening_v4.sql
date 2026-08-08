-- 010_security_hardening_v4.sql
-- Repeated the exact same mistake as 006 -> 007: revoking EXECUTE from
-- `anon` alone is not enough, because PostgreSQL grants EXECUTE to the
-- PUBLIC pseudo-role by default at CREATE FUNCTION time, and anon
-- inherits through PUBLIC. Caught again by immediately re-running the
-- security advisor after 009 — same lesson, this time actually
-- internalized: always revoke FROM PUBLIC for anything meant to be
-- authenticated-only, never just FROM anon.

revoke execute on function public.create_family(text) from public;
revoke execute on function public.join_family_by_code(text) from public;
revoke execute on function public.leave_family() from public;
revoke execute on function public.remove_family_member(uuid) from public;
revoke execute on function public.regenerate_invite_code() from public;
revoke execute on function public.soft_delete_shopping_list(uuid) from public;
revoke execute on function public.restore_shopping_list(uuid) from public;
revoke execute on function public.permanently_delete_shopping_list(uuid) from public;
revoke execute on function public.mark_item_purchased(uuid, boolean, numeric) from public;

-- Re-grant to authenticated explicitly: revoking from PUBLIC also strips
-- it from every role that only had EXECUTE via PUBLIC, including
-- `authenticated` itself, since it never had a separate explicit grant.
grant execute on function public.create_family(text) to authenticated;
grant execute on function public.join_family_by_code(text) to authenticated;
grant execute on function public.leave_family() to authenticated;
grant execute on function public.remove_family_member(uuid) to authenticated;
grant execute on function public.regenerate_invite_code() to authenticated;
grant execute on function public.soft_delete_shopping_list(uuid) to authenticated;
grant execute on function public.restore_shopping_list(uuid) to authenticated;
grant execute on function public.permanently_delete_shopping_list(uuid) to authenticated;
grant execute on function public.mark_item_purchased(uuid, boolean, numeric) to authenticated;
