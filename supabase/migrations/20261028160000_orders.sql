-- Заказы, позиции заказов и отзывы — перенесены из проекта на Django.
-- Итоговая сумма заказа считается на сервере по правилам предметной области.

do $$
begin
  create type public.order_status as enum ('new', 'processing', 'shipped', 'delivered', 'cancelled');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.delivery_method as enum ('pickup', 'delivery', 'mail');
exception when duplicate_object then null;
end $$;

create table if not exists public.orders (
  id              serial primary key,
  customer_id     integer not null references public.customers (id) on delete restrict,
  customer_name   text not null default '',
  status          public.order_status not null default 'new',
  delivery_method public.delivery_method not null default 'pickup',
  subtotal        numeric(12, 2) not null default 0,
  discount_percent numeric(5, 2) not null default 0,
  delivery_cost   numeric(10, 2) not null default 0,
  total_price     numeric(12, 2) not null default 0,
  comment         text not null default '',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz,
  constraint orders_comment_check check (char_length(comment) <= 500)
);

create index if not exists orders_customer_idx on public.orders (customer_id);
create index if not exists orders_created_idx on public.orders (created_at desc);

create table if not exists public.order_items (
  id         serial primary key,
  order_id   integer not null references public.orders (id) on delete cascade,
  product_id integer not null references public.products (id) on delete restrict,
  product_name text not null default '',
  quantity   integer not null default 1,
  price      numeric(12, 2) not null,
  constraint order_items_quantity_check check (quantity between 1 and 1000),
  constraint order_items_price_check check (price >= 0)
);

create index if not exists order_items_order_idx on public.order_items (order_id);

create table if not exists public.reviews (
  id            serial primary key,
  product_id    integer not null references public.products (id) on delete cascade,
  customer_id   integer not null references public.customers (id) on delete cascade,
  customer_name text not null default '',
  rating        integer not null,
  text          text not null,
  created_at    timestamptz not null default now(),
  deleted_at    timestamptz,
  constraint reviews_rating_check check (rating between 1 and 5),
  constraint reviews_text_check check (char_length(text) between 2 and 1000)
);

create unique index if not exists reviews_one_per_customer
  on public.reviews (product_id, customer_id) where deleted_at is null;

-- Пересчёт заказа: скидка по уровню карты лояльности и стоимость доставки.
create or replace function public.recalc_order(p_order_id integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_subtotal numeric(12, 2);
  v_tier text;
  v_discount numeric(5, 2);
  v_delivery public.delivery_method;
  v_delivery_cost numeric(10, 2);
begin
  select coalesce(sum(quantity * price), 0)
    into v_subtotal
    from public.order_items
   where order_id = p_order_id;

  select lc.tier into v_tier
    from public.orders o
    left join public.loyalty_cards lc on lc.customer_id = o.customer_id
   where o.id = p_order_id;

  v_discount := case v_tier
    when 'gold' then 10
    when 'silver' then 5
    else 0
  end;

  select delivery_method into v_delivery
    from public.orders where id = p_order_id;

  v_delivery_cost := case v_delivery
    when 'pickup' then 0
    when 'mail' then 490
    when 'delivery' then case when v_subtotal >= 50000 then 0 else 990 end
    else 0
  end;

  update public.orders
     set subtotal = v_subtotal,
         discount_percent = v_discount,
         delivery_cost = v_delivery_cost,
         total_price = round(v_subtotal * (1 - v_discount / 100) + v_delivery_cost, 2),
         updated_at = now()
   where id = p_order_id;
end $$;

create or replace function public.on_order_item_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.recalc_order(coalesce(new.order_id, old.order_id));
  return coalesce(new, old);
end $$;

drop trigger if exists order_items_recalc on public.order_items;
create trigger order_items_recalc
  after insert or update or delete on public.order_items
  for each row execute function public.on_order_item_change();

create or replace function public.on_order_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' or new.delivery_method is distinct from old.delivery_method then
    perform public.recalc_order(new.id);
  end if;
  return new;
end $$;

drop trigger if exists orders_recalc on public.orders;
create trigger orders_recalc
  after insert or update of delivery_method on public.orders
  for each row execute function public.on_order_change();

alter table public.orders      enable row level security;
alter table public.order_items enable row level security;
alter table public.reviews     enable row level security;

create policy orders_read_staff on public.orders
  for select to authenticated using (public.app_role() in ('manager', 'admin'));
create policy orders_read_own on public.orders
  for select to authenticated
  using (public.app_role() = 'customer' and customer_id = public.app_customer_id());
create policy orders_insert_own on public.orders
  for insert to authenticated
  with check (public.app_role() = 'customer' and customer_id = public.app_customer_id());
create policy orders_insert_staff on public.orders
  for insert to authenticated
  with check (public.app_role() in ('manager', 'admin'));
create policy orders_update_staff on public.orders
  for update to authenticated
  using (public.app_role() in ('manager', 'admin'))
  with check (public.app_role() in ('manager', 'admin'));

create policy order_items_read on public.order_items
  for select to authenticated using (
    exists (
      select 1 from public.orders o
       where o.id = order_id
         and (public.app_role() in ('manager', 'admin') or o.customer_id = public.app_customer_id())
    )
  );
create policy order_items_write on public.order_items
  for all to authenticated using (
    exists (
      select 1 from public.orders o
       where o.id = order_id
         and (public.app_role() in ('manager', 'admin') or o.customer_id = public.app_customer_id())
    )
  ) with check (
    exists (
      select 1 from public.orders o
       where o.id = order_id
         and (public.app_role() in ('manager', 'admin') or o.customer_id = public.app_customer_id())
    )
  );

create policy reviews_read on public.reviews
  for select to authenticated using (deleted_at is null);
create policy reviews_insert_own on public.reviews
  for insert to authenticated
  with check (
    public.app_role() = 'customer'
    and customer_id = public.app_customer_id()
  );
create policy reviews_insert_staff on public.reviews
  for insert to authenticated
  with check (public.app_role() in ('manager', 'admin'));
create policy reviews_update on public.reviews
  for update to authenticated using (
    public.app_role() in ('manager', 'admin') or customer_id = public.app_customer_id()
  ) with check (
    public.app_role() in ('manager', 'admin') or customer_id = public.app_customer_id()
  );
create policy reviews_delete on public.reviews
  for delete to authenticated using (
    public.app_role() in ('manager', 'admin') or customer_id = public.app_customer_id()
  );

grant select, insert, update, delete on public.orders, public.order_items, public.reviews to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- Сводка дополняется показателями по заказам и отзывам.
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
  (select count(*) from public.products where deleted_at is null and stock between 1 and 4)::int as low_stock,
  (select count(*) from public.orders where deleted_at is null)::int as orders,
  (select coalesce(sum(total_price), 0) from public.orders where deleted_at is null and status <> 'cancelled')::numeric(14, 2) as revenue,
  (select coalesce(round(avg(rating), 2), 0) from public.reviews where deleted_at is null)::numeric(4, 2) as avg_rating;

grant select on public.v_shop_stats to authenticated;
