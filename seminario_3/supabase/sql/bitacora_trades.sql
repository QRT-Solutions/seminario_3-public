-- Author: QRT Solutions. Additive migration; native comments and human reasons stay separate.
alter table public.mt5_deals
  add column deal_comment text check (length(deal_comment) <= 1024),
  add column order_comment text check (length(order_comment) <= 1024),
  add column deal_reason text,
  add column magic numeric(20,0);
create index mt5_deals_account_position_time_idx
  on public.mt5_deals(account_id, position_id, deal_time, deal_ticket);

create table public.mt5_trade_journal (
  id uuid primary key default gen_random_uuid(),
  account_id text not null,
  position_id numeric(20,0) not null,
  opening_reason text check (length(opening_reason) between 1 and 1000),
  closing_reason text check (length(closing_reason) between 1 and 1000),
  updated_at timestamptz not null default now(),
  unique(account_id, position_id)
);
alter table public.mt5_trade_journal enable row level security;
revoke all on public.mt5_trade_journal from public, anon, authenticated, service_role;
grant select on public.mt5_trade_journal to service_role;

create function public.mt5_ensure_trade_journal()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.position_id > 0 and new.deal_type in ('BUY','SELL') then
    insert into public.mt5_trade_journal(account_id,position_id)
    values (new.account_id,new.position_id) on conflict(account_id,position_id) do nothing;
  end if;
  return new;
end;
$$;
revoke all on function public.mt5_ensure_trade_journal() from public, anon, authenticated, service_role;
create trigger mt5_deal_journal after insert on public.mt5_deals
for each row execute function public.mt5_ensure_trade_journal();
insert into public.mt5_trade_journal(account_id,position_id)
select distinct account_id,position_id from public.mt5_deals
where position_id>0 and deal_type in ('BUY','SELL') on conflict do nothing;

create table public.mt5_telegram_editors (
  account_id text not null,
  user_id bigint not null check (user_id>0),
  chat_id bigint not null check (chat_id>0),
  active boolean not null default true,
  primary key(account_id,user_id,chat_id),
  check (user_id=chat_id)
);
alter table public.mt5_telegram_editors enable row level security;
revoke all on public.mt5_telegram_editors from public, anon, authenticated, service_role;
grant select on public.mt5_telegram_editors to service_role;

create table public.mt5_trade_reason_audit (
  telegram_update_id bigint primary key,
  journal_id uuid not null references public.mt5_trade_journal(id),
  phase text not null check (phase in ('opening','closing')),
  reason text not null check(length(reason) between 1 and 1000),
  actor_user_id bigint not null,
  recorded_at timestamptz not null default now()
);
alter table public.mt5_trade_reason_audit enable row level security;
revoke all on public.mt5_trade_reason_audit from public, anon, authenticated, service_role;

-- Called only by the trusted Telegram server after verifying the webhook secret.
-- The database independently checks private-chat authorization and trade ownership.
create function public.mt5_record_trade_reason(
  p_account_id text, p_reference text, p_phase text, p_reason text,
  p_user_id bigint, p_chat_id bigint, p_update_id bigint
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare journal public.mt5_trade_journal; matches bigint;
begin
  if p_phase not in ('opening','closing') or p_phase is null
     or p_reason is null or length(btrim(p_reason)) not between 1 and 1000
     or p_reference is null or p_reference !~ '^[a-f0-9]{8}$'
     or p_update_id is null or p_update_id < 0 then
    raise exception 'invalid_input' using errcode='22023';
  end if;
  if not exists(select 1 from public.mt5_telegram_editors e
    where e.account_id=p_account_id and e.user_id=p_user_id and e.chat_id=p_chat_id and e.active) then
    raise exception 'not_authorized' using errcode='42501';
  end if;
  select count(*) into matches from public.mt5_trade_journal j
    where j.account_id=p_account_id and left(j.id::text,8)=p_reference;
  if matches<>1 then raise exception 'reference_not_unique' using errcode='22023'; end if;
  select * into journal from public.mt5_trade_journal j
    where j.account_id=p_account_id and left(j.id::text,8)=p_reference for update;
  if not exists(select 1 from public.mt5_deals d
    where d.account_id=journal.account_id and d.position_id=journal.position_id
      and ((p_phase='opening' and d.deal_entry in ('IN','INOUT'))
        or (p_phase='closing' and d.deal_entry in ('OUT','OUT_BY','INOUT')))) then
    raise exception 'phase_not_recorded' using errcode='22023';
  end if;
  insert into public.mt5_trade_reason_audit(telegram_update_id,journal_id,phase,reason,actor_user_id)
    values(p_update_id,journal.id,p_phase,btrim(p_reason),p_user_id) on conflict do nothing;
  if not found then return jsonb_build_object('ok',true,'duplicate',true); end if;
  -- Older Telegram updates are retained in the audit, but never overwrite a newer reason.
  if not exists(select 1 from public.mt5_trade_reason_audit a
    where a.journal_id=journal.id and a.phase=p_phase and a.telegram_update_id>p_update_id) then
    update public.mt5_trade_journal set
      opening_reason=case when p_phase='opening' then btrim(p_reason) else opening_reason end,
      closing_reason=case when p_phase='closing' then btrim(p_reason) else closing_reason end,
      updated_at=now() where id=journal.id;
  end if;
  return jsonb_build_object('ok',true,'duplicate',false,'reference',p_reference);
end;
$$;
revoke all on function public.mt5_record_trade_reason(text,text,text,text,bigint,bigint,bigint)
  from public, anon, authenticated;
grant execute on function public.mt5_record_trade_reason(text,text,text,text,bigint,bigint,bigint) to service_role;
comment on table public.mt5_trade_journal is 'QRT Solutions: one journal per MT5 position identifier; manual reasons never overwrite broker comments.';

create or replace function public.mt5_public_dashboard()
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
    'deal_comment', d.deal_comment, 'order_comment', d.order_comment,
    'deal_reason', d.deal_reason, 'magic', d.magic::text,
    'commission', d.commission, 'swap', d.swap,
    'deal_time', to_char(d.deal_time at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS'),
    'received_at', d.received_at
  ) as item, d.deal_time, d.deal_ticket from recent_deals d
)
select jsonb_build_object(
  'version', 1, 'generated_at', now(),
  'journals', coalesce((select jsonb_agg(item order by last_time desc) from (
    select jsonb_build_object('id',j.id,'opening_reason',j.opening_reason,'closing_reason',j.closing_reason,
      'updated_at',j.updated_at,'events_total',(select count(*) from public.mt5_deals d where d.account_id=j.account_id and d.position_id=j.position_id),
      'events',coalesce((select jsonb_agg(jsonb_build_object(
        'symbol',d.symbol,'deal_type',d.deal_type,'deal_entry',d.deal_entry,
        'volume',d.volume,'price',d.price,'profit',d.profit,'commission',d.commission,'swap',d.swap,
        'deal_time',to_char(d.deal_time at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS'),
        'deal_comment',d.deal_comment,'order_comment',d.order_comment,'deal_reason',d.deal_reason,
        'magic',d.magic::text
      ) order by d.deal_time,d.deal_ticket) from (select d.* from public.mt5_deals d
        where d.account_id=j.account_id and d.position_id=j.position_id
        order by d.deal_time desc,d.deal_ticket desc limit 200) d),'[]'::jsonb)
    ) as item, (select max(d.deal_time) from public.mt5_deals d where d.account_id=j.account_id and d.position_id=j.position_id) as last_time
    from public.mt5_trade_journal j join chosen s on s.account_id=j.account_id
    order by last_time desc,j.id limit 100
  ) journal_items),'[]'::jsonb),
  'journals_total',(select count(*) from public.mt5_trade_journal j join chosen s on s.account_id=j.account_id),
  'journals_limit',100,
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
'QRT Solutions: opt-in public demo telemetry; read-only fixed projection, broker comments and separate human reasons; no login, server, tickets or credentials.';

