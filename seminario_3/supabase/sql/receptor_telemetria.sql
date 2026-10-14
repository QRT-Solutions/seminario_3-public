-- Author: QRT Solutions. Apply once after esquema_telemetria.sql.
create table public.mt5_ingest_credentials (
  token_sha256 text primary key check (token_sha256 ~ '^[a-f0-9]{64}$'),
  login text not null check (login ~ '^[0-9]+$'),
  broker text not null,
  server text not null,
  account_id text not null,
  project_name text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  check (expires_at > created_at)
);
alter table public.mt5_ingest_credentials enable row level security;
revoke all on table public.mt5_ingest_credentials from public, anon, authenticated;
-- The Edge Function may only read credential grants, never issue or rotate them.
revoke all on table public.mt5_ingest_credentials from service_role;
grant select on table public.mt5_ingest_credentials to service_role;

alter table public.mt5_accounts_snapshot add column received_at timestamptz not null default now();
alter table public.mt5_deals add column received_at timestamptz not null default now();
alter table public.mt5_swap_rates add column received_at timestamptz not null default now();
-- Upsert needs SELECT, INSERT and UPDATE. Clients still have no table privileges.
revoke all on table public.mt5_accounts_snapshot, public.mt5_deals, public.mt5_swap_rates from service_role;
grant select, insert, update on table public.mt5_accounts_snapshot, public.mt5_deals, public.mt5_swap_rates to service_role;
comment on table public.mt5_ingest_credentials is 'QRT Solutions: server-side SHA-256 credential registry; raw tokens are never stored here.';
