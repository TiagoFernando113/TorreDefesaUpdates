-- ============================================================
-- Segurança do Ranking — Cyron Defense
-- Rodar no SQL Editor do Supabase Dashboard
-- ============================================================

-- ── 1. RLS: bloqueia escrita direta na tabela ranking ────────────────────────
-- Qualquer um pode LER (placar público), mas ninguém pode
-- escrever diretamente — só via RPC autenticada abaixo.

ALTER TABLE ranking ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ranking_select  ON ranking;
DROP POLICY IF EXISTS ranking_insert  ON ranking;
DROP POLICY IF EXISTS ranking_update  ON ranking;
DROP POLICY IF EXISTS ranking_delete  ON ranking;

-- Leitura pública
CREATE POLICY ranking_select ON ranking
  FOR SELECT USING (true);

-- Escrita bloqueada para anon/authenticated direto
CREATE POLICY ranking_insert ON ranking
  FOR INSERT WITH CHECK (false);

CREATE POLICY ranking_update ON ranking
  FOR UPDATE USING (false);

CREATE POLICY ranking_delete ON ranking
  FOR DELETE USING (false);


-- ── 2. RPC: submit_ranking ───────────────────────────────────────────────────
-- Valida credenciais e faz upsert só se wave > recorde atual.
-- SECURITY DEFINER = executa com permissão do dono (bypass RLS controlado).

CREATE OR REPLACE FUNCTION submit_ranking(
  p_nome       TEXT,
  p_senha_hash TEXT,
  p_wave       INT,
  p_score      INT,
  p_avatar_idx INT,
  p_temporada  INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_existe     BOOL;
  v_wave_atual INT;
BEGIN
  -- Validação básica de range
  IF p_wave <= 0 OR p_wave > 99999 THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'wave_invalida');
  END IF;

  -- Verifica credenciais na tabela usuarios
  SELECT EXISTS (
    SELECT 1 FROM usuarios
    WHERE nome = p_nome AND senha = p_senha_hash
  ) INTO v_existe;

  IF NOT v_existe THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'credenciais_invalidas');
  END IF;

  -- Busca recorde atual dessa temporada
  SELECT wave INTO v_wave_atual
  FROM ranking
  WHERE nome = p_nome AND temporada = p_temporada;

  -- Só aceita se for novo recorde (ou primeira entrada)
  IF v_wave_atual IS NOT NULL AND p_wave <= v_wave_atual THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'nao_e_recorde');
  END IF;

  -- Upsert seguro
  INSERT INTO ranking (nome, wave, score, avatar_idx, temporada)
  VALUES (p_nome, p_wave, p_score, p_avatar_idx, p_temporada)
  ON CONFLICT (nome, temporada) DO UPDATE
    SET wave       = EXCLUDED.wave,
        score      = EXCLUDED.score,
        avatar_idx = EXCLUDED.avatar_idx;

  RETURN jsonb_build_object('ok', true);
END;
$$;


-- ── 3. RPC: remove_ranking_entry (para rename/reset) ────────────────────────
-- Deleta a entrada do ranking só se a senha bater.

CREATE OR REPLACE FUNCTION remove_ranking_entry(
  p_nome       TEXT,
  p_senha_hash TEXT,
  p_temporada  INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_existe BOOL;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM usuarios
    WHERE nome = p_nome AND senha = p_senha_hash
  ) INTO v_existe;

  IF NOT v_existe THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'credenciais_invalidas');
  END IF;

  DELETE FROM ranking
  WHERE nome = p_nome AND temporada = p_temporada;

  RETURN jsonb_build_object('ok', true);
END;
$$;


-- ── 4. Verificação final ─────────────────────────────────────────────────────
-- Confirma que RLS está ativo
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'ranking';
