alter table usuarios
add column if not exists discord_id text unique;

create or replace function confirm_discord_link(
  p_code text,
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
  v_link record;
  v_player record;
begin
  select *
    into v_link
    from discord_link_codes
   where code = upper(trim(p_code))
     and used = false
     and expires_at > now()
   limit 1;

  if not found then
    return json_build_object('ok', false, 'erro', 'Codigo expirado ou invalido.');
  end if;

  select *
    into v_player
    from usuarios
   where (
     (coalesce(p_player_id, '') <> '' and player_id::text = p_player_id)
     or (nome = p_nome and senha = p_senha_hash)
   )
   limit 1;

  if not found then
    return json_build_object('ok', false, 'erro', 'Conta do jogo nao encontrada.');
  end if;

  update usuarios
     set discord_id = v_link.discord_id
   where id = v_player.id;

  update discord_link_codes
     set used = true
   where id = v_link.id;

  return json_build_object('ok', true, 'erro', '');
end;
$$;

grant execute on function confirm_discord_link(text, text, text, text) to anon, authenticated;
