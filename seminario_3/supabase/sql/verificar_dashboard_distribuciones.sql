-- Author: QRT Solutions. Chart fixtures after dashboard_distribuciones.sql; local database only. Always ROLLBACK.
begin;
insert into public.mt5_accounts_snapshot(account_id,login,broker,server,currency,account_type,margin_mode,leverage,balance,equity,margin,margin_free,margin_level,profit_floating,open_positions_count,positions_json,updated_at,project_name,terminal_closed_profit,terminal_total_deals,today_closed_profit,today_trades_count)
values ('KPI_TEST',1,'TEST','TEST','USD','DEMO','HEDGING',1,1000,1000,0,1000,0,0,0,'[]',now(),'TEST',0,0,0,0);
insert into public.mt5_dashboard_publication(singleton,account_id,enabled,display_name) values(true,'KPI_TEST',true,'TEST');
-- BUY +10%, SELL -10%, partial BUY 0%, incomplete exit, reversal and interleaved scale-in.
insert into public.mt5_deals(deal_ticket,order_ticket,position_id,account_id,login,broker,project_name,symbol,deal_type,deal_entry,volume,price,profit,commission,swap,deal_time,approval_status)
select ticket,ticket,pid,'KPI_TEST',1,'TEST','TEST','TEST',side,entry,vol,price,profit,-1,0,stamp::timestamptz,'TEST'
from (values
 (1,1,'BUY','IN',1,100,0,'2026-01-01'),(2,1,'SELL','OUT',1,110,10,'2026-01-03'),
 (3,2,'SELL','IN',1,100,0,'2026-01-01'),(4,2,'BUY','OUT',1,110,-10,'2026-01-04'),
 (5,3,'BUY','IN',2,100,0,'2026-01-01'),(6,3,'SELL','OUT',1,90,-10,'2026-01-05'),(7,3,'SELL','OUT',1,110,10,'2026-01-06'),
 (8,4,'SELL','OUT',1,110,10,'2026-01-07'),
 (9,5,'BUY','IN',1,100,0,'2026-01-01'),(10,5,'SELL','INOUT',2,100,0,'2026-01-08'),
 (11,6,'BUY','IN',2,100,0,'2026-01-01'),(12,6,'SELL','OUT',1,105,5,'2026-01-02'),(13,6,'BUY','IN',1,110,0,'2026-01-03'),(14,6,'SELL','OUT',2,115,20,'2026-01-09')
) x(ticket,pid,side,entry,vol,price,profit,stamp);
do $$ declare k jsonb; begin
 k:=public.mt5_public_dashboard_kpis();
 assert (k->>'count')::int=3 and (k->>'excluded')::int=3,'coverage';
 assert (k->>'net')::numeric=-7,'entry and partial commissions';
 assert (k->>'cumulative_return_pct')::numeric=0,'BUY SELL and partial weighting';
 assert (k->>'profit_factor_pct')::numeric=1 and (k->>'payoff_pct')::numeric=1,'ratios';
 assert abs((k->>'win_rate_pct')::numeric-100.0/3)<0.00001,'neutral denominator';
 assert (select sum((b->>'count')::int) from jsonb_array_elements(k#>'{charts,histogram_return}') b)=3,'histogram count';
 assert (select sum((b->>'count')::int) from jsonb_array_elements(k#>'{charts,histogram_net}') b)=3,'monetary histogram count';
 assert jsonb_array_length(k#>'{charts,curve}')=3,'one curve point per close';
 assert (k#>>'{charts,curve,0,cumulative_net}')::numeric=8,'first net';
 assert (k#>>'{charts,curve,1,cumulative_net}')::numeric=-4,'second net';
 assert (k#>>'{charts,curve,2,cumulative_net}')::numeric=-7,'last net';
 assert (k#>>'{charts,curve,2,cumulative_return_pct}')::numeric=0,'last return';
 assert (k#>>'{charts,curve,2,cumulative_long_pct}')::numeric=10,'long contribution';
 assert (k#>>'{charts,curve,2,cumulative_short_pct}')::numeric=-10,'short contribution';
 k:=public.mt5_public_dashboard_kpis(null,'SELL');
 assert (k->>'count')::int=1 and (k->>'cumulative_return_pct')::numeric=-10,'original SELL direction';
 assert jsonb_array_length(k#>'{charts,histogram_return}')=1,'constant sample: one bin';
 assert (k#>>'{charts,histogram_return,0,lower}')::numeric=-10,'constant lower';
 assert (k#>>'{charts,histogram_return,0,upper}')::numeric=-10,'constant upper';
 assert (k->>'profit_factor_pct')::numeric=0 and k->>'payoff_pct' is null,'only losses';
 k:=public.mt5_public_dashboard_kpis(null,null,'2026-01-03','2026-01-03');
 assert (k->>'count')::int=1 and (k->>'net')::numeric=8,'opening before period retained';
 assert k->>'profit_factor_pct' is null,'no losses is undefined';
 k:=public.mt5_public_dashboard_kpis('ABSENT');
 assert (k->>'count')::int=0 and k->>'net' is null and k->>'win_rate_pct' is null,'empty is not zero';
 assert k#>'{charts,curve}'='[]'::jsonb and k#>'{charts,histogram_return}'='[]'::jsonb,'empty charts';
 update public.mt5_dashboard_publication set enabled=false;
 assert public.mt5_public_dashboard_kpis() is null,'publication disabled';
 update public.mt5_dashboard_publication set enabled=true;
 update public.mt5_accounts_snapshot set account_type='REAL';
 assert public.mt5_public_dashboard_kpis() is null,'real account cannot be published';
 assert not has_table_privilege('anon','public.mt5_deals','SELECT'),'no table access';
 assert has_function_privilege('anon','public.mt5_public_dashboard_kpis(text,text,date,date)','EXECUTE'),'projection access';
end $$;
-- More than 400 closes: preserve totals and coverage with bounded chart payload.
update public.mt5_accounts_snapshot set account_type='DEMO';
insert into public.mt5_deals(deal_ticket,order_ticket,position_id,account_id,login,broker,project_name,symbol,deal_type,deal_entry,volume,price,profit,commission,swap,deal_time,approval_status)
select 1000+2*i+j,1000+2*i+j,1000+i,'KPI_TEST',1,'TEST','TEST','LARGE',
  case when j=0 then 'BUY' else 'SELL' end,case when j=0 then 'IN' else 'OUT' end,
  1,case when j=0 then 100 else 101 end,case when j=0 then 0 else 1 end,0,0,
  '2026-02-01'::timestamptz+(2*i+j)*interval '1 second','TEST'
from generate_series(1,805) i cross join generate_series(0,1) j;
do $$ declare k jsonb; last_point jsonb; begin
 k:=public.mt5_public_dashboard_kpis('LARGE');
 assert (k->>'count')::int=805,'large sample count';
 assert jsonb_array_length(k#>'{charts,curve}')<=400,'bounded curve size';
 last_point:=k#>'{charts,curve,-1}';
 assert (last_point->>'trade_to')::int=805,'last operation retained';
 assert (last_point->>'cumulative_return_pct')::numeric=805 and (last_point->>'cumulative_net')::numeric=805,'all results retained';
 assert (select sum((p->>'trade_to')::int-(p->>'trade_from')::int+1) from jsonb_array_elements(k#>'{charts,curve}') p)=805,'all buckets contiguous coverage';
 assert (k#>>'{charts,histogram_return,0,count}')::int=805,'constant histogram across full sample';
end $$;
rollback;
