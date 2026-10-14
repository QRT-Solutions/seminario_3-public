-- Author: QRT Solutions. Apply after dashboard_editor.sql. Observation only; no trading.
create table public.mt5_protection_groups (
 id uuid primary key default gen_random_uuid(), journal_id uuid not null references public.mt5_trade_journal(id),
 window_start timestamptz not null, symbol text not null,
 old_sl numeric not null, old_tp numeric not null, new_sl numeric not null, new_tp numeric not null,
 changes integer not null default 1, first_observed_at timestamptz not null, last_observed_at timestamptz not null,
 reason text check(char_length(reason) between 1 and 1000), updated_at timestamptz not null default clock_timestamp(),
 unique(journal_id,window_start)
);
create table public.mt5_protection_events (
 id bigint generated always as identity primary key, group_id uuid not null references public.mt5_protection_groups(id),
 old_sl numeric not null, old_tp numeric not null, new_sl numeric not null, new_tp numeric not null,
 observed_at timestamptz not null, received_at timestamptz not null default clock_timestamp()
);
create index mt5_protection_event_group on public.mt5_protection_events(group_id,id);
create table public.mt5_protection_audit (
 request_key text primary key, group_id uuid not null references public.mt5_protection_groups(id),
 source text not null check(source in ('web','telegram')), actor_user_id bigint not null,
 previous_reason text, reason text not null check(char_length(reason) between 1 and 1000),
 recorded_at timestamptz not null default clock_timestamp()
);
create index mt5_protection_audit_group on public.mt5_protection_audit(group_id,recorded_at desc);
alter table public.mt5_protection_groups enable row level security;
alter table public.mt5_protection_events enable row level security;
alter table public.mt5_protection_audit enable row level security;
revoke all on public.mt5_protection_groups,public.mt5_protection_events,public.mt5_protection_audit from public,anon,authenticated,service_role;
alter table public.mt5_telegram_notifications add column protection_id uuid references public.mt5_protection_groups(id);
alter table public.mt5_telegram_notifications drop constraint mt5_telegram_notifications_phase_check;
alter table public.mt5_telegram_notifications add constraint mt5_telegram_notifications_phase_check check(
 (phase in ('opening','closing') and protection_id is null) or (phase='protection' and protection_id is not null));
alter table public.mt5_telegram_notifications drop constraint mt5_telegram_notifications_journal_id_user_id_phase_key;
create unique index mt5_notification_phase on public.mt5_telegram_notifications(journal_id,user_id,phase) where protection_id is null;
create unique index mt5_notification_protection on public.mt5_telegram_notifications(protection_id,user_id) where protection_id is not null;

create function public.mt5_observe_protections()
returns trigger language plpgsql security definer set search_path='' as $$
declare p jsonb; previous jsonb; jid uuid; gid uuid; bucket timestamptz;
begin
 -- Old clients lack POSITION_IDENTIFIER. Never guess that their ticket is that identifier.
 -- Ignore an older/retried observation rather than manufacturing a reverse change.
 if new.updated_at <= old.updated_at then return new; end if;
 for p in select value from jsonb_array_elements(new.positions_json) loop
   if coalesce(p->>'position_id','') !~ '^[1-9][0-9]{0,19}$' then continue; end if;
   select value into previous from jsonb_array_elements(old.positions_json)
     where value->>'position_id'=p->>'position_id' limit 1;
   if previous is null or ((previous->>'sl')::numeric=(p->>'sl')::numeric and (previous->>'tp')::numeric=(p->>'tp')::numeric) then continue; end if;
   insert into public.mt5_trade_journal(account_id,position_id) values(new.account_id,(p->>'position_id')::numeric) on conflict do nothing;
   select id into jid from public.mt5_trade_journal where account_id=new.account_id and position_id=(p->>'position_id')::numeric;
   bucket=date_trunc('minute',clock_timestamp());
   insert into public.mt5_protection_groups(journal_id,window_start,symbol,old_sl,old_tp,new_sl,new_tp,first_observed_at,last_observed_at)
   values(jid,bucket,p->>'symbol',(previous->>'sl')::numeric,(previous->>'tp')::numeric,(p->>'sl')::numeric,(p->>'tp')::numeric,new.updated_at,new.updated_at)
   on conflict(journal_id,window_start) do update set new_sl=excluded.new_sl,new_tp=excluded.new_tp,
     changes=mt5_protection_groups.changes+1,last_observed_at=excluded.last_observed_at,updated_at=clock_timestamp() returning id into gid;
   insert into public.mt5_protection_events(group_id,old_sl,old_tp,new_sl,new_tp,observed_at)
   values(gid,(previous->>'sl')::numeric,(previous->>'tp')::numeric,(p->>'sl')::numeric,(p->>'tp')::numeric,new.updated_at);
   insert into public.mt5_telegram_notifications(account_id,journal_id,user_id,chat_id,phase,protection_id,symbol,direction,volume,price,next_attempt)
   select new.account_id,jid,e.user_id,e.chat_id,'protection',gid,p->>'symbol',p->>'type',(p->>'volume')::numeric,(p->>'current_price')::numeric,bucket+interval '1 minute'
   from public.mt5_telegram_editors e where e.account_id=new.account_id and e.active on conflict do nothing;
 end loop;
 return new;
end $$;
revoke all on function public.mt5_observe_protections() from public,anon,authenticated,service_role;
create trigger mt5_protection_snapshot after update on public.mt5_accounts_snapshot for each row execute function public.mt5_observe_protections();

create or replace function public.mt5_claim_opening_notifications(p_account_id text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 with picked as (
   select n.id from public.mt5_telegram_notifications n
   join public.mt5_trade_journal j on j.id=n.journal_id
   left join public.mt5_protection_groups g on g.id=n.protection_id
   where n.account_id=p_account_id and n.sent_at is null and n.next_attempt<=now()
    and (n.lease_until is null or n.lease_until<now())
    and ((n.phase='opening' and j.opening_reason is null) or (n.phase='closing' and j.closing_reason is null) or (n.phase='protection' and g.reason is null))
    and exists(select 1 from public.mt5_telegram_editors e where e.account_id=n.account_id and e.user_id=n.user_id and e.chat_id=n.chat_id and e.active)
   order by n.id for update of n skip locked limit 3
 ), leased as (
   update public.mt5_telegram_notifications n set lease_until=now()+interval '60 seconds',lease_token=gen_random_uuid(),attempts=attempts+1
   from picked p where n.id=p.id returning n.*
 ) select coalesce(jsonb_agg(jsonb_build_object('id',n.id::text,'lease_token',n.lease_token,'reference',left(n.journal_id::text,8),
   'chat_id',n.chat_id,'symbol',n.symbol,'phase',n.phase,'direction',n.direction,'volume',n.volume,'price',n.price,
   'protection_id',n.protection_id,'old_sl',g.old_sl,'new_sl',g.new_sl,'old_tp',g.old_tp,'new_tp',g.new_tp,'changes',g.changes)), '[]'::jsonb)
 into result from leased n left join public.mt5_protection_groups g on g.id=n.protection_id;
 return result;
end $$;

create or replace function public.mt5_telegram_prompt_reference(p_account_id text,p_user_id bigint,p_chat_id bigint,p_message_id bigint)
returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('reference',left(n.journal_id::text,8),'phase',n.phase,'protection_id',n.protection_id)
 from public.mt5_telegram_notifications n where n.account_id=p_account_id and n.user_id=p_user_id and n.chat_id=p_chat_id
 and n.message_id=p_message_id and n.sent_at is not null
 and exists(select 1 from public.mt5_telegram_editors e where e.account_id=n.account_id and e.user_id=n.user_id and e.chat_id=n.chat_id and e.active);
$$;

-- Shared revision writer, callable only from the authenticated RPCs below.
create function public.mt5_write_protection_reason(p_id uuid,p_user bigint,p_reason text,p_key text,p_source text,p_expected timestamptz)
returns jsonb language plpgsql security definer set search_path='' as $$
declare g public.mt5_protection_groups; a public.mt5_protection_audit;
begin
 if p_reason is null or char_length(btrim(p_reason)) not between 1 and 1000 or p_key is null or p_source not in ('web','telegram') then return jsonb_build_object('error','invalid_input'); end if;
 select * into g from public.mt5_protection_groups where id=p_id for update;
 if not found then return jsonb_build_object('error','not_found'); end if;
 if g.window_start+interval '1 minute'>clock_timestamp() then return jsonb_build_object('error','group_pending'); end if;
 select * into a from public.mt5_protection_audit where request_key=p_key;
 if found then
   if a.group_id=p_id and a.actor_user_id=p_user and a.reason=btrim(p_reason) then return jsonb_build_object('ok',true,'duplicate',true); end if;
   return jsonb_build_object('error','invalid_input');
 end if;
 if p_expected is null or g.updated_at<>p_expected then return jsonb_build_object('error','conflict'); end if;
 insert into public.mt5_protection_audit(request_key,group_id,source,actor_user_id,previous_reason,reason) values(p_key,p_id,p_source,p_user,g.reason,btrim(p_reason));
 update public.mt5_protection_groups set reason=btrim(p_reason),updated_at=clock_timestamp() where id=p_id;
 return jsonb_build_object('ok',true,'duplicate',false);
end $$;
revoke all on function public.mt5_write_protection_reason(uuid,bigint,text,text,text,timestamptz) from public,anon,authenticated,service_role;

create function public.mt5_telegram_protections(p_account text,p_user bigint,p_chat bigint,p_id uuid default null,p_reason text default null,p_update bigint default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare g public.mt5_protection_groups; result jsonb;
begin
 perform 1 from public.mt5_telegram_editors where account_id=p_account and user_id=p_user and chat_id=p_chat and active for share;
 if not found then raise exception 'unauthorized' using errcode='42501'; end if;
 if p_id is null then
   select coalesce(jsonb_agg(x),'[]'::jsonb) into result from (
     select g2.id,left(j.id::text,8) reference,g2.symbol,g2.first_observed_at,g2.changes from public.mt5_protection_groups g2
     join public.mt5_trade_journal j on j.id=g2.journal_id where j.account_id=p_account and g2.reason is null and g2.window_start+interval '1 minute'<=now()
     order by g2.first_observed_at desc,g2.id limit 20) x;
   return result;
 end if;
 select g1.* into g from public.mt5_protection_groups g1 join public.mt5_trade_journal j on j.id=g1.journal_id
 where g1.id=p_id and j.account_id=p_account for update of g1;
 if not found then raise exception 'not_found' using errcode='22023'; end if;
 if p_reason is null then return jsonb_build_object('id',g.id,'reason',g.reason,'updated_at',g.updated_at); end if;
 if p_update is null or p_update<0 then raise exception 'invalid_input' using errcode='22023'; end if;
 -- Late Telegram requests cannot overwrite a more recent Telegram request.
 if exists(select 1 from public.mt5_protection_audit where group_id=p_id and source='telegram' and recorded_at>now()-interval '7 days' and (case when source='telegram' then substring(request_key from 4)::bigint end)>p_update) then return jsonb_build_object('ok',true,'stale',true); end if;
 return public.mt5_write_protection_reason(p_id,p_user,p_reason,'tg:'||p_update,'telegram',g.updated_at);
end $$;
revoke all on function public.mt5_telegram_protections(text,bigint,bigint,uuid,text,bigint) from public,anon,authenticated;
grant execute on function public.mt5_telegram_protections(text,bigint,bigint,uuid,text,bigint) to service_role;

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
   on conflict do nothing;
 end loop;
 return new;
end;
$$;
revoke all on function public.mt5_enqueue_opening_prompt() from public,anon,authenticated,service_role;


create or replace function public.mt5_dashboard_editor(p_action text,p_hash text,p_data jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare c public.mt5_dashboard_login_codes; s public.mt5_dashboard_sessions;
 j public.mt5_trade_journal; a public.mt5_web_reason_audit;
 g public.mt5_protection_groups;
 phase text; reason text; old_reason text; v_request_id uuid; events boolean; history jsonb;
begin
 if p_hash is null or p_hash !~ '^[a-f0-9]{64}$' then return jsonb_build_object('error','unauthorized'); end if;
 if p_action='login' then
   if coalesce(p_data->>'session_hash','') !~ '^[a-f0-9]{64}$' then return jsonb_build_object('error','invalid_input'); end if;
   select * into c from public.mt5_dashboard_login_codes where hash=p_hash for update;
   if not found or c.expires_at<=now() or c.consumed_at is not null then return jsonb_build_object('error','unauthorized'); end if;
   perform 1 from public.mt5_telegram_editors where account_id=c.account_id and user_id=c.user_id and chat_id=c.chat_id and active for share;
   if not found then return jsonb_build_object('error','unauthorized'); end if;
   insert into public.mt5_dashboard_sessions(hash,account_id,user_id,chat_id) values(p_data->>'session_hash',c.account_id,c.user_id,c.chat_id) returning * into s;
   update public.mt5_dashboard_login_codes set consumed_at=now() where hash=p_hash;
   return jsonb_build_object('ok',true,'expires_at',s.expires_at);
 end if;
 select * into s from public.mt5_dashboard_sessions where hash=p_hash for update;
 if not found or s.expires_at<=now() or s.revoked_at is not null then return jsonb_build_object('error','unauthorized'); end if;
 perform 1 from public.mt5_telegram_editors where account_id=s.account_id and user_id=s.user_id and chat_id=s.chat_id and active for share;
 if not found then return jsonb_build_object('error','unauthorized'); end if;
 if p_action='logout' then
   update public.mt5_dashboard_sessions set revoked_at=now() where hash=p_hash;
   return jsonb_build_object('ok',true);
 end if;
 if p_action='session' then return jsonb_build_object('ok',true,'expires_at',s.expires_at); end if;
 if p_action in ('protection','save_protection') then
   select g1.* into g from public.mt5_protection_groups g1 join public.mt5_trade_journal j1 on j1.id=g1.journal_id
    where g1.id=(p_data->>'journal_id')::uuid and j1.account_id=s.account_id for update of g1;
   if not found then return jsonb_build_object('error','not_found'); end if;
   if p_action='save_protection' then
     v_request_id=(p_data->>'request_id')::uuid;
     return public.mt5_write_protection_reason(g.id,s.user_id,p_data->>'reason','web:'||v_request_id,'web',(p_data->>'expected_updated_at')::timestamptz);
   end if;
   select coalesce(jsonb_agg(x),'[]'::jsonb) into history from (
     select pa.source,'protection'::text phase,pa.previous_reason,pa.reason,pa.recorded_at from public.mt5_protection_audit pa where pa.group_id=g.id order by pa.recorded_at desc limit 50) x;
   return jsonb_build_object('ok',true,'journal',jsonb_build_object('id',g.id,'protection_reason',g.reason,'updated_at',g.updated_at),'history',history);
 end if;
 if p_action not in ('journal','save') then return jsonb_build_object('error','invalid_input'); end if;
 select * into j from public.mt5_trade_journal where id=(p_data->>'journal_id')::uuid and account_id=s.account_id for update;
 if not found then return jsonb_build_object('error','not_found'); end if;
 if p_action='save' then
   phase=p_data->>'phase'; reason=btrim(p_data->>'reason'); v_request_id=(p_data->>'request_id')::uuid;
   if phase is null or phase not in ('opening','closing') or reason is null or char_length(reason) not between 1 and 1000 or v_request_id is null then return jsonb_build_object('error','invalid_input'); end if;
   select * into a from public.mt5_web_reason_audit where mt5_web_reason_audit.request_id=v_request_id;
   if found then
     if a.journal_id=j.id and a.phase=phase and a.reason=reason and a.actor_user_id=s.user_id then return jsonb_build_object('ok',true,'duplicate',true); end if;
     return jsonb_build_object('error','invalid_input');
   end if;
   if j.updated_at is distinct from (p_data->>'expected_updated_at')::timestamptz then return jsonb_build_object('error','conflict'); end if;
   select exists(select 1 from public.mt5_deals d where d.account_id=j.account_id and d.position_id=j.position_id and d.deal_type in ('BUY','SELL') and ((phase='opening' and d.deal_entry in ('IN','INOUT')) or (phase='closing' and d.deal_entry in ('OUT','OUT_BY','INOUT')))) into events;
   if not events then return jsonb_build_object('error','phase_unavailable'); end if;
   old_reason=case when phase='opening' then j.opening_reason else j.closing_reason end;
   update public.mt5_trade_journal set opening_reason=case when phase='opening' then reason else opening_reason end,
     closing_reason=case when phase='closing' then reason else closing_reason end,updated_at=clock_timestamp() where id=j.id returning * into j;
   insert into public.mt5_web_reason_audit(request_id,journal_id,phase,previous_reason,reason,actor_user_id) values(v_request_id,j.id,phase,old_reason,reason,s.user_id);
   return jsonb_build_object('ok',true,'updated_at',j.updated_at);
 end if;
 select coalesce(jsonb_agg(x order by x.recorded_at desc),'[]'::jsonb) into history from (
   select 'web'::text source,w.phase,w.previous_reason,w.reason,w.recorded_at from public.mt5_web_reason_audit w where w.journal_id=j.id
   union all
   select 'telegram_request',t.phase,null,t.reason,t.recorded_at from public.mt5_trade_reason_audit t where t.journal_id=j.id
   order by recorded_at desc limit 50
 ) x;
 return jsonb_build_object('ok',true,'journal',jsonb_build_object('id',j.id,'opening_reason',j.opening_reason,'closing_reason',j.closing_reason,'updated_at',j.updated_at),'history',history);
exception when invalid_text_representation or invalid_datetime_format or datetime_field_overflow then return jsonb_build_object('error','invalid_input');
end $$;
revoke all on function public.mt5_issue_dashboard_code(text,text,bigint,bigint,bigint),public.mt5_dashboard_editor(text,text,jsonb) from public,anon,authenticated;
grant execute on function public.mt5_issue_dashboard_code(text,text,bigint,bigint,bigint),public.mt5_dashboard_editor(text,text,jsonb) to service_role;

-- Author: QRT Solutions. Keep the comparison baseline monotonic on retries.
create function public.mt5_snapshot_monotonic()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.updated_at<=old.updated_at then return old; end if;
 return new;
end $$;
revoke all on function public.mt5_snapshot_monotonic() from public,anon,authenticated,service_role;
create trigger mt5_snapshot_order before update on public.mt5_accounts_snapshot for each row execute function public.mt5_snapshot_monotonic();
