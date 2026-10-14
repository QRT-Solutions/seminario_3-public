-- Author: QRT Solutions
-- Consultas de solo lectura. Ejecutar cada sentencia por separado si el cliente
-- solo devuelve el resultado de la ultima sentencia.

select c.relname as table_name, c.relrowsecurity as rls_enabled,
       has_table_privilege('anon', c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') as anon_any_access,
       has_table_privilege('authenticated', c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') as authenticated_any_access
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
  and c.relname in ('mt5_accounts_snapshot', 'mt5_deals', 'mt5_swap_rates')
order by c.relname;

select table_name, column_name, data_type, is_nullable,
       numeric_precision, numeric_scale
from information_schema.columns
where table_schema = 'public'
  and table_name in ('mt5_accounts_snapshot', 'mt5_deals', 'mt5_swap_rates')
order by table_name, ordinal_position;

select c.relname as table_name, con.conname,
       pg_get_constraintdef(con.oid) as definition
from pg_constraint con
join pg_class c on c.oid = con.conrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('mt5_accounts_snapshot', 'mt5_deals', 'mt5_swap_rates')
order by c.relname, con.conname;

select 'mt5_accounts_snapshot' as table_name, count(*) as rows from public.mt5_accounts_snapshot
union all select 'mt5_deals', count(*) from public.mt5_deals
union all select 'mt5_swap_rates', count(*) from public.mt5_swap_rates;

select tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('mt5_accounts_snapshot', 'mt5_deals', 'mt5_swap_rates');
