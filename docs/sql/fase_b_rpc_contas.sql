-- =====================================================================
-- Fase B — RPCs "porteiro" para a tabela `usuarios`
-- =====================================================================
-- Objetivo: parar de mexer DIRETO na tabela usuarios (que hoje deixa o
-- anon ler a coluna `senha` de todos). Estas funcoes checam a senha e
-- NUNCA devolvem a coluna `senha`.
--
-- SEGURANCA: ADITIVO. O cliente atual continua usando o caminho antigo;
-- estas funcoes so passam a ser usadas depois do refactor do cliente.
-- Aplicar isto NAO quebra nenhum jogador. Reverter = DROP FUNCTION.
--
-- Ordem de lockdown (NAO pular):
--   1. Aplicar estas RPCs (este arquivo) — seguro agora.
--   2. Refatorar cliente (contas.gd / ranking_online.gd) p/ usar as RPCs.
--   3. Lancar update (PC + Android) e esperar propagar.
--   4. SO ENTAO fechar o RLS / revogar SELECT(senha) do anon.
-- =====================================================================

-- 1) Cadastro de conta nova
create or replace function public.cadastrar_usuario(
	p_nome text, p_email text, p_senha_hash text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_nome  text := left(btrim(p_nome), 20);
	v_email text := nullif(left(btrim(coalesce(p_email, '')), 100), '');
	v_row   public.usuarios%rowtype;
begin
	if v_nome = '' or coalesce(p_senha_hash, '') = '' then
		raise exception 'dados_invalidos';
	end if;
	if exists (select 1 from public.usuarios where nome = v_nome) then
		raise exception 'nome_em_uso';
	end if;
	insert into public.usuarios(nome, email, senha)
	values (v_nome, v_email, p_senha_hash)
	returning * into v_row;
	return jsonb_build_object(
		'nome', v_row.nome, 'email', v_row.email,
		'player_id', v_row.player_id, 'id_sequencial', v_row.id_sequencial
	);
end;
$$;

-- 2) Login por nome OU email + senha
create or replace function public.login_usuario(
	p_identificador text, p_senha_hash text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_id  text := btrim(p_identificador);
	v_row public.usuarios%rowtype;
begin
	if v_id = '' or coalesce(p_senha_hash, '') = '' then
		return null;
	end if;
	select * into v_row from public.usuarios
	where (nome = v_id or email = v_id) and senha = p_senha_hash
	limit 1;
	if not found then
		return null;
	end if;
	return jsonb_build_object(
		'nome', v_row.nome, 'email', v_row.email,
		'player_id', v_row.player_id, 'id_sequencial', v_row.id_sequencial
	);
end;
$$;

-- 3) Login/sync por player_id + senha (corrige divergencia multi-dispositivo)
create or replace function public.login_por_player_id(
	p_player_id uuid, p_senha_hash text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_row public.usuarios%rowtype;
begin
	if p_player_id is null or coalesce(p_senha_hash, '') = '' then
		return null;
	end if;
	select * into v_row from public.usuarios
	where player_id = p_player_id and senha = p_senha_hash
	limit 1;
	if not found then
		return null;
	end if;
	return jsonb_build_object(
		'nome', v_row.nome, 'email', v_row.email,
		'player_id', v_row.player_id, 'id_sequencial', v_row.id_sequencial
	);
end;
$$;

-- 4) Busca nome por email (fluxo Google). Retorna SO o nome, nunca a senha.
create or replace function public.buscar_nome_por_email(
	p_email text
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare v_nome text;
begin
	if coalesce(btrim(p_email), '') = '' then
		return null;
	end if;
	select nome into v_nome from public.usuarios
	where email = btrim(p_email) limit 1;
	return v_nome;
end;
$$;

grant execute on function public.cadastrar_usuario(text, text, text)   to anon, authenticated;
grant execute on function public.login_usuario(text, text)             to anon, authenticated;
grant execute on function public.login_por_player_id(uuid, text)       to anon, authenticated;
grant execute on function public.buscar_nome_por_email(text)           to anon, authenticated;
