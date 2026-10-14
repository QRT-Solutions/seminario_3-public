-- Author: QRT Solutions. Synthetic fixtures, always rolled back. Run only in a local test database.
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
 k:=public.mt5_public_dashboard_kpis(null,'SELL');
 assert (k->>'count')::int=1 and (k->>'cumulative_return_pct')::numeric=-10,'original SELL direction';
 assert (k->>'profit_factor_pct')::numeric=0 and k->>'payoff_pct' is null,'only losses';
 k:=public.mt5_public_dashboard_kpis(null,null,'2026-01-03','2026-01-03');
 assert (k->>'count')::int=1 and (k->>'net')::numeric=8,'opening before period retained';
 assert k->>'profit_factor_pct' is null,'no losses is undefined';
 k:=public.mt5_public_dashboard_kpis('ABSENT');
 assert (k->>'count')::int=0 and k->>'net' is null and k->>'win_rate_pct' is null,'empty is not zero';
 update public.mt5_dashboard_publication set enabled=false;
 assert public.mt5_public_dashboard_kpis() is null,'publication disabled';
 update public.mt5_dashboard_publication set enabled=true;
 update public.mt5_accounts_snapshot set account_type='REAL';
 assert public.mt5_public_dashboard_kpis() is null,'real account cannot be published';
 assert not has_table_privilege('anon','public.mt5_deals','SELECT'),'no table access';
 assert has_function_privilege('anon','public.mt5_public_dashboard_kpis(text,text,date,date)','EXECUTE'),'projection access';
end $$;
rollback;
