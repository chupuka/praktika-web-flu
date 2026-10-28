-- Схема данных итогового проекта «Мебельный салон»
-- Supabase (PostgreSQL). REST-API по этой схеме формируется PostgREST автоматически.

create extension if not exists pgcrypto;

do $$
begin
  create type public.user_role as enum ('customer', 'manager', 'admin');
exception
  when duplicate_object then null;
end $$;

create table if not exists public.categories (
  id          serial primary key,
  name        text not null,
  description text not null default '',
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  constraint categories_name_check check (char_length(name) between 2 and 80),
  constraint categories_description_check check (char_length(description) <= 1000)
);

create unique index if not exists categories_name_key
  on public.categories (lower(name)) where deleted_at is null;

create table if not exists public.manufacturers (
  id            serial primary key,
  name          text not null,
  country       text not null default '',
  contact_email text not null default '',
  created_at    timestamptz not null default now(),
  deleted_at    timestamptz,
  constraint manufacturers_name_check check (char_length(name) between 2 and 80),
  constraint manufacturers_country_check check (char_length(country) <= 60),
  constraint manufacturers_email_check check (contact_email = '' or contact_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

create unique index if not exists manufacturers_name_key
  on public.manufacturers (lower(name)) where deleted_at is null;

create table if not exists public.materials (
  id          serial primary key,
  name        text not null,
  description text not null default '',
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  constraint materials_name_check check (char_length(name) between 2 and 60),
  constraint materials_description_check check (char_length(description) <= 1000)
);

create unique index if not exists materials_name_key
  on public.materials (lower(name)) where deleted_at is null;

create table if not exists public.customers (
  id         serial primary key,
  full_name  text not null,
  email      text not null,
  phone      text not null default '',
  address    text not null default '',
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint customers_full_name_check check (char_length(full_name) between 3 and 120),
  constraint customers_email_check check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  constraint customers_phone_check check (phone = '' or phone ~ '^[0-9+()\-\s]{7,25}$'),
  constraint customers_address_check check (char_length(address) <= 200)
);

create unique index if not exists customers_email_key
  on public.customers (lower(email)) where deleted_at is null;

create table if not exists public.loyalty_cards (
  id          serial primary key,
  customer_id integer not null unique references public.customers (id) on delete cascade,
  number      text not null,
  issued_at   date not null,
  tier        text not null default 'basic',
  points      integer not null default 0,
  created_at  timestamptz not null default now(),
  constraint loyalty_cards_number_check check (char_length(number) between 3 and 30),
  constraint loyalty_cards_tier_check check (tier in ('basic', 'silver', 'gold')),
  constraint loyalty_cards_points_check check (points between 0 and 1000000)
);

create unique index if not exists loyalty_cards_number_key
  on public.loyalty_cards (lower(number));

create table if not exists public.products (
  id              serial primary key,
  name            text not null,
  sku             text not null,
  description     text not null default '',
  style           text not null default 'modern',
  price           numeric(12, 2) not null,
  stock           integer not null default 0,
  width           numeric(8, 2),
  depth           numeric(8, 2),
  height          numeric(8, 2),
  weight          numeric(8, 2),
  color           text not null default '',
  category_id     integer not null references public.categories (id) on delete restrict,
  manufacturer_id integer not null references public.manufacturers (id) on delete restrict,
  created_at      timestamptz not null default now(),
  deleted_at      timestamptz,
  constraint products_name_check check (char_length(name) between 2 and 120),
  constraint products_sku_check check (char_length(sku) between 2 and 40),
  constraint products_description_check check (char_length(description) <= 2000),
  constraint products_style_check check (style in ('modern', 'classic', 'scandi', 'loft', 'provence')),
  constraint products_price_check check (price >= 0 and price <= 10000000),
  constraint products_stock_check check (stock between 0 and 1000000),
  constraint products_width_check check (width is null or (width > 0 and width <= 1000)),
  constraint products_depth_check check (depth is null or (depth > 0 and depth <= 1000)),
  constraint products_height_check check (height is null or (height > 0 and height <= 1000)),
  constraint products_weight_check check (weight is null or (weight > 0 and weight <= 5000)),
  constraint products_color_check check (char_length(color) <= 40)
);

create unique index if not exists products_sku_key
  on public.products (upper(sku)) where deleted_at is null;

create index if not exists products_category_idx on public.products (category_id);
create index if not exists products_manufacturer_idx on public.products (manufacturer_id);

create table if not exists public.product_materials (
  product_id  integer not null references public.products (id) on delete cascade,
  material_id integer not null references public.materials (id) on delete cascade,
  primary key (product_id, material_id)
);

create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  username    text not null,
  full_name   text not null default '',
  email       text not null,
  role        public.user_role not null default 'customer',
  customer_id integer unique references public.customers (id) on delete set null,
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  constraint profiles_username_check check (username ~ '^[a-zA-Z0-9_.-]{3,32}$'),
  constraint profiles_full_name_check check (char_length(full_name) <= 120)
);

create unique index if not exists profiles_username_key
  on public.profiles (lower(username)) where deleted_at is null;

-- Служебные функции: роль и карточка текущего пользователя.
create or replace function public.app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role::text from public.profiles
   where id = auth.uid() and deleted_at is null
$$;

create or replace function public.app_customer_id()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select customer_id from public.profiles
   where id = auth.uid() and deleted_at is null
$$;

-- Профиль создаётся автоматически после регистрации в Supabase Auth.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  uname text;
begin
  uname := coalesce(
    nullif(new.raw_user_meta_data ->> 'username', ''),
    split_part(new.email, '@', 1)
  );
  if exists (select 1 from public.profiles where lower(username) = lower(uname)) then
    uname := uname || '_' || substr(new.id::text, 1, 4);
  end if;
  insert into public.profiles (id, username, full_name, email, role)
  values (
    new.id,
    uname,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.email,
    'customer'
  );
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Правила доступа на уровне записей.
alter table public.categories      enable row level security;
alter table public.manufacturers   enable row level security;
alter table public.materials       enable row level security;
alter table public.customers       enable row level security;
alter table public.loyalty_cards   enable row level security;
alter table public.products        enable row level security;
alter table public.product_materials enable row level security;
alter table public.profiles        enable row level security;

create policy categories_read on public.categories
  for select to authenticated using (true);
create policy categories_write on public.categories
  for all to authenticated
  using (public.app_role() in ('manager', 'admin'))
  with check (public.app_role() in ('manager', 'admin'));

create policy manufacturers_read on public.manufacturers
  for select to authenticated using (true);
create policy manufacturers_write on public.manufacturers
  for all to authenticated
  using (public.app_role() in ('manager', 'admin'))
  with check (public.app_role() in ('manager', 'admin'));

create policy materials_read on public.materials
  for select to authenticated using (true);
create policy materials_write on public.materials
  for all to authenticated
  using (public.app_role() in ('manager', 'admin'))
  with check (public.app_role() in ('manager', 'admin'));

create policy products_read on public.products
  for select to authenticated using (true);
create policy products_write on public.products
  for all to authenticated
  using (public.app_role() in ('manager', 'admin'))
  with check (public.app_role() in ('manager', 'admin'));

create policy product_materials_read on public.product_materials
  for select to authenticated using (true);
create policy product_materials_write on public.product_materials
  for all to authenticated
  using (public.app_role() in ('manager', 'admin'))
  with check (public.app_role() in ('manager', 'admin'));

create policy customers_read_manager on public.customers
  for select to authenticated using (public.app_role() in ('manager', 'admin'));
create policy customers_read_own on public.customers
  for select to authenticated
  using (public.app_role() = 'customer' and id = public.app_customer_id());
create policy customers_write on public.customers
  for all to authenticated
  using (public.app_role() in ('manager', 'admin'))
  with check (public.app_role() in ('manager', 'admin'));

create policy loyalty_cards_read_manager on public.loyalty_cards
  for select to authenticated using (public.app_role() in ('manager', 'admin'));
create policy loyalty_cards_read_own on public.loyalty_cards
  for select to authenticated
  using (public.app_role() = 'customer' and customer_id = public.app_customer_id());
create policy loyalty_cards_write on public.loyalty_cards
  for all to authenticated
  using (public.app_role() in ('manager', 'admin'))
  with check (public.app_role() in ('manager', 'admin'));

create policy profiles_read_own on public.profiles
  for select to authenticated using (id = auth.uid() and deleted_at is null);
create policy profiles_read_admin on public.profiles
  for select to authenticated using (public.app_role() = 'admin');
create policy profiles_update_admin on public.profiles
  for update to authenticated
  using (public.app_role() = 'admin')
  with check (public.app_role() = 'admin');

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- Сводные показатели для отчёта администратора.
-- Представления выполняются от владельца схемы: администратор видит сводку,
-- хотя прямого доступа к списку покупателей у него нет.
create or replace view public.v_shop_stats as
select
  (select count(*) from public.products where deleted_at is null)::int as products,
  (select count(*) from public.categories where deleted_at is null)::int as categories,
  (select count(*) from public.manufacturers where deleted_at is null)::int as manufacturers,
  (select count(*) from public.materials where deleted_at is null)::int as materials,
  (select count(*) from public.customers where deleted_at is null)::int as customers,
  (select count(*) from public.profiles where deleted_at is null)::int as users,
  (select coalesce(sum(price * stock), 0) from public.products where deleted_at is null)::numeric(14, 2) as stock_value,
  (select coalesce(round(avg(price), 2), 0) from public.products where deleted_at is null)::numeric(12, 2) as avg_price,
  (select count(*) from public.products where deleted_at is null and stock = 0)::int as out_of_stock,
  (select count(*) from public.products where deleted_at is null and stock between 1 and 4)::int as low_stock;

create or replace view public.v_category_stats as
select
  c.id,
  c.name,
  count(p.id)::int as product_count,
  coalesce(sum(p.price * p.stock), 0)::numeric(14, 2) as stock_value
from public.categories c
left join public.products p
  on p.category_id = c.id and p.deleted_at is null
where c.deleted_at is null
group by c.id, c.name
order by product_count desc, c.name;

grant select on public.v_shop_stats, public.v_category_stats to authenticated;
