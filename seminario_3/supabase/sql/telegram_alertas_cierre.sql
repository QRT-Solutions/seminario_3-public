-- Author: QRT Solutions. Incremental extension after telegram_alertas_apertura.sql.
-- Keep existing RPC names for rolling-deployment compatibility.
alter table public.mt5_telegram_notifications drop constraint mt5_telegram_notifications_phase_check;
alter table public.mt5_telegram_notifications add constraint mt5_telegram_notifications_phase_check
 check(phase in ('opening','closing'));

create or replace function public.mt5_enqueue_opening_prompt()
returns trigger language plpgsql security definer set search_path='' as $$
declare jid uuid; event_phase text;
begin
 if new.deal_type not in ('BUY','SELL') or new.deal_entry not in ('IN','OUT','OUT_BY','INOUT')
   or new.approval_status<>'PENDING' or new.position_id<=0 then return new; end if;
 insert into public.mt5_trade_journal(account_id,position_id)
 values(new.account_id,new.position_id) on conflict do nothing;
 select id into jid from public.mt5_trade_journal where account_id=new.account_id and position_id=new.position_id;
 for event_phase in
   select 'opening' where new.deal_entry in ('IN','INOUT')
   union all select 'closing' where new.deal_entry in ('OUT','OUT_BY','INOUT')
 loop
   insert into public.mt5_telegram_notifications(account_id,journal_id,user_id,chat_id,phase,symbol,direction,volume,price)
   select new.account_id,jid,e.user_id,e.chat_id,event_phase,new.symbol,new.deal_type,new.volume,new.price
   from public.mt5_telegram_editors e where e.account_id=new.account_id and e.active
   on conflict(journal_id,user_id,phase) do nothing;
 end loop;
 return new;
end;
$$;
revoke all on function public.mt5_enqueue_opening_prompt() from public,anon,authenticated,service_role;

create or replace function public.mt5_claim_opening_notifications(p_account_id text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 with picked as (
   select n.id from public.mt5_telegram_notifications n
   join public.mt5_trade_journal j on j.id=n.journal_id
   where n.account_id=p_account_id and n.sent_at is null and n.next_attempt<=now()
    and (n.lease_until is null or n.lease_until<now())
    and ((n.phase='opening' and j.opening_reason is null) or (n.phase='closing' and j.closing_reason is null))
    and exists(select 1 from public.mt5_telegram_editors e where e.account_id=n.account_id
      and e.user_id=n.user_id and e.chat_id=n.chat_id and e.active)
   order by n.id for update of n skip locked limit 3
 ), leased as (
   update public.mt5_telegram_notifications n set lease_until=now()+interval '60 seconds',
     lease_token=gen_random_uuid(),attempts=attempts+1
   from picked p where n.id=p.id returning n.*
 ) select coalesce(jsonb_agg(jsonb_build_object('id',id::text,'lease_token',lease_token,
    'reference',left(journal_id::text,8),'chat_id',chat_id,'symbol',symbol,'phase',phase,
    'direction',direction,'volume',volume,'price',price)),'[]'::jsonb) into result from leased;
 return result;
end;
$$;
revoke all on function public.mt5_claim_opening_notifications(text) from public,anon,authenticated;
grant execute on function public.mt5_claim_opening_notifications(text) to service_role;
