-- Author: QRT Solutions. One bot per project; pairing codes are private, expiring and single-use.
create table public.mt5_telegram_pairing (
  token_sha256 text primary key check (token_sha256 ~ '^[a-f0-9]{64}$'),
  account_id text not null references public.mt5_accounts_snapshot(account_id),
  expires_at timestamptz not null,
  used_by bigint,
  used_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.mt5_telegram_pairing enable row level security;
revoke all on public.mt5_telegram_pairing from public, anon, authenticated, service_role;

create function public.mt5_claim_telegram_pairing(p_hash text, p_user_id bigint, p_chat_id bigint)
returns boolean language plpgsql security definer set search_path = '' as $$
declare pairing public.mt5_telegram_pairing;
begin
  if p_hash is null or p_hash !~ '^[a-f0-9]{64}$' or p_user_id is null
     or p_chat_id is null or p_user_id<=0 or p_user_id<>p_chat_id then return false; end if;
  perform pg_catalog.pg_advisory_xact_lock(p_user_id);
  select * into pairing from public.mt5_telegram_pairing where token_sha256=p_hash for update;
  if not found or pairing.expires_at<=now() then return false; end if;
  if pairing.used_by is not null then
    return pairing.used_by=p_user_id and exists(select 1 from public.mt5_telegram_editors
      where account_id=pairing.account_id and user_id=p_user_id and chat_id=p_chat_id and active);
  end if;
  -- A single private chat maps to one account in this version.
  if exists(select 1 from public.mt5_telegram_editors where user_id=p_user_id
    and active and account_id<>pairing.account_id) then return false; end if;
  insert into public.mt5_telegram_editors(account_id,user_id,chat_id,active)
    values(pairing.account_id,p_user_id,p_chat_id,true)
    on conflict(account_id,user_id,chat_id) do update set active=true;
  update public.mt5_telegram_pairing set used_by=p_user_id,used_at=now() where token_sha256=p_hash;
  return true;
end;
$$;
revoke all on function public.mt5_claim_telegram_pairing(text,bigint,bigint) from public,anon,authenticated;
grant execute on function public.mt5_claim_telegram_pairing(text,bigint,bigint) to service_role;

create function public.mt5_telegram_journals(p_account_id text,p_user_id bigint,p_chat_id bigint,p_reference text default null)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb;
begin
  if not exists(select 1 from public.mt5_telegram_editors e where e.account_id=p_account_id
    and e.user_id=p_user_id and e.chat_id=p_chat_id and e.active) then
    raise exception 'not_authorized' using errcode='42501';
  end if;
  if p_reference is not null and p_reference !~ '^[a-f0-9]{8}$' then
    raise exception 'invalid_reference' using errcode='22023';
  end if;
  if p_reference is not null and (select count(*) from public.mt5_trade_journal j
    where j.account_id=p_account_id and left(j.id::text,8)=p_reference)<>1 then
    raise exception 'reference_not_unique' using errcode='22023';
  end if;
  select coalesce(jsonb_agg(to_jsonb(x) order by last_time desc),'[]'::jsonb) into result from (
    select left(j.id::text,8) as reference,j.opening_reason,j.closing_reason,
      string_agg(distinct d.symbol,', ' order by d.symbol) as symbols,
      bool_or(d.deal_entry in ('IN','INOUT')) as has_opening,
      bool_or(d.deal_entry in ('OUT','OUT_BY','INOUT')) as has_closing,
      max(d.deal_time) as last_time
    from public.mt5_trade_journal j join public.mt5_deals d
      on d.account_id=j.account_id and d.position_id=j.position_id
    where j.account_id=p_account_id and (p_reference is null or left(j.id::text,8)=p_reference)
    group by j.id
    having p_reference is not null or
      (j.opening_reason is null and bool_or(d.deal_entry in ('IN','INOUT'))) or
      (j.closing_reason is null and bool_or(d.deal_entry in ('OUT','OUT_BY','INOUT')))
    order by max(d.deal_time) desc,j.id limit 20
  ) x;
  return result;
end;
$$;
revoke all on function public.mt5_telegram_journals(text,bigint,bigint,text) from public,anon,authenticated;
grant execute on function public.mt5_telegram_journals(text,bigint,bigint,text) to service_role;
comment on table public.mt5_telegram_pairing is 'QRT Solutions: private SHA-256 pairing registry; never stores the raw code.';
