-- ============================================================
-- Premio automatico por entrada no Discord - Cyron Defense
-- Rodar no SQL Editor do Supabase Dashboard.
-- ============================================================

create extension if not exists pgcrypto;

alter table usuarios
add column if not exists discord_id text unique;

create table if not exists discord_join_invite_requests (
  id uuid primary key default gen_random_uuid(),
  player_id text not null,
  nome text not null,
  invite_code text unique,
  invite_url text,
  discord_id text,
  status text not null default 'pending'
    check (status in ('pending', 'ready', 'claimed', 'failed', 'expired')),
  error text,
  requested_at timestamptz not null default now(),
  ready_at timestamptz,
  claimed_at timestamptz,
  expires_at timestamptz not null default (now() + interval '30 minutes'),
  updated_at timestamptz not null default now()
);

create index if not exists idx_discord_join_invite_requests_status
  on discord_join_invite_requests (status, expires_at);

create index if not exists idx_discord_join_invite_requests_player
  on discord_join_invite_requests (player_id, requested_at desc);

create table if not exists discord_join_reward_claims (
  id uuid primary key default gen_random_uuid(),
  player_id text not null unique,
  discord_id text not null unique,
  invite_request_id uuid references discord_join_invite_requests(id),
  claimed_at timestamptz not null default now()
);

create table if not exists pending_rewards (
  id uuid primary key default gen_random_uuid(),
  player_id text not null,
  discord_id text,
  nome text,
  reward_type text not null check (reward_type in ('ouro', 'cristais', 'orbe', 'barreira', 'runa', 'bau_lendario')),
  amount int not null check (amount > 0),
  source text not null default 'bot',
  claimed boolean not null default false,
  created_at timestamptz not null default now(),
  claimed_at timestamptz
);

alter table pending_rewards
add column if not exists discord_id text;

alter table pending_rewards
add column if not exists nome text;

alter table pending_rewards
add column if not exists source text not null default 'bot';

alter table pending_rewards
add column if not exists claimed boolean not null default false;

alter table pending_rewards
add column if not exists created_at timestamptz not null default now();

alter table pending_rewards
add column if not exists claimed_at timestamptz;

alter table pending_rewards
alter column player_id type text using player_id::text;

create index if not exists idx_pending_rewards_player_claimed
  on pending_rewards (player_id, claimed, created_at);

alter table pending_rewards
drop constraint if exists pending_rewards_reward_type_check;

alter table pending_rewards
add constraint pending_rewards_reward_type_check
check (reward_type in ('ouro', 'cristais', 'orbe', 'barreira', 'runa', 'bau_lendario'));

alter table discord_join_invite_requests enable row level security;
alter table discord_join_reward_claims enable row level security;
alter table pending_rewards enable row level security;

create or replace function request_discord_join_invite(
  p_player_id text,
  p_nome text,
  p_senha_hash text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player record;
  v_existing record;
  v_request_id uuid;
begin
  select *
    into v_player
    from usuarios
   where (
     (coalesce(p_player_id, '') <> '' and player_id::text = p_player_id)
     or (nome = p_nome and senha = p_senha_hash)
   )
   limit 1;

  if not found then
    return json_build_object('ok', false, 'erro', 'Entre na sua conta para receber o premio do Discord.');
  end if;

  if exists (select 1 from discord_join_reward_claims where player_id = v_player.player_id::text) then
    return json_build_object('ok', false, 'erro', 'Premio do Discord ja resgatado nessa conta.');
  end if;

  select *
    into v_existing
    from discord_join_invite_requests
   where player_id = v_player.player_id::text
     and status in ('pending', 'ready')
     and expires_at > now()
   order by requested_at desc
   limit 1;

  if found then
    return json_build_object(
      'ok', true,
      'request_id', v_existing.id,
      'status', v_existing.status,
      'invite_url', coalesce(v_existing.invite_url, '')
    );
  end if;

  insert into discord_join_invite_requests (player_id, nome)
  values (v_player.player_id::text, v_player.nome)
  returning id into v_request_id;

  return json_build_object('ok', true, 'request_id', v_request_id, 'status', 'pending', 'invite_url', '');
end;
$$;

create or replace function get_discord_join_invite_status(
  p_request_id uuid
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request record;
begin
  select *
    into v_request
    from discord_join_invite_requests
   where id = p_request_id
   limit 1;

  if not found then
    return json_build_object('ok', false, 'erro', 'Pedido de convite nao encontrado.');
  end if;

  if v_request.expires_at <= now() and v_request.status in ('pending', 'ready') then
    update discord_join_invite_requests
       set status = 'expired', updated_at = now()
     where id = v_request.id;
    return json_build_object('ok', false, 'erro', 'Convite expirado. Tente novamente.');
  end if;

  return json_build_object(
    'ok', true,
    'request_id', v_request.id,
    'status', v_request.status,
    'invite_url', coalesce(v_request.invite_url, ''),
    'erro', coalesce(v_request.error, '')
  );
end;
$$;

create or replace function claim_discord_join_reward(
  p_invite_code text,
  p_discord_id text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request record;
  v_rewards json;
begin
  select *
    into v_request
    from discord_join_invite_requests
   where invite_code = p_invite_code
     and status = 'ready'
     and expires_at > now()
   limit 1;

  if not found then
    return json_build_object('ok', false, 'erro', 'convite_sem_premio');
  end if;

  if exists (select 1 from discord_join_reward_claims where player_id = v_request.player_id) then
    return json_build_object('ok', false, 'erro', 'conta_ja_resgatou');
  end if;

  if exists (select 1 from discord_join_reward_claims where discord_id = p_discord_id) then
    return json_build_object('ok', false, 'erro', 'discord_ja_resgatou');
  end if;

  insert into discord_join_reward_claims (player_id, discord_id, invite_request_id)
  values (v_request.player_id, p_discord_id, v_request.id);

  update usuarios
     set discord_id = p_discord_id
   where player_id::text = v_request.player_id;

  insert into pending_rewards (player_id, discord_id, nome, reward_type, amount, source)
  values
    (v_request.player_id, p_discord_id, v_request.nome, 'cristais', 25, 'discord_join'),
    (v_request.player_id, p_discord_id, v_request.nome, 'orbe', 1, 'discord_join'),
    (v_request.player_id, p_discord_id, v_request.nome, 'bau_lendario', 2, 'discord_join');

  update discord_join_invite_requests
     set status = 'claimed',
         discord_id = p_discord_id,
         claimed_at = now(),
         updated_at = now()
   where id = v_request.id;

  select json_agg(json_build_object('reward_type', reward_type, 'amount', amount))
    into v_rewards
    from pending_rewards
   where player_id::text = v_request.player_id
     and claimed = false
     and source = 'discord_join';

  return json_build_object('ok', true, 'rewards', coalesce(v_rewards, '[]'::json));
end;
$$;

create or replace function claim_discord_join_reward_by_request(
  p_request_id uuid,
  p_player_id text,
  p_nome text,
  p_senha_hash text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player record;
  v_request record;
  v_discord_id text;
  v_rewards json;
begin
  select *
    into v_player
    from usuarios
   where (
     coalesce(p_player_id, '') <> ''
     and player_id::text = p_player_id
     and nome = p_nome
     and senha = p_senha_hash
   )
   or (
     coalesce(p_player_id, '') = ''
     and nome = p_nome
     and senha = p_senha_hash
   )
   limit 1;

  if not found then
    return json_build_object('ok', false, 'erro', 'credenciais_invalidas', 'rewards', '[]'::json);
  end if;

  if exists (select 1 from discord_join_reward_claims where player_id = v_player.player_id::text) then
    return json_build_object('ok', true, 'status', 'ja_resgatado', 'rewards', '[]'::json);
  end if;

  select *
    into v_request
    from discord_join_invite_requests
   where id = p_request_id
     and player_id = v_player.player_id::text
     and status in ('pending', 'ready')
     and expires_at > now()
   limit 1;

  if not found then
    return json_build_object('ok', false, 'erro', 'pedido_invalido_ou_expirado', 'rewards', '[]'::json);
  end if;

  v_discord_id := 'opened:' || v_player.player_id::text;

  insert into discord_join_reward_claims (player_id, discord_id, invite_request_id)
  values (v_player.player_id::text, v_discord_id, v_request.id);

  insert into pending_rewards (player_id, discord_id, nome, reward_type, amount, source)
  values
    (v_player.player_id::text, v_discord_id, v_player.nome, 'cristais', 25, 'discord_join'),
    (v_player.player_id::text, v_discord_id, v_player.nome, 'orbe', 1, 'discord_join'),
    (v_player.player_id::text, v_discord_id, v_player.nome, 'bau_lendario', 2, 'discord_join');

  update discord_join_invite_requests
     set status = 'claimed',
         discord_id = v_discord_id,
         claimed_at = now(),
         updated_at = now()
   where id = v_request.id;

  select json_agg(json_build_object('reward_type', reward_type, 'amount', amount))
    into v_rewards
    from pending_rewards
   where player_id::text = v_player.player_id::text
     and claimed = false
     and source = 'discord_join';

  return json_build_object('ok', true, 'status', 'claimed', 'rewards', coalesce(v_rewards, '[]'::json));
end;
$$;

create or replace function claim_pending_rewards(
  p_player_id text,
  p_nome text,
  p_senha_hash text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player record;
  v_rewards json;
begin
  select *
    into v_player
    from usuarios
   where (
     coalesce(p_player_id, '') <> ''
     and player_id::text = p_player_id
     and nome = p_nome
     and senha = p_senha_hash
   )
   or (
     coalesce(p_player_id, '') = ''
     and nome = p_nome
     and senha = p_senha_hash
   )
   limit 1;

  if not found then
    return json_build_object('ok', false, 'erro', 'credenciais_invalidas', 'rewards', '[]'::json);
  end if;

  select json_agg(json_build_object('reward_type', reward_type, 'amount', amount))
    into v_rewards
    from pending_rewards
   where player_id::text = v_player.player_id::text
     and claimed = false;

  update pending_rewards
     set claimed = true, claimed_at = now()
   where player_id::text = v_player.player_id::text
     and claimed = false;

  return json_build_object('ok', true, 'rewards', coalesce(v_rewards, '[]'::json));
end;
$$;

revoke all on table discord_join_invite_requests from anon, authenticated, public;
revoke all on table discord_join_reward_claims from anon, authenticated, public;
revoke all on table pending_rewards from anon, authenticated, public;
grant all on table discord_join_invite_requests to service_role;
grant all on table discord_join_reward_claims to service_role;
grant all on table pending_rewards to service_role;

revoke execute on function claim_discord_join_reward(text, text) from anon, authenticated, public;
grant execute on function claim_discord_join_reward(text, text) to service_role;

revoke execute on function request_discord_join_invite(text, text, text) from public;
revoke execute on function get_discord_join_invite_status(uuid) from public;
revoke execute on function claim_discord_join_reward_by_request(uuid, text, text, text) from public;
revoke execute on function claim_pending_rewards(text, text, text) from public;
grant execute on function request_discord_join_invite(text, text, text) to anon, authenticated;
grant execute on function get_discord_join_invite_status(uuid) to anon, authenticated;
grant execute on function claim_discord_join_reward_by_request(uuid, text, text, text) to anon, authenticated;
grant execute on function claim_pending_rewards(text, text, text) to anon, authenticated;

