-- 005_shopping_items.sql
-- Categories (FT-022) + Shopping Items (FT-023).

create table if not exists public.categories (
  id uuid primary key default uuid_generate_v4(),
  family_id uuid references public.families (id) on delete cascade, -- null = system default
  name text not null,
  icon text,
  color text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.shopping_items (
  id uuid primary key default uuid_generate_v4(),
  shopping_list_id uuid not null references public.shopping_lists (id) on delete cascade,
  category_id uuid references public.categories (id),
  product_id uuid, -- FK to a future `products` catalog table (Search/AI phase)
  name text not null,
  quantity numeric(10, 2) not null default 1,
  unit text,
  brand text,
  notes text,
  priority integer not null default 0,
  estimated_price numeric(12, 2),
  purchased_price numeric(12, 2),
  purchased boolean not null default false,
  purchased_at timestamptz,
  purchased_by uuid references auth.users (id),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_shopping_items_updated_at on public.shopping_items;
create trigger trg_shopping_items_updated_at
  before update on public.shopping_items
  for each row execute function public.set_updated_at();

create index if not exists idx_shopping_items_list on public.shopping_items (shopping_list_id);
create index if not exists idx_shopping_items_category on public.shopping_items (category_id);
create index if not exists idx_shopping_items_purchased on public.shopping_items (purchased);
create index if not exists idx_categories_family on public.categories (family_id);

-- ---------------------------------------------------------------------
-- Seed default categories (FT-022) — family_id null = visible to everyone.
-- ---------------------------------------------------------------------
insert into public.categories (name, sort_order) values
  ('لبنیات', 1), ('نانوایی', 2), ('گوشت', 3), ('میوه', 4),
  ('سبزیجات', 5), ('نوشیدنی', 6), ('تنقلات', 7), ('نظافت', 8),
  ('بهداشت شخصی', 9), ('غذای منجمد', 10)
on conflict do nothing;

-- ---------------------------------------------------------------------
-- RPC: mark_item_purchased — stamps purchased_by/purchased_at atomically
-- (06_API_SPECIFICATION.md - Mark Purchased: "Automatically stores
-- Purchased By, Purchased At").
-- ---------------------------------------------------------------------
create or replace function public.mark_item_purchased(p_item_id uuid, p_purchased boolean, p_purchased_price numeric default null)
returns public.shopping_items
language plpgsql
security definer set search_path = public
as $$
declare
  v_item public.shopping_items;
begin
  update public.shopping_items
  set purchased = p_purchased,
      purchased_at = case when p_purchased then now() else null end,
      purchased_by = case when p_purchased then auth.uid() else null end,
      purchased_price = case when p_purchased then p_purchased_price else null end
  where id = p_item_id
  returning * into v_item;

  return v_item;
end;
$$;

-- ---------------------------------------------------------------------
-- Trigger: keep shopping_lists.estimated_total in sync with its items
-- (18_PRICE_ESTIMATION_SYSTEM.md - Total = Σ(Product Price × Quantity)).
-- ---------------------------------------------------------------------
create or replace function public.recalc_list_estimated_total()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_list_id uuid;
begin
  v_list_id := coalesce(new.shopping_list_id, old.shopping_list_id);

  update public.shopping_lists
  set estimated_total = coalesce((
    select sum(coalesce(estimated_price, 0) * quantity)
    from public.shopping_items
    where shopping_list_id = v_list_id
  ), 0)
  where id = v_list_id;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_recalc_total_on_items on public.shopping_items;
create trigger trg_recalc_total_on_items
  after insert or update of estimated_price, quantity or delete on public.shopping_items
  for each row execute function public.recalc_list_estimated_total();

-- ---------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------
alter table public.categories enable row level security;
alter table public.shopping_items enable row level security;

-- categories: system defaults (family_id is null) are visible to everyone;
-- custom categories are visible to that family only.
create policy "categories_select"
  on public.categories for select
  using (
    family_id is null
    or family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

create policy "categories_insert_own_family"
  on public.categories for insert
  with check (
    family_id in (select family_id from public.family_members where user_id = auth.uid())
  );

-- shopping_items: visibility mirrors the parent list's visibility
-- (owner or same-family member) — 08_SECURITY.md Principle 1.
create policy "shopping_items_select"
  on public.shopping_items for select
  using (
    exists (
      select 1 from public.shopping_lists l
      where l.id = shopping_list_id
        and (
          l.owner_id = auth.uid()
          or l.family_id in (select family_id from public.family_members where user_id = auth.uid())
        )
    )
  );

create policy "shopping_items_insert"
  on public.shopping_items for insert
  with check (
    exists (
      select 1 from public.shopping_lists l
      where l.id = shopping_list_id
        and (
          l.owner_id = auth.uid()
          or l.family_id in (select family_id from public.family_members where user_id = auth.uid())
        )
    )
  );

create policy "shopping_items_update"
  on public.shopping_items for update
  using (
    exists (
      select 1 from public.shopping_lists l
      where l.id = shopping_list_id
        and (
          l.owner_id = auth.uid()
          or l.family_id in (select family_id from public.family_members where user_id = auth.uid())
        )
    )
  );

create policy "shopping_items_delete"
  on public.shopping_items for delete
  using (
    exists (
      select 1 from public.shopping_lists l
      where l.id = shopping_list_id
        and (
          l.owner_id = auth.uid()
          or l.family_id in (select family_id from public.family_members where user_id = auth.uid())
        )
    )
  );
