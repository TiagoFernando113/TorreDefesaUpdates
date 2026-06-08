-- ============================================================
-- Migração: Ranking Universal com Temporadas
-- Rodar no SQL Editor do Supabase Dashboard
-- ============================================================

-- 1. Adiciona coluna temporada (0 = Temporada 1, iniciada 2026-05-10)
ALTER TABLE ranking
  ADD COLUMN IF NOT EXISTS temporada INT NOT NULL DEFAULT 0;

-- 2. Remove coluna dificuldade (não usada no novo sistema)
--    ATENÇÃO: só rode essa linha depois de confirmar que o jogo
--    está funcionando com o novo código. Enquanto isso, a coluna
--    fica sem uso mas não causa erro.
-- ALTER TABLE ranking DROP COLUMN IF EXISTS dificuldade;

-- 3. Remove entradas duplicadas do mesmo jogador na mesma temporada
--    (mantém apenas o melhor wave por nome+temporada)
DELETE FROM ranking a
USING ranking b
WHERE a.id > b.id
  AND a.nome = b.nome
  AND a.temporada = b.temporada;

-- 4. Constraint única: 1 entrada por jogador por temporada
ALTER TABLE ranking
  DROP CONSTRAINT IF EXISTS ranking_nome_temporada_key;

ALTER TABLE ranking
  ADD CONSTRAINT ranking_nome_temporada_key
  UNIQUE (nome, temporada);

-- 5. Índice para busca rápida por temporada + wave
DROP INDEX IF EXISTS idx_ranking_temporada_wave;
CREATE INDEX idx_ranking_temporada_wave
  ON ranking (temporada, wave DESC);

-- 6. Remove entradas antigas de dificuldades separadas que
--    duplicam o mesmo jogador (mantém só o melhor global)
--    Execute só se tiver entradas duplicadas do old system.
-- DELETE FROM ranking WHERE temporada = 0 AND dificuldade IS NOT NULL;

-- 7. Verificação: top 10 da temporada atual
SELECT nome, wave, score, avatar_idx, temporada
FROM ranking
WHERE temporada = 0
ORDER BY wave DESC
LIMIT 10;
