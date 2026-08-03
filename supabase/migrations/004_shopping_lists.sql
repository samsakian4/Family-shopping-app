-- 004_shopping_lists.sql
-- Personal & Shared shopping lists (03_FEATURE_LIST.md FT-020/FT-021/FT-025).

create table if not exists public.shopping_lists (
  id uuid primary key default uuid_generate_v4(),
  family_id uuid references public.families (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  type text not null check (type in ('personal', 'shared')),
  archived boolean not null default false,
  estimated_total numeric(12, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz, -- soft delete / Trash (FT-025, 30-day retention)
  constraint shopping_lists_shared_requires_family
    check (type = 'personal' or family_id is not null)
);

drop trigger if exists trg_shopping_lists_updated_at on public.shopping_lists;
create trigger trg_shopping_lists_updated_at
  before update on public.shopping_lists
  for each row execute function public.set_updated_at();

create index if not exists idx_shopping_lists_owner on public.shopping_lists (owner_id);
create index if not exists idx_shopping_lists_family on public.shopping_lists (family_id);
create index if not exists idx_shopping_lists_deleted_at on public.shopping_lists (deleted_at);

-- ---------------------------------------------------------------------
-- RPC: soft_delete_shopping_list / restore_shopping_list / purge_trash
-- Kept as functions (rather than raw client updates) so the 30-day Trash
-- retention rule (FT-025) is enforced in one place.
-- ---------------------------------------------------------------------
create or replace function public.soft_delete_shopping_list(p_list_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  update public.shopping_lists
  set deleted_at = now()
  where id = p_list_id
    and (
      owner_id = auth.uid()
      or family_id in (select family_id from public.family_members where user_id = auth.uid())
    );
end;
$$;

create or replace function public.restore_shopping_list(p_list_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  update public.shopping_lists
  set deleted_at = null
  where id = p_list_id
    and deleted_at > now() - interval '30 days'
    and (
      owner_id = auth.uid()
      or family_id in (select family_id from public.family_members where user_id = auth.uid())
    );
end;
$$;

-- Scheduled via a future cron/Edge Function (14_EDGE_FUNCTIONS.md - cleanup).
create or replace function public.purge_expired_trash()
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  delete from public.shopping_lists
  where deleted_at is not null
    and deleted_at < now() - interval '30 days';
end;
$$;

-- User-triggered permanent delete from the Trash screen (FT-025).
create or replace function public.permanently_delete_shopping_list(p_list_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  delete from public.shopping_lists
  where id = p_list_id
    and deleted_at is not null
    and (
      owner_id = auth.uid()
      or family_id in (select family_id from public.family_members where user_id = auth.uid())
    );
end;
$$;

-- ---------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------
alter table public.shopping_lists enable row level security;

create policy "shopping_lists_select"
  on public.shopping_lists for select
  using (
    owner_id = auth.uid()
    or family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

create policy "shopping_lists_insert"
  on public.shopping_lists for insert
  with check (
    owner_id = auth.uid()
    and (
      type = 'personal'
      or family_id in (select family_id from public.family_members where user_id = auth.uid())
    )
  );

create policy "shopping_lists_update"
  on public.shopping_lists for update
  using (
    owner_id = auth.uid()
    or family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

-- No direct delete policy: deletion always goes through
-- soft_delete_shopping_list(); hard delete is never exposed to clients.
