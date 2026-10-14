-- Author: QRT Solutions. Synthetic fixtures; always rolled back. No Telegram delivery.
begin;
insert into public.mt5_accounts_snapshot(account_id,login,broker,server,currency,account_type,margin_mode,leverage,balance,equity,margin,margin_free,margin_level,profit_floating,open_positions_count,positions_json,updated_at,project_name,terminal_closed_profit,terminal_total_deals,today_closed_profit,today_trades_count)
values('qrt-fixture-simple',1,'Fixture','Fixture','USD','DEMO','HEDGING',1,100,100,0,100,0,0,1,'[{"ticket":"9001","position_id":"9000","symbol":"TEST","type":"BUY","volume":1,"current_price":100,"sl":90,"tp":120}]','2020-01-01','Fixture',0,0,0,0);
insert into public.mt5_telegram_editors(account_id,user_id,chat_id) values('qrt-fixture-simple',999000001,999000001);
update public.mt5_accounts_snapshot set positions_json=jsonb_set(positions_json,'{0,sl}','95'),updated_at='2020-01-02' where account_id='qrt-fixture-simple';
update public.mt5_accounts_snapshot set positions_json=jsonb_set(positions_json,'{0,tp}','130'),updated_at='2020-01-03' where account_id='qrt-fixture-simple';
update public.mt5_accounts_snapshot set updated_at='2020-01-04' where account_id='qrt-fixture-simple';
insert into public.mt5_deals(deal_ticket,order_ticket,position_id,account_id,login,broker,project_name,symbol,deal_type,deal_entry,volume,price,profit,commission,swap,deal_time,approval_status)
select 999000000000+i,999000000000+i,9000,'qrt-fixture-simple',1,'Fixture','Fixture',case when i<=15 then 'TEST' else 'OTHER' end,'BUY','IN',1,100,1,0,0,'2020-01-01'::timestamptz+i*interval '1 second','APPROVED' from generate_series(1,30) i;
insert into public.mt5_dashboard_publication(singleton,account_id,enabled,display_name) values(true,'qrt-fixture-simple',true,'Fixture')
on conflict(singleton) do update set account_id=excluded.account_id,enabled=true;
update public.mt5_protection_groups set window_start=window_start-interval '2 minutes' where journal_id in (select id from public.mt5_trade_journal where account_id='qrt-fixture-simple');
do $$
declare g public.mt5_protection_groups; r jsonb; stamp timestamptz;
begin
 select g1.* into g from public.mt5_protection_groups g1 join public.mt5_trade_journal j on j.id=g1.journal_id where j.account_id='qrt-fixture-simple' order by g1.first_observed_at limit 1;
 if g.id is null or g.old_sl<>90 or g.new_sl<>95 then raise exception 'SL history incorrect'; end if;
 if (select count(*) from public.mt5_protection_events e join public.mt5_protection_groups g1 on g1.id=e.group_id join public.mt5_trade_journal j on j.id=g1.journal_id where j.account_id='qrt-fixture-simple')<>2 then raise exception 'unchanged snapshots duplicated'; end if;
 if (select count(*) from public.mt5_telegram_notifications where account_id='qrt-fixture-simple')>2 then raise exception 'notification grouping failed'; end if;
 r=public.mt5_telegram_protections('qrt-fixture-simple',999000001,999000001,g.id,'Reducir riesgo',900000001);
 if not coalesce((r->>'ok')::boolean,false) then raise exception 'write failed'; end if;
 r=public.mt5_telegram_protections('qrt-fixture-simple',999000001,999000001,g.id,'Reducir riesgo',900000001);
 if not (r->>'duplicate')::boolean then raise exception 'retry not idempotent'; end if;
 begin
   perform public.mt5_telegram_protections('qrt-fixture-simple',999000002,999000002,g.id,'Intrusion',900000002);
   raise exception 'unauthorized writer accepted';
 exception when insufficient_privilege then null; end;
 insert into public.mt5_dashboard_sessions(hash,account_id,user_id,chat_id) values(repeat('e',64),'qrt-fixture-simple',999000001,999000001);
 r=public.mt5_dashboard_editor('protection',repeat('e',64),jsonb_build_object('journal_id',g.id));
 stamp=(r->'journal'->>'updated_at')::timestamptz;
 r=public.mt5_dashboard_editor('save_protection',repeat('e',64),jsonb_build_object('journal_id',g.id,'reason','Revisión web','request_id',gen_random_uuid(),'expected_updated_at',stamp));
 if not coalesce((r->>'ok')::boolean,false) then raise exception 'web write failed'; end if;
 r=public.mt5_dashboard_editor('save_protection',repeat('e',64),jsonb_build_object('journal_id',g.id,'reason','Borrador viejo','request_id',gen_random_uuid(),'expected_updated_at',stamp));
 if r->>'error'<>'conflict' then raise exception 'stale web edit accepted'; end if;
 if (select count(*) from public.mt5_protection_audit where group_id=g.id)<>2 then raise exception 'audit incorrect'; end if;
 if has_table_privilege('anon','public.mt5_protection_groups','select') or has_function_privilege('anon','public.mt5_telegram_protections(text,bigint,bigint,uuid,text,bigint)','execute') then raise exception 'private data exposed'; end if;
 r=public.mt5_public_dashboard_page();
 if (r->>'deals_total')::int<>30 or jsonb_array_length(r->'deals')<>25 or (r->'summary'->>'net')::numeric<>30 then raise exception 'global totals/page 1'; end if;
 r=public.mt5_public_dashboard_page(1);
 if jsonb_array_length(r->'deals')<>5 then raise exception 'page 2'; end if;
 r=public.mt5_public_dashboard_page(0,0,'TEST');
 if (r->>'deals_total')::int<>15 then raise exception 'server symbol filter'; end if;
 r=public.mt5_public_dashboard_page(0,0,null,null,null,null,false);
 if jsonb_array_length(r->'deals')<>0 or jsonb_array_length(r->'journals')<>0 then raise exception 'lightweight polling'; end if;
 r=public.mt5_telegram_protections('qrt-fixture-simple',999000001,999000001);
 if jsonb_typeof(r)<>'array' then raise exception 'pending reader'; end if;
 r=public.mt5_public_dashboard_page();
 if (r->>'version')::int<>2 or jsonb_array_length(r->'deals')>25 or jsonb_array_length(r->'journals')>10 then raise exception 'pagination contract'; end if;
end $$;
select 'protection, ownership, revisions, idempotency and pagination checks passed' as result;
rollback;
