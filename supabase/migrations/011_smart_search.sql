-- 011_smart_search.sql
-- Milestone 2, Phase 2: Smart Search (17_PRODUCT_SEARCH_AND_AUTOCOMPLETE.md
-- - Persian character normalization, typo tolerance via pg_trgm,
-- favorite-boosted ranking).

-- ---------------------------------------------------------------------
-- Server-side Persian normalization — NEVER trust client-side
-- normalization for search consistency (08_SECURITY.md Principle 3:
-- Never Trust Client Input). Unifies Arabic/Persian character variants
-- (ي/ی, ك/ک, ة/ه) and collapses whitespace.
-- ---------------------------------------------------------------------
create or replace function public.normalize_product_text(p_text text)
returns text
language sql
immutable
set search_path = public
as $$
  select trim(regexp_replace(
    replace(replace(replace(lower(p_text), 'ي', 'ی'), 'ك', 'ک'), 'ة', 'ه'),
    '\s+', ' ', 'g'
  ));
$$;

revoke execute on function public.normalize_product_text(text) from public, anon;
grant execute on function public.normalize_product_text(text) to authenticated;

-- Auto-normalize products.normalized_name whenever name changes, so it's
-- never possible for client and server normalization to drift apart.
create or replace function public.set_product_normalized_name()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.normalized_name := public.normalize_product_text(new.name);
  return new;
end;
$$;

drop trigger if exists trg_products_normalize on public.products;
create trigger trg_products_normalize
  before insert or update of name on public.products
  for each row execute function public.set_product_normalized_name();

revoke execute on function public.set_product_normalized_name() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Replace get_or_create_product: drop the client-supplied
-- p_normalized_name parameter entirely and compute it server-side.
-- Trusting a client-provided "normalized" value defeats the point of
-- having server-side normalization at all.
-- ---------------------------------------------------------------------
drop function if exists public.get_or_create_product(text, text, uuid, text, uuid, text);

create or replace function public.get_or_create_product(
  p_name text,
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
  v_normalized text;
begin
  v_normalized := public.normalize_product_text(p_name);

  select * into v_product
  from public.products
  where normalized_name = v_normalized
    and coalesce(brand_id::text, '') = coalesce(p_brand_id::text, '')
    and coalesce(package_size, '') = coalesce(p_package_size, '')
  limit 1;

  if v_product.id is not null then
    return v_product;
  end if;

  insert into public.products (name, normalized_name, brand_id, package_size, category_id, default_unit)
  values (p_name, v_normalized, p_brand_id, p_package_size, p_category_id, p_default_unit)
  returning * into v_product;

  return v_product;
end;
$$;

revoke execute on function public.get_or_create_product(text, uuid, text, uuid, text) from public, anon;
grant execute on function public.get_or_create_product(text, uuid, text, uuid, text) to authenticated;

-- ---------------------------------------------------------------------
-- RPC: search_products — the actual autocomplete backend
-- (17_PRODUCT_SEARCH_AND_AUTOCOMPLETE.md - Matching Methods priority:
-- exact match > starts with > contains > similar words). Favorites rank
-- first (FT-031: "Favorite Products ... Higher search priority").
-- ---------------------------------------------------------------------
create or replace function public.search_products(p_query text, p_limit integer default 10)
returns table (
  id uuid,
  name text,
  brand_name text,
  package_size text,
  category_id uuid,
  image_url text,
  default_unit text,
  is_favorite boolean,
  match_score real
)
language sql
stable
security definer set search_path = public
as $$
  select
    p.id,
    p.name,
    b.name as brand_name,
    p.package_size,
    p.category_id,
    p.image_url,
    p.default_unit,
    coalesce(uph.favorite, false) as is_favorite,
    greatest(
      extensions.similarity(p.normalized_name, public.normalize_product_text(p_query)),
      coalesce((
        select max(extensions.similarity(pa.alias, public.normalize_product_text(p_query)))
        from public.product_aliases pa where pa.product_id = p.id
      ), 0)
    ) as match_score
  from public.products p
  left join public.brands b on b.id = p.brand_id
  left join public.user_product_history uph on uph.product_id = p.id and uph.user_id = auth.uid()
  where p.active
    and (
      p.normalized_name ilike '%' || public.normalize_product_text(p_query) || '%'
      or exists (
        select 1 from public.product_aliases pa
        where pa.product_id = p.id
          and pa.alias ilike '%' || public.normalize_product_text(p_query) || '%'
      )
      or extensions.similarity(p.normalized_name, public.normalize_product_text(p_query)) > 0.2
    )
  order by is_favorite desc, match_score desc, p.name
  limit p_limit;
$$;

revoke execute on function public.search_products(text, integer) from public, anon;
grant execute on function public.search_products(text, integer) to authenticated;
