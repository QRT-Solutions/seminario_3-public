-- Author: QRT Solutions
-- Correccion condicional: inspeccionar primero. No crear esta funcion si no existe.
-- Ejecutar la inspeccion y la correccion por separado.
select p.oid::regprocedure::text as function_name,
       p.prorettype::regtype::text as return_type,
       p.prosecdef as security_definer,
       pg_get_userbyid(p.proowner) as owner
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'rls_auto_enable';

-- Solo tras verificar la funcion administrativa sin argumentos,
-- de tipo event_trigger, instalada por el RLS automatico del panel:
-- aplicar como migracion separada y volver a ejecutar asesores.
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
