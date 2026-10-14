-- Author: QRT Solutions. Durable opening prompts; excludes pre-existing and historical deals.
create table public.mt5_telegram_notifications (
 id bigint generated always as identity primary key,
 account_id text not null,
 journal_id uuid not null references public.mt5_trade_journal(id),
 user_id bigint not null,
 chat_id bigint not null,
 phase text not null default 'opening' check(phase='opening'),
 symbol text not null, direction text not null, volume numeric not null, price numeric not null,
 created_at timestamptz not null default now(),
 sent_at timestamptz, message_id bigint,
 lease_until timestamptz, lease_token uuid,
 next_attempt timestamptz not null default now(), attempts integer not null default 0,
 unique(journal_id,user_id,phase), unique(chat_id,message_id)
);
alter table public.mt5_telegram_notifications enable row level security;
revoke all on public.mt5_telegram_notifications from public,anon,authenticated,service_role;
create index mt5_telegram_notifications_pending on public.mt5_telegram_notifications(account_id,next_attempt) where sent_at is null;

create function public.mt5_enqueue_opening_prompt()
returns trigger language plpgsql security definer set search_path='' as $$
declare jid uuid;
begin
 if new.deal_type not in ('BUY','SELL') or new.deal_entry not in ('IN','INOUT')
   or new.approval_status<>'PENDING' or new.position_id<=0 then return new; end if;
 -- PENDING identifies the existing event-driven EA payload, not a human approval.
 -- Never backfill old deals into this queue. Historical exports are APPROVED.
 insert into public.mt5_trade_journal(account_id,position_id)
 values(new.account_id,new.position_id) on conflict do nothing;
 select id into jid from public.mt5_trade_journal where account_id=new.account_id and position_id=new.position_id;
 insert into public.mt5_telegram_notifications(account_id,journal_id,user_id,chat_id,symbol,direction,volume,price)
 select new.account_id,jid,e.user_id,e.chat_id,new.symbol,new.deal_type,new.volume,new.price
 from public.mt5_telegram_editors e where e.account_id=new.account_id and e.active
 on conflict(journal_id,user_id,phase) do nothing;
 return new;
end;
$$;
revoke all on function public.mt5_enqueue_opening_prompt() from public,anon,authenticated,service_role;
create trigger mt5_opening_prompt after insert on public.mt5_deals
for each row execute function public.mt5_enqueue_opening_prompt();

create function public.mt5_claim_opening_notifications(p_account_id text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 with picked as (
   select n.id from public.mt5_telegram_notifications n
   join public.mt5_trade_journal j on j.id=n.journal_id
   where n.account_id=p_account_id and n.sent_at is null and n.next_attempt<=now()
    and (n.lease_until is null or n.lease_until<now()) and j.opening_reason is null
    and exists(select 1 from public.mt5_telegram_editors e where e.account_id=n.account_id
      and e.user_id=n.user_id and e.chat_id=n.chat_id and e.active)
   order by n.id for update of n skip locked limit 3
 ), leased as (
   update public.mt5_telegram_notifications n set lease_until=now()+interval '60 seconds',
     lease_token=gen_random_uuid(),attempts=attempts+1
   from picked p where n.id=p.id returning n.*
 ) select coalesce(jsonb_agg(jsonb_build_object('id',id::text,'lease_token',lease_token,
    'reference',left(journal_id::text,8),'chat_id',chat_id,'symbol',symbol,
    'direction',direction,'volume',volume,'price',price)),'[]'::jsonb) into result from leased;
 return result;
end;
$$;

create function public.mt5_finish_opening_notification(p_id bigint,p_lease uuid,p_message_id bigint)
returns boolean language plpgsql security definer set search_path='' as $$
begin
 if p_message_id is not null and p_message_id<=0 then return false; end if;
 update public.mt5_telegram_notifications set
   message_id=p_message_id,sent_at=case when p_message_id is not null then now() else null end,
   next_attempt=now()+interval '30 seconds',lease_until=null,lease_token=null
 where id=p_id and lease_token=p_lease and sent_at is null;
 return found;
end;
$$;

create function public.mt5_telegram_prompt_reference(p_account_id text,p_user_id bigint,p_chat_id bigint,p_message_id bigint)
returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('reference',left(n.journal_id::text,8),'phase',n.phase)
 from public.mt5_telegram_notifications n
 where n.account_id=p_account_id and n.user_id=p_user_id and n.chat_id=p_chat_id
   and n.message_id=p_message_id and n.sent_at is not null
   and exists(select 1 from public.mt5_telegram_editors e where e.account_id=n.account_id
     and e.user_id=n.user_id and e.chat_id=n.chat_id and e.active);
$$;
revoke all on function public.mt5_claim_opening_notifications(text) from public,anon,authenticated;
revoke all on function public.mt5_finish_opening_notification(bigint,uuid,bigint) from public,anon,authenticated;
revoke all on function public.mt5_telegram_prompt_reference(text,bigint,bigint,bigint) from public,anon,authenticated;
grant execute on function public.mt5_claim_opening_notifications(text) to service_role;
grant execute on function public.mt5_finish_opening_notification(bigint,uuid,bigint) to service_role;
grant execute on function public.mt5_telegram_prompt_reference(text,bigint,bigint,bigint) to service_role;
