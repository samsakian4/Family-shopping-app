-- 003_family_system.sql
-- Family, Family Members, Invitations (05_DATABASE_SCHEMA.md, 03_FEATURE_LIST.md
-- FT-010..FT-013). Version 1 rule: one user belongs to at most one family
-- (01_PROJECT_VISION.md / 16_AUTH.md).

create table if not exists public.families (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  owner_id uuid not null references auth.users (id) on delete cascade,
  invitation_code text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.family_members (
  id uuid primary key default uuid_generate_v4(),
  family_id uuid not null references public.families (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null default now(),
  unique (user_id) -- V1: a user belongs to at most one family
);

create table if not exists public.invitations (
  id uuid primary key default uuid_generate_v4(),
  family_id uuid not null references public.families (id) on delete cascade,
  invitation_code text not null unique,
  status text not null default 'active' check (status in ('active', 'used', 'expired', 'revoked')),
  expires_at timestamptz not null default (now() + interval '7 days'),
  created_by uuid not null references auth.users (id),
  used_by uuid references auth.users (id),
  created_at timestamptz not null default now()
);

drop trigger if exists trg_families_updated_at on public.families;
create trigger trg_families_updated_at
  before update on public.families
  for each row execute function public.set_updated_at();

create index if not exists idx_family_members_family_id on public.family_members (family_id);
create index if not exists idx_invitations_family_id on public.invitations (family_id);
create index if not exists idx_invitations_code on public.invitations (invitation_code);

-- ---------------------------------------------------------------------
-- Helper: short human-friendly invitation code (e.g. "K7J2P9").
-- ---------------------------------------------------------------------
create or replace function public.generate_invite_code()
returns text
language plpgsql
as $$
declare
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no O/0/I/1 ambiguity
  result text := '';
  i int;
begin
  for i in 1..6 loop
    result := result || substr(chars, 1 + floor(random() * length(chars))::int, 1);
  end loop;
  return result;
end;
$$;

-- ---------------------------------------------------------------------
-- RPC: create_family — atomic "create family + become owner" (FT-010).
-- ---------------------------------------------------------------------
create or replace function public.create_family(p_name text)
returns public.families
language plpgsql
security definer set search_path = public
as $$
declare
  v_family public.families;
  v_code text;
begin
  if exists (select 1 from public.family_members where user_id = auth.uid()) then
    raise exception 'ALREADY_IN_FAMILY' using errcode = 'P0001';
  end if;

  v_code := public.generate_invite_code();
  insert into public.families (name, owner_id, invitation_code)
  values (trim(p_name), auth.uid(), v_code)
  returning * into v_family;

  insert into public.family_members (family_id, user_id, role)
  values (v_family.id, auth.uid(), 'owner');

  return v_family;
end;
$$;

-- ---------------------------------------------------------------------
-- RPC: join_family_by_code — atomic "validate code + join" (FT-011).
-- ---------------------------------------------------------------------
create or replace function public.join_family_by_code(p_code text)
returns public.families
language plpgsql
security definer set search_path = public
as $$
declare
  v_family public.families;
begin
  if exists (select 1 from public.family_members where user_id = auth.uid()) then
    raise exception 'ALREADY_IN_FAMILY' using errcode = 'P0001';
  end if;

  select f.* into v_family
  from public.families f
  where f.invitation_code = upper(trim(p_code));

  if v_family.id is null then
    raise exception 'INVALID_CODE' using errcode = 'P0002';
  end if;

  insert into public.family_members (family_id, user_id, role)
  values (v_family.id, auth.uid(), 'member');

  return v_family;
end;
$$;

-- ---------------------------------------------------------------------
-- RPC: leave_family — self-service leave (FT-012). Owner cannot leave;
-- must transfer ownership or delete the family first.
-- ---------------------------------------------------------------------
create or replace function public.leave_family()
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_role text;
begin
  select role into v_role from public.family_members where user_id = auth.uid();

  if v_role is null then
    raise exception 'NOT_IN_FAMILY' using errcode = 'P0003';
  end if;
  if v_role = 'owner' then
    raise exception 'OWNER_CANNOT_LEAVE' using errcode = 'P0004';
  end if;

  delete from public.family_members where user_id = auth.uid();
end;
$$;

-- ---------------------------------------------------------------------
-- RPC: remove_member — owner/admin removes another member (FT-012).
-- ---------------------------------------------------------------------
create or replace function public.remove_family_member(p_member_user_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_caller_role text;
  v_caller_family uuid;
  v_target_family uuid;
  v_target_role text;
begin
  select role, family_id into v_caller_role, v_caller_family
  from public.family_members where user_id = auth.uid();

  select family_id, role into v_target_family, v_target_role
  from public.family_members where user_id = p_member_user_id;

  if v_caller_role is null or v_caller_role not in ('owner', 'admin') then
    raise exception 'PERMISSION_DENIED' using errcode = 'P0005';
  end if;
  if v_target_family is null or v_target_family <> v_caller_family then
    raise exception 'NOT_SAME_FAMILY' using errcode = 'P0006';
  end if;
  if v_target_role = 'owner' then
    raise exception 'CANNOT_REMOVE_OWNER' using errcode = 'P0007';
  end if;

  delete from public.family_members where user_id = p_member_user_id;
end;
$$;

-- ---------------------------------------------------------------------
-- RPC: regenerate_invite_code — owner/admin only (FT-011).
-- ---------------------------------------------------------------------
create or replace function public.regenerate_invite_code()
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_family_id uuid;
  v_role text;
  v_code text;
begin
  select family_id, role into v_family_id, v_role
  from public.family_members where user_id = auth.uid();

  if v_role is null or v_role not in ('owner', 'admin') then
    raise exception 'PERMISSION_DENIED' using errcode = 'P0005';
  end if;

  v_code := public.generate_invite_code();
  update public.families set invitation_code = v_code where id = v_family_id;
  return v_code;
end;
$$;

-- ---------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.invitations enable row level security;

-- families: readable by its own members only
create policy "families_select_members"
  on public.families for select
  using (
    id in (select family_id from public.family_members where user_id = auth.uid())
  );

create policy "families_update_owner"
  on public.families for update
  using (owner_id = auth.uid());

create policy "families_delete_owner"
  on public.families for delete
  using (owner_id = auth.uid());

-- No direct insert policy: families are only created via create_family().

-- family_members: readable by members of the same family
create policy "family_members_select_same_family"
  on public.family_members for select
  using (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

-- No direct insert/update/delete policies: all writes go through the
-- security-definer RPC functions above, which enforce role checks.

-- invitations: owner/admin of the family can view its invitation history
create policy "invitations_select_owner_admin"
  on public.invitations for select
  using (
    family_id in (
      select family_id from public.family_members
      where user_id = auth.uid() and role in ('owner', 'admin')
    )
  );

-- ---------------------------------------------------------------------
-- Extend profiles RLS (created in 001_...sql) so family members can see
-- each other's basic profile (display name, avatar) — needed for the
-- Members screen (10_UI_UX.md - Family Screens). This is an ADDITIONAL
-- policy, evaluated with OR alongside "profiles_select_own"
-- (26_DATABASE_MIGRATION_STRATEGY.md - never break existing data/access).
-- ---------------------------------------------------------------------
create policy "profiles_select_family_members"
  on public.profiles for select
  using (
    id in (
      select fm2.user_id
      from public.family_members fm1
      join public.family_members fm2 on fm1.family_id = fm2.family_id
      where fm1.user_id = auth.uid()
    )
  );
