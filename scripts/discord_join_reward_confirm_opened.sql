-- ============================================================
-- Correcao do premio Discord para contas que ja estao no servidor.
-- Rode este SQL no Supabase depois do setup principal.
-- ============================================================

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

alter table pending_rewards
drop constraint if exists pending_rewards_reward_type_check;

alter table pending_rewards
add constraint pending_rewards_reward_type_check
check (reward_type in ('ouro', 'cristais', 'orbe', 'barreira', 'runa', 'bau_lendario'));

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

revoke execute on function claim_discord_join_reward(text, text) from anon, authenticated, public;
grant execute on function claim_discord_join_reward(text, text) to service_role;

revoke execute on function claim_discord_join_reward_by_request(uuid, text, text, text) from public;
grant execute on function claim_discord_join_reward_by_request(uuid, text, text, text) to anon, authenticated;

revoke execute on function claim_pending_rewards(text, text, text) from public;
grant execute on function claim_pending_rewards(text, text, text) to anon, authenticated;

