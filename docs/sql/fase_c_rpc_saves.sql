-- =====================================================================
-- Fase C — RPCs "porteiro" para a tabela `saves`
-- =====================================================================
-- Hoje upload/download/delete de save NAO conferem senha (so nome/player_id).
-- Estas RPCs exigem (nome + senha_hash) validos antes de ler/escrever, e
-- derivam o player_id do servidor (nunca confiam no client).
--
-- saves: PK = nome ; player_id UNIQUE. Cada usuario tem player_id (default).
-- Upsert chaveia por player_id (sobrevive a rename); fallback por nome.
--
-- ADITIVO: o cliente atual continua no caminho velho. Aplicar nao quebra nada.
-- =====================================================================

-- Helper interno: valida credencial e devolve (player_id, nome). Lanca excecao
-- 'credencial_invalida' se nao casar. SECURITY DEFINER.
create or replace function public._auth_usuario(
	p_nome text, p_senha_hash text
) returns public.usuarios
language plpgsql
security definer
set search_path = public
as $$
declare v_row public.usuarios%rowtype;
begin
	select * into v_row from public.usuarios
	where nome = left(btrim(p_nome), 20) and senha = p_senha_hash
	limit 1;
	if not found then
		raise exception 'credencial_invalida';
	end if;
	return v_row;
end;
$$;

-- 1) Upload (upsert) do save do proprio jogador
create or replace function public.upload_save(
	p_nome text, p_senha_hash text, p_data jsonb
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_u public.usuarios%rowtype;
begin
	v_u := public._auth_usuario(p_nome, p_senha_hash);
	update public.saves
	   set data = p_data, nome = v_u.nome, atualizado_em = now()
	 where player_id = v_u.player_id;
	if not found then
		-- limpa linha velha com mesmo nome mas outro player_id (save legado)
		delete from public.saves
		 where nome = v_u.nome and player_id is distinct from v_u.player_id;
		insert into public.saves(nome, data, player_id, atualizado_em)
		values (v_u.nome, p_data, v_u.player_id, now());
	end if;
end;
$$;

-- 2) Download do save do proprio jogador. Retorna {data, force_sync} ou null.
create or replace function public.download_save(
	p_nome text, p_senha_hash text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare v_u public.usuarios%rowtype; v_s public.saves%rowtype;
begin
	v_u := public._auth_usuario(p_nome, p_senha_hash);
	select * into v_s from public.saves where player_id = v_u.player_id limit 1;
	if not found then
		select * into v_s from public.saves where nome = v_u.nome limit 1;
	end if;
	if not found then
		return null;
	end if;
	return jsonb_build_object('data', v_s.data, 'force_sync', coalesce(v_s.force_sync, false));
end;
$$;

-- 3) Apaga o save do proprio jogador (reset total da conta)
create or replace function public.apagar_save(
	p_nome text, p_senha_hash text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_u public.usuarios%rowtype;
begin
	v_u := public._auth_usuario(p_nome, p_senha_hash);
	delete from public.saves where player_id = v_u.player_id or nome = v_u.nome;
end;
$$;

-- 4) Limpa saves orfaos do proprio jogador (sobras de rename)
create or replace function public.limpar_saves_orfaos(
	p_nome text, p_senha_hash text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_u public.usuarios%rowtype;
begin
	v_u := public._auth_usuario(p_nome, p_senha_hash);
	delete from public.saves where player_id = v_u.player_id and nome <> v_u.nome;
end;
$$;

-- _auth_usuario e helper interno: NAO exposto ao anon.
revoke all on function public._auth_usuario(text, text) from public, anon, authenticated;
grant execute on function public.upload_save(text, text, jsonb)     to anon, authenticated;
grant execute on function public.download_save(text, text)          to anon, authenticated;
grant execute on function public.apagar_save(text, text)            to anon, authenticated;
grant execute on function public.limpar_saves_orfaos(text, text)    to anon, authenticated;
