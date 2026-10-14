-- Author: QRT Solutions. Apply after protecciones_bitacora.sql. Old RPC retained for rollback.
create or replace function public.mt5_public_dashboard_page(p_deal_page integer default 0,p_journal_page integer default 0,
 p_symbol text default null,p_entry text default null,p_from date default null,p_to date default null,p_history boolean default true)
returns jsonb language sql stable security definer set search_path = ''
as $$
with chosen as (
  select s.*, p.display_name
  from public.mt5_dashboard_publication p
  join public.mt5_accounts_snapshot s on s.account_id = p.account_id
  where p.singleton and p.enabled and s.account_type = 'DEMO'
), filtered as materialized (
 select d.* from public.mt5_deals d join chosen s on d.account_id=s.account_id
 where p_history and d.deal_type in ('BUY','SELL') and (p_symbol is null or d.symbol=p_symbol)
 and (p_entry is null or d.deal_entry=p_entry) and (p_from is null or d.deal_time >= p_from::timestamp at time zone 'UTC')
 and (p_to is null or d.deal_time < (p_to+1)::timestamp at time zone 'UTC')
), recent_deals as (
  select d.* from filtered d order by d.deal_time desc,d.deal_ticket desc limit 25 offset (least(greatest(coalesce(p_deal_page,0),0),100000)*25)
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
  'version', 2, 'generated_at', now(), 'history_included',p_history,
  'summary',(select jsonb_build_object('net',coalesce(sum(profit+commission+swap),0),'profit',coalesce(sum(profit),0),'commission',coalesce(sum(commission),0),'swap',coalesce(sum(swap),0)) from filtered),
  'symbols',coalesce((select jsonb_agg(x.symbol order by x.symbol) from (select distinct d.symbol from public.mt5_deals d join chosen s on s.account_id=d.account_id where p_history and d.deal_type in ('BUY','SELL')) x),'[]'::jsonb),
  'journals', coalesce((select jsonb_agg(item order by last_time desc) from (
    select jsonb_build_object('id',j.id,'opening_reason',j.opening_reason,'closing_reason',j.closing_reason,
      'updated_at',j.updated_at,
      'protections_total',(select count(*) from public.mt5_protection_groups g where g.journal_id=j.id and g.window_start+interval '1 minute'<=now()),
      'protections',coalesce((select jsonb_agg(x order by x.first_observed_at desc) from (
        select g.id,g.symbol,g.old_sl,g.new_sl,g.old_tp,g.new_tp,g.changes,g.first_observed_at,g.last_observed_at,g.reason,g.updated_at
        from public.mt5_protection_groups g where g.journal_id=j.id and g.window_start+interval '1 minute'<=now() order by g.first_observed_at desc,g.id limit 10) x),'[]'::jsonb),
      'events_total',(select count(*) from public.mt5_deals d where d.account_id=j.account_id and d.position_id=j.position_id),
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
    where p_history order by last_time desc nulls last,j.id limit 10 offset (least(greatest(coalesce(p_journal_page,0),0),100000)*10)
  ) journal_items),'[]'::jsonb),
  'journals_total',(select count(*) from public.mt5_trade_journal j join chosen s on s.account_id=j.account_id),
  'journals_limit',10,
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
  'deals_total',(select count(*) from filtered),
  'deals_limit',25,
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

revoke all on function public.mt5_public_dashboard_page(integer,integer,text,text,date,date,boolean) from public,anon,authenticated;
grant execute on function public.mt5_public_dashboard_page(integer,integer,text,text,date,date,boolean) to anon,authenticated;
comment on function public.mt5_public_dashboard_page(integer,integer,text,text,date,date,boolean) is 'QRT Solutions: opt-in demo projection, server pagination, filtered totals, no private account identifiers.';
