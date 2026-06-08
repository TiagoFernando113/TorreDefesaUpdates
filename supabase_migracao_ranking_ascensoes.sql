-- ============================================================
-- Migracao: Badge de Prestigio (ascensoes) no Ranking
-- Rodar no SQL Editor do Supabase Dashboard
-- ============================================================

-- 1. Adiciona coluna ascensoes (numero de prestigios do jogador)
ALTER TABLE ranking
  ADD COLUMN IF NOT EXISTS ascensoes INT NOT NULL DEFAULT 0;

-- 2. Atualiza a RPC submit_ranking para aceitar e gravar p_ascensoes.
--    p_ascensoes tem DEFAULT 0 para manter compatibilidade com clientes
--    antigos que ainda nao enviam o campo.
CREATE OR REPLACE FUNCTION submit_ranking(
  p_nome       TEXT,
  p_senha_hash TEXT,
  p_wave       INT,
  p_score      INT,
  p_avatar_idx INT,
  p_temporada  INT,
  p_ascensoes  INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_existe     BOOL;
  v_wave_atual INT;
BEGIN
  IF p_wave <= 0 OR p_wave > 99999 THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'wave_invalida');
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM usuarios
    WHERE nome = p_nome AND senha = p_senha_hash
  ) INTO v_existe;

  IF NOT v_existe THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'credenciais_invalidas');
  END IF;

  SELECT wave INTO v_wave_atual
  FROM ranking
  WHERE nome = p_nome AND temporada = p_temporada;

  IF v_wave_atual IS NOT NULL AND p_wave <= v_wave_atual THEN
    -- Mesmo sem novo recorde de wave, mantem ascensoes atualizado.
    UPDATE ranking
      SET ascensoes = GREATEST(ascensoes, p_ascensoes)
      WHERE nome = p_nome AND temporada = p_temporada;
    RETURN jsonb_build_object('ok', false, 'erro', 'nao_e_recorde');
  END IF;

  INSERT INTO ranking (nome, wave, score, avatar_idx, temporada, ascensoes)
  VALUES (p_nome, p_wave, p_score, p_avatar_idx, p_temporada, p_ascensoes)
  ON CONFLICT (nome, temporada) DO UPDATE
    SET wave       = EXCLUDED.wave,
        score      = EXCLUDED.score,
        avatar_idx = EXCLUDED.avatar_idx,
        ascensoes  = EXCLUDED.ascensoes;

  RETURN jsonb_build_object('ok', true);
END;
$$;

-- 3. Verificacao
SELECT nome, wave, score, avatar_idx, ascensoes, temporada
FROM ranking
WHERE temporada = 0
ORDER BY wave DESC
LIMIT 10;
