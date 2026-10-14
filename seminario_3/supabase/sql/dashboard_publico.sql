-- Author: QRT Solutions.
-- Run once after the receiver migrations. Publication starts DISABLED.
create table public.mt5_dashboard_publication (
  singleton boolean primary key default true check (singleton),
  account_id text not null references public.mt5_accounts_snapshot(account_id),
  enabled boolean not null default false,
  display_name text not null default 'Cuenta demo · Seminario 3',
  created_at timestamptz not null default now()
);
alter table public.mt5_dashboard_publication enable row level security;
revoke all on public.mt5_dashboard_publication from public, anon, authenticated, service_role;

-- Intentional, narrow public API. No account parameters, arbitrary SQL or writes.
-- Fixed empty search_path and explicit output allowlists; raw tables remain private.
create function public.mt5_public_dashboard()
returns jsonb language sql stable security definer set search_path = ''
as $$
with chosen as (
  select s.*, p.display_name
  from public.mt5_dashboard_publication p
  join public.mt5_accounts_snapshot s on s.account_id = p.account_id
  where p.singleton and p.enabled and s.account_type = 'DEMO'
), recent_deals as (
  select d.* from public.mt5_deals d
  join chosen s on d.account_id = s.account_id
  where d.deal_type in ('BUY', 'SELL')
  order by d.deal_time desc, d.deal_ticket desc limit 1000
), exported_deals as (
  select jsonb_build_object(
    'symbol', d.symbol, 'deal_type', d.deal_type, 'deal_entry', d.deal_entry,
    'volume', d.volume, 'price', d.price, 'profit', d.profit,
    'commission', d.commission, 'swap', d.swap,
    'deal_time', to_char(d.deal_time at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS'),
    'received_at', d.received_at
  ) as item, d.deal_time, d.deal_ticket from recent_deals d
)
select jsonb_build_object(
  'version', 1, 'generated_at', now(),
  'account', (select jsonb_build_object(
    'display_name', s.display_name, 'broker', s.broker, 'account_type', s.account_type,
    'currency', s.currency, 'balance', s.balance, 'equity', s.equity,
    'margin', s.margin, 'margin_free', s.margin_free, 'margin_level', s.margin_level,
    'profit_floating', s.profit_floating, 'open_positions_count', s.open_positions_count,
    'received_at', s.received_at,
    'positions', coalesce((select jsonb_agg(jsonb_build_object(
      'symbol', pos->>'symbol', 'type', pos->>'type',
      'volume', pos->'volume', 'open_price', pos->'open_price',
      'current_price', pos->'current_price', 'sl', pos->'sl', 'tp', pos->'tp',
      'profit', pos->'profit', 'swap', pos->'swap'
    )) from jsonb_array_elements(s.positions_json) pos), '[]'::jsonb)
  ) from chosen s),
  'deals', coalesce((select jsonb_agg(item order by deal_time, deal_ticket) from exported_deals), '[]'::jsonb),
  'deals_total', (select count(*) from public.mt5_deals d join chosen s
    on d.account_id = s.account_id where d.deal_type in ('BUY','SELL')),
  'deals_limit', 1000,
  'swap_rates', coalesce((select jsonb_agg(jsonb_build_object(
    'symbol', r.symbol, 'swap_long', r.swap_long, 'swap_short', r.swap_short,
    'swap_mode', r.swap_mode, 'triple_swap_day', r.triple_swap_day,
    'received_at', r.received_at
  ) order by r.symbol) from public.mt5_swap_rates r join chosen s on r.broker = s.broker
  where exists (select 1 from public.mt5_deals d where d.account_id = s.account_id and d.symbol = r.symbol)
     or exists (select 1 from jsonb_array_elements(s.positions_json) pos where pos->>'symbol' = r.symbol)
  ), '[]'::jsonb)
);
$$;
revoke all on function public.mt5_public_dashboard() from public, anon, authenticated;
grant execute on function public.mt5_public_dashboard() to anon, authenticated;
comment on function public.mt5_public_dashboard() is
'QRT Solutions: opt-in public demo telemetry; read-only fixed projection, no login, server, tickets or credentials.';

