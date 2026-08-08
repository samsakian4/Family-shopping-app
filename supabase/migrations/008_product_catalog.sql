-- 008_product_catalog.sql
-- Milestone 2, Phase 1: Product Catalog (05_DATABASE_SCHEMA.md Part 2,
-- 36_MILESTONE_2.md). A shared catalog — not per-family — so the whole
-- user base benefits from entries anyone adds (17_PRODUCT_SEARCH...md).

create table if not exists public.brands (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  logo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default uuid_generate_v4(),
  category_id uuid references public.categories (id),
  brand_id uuid references public.brands (id),
  name text not null,
  normalized_name text not null,
  package_size text,
  barcode text,
  image_url text,
  default_unit text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint products_unique_brand_name_size unique (brand_id, name, package_size)
);

create table if not exists public.product_aliases (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references public.products (id) on delete cascade,
  alias text not null,
  created_at timestamptz not null default now()
);

-- Per-user purchase history / favorites (05_DATABASE_SCHEMA.md -
-- user_product_history). Feeds Milestone 2 Phase 5 (Shopping
-- Intelligence) — created now so Phase 1's `product_id` link on
-- shopping_items has somewhere to record usage going forward.
create table if not exists public.user_product_history (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  purchase_count integer not null default 0,
  last_purchased_at timestamptz,
  favorite boolean not null default false,
  average_quantity numeric(10, 2),
  unique (user_id, product_id)
);

drop trigger if exists trg_brands_updated_at on public.brands;
create trigger trg_brands_updated_at
  before update on public.brands
  for each row execute function public.set_updated_at();

drop trigger if exists trg_products_updated_at on public.products;
create trigger trg_products_updated_at
  before update on public.products
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- Search indexes (17_PRODUCT_SEARCH_AND_AUTOCOMPLETE.md - Search Indexes,
-- Full Text Search: Persian + English, tolerate spacing/character
-- variations).
-- ---------------------------------------------------------------------
create index if not exists idx_products_normalized_name on public.products (normalized_name);
create index if not exists idx_products_barcode on public.products (barcode);
create index if not exists idx_products_brand on public.products (brand_id);
create index if not exists idx_products_category on public.products (category_id);
create index if not exists idx_products_name_trgm on public.products using gin (normalized_name gin_trgm_ops);
create index if not exists idx_product_aliases_product on public.product_aliases (product_id);
create index if not exists idx_product_aliases_alias_trgm on public.product_aliases using gin (alias gin_trgm_ops);

create extension if not exists pg_trgm;

-- ---------------------------------------------------------------------
-- RPC: get_or_create_product — used when a shopping_item's free-typed
-- name should also become/reuse a catalog entry (called from the app
-- only when the user explicitly picks "add to catalog", not on every
-- item — see Phase 2 for the actual autocomplete wiring).
-- ---------------------------------------------------------------------
create or replace function public.get_or_create_product(
  p_name text,
  p_normalized_name text,
  p_brand_id uuid default null,
  p_package_size text default null,
  p_category_id uuid default null,
  p_default_unit text default null
)
returns public.products
language plpgsql
security definer set search_path = public
as $$
declare
  v_product public.products;
begin
  select * into v_product
  from public.products
  where normalized_name = p_normalized_name
    and coalesce(brand_id::text, '') = coalesce(p_brand_id::text, '')
    and coalesce(package_size, '') = coalesce(p_package_size, '')
  limit 1;

  if v_product.id is not null then
    return v_product;
  end if;

  insert into public.products (
    name, normalized_name, brand_id, package_size, category_id, default_unit
  ) values (
    p_name, p_normalized_name, p_brand_id, p_package_size, p_category_id, p_default_unit
  )
  returning * into v_product;

  return v_product;
end;
$$;

-- ---------------------------------------------------------------------
-- RPC: record_product_purchase — upserts user_product_history so
-- favorites/frequently-purchased (Milestone 2 Phase 5) have real data to
-- work with from day one of the catalog existing.
-- ---------------------------------------------------------------------
create or replace function public.record_product_purchase(p_product_id uuid, p_quantity numeric default 1)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.user_product_history (user_id, product_id, purchase_count, last_purchased_at, average_quantity)
  values (auth.uid(), p_product_id, 1, now(), p_quantity)
  on conflict (user_id, product_id) do update
  set purchase_count = public.user_product_history.purchase_count + 1,
      last_purchased_at = now(),
      average_quantity = (
        (public.user_product_history.average_quantity * public.user_product_history.purchase_count) + p_quantity
      ) / (public.user_product_history.purchase_count + 1);
end;
$$;

create or replace function public.toggle_favorite_product(p_product_id uuid, p_favorite boolean)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.user_product_history (user_id, product_id, favorite)
  values (auth.uid(), p_product_id, p_favorite)
  on conflict (user_id, product_id) do update
  set favorite = p_favorite;
end;
$$;

-- Lock down grants the same way 006/007 did for trigger-only functions —
-- get_or_create_product/record_product_purchase/toggle_favorite_product
-- are meant to be called directly by authenticated users (they check/scope
-- by auth.uid() internally), so they intentionally KEEP their default
-- PUBLIC execute grant restricted only to authenticated (never anon).
revoke execute on function public.get_or_create_product(text, text, uuid, text, uuid, text) from public, anon;
revoke execute on function public.record_product_purchase(uuid, numeric) from public, anon;
revoke execute on function public.toggle_favorite_product(uuid, boolean) from public, anon;
grant execute on function public.get_or_create_product(text, text, uuid, text, uuid, text) to authenticated;
grant execute on function public.record_product_purchase(uuid, numeric) to authenticated;
grant execute on function public.toggle_favorite_product(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------
alter table public.brands enable row level security;
alter table public.products enable row level security;
alter table public.product_aliases enable row level security;
alter table public.user_product_history enable row level security;

-- Shared catalog: any authenticated user can read (it's not per-family
-- data — 08_SECURITY.md's family-isolation principle applies to family
-- data, not to a shared product reference catalog).
create policy "brands_select_authenticated"
  on public.brands for select
  using (auth.role() = 'authenticated');

create policy "products_select_authenticated"
  on public.products for select
  using (auth.role() = 'authenticated');

create policy "product_aliases_select_authenticated"
  on public.product_aliases for select
  using (auth.role() = 'authenticated');

-- No direct insert/update/delete policies for brands/products/aliases:
-- all catalog writes go through get_or_create_product() (security
-- definer), keeping catalog growth consistent and de-duplicated.

-- user_product_history: strictly private per user.
create policy "user_product_history_select_own"
  on public.user_product_history for select
  using (user_id = auth.uid());
