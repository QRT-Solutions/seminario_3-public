-- Author: QRT Solutions. Apply after dashboard_paginado.sql.
-- Additive projection: no account identifiers, raw trades, permissions or publication changes.
create or replace function public.mt5_public_dashboard_kpis(
  p_symbol text default null, p_direction text default null,
  p_from date default null, p_to date default null)
returns jsonb language sql stable security definer set search_path = ''
as $$
with chosen as materialized (
  select s.account_id from public.mt5_dashboard_publication p
  join public.mt5_accounts_snapshot s using(account_id)
  where p.singleton and p.enabled and s.account_type = 'DEMO'
), ordered as (
  select d.*, row_number() over w as seq,
    sum(case when deal_entry='IN' then volume when deal_entry in ('OUT','OUT_BY') then -volume else 0 end) over w as remaining
  from public.mt5_deals d join chosen s using(account_id)
  where d.position_id>0 and d.deal_type in ('BUY','SELL')
  window w as (partition by d.account_id,d.position_id order by d.deal_time,d.deal_ticket rows unbounded preceding)
), grouped as (
  select account_id,position_id,min(symbol) as symbol,
    min(deal_type) filter(where deal_entry='IN') as direction,
    max(deal_time) filter(where deal_entry in ('OUT','OUT_BY','INOUT')) as closed_at,
    count(*) filter(where deal_entry in ('OUT','OUT_BY','INOUT')) as exits,
    sum(volume) filter(where deal_entry='IN') as volume_in,
    sum(volume) filter(where deal_entry in ('OUT','OUT_BY')) as volume_out,
    sum(price*volume) filter(where deal_entry='IN') / nullif(sum(volume) filter(where deal_entry='IN'),0) as price_in,
    sum(price*volume) filter(where deal_entry in ('OUT','OUT_BY')) / nullif(sum(volume) filter(where deal_entry in ('OUT','OUT_BY')),0) as price_out,
    sum(profit+commission+swap) as net,
    bool_and(profit is not null and commission is not null and swap is not null) as costs_present,
    bool_and(volume>0 and price>0 and deal_entry in ('IN','OUT','OUT_BY'))
      and count(distinct symbol)=1
      and count(distinct deal_type) filter(where deal_entry='IN')=1
      and count(distinct deal_type) filter(where deal_entry in ('OUT','OUT_BY'))=1
      and min(deal_type) filter(where deal_entry='IN')<>min(deal_type) filter(where deal_entry in ('OUT','OUT_BY'))
      and max(seq) filter(where deal_entry='IN')<min(seq) filter(where deal_entry in ('OUT','OUT_BY'))
      and min(remaining)>=0
      and count(*) filter(where remaining=0)=1 as valid_sequence
  from ordered group by account_id,position_id
), candidates as (
  select *, coalesce(valid_sequence and volume_in=volume_out and volume_in>0,false) as complete
  from grouped where exits>0
    and (p_symbol is null or symbol=p_symbol)
    and (p_direction is null or direction=p_direction)
    -- EA broker wall times are stored with a Z suffix; do not claim actual UTC.
    and (p_from is null or closed_at>=p_from::timestamp at time zone 'UTC')
    and (p_to is null or closed_at<(p_to+1)::timestamp at time zone 'UTC')
), trades as (
  select *, 100*(case when direction='BUY' then 1 else -1 end)*(price_out-price_in)/price_in as return_pct
  from candidates where complete
), totals as (
  select count(*) as n,
    case when bool_and(costs_present) then sum(net) end as net,
    sum(return_pct) as cumulative_return_pct, avg(return_pct) as expectancy_pct,
    100.0*count(*) filter(where return_pct>0)/nullif(count(*),0) as win_rate_pct,
    sum(return_pct) filter(where return_pct>0)/nullif(abs(sum(return_pct) filter(where return_pct<0)),0) as profit_factor_pct,
    avg(return_pct) filter(where return_pct>0)/nullif(abs(avg(return_pct) filter(where return_pct<0)),0) as payoff_pct,
    case when bool_and(costs_present) then
      sum(net) filter(where net>0)/nullif(abs(sum(net) filter(where net<0)),0) end as profit_factor_money
  from trades
)
select case when not exists(select 1 from chosen) then null else
  jsonb_build_object('version',1,'generated_at',now(),'time_basis','broker',
    'count',n,'excluded',(select count(*) from candidates where not complete),
    'unlinked_deals',(select count(*) from public.mt5_deals d join chosen s using(account_id)
      where d.position_id<=0 and d.deal_type in ('BUY','SELL')),
    'net',net,'cumulative_return_pct',cumulative_return_pct,'win_rate_pct',win_rate_pct,
    'profit_factor_pct',case when n>0 then coalesce(profit_factor_pct,
      case when exists(select 1 from trades where return_pct<0) then 0 end) end,
    'profit_factor_money',case when n>0 then coalesce(profit_factor_money,
      case when (select bool_and(costs_present) from trades) and exists(select 1 from trades where net<0) then 0 end) end,
    'payoff_pct',payoff_pct,'expectancy_pct',expectancy_pct)
  end from totals;
$$;
revoke all on function public.mt5_public_dashboard_kpis(text,text,date,date) from public,anon,authenticated;
grant execute on function public.mt5_public_dashboard_kpis(text,text,date,date) to anon,authenticated;
comment on function public.mt5_public_dashboard_kpis(text,text,date,date) is
  'QRT Solutions: aggregates of observed complete demo positions, close-date filters, no reversals or interleaved scaling, no account identifiers.';
