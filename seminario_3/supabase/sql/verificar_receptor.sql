-- Author: QRT Solutions. Read-only; run each statement separately if needed.
select 'snapshot' as resource, count(*) as rows, max(received_at) as latest
from public.mt5_accounts_snapshot
union all select 'deals', count(*), max(received_at) from public.mt5_deals
union all select 'swaps', count(*), max(received_at) from public.mt5_swap_rates;

select c.relname as table_name, c.relrowsecurity as rls_enabled,
       has_table_privilege('anon', c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') as anon_any_access,
       has_table_privilege('authenticated', c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') as authenticated_any_access,
       has_table_privilege('service_role', c.oid, 'DELETE') as server_delete
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
  and c.relname in ('mt5_accounts_snapshot','mt5_deals','mt5_swap_rates','mt5_ingest_credentials')
order by c.relname;

select count(*) as total_credentials,
       count(*) filter (where active and expires_at > now()) as active_credentials
from public.mt5_ingest_credentials;
