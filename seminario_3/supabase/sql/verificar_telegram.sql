-- Author: QRT Solutions. Read-only verification; no tokens or chat identifiers returned.
select relname,relrowsecurity,
  has_table_privilege('anon',c.oid,'SELECT') as anon_read,
  has_table_privilege('anon',c.oid,'INSERT') as anon_insert
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and relname in
 ('mt5_telegram_pairing','mt5_telegram_editors','mt5_trade_journal','mt5_trade_reason_audit');

select proname,
  has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute,
  has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute,
  has_function_privilege('service_role',p.oid,'EXECUTE') as server_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and proname in
 ('mt5_claim_telegram_pairing','mt5_telegram_journals','mt5_record_trade_reason');

select (select count(*) from public.mt5_telegram_editors where active) as active_editors,
 (select count(*) from public.mt5_telegram_pairing where used_at is not null) as redeemed_codes,
 (select count(*) from public.mt5_trade_reason_audit) as recorded_reason_messages;
