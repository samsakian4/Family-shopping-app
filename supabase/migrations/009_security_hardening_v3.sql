-- 009_security_hardening_v3.sql
-- Two findings from re-running the security advisor after Milestone 2
-- Phase 1's migration (008_product_catalog.sql). See
-- docs/LOOP_ENGINEERING_LOG.md, "Milestone 2 Phase 1" entry, for the
-- full story.

-- 1. CRITICAL: mark_item_purchased() had NO ownership/access check at
--    all. Because it's SECURITY DEFINER, it bypasses shopping_items' RLS
--    entirely, so its own internal logic is the ONLY line of defense —
--    and there wasn't one. Any authenticated user could toggle the
--    purchased state (and set an arbitrary purchased_price) on ANY item
--    belonging to ANY family, just by guessing/enumerating a UUID.
create or replace function public.mark_item_purchased(
  p_item_id uuid,
  p_purchased boolean,
  p_purchased_price numeric default null
)
returns public.shopping_items
language plpgsql
security definer set search_path = public
as $$
declare
  v_item public.shopping_items;
begin
  update public.shopping_items si
  set purchased = p_purchased,
      purchased_at = case when p_purchased then now() else null end,
      purchased_by = case when p_purchased then auth.uid() else null end,
      purchased_price = case when p_purchased then p_purchased_price else null end
  where si.id = p_item_id
    and exists (
      select 1 from public.shopping_lists l
      where l.id = si.shopping_list_id
        and (
          l.owner_id = auth.uid()
          or l.family_id in (select family_id from public.family_members where user_id = auth.uid())
        )
    )
  returning * into v_item;

  if v_item.id is null then
    raise exception 'PERMISSION_DENIED_OR_NOT_FOUND' using errcode = 'P0008';
  end if;

  return v_item;
end;
$$;

-- 2. Explicitly revoke EXECUTE from anon on every authenticated-only RPC.
--    Most of these already failed safely for anon (auth.uid() is NULL,
--    blocked by either a NOT NULL constraint or an explicit NULL-role
--    check) but relying on that incidental behavior is fragile. Explicit
--    REVOKE is the correct, self-documenting fix. (Note: as with 006/007,
--    this alone is NOT sufficient — see 010_security_hardening_v4.sql.)
revoke execute on function public.create_family(text) from anon;
revoke execute on function public.join_family_by_code(text) from anon;
revoke execute on function public.leave_family() from anon;
revoke execute on function public.remove_family_member(uuid) from anon;
revoke execute on function public.regenerate_invite_code() from anon;
revoke execute on function public.soft_delete_shopping_list(uuid) from anon;
revoke execute on function public.restore_shopping_list(uuid) from anon;
revoke execute on function public.permanently_delete_shopping_list(uuid) from anon;
revoke execute on function public.mark_item_purchased(uuid, boolean, numeric) from anon;

-- 3. Move pg_trgm out of the public schema (Supabase linter best practice
--    — extensions in `public` can shadow objects and complicate RLS
--    reasoning). pg_trgm is relocatable, so this is a safe no-downtime move.
create schema if not exists extensions;
alter extension pg_trgm set schema extensions;
