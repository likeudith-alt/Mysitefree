-- Run in Supabase Dashboard -> SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.like_requests(
  id uuid primary key default gen_random_uuid(),
  request_day date not null,
  client_hash text not null,
  uid text not null,
  status text not null default 'pending' check(status in ('pending','success','failed')),
  provider_response text,
  provider_http_status integer,
  created_at timestamptz not null default now(),
  finished_at timestamptz,
  unique(request_day, client_hash)
);

create index if not exists like_requests_day_status_idx on public.like_requests(request_day, status);

alter table public.like_requests enable row level security;

create or replace function public.reserve_like_slot(p_request_day date, p_client_hash text, p_uid text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  v_id uuid;
  v_used integer;
begin
  perform pg_advisory_xact_lock(hashtext('udith-free-likes:'||p_request_day::text));
  if exists(select 1 from public.like_requests where request_day=p_request_day and client_hash=p_client_hash) then
    select count(*) into v_used from public.like_requests where request_day=p_request_day and status='success';
    return jsonb_build_object('ok',false,'reason','already_used','remaining',greatest(0,15-v_used));
  end if;
  select count(*) into v_used from public.like_requests where request_day=p_request_day and status='success';
  if v_used>=15 then
    return jsonb_build_object('ok',false,'reason','limit_reached','remaining',0);
  end if;
  insert into public.like_requests(request_day,client_hash,uid,status)
  values(p_request_day,p_client_hash,p_uid,'pending') returning id into v_id;
  return jsonb_build_object('ok',true,'request_id',v_id,'remaining',greatest(0,15-v_used));
end $$;

create or replace function public.finish_like_request(p_request_id uuid, p_success boolean, p_provider_response text, p_http_status integer)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  v_day date;
  v_used integer;
begin
  select request_day into v_day from public.like_requests where id=p_request_id;
  if v_day is null then
    return jsonb_build_object('ok',false,'reason','not_found');
  end if;
  perform pg_advisory_xact_lock(hashtext('udith-free-likes:'||v_day::text));
  update public.like_requests
  set status=case when p_success then 'success' else 'failed' end,
      provider_response=left(p_provider_response,8000),
      provider_http_status=p_http_status,
      finished_at=now()
  where id=p_request_id and status='pending';
  select count(*) into v_used from public.like_requests where request_day=v_day and status='success';
  return jsonb_build_object('ok',true,'remaining',greatest(0,15-v_used));
end $$;

revoke all on function public.reserve_like_slot(date,text,text) from public,anon,authenticated;
revoke all on function public.finish_like_request(uuid,boolean,text,integer) from public,anon,authenticated;
grant execute on function public.reserve_like_slot(date,text,text) to service_role;
grant execute on function public.finish_like_request(uuid,boolean,text,integer) to service_role;