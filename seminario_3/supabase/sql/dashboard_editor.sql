-- Author: QRT Solutions. Human journal reasons only; no trading privileges.
create table public.mt5_dashboard_web_config (
  singleton boolean primary key default true check(singleton),
  origin text not null check(origin ~ '^https://[a-zA-Z0-9.-]+$'),
  bot_username text not null check(bot_username ~ '^[a-zA-Z0-9_]{5,32}$')
);
create table public.mt5_dashboard_login_codes (
  hash text primary key check(hash ~ '^[a-f0-9]{64}$'),
  account_id text not null references public.mt5_accounts_snapshot(account_id),
  user_id bigint not null, chat_id bigint not null,
  telegram_update_id bigint unique not null,
  expires_at timestamptz not null default now()+interval '5 minutes',
  consumed_at timestamptz
);
create table public.mt5_dashboard_sessions (
  hash text primary key check(hash ~ '^[a-f0-9]{64}$'),
  account_id text not null references public.mt5_accounts_snapshot(account_id),
  user_id bigint not null, chat_id bigint not null,
  expires_at timestamptz not null default now()+interval '1 hour',
  revoked_at timestamptz
);
create table public.mt5_web_reason_audit (
  request_id uuid primary key,
  journal_id uuid not null references public.mt5_trade_journal(id),
  phase text not null check(phase in ('opening','closing')),
  previous_reason text, reason text not null check(char_length(reason) between 1 and 1000),
  actor_user_id bigint not null, recorded_at timestamptz not null default clock_timestamp()
);
create index mt5_web_reason_history on public.mt5_web_reason_audit(journal_id,recorded_at desc);
alter table public.mt5_dashboard_web_config enable row level security;
alter table public.mt5_dashboard_login_codes enable row level security;
alter table public.mt5_dashboard_sessions enable row level security;
alter table public.mt5_web_reason_audit enable row level security;
revoke all on public.mt5_dashboard_web_config,public.mt5_dashboard_login_codes,public.mt5_dashboard_sessions,public.mt5_web_reason_audit from public,anon,authenticated,service_role;
grant select on public.mt5_dashboard_web_config to service_role;

create function public.mt5_issue_dashboard_code(p_hash text,p_account text,p_user bigint,p_chat bigint,p_update bigint)
returns jsonb language plpgsql security definer set search_path='' as $$
declare c public.mt5_dashboard_login_codes;
begin
 if p_hash is null or p_hash !~ '^[a-f0-9]{64}$' or p_update is null or p_update<0 then raise exception 'invalid_input' using errcode='22023'; end if;
 perform 1 from public.mt5_telegram_editors where account_id=p_account and user_id=p_user and chat_id=p_chat and active for share;
 if not found then raise exception 'unauthorized' using errcode='42501'; end if;
 perform pg_catalog.pg_advisory_xact_lock(p_user);
 select * into c from public.mt5_dashboard_login_codes where telegram_update_id=p_update;
 if found then
   if c.hash<>p_hash or c.account_id<>p_account or c.user_id<>p_user or c.chat_id<>p_chat then raise exception 'invalid_input' using errcode='22023'; end if;
   return jsonb_build_object('valid',c.expires_at>now() and c.consumed_at is null,'expires_at',c.expires_at);
 end if;
 -- New command supersedes older unused codes; repeated webhook delivery is idempotent.
 update public.mt5_dashboard_login_codes set consumed_at=now() where user_id=p_user and consumed_at is null;
 insert into public.mt5_dashboard_login_codes(hash,account_id,user_id,chat_id,telegram_update_id)
 values(p_hash,p_account,p_user,p_chat,p_update) returning * into c;
 return jsonb_build_object('valid',true,'expires_at',c.expires_at);
end $$;

create function public.mt5_dashboard_editor(p_action text,p_hash text,p_data jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare c public.mt5_dashboard_login_codes; s public.mt5_dashboard_sessions;
 j public.mt5_trade_journal; a public.mt5_web_reason_audit;
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
