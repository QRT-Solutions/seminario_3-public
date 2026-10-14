-- Referencia aplicada al EA v3.10; revisar tablas existentes antes de ejecutar.
-- No contiene datos ni credenciales. No es una migracion CLI con version.
-- Author: QRT Solutions
-- Initial storage contract for MT5 Telemetry Exporter Universal 3.10.
-- Ingestion authorization is provisioned separately; public clients have no access.
create table public.mt5_accounts_snapshot (
  account_id text primary key,
  login bigint not null,
  broker text not null,
  server text not null,
  currency text not null,
  account_type text not null,
  margin_mode text not null,
  leverage bigint not null,
  balance numeric not null,
  equity numeric not null,
  margin numeric not null,
  margin_free numeric not null,
  margin_level numeric not null,
  profit_floating numeric not null,
  open_positions_count integer not null,
  positions_json jsonb not null check (jsonb_typeof(positions_json) = 'array'),
  updated_at timestamptz not null,
  project_name text not null,
  terminal_closed_profit numeric not null,
  terminal_total_deals integer not null,
  today_closed_profit numeric not null,
  today_trades_count integer not null
);
create table public.mt5_deals (
  deal_ticket numeric(20,0) primary key,
  order_ticket numeric(20,0) not null,
  position_id numeric(20,0) not null,
  account_id text not null,
  login bigint not null,
  broker text not null,
  project_name text not null,
  symbol text not null,
  deal_type text not null,
  deal_entry text not null,
  volume numeric not null,
  price numeric not null,
  profit numeric not null,
  commission numeric not null,
  swap numeric not null,
  deal_time timestamptz not null,
  approval_status text not null
);
create index mt5_deals_account_time_idx on public.mt5_deals(account_id, deal_time desc);
create table public.mt5_swap_rates (
  broker text not null,
  symbol text not null,
  swap_long numeric not null,
  swap_short numeric not null,
  swap_mode integer not null,
  triple_swap_day integer not null,
  updated_at timestamptz not null,
  primary key (broker, symbol)
);
alter table public.mt5_accounts_snapshot enable row level security;
alter table public.mt5_deals enable row level security;
alter table public.mt5_swap_rates enable row level security;
revoke all on table public.mt5_accounts_snapshot, public.mt5_deals, public.mt5_swap_rates from public, anon, authenticated;
comment on table public.mt5_accounts_snapshot is 'QRT Solutions: latest MT5 account snapshot; not a historical equity series.';
comment on table public.mt5_deals is 'QRT Solutions: MT5 deals, v3.10 conflict key. Scope: one broker ticket namespace until composite keys are adopted.';
comment on column public.mt5_deals.deal_time is 'Timestamp supplied by EA v3.10. Broker clock is labelled Z by the source; UTC normalization remains to be implemented.';
comment on table public.mt5_swap_rates is 'QRT Solutions: latest swap rates per broker and symbol.';
