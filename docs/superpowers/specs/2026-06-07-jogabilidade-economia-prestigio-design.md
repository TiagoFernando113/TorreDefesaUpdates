# Cyron Defense — Jogabilidade, Economia & Prestígio

**Data:** 2026-06-07
**Status:** aprovado (iterativo, em implementação)

## Problemas

1. **Waves repetitivas** — falta variedade percebida ao longo da partida.
2. **Economia quebrada** — banco de ouro é pool único que cresce a cada partida; veterano acumula e desbloqueia todo conteúdo novo na hora, sem dreno de fim-de-jogo.

Critérios do usuário para a economia: **não afetar jogador novo**, **fazer veterano gastar o excesso**, **balancear o ganho** futuro.

## Solução

### 1. Prestígio real (ascensão) — dreno principal

Hoje `ascender()` só limpa `talentos` e desconta custo. Vira reset de prestígio.

**Wipe (zera):**
- `ouro_banco` → 0
- `talentos` → vazio (já hoje)
- `melhorias` (loja: forca/resistencia/visao/cadencia/fortuna) → 0

**Mantém:**
- `cristais` (premium) — gasta o custo de cristais como gate
- `skins_desbloqueadas` (identidade)
- High scores + totais (estatísticas/bragging)
- `baus_estoque` (conquistados — menos punitivo no início)
- consumíveis (orbe/cristal/runa/revive) — itens conquistados/premium
- `atributos_conta` + `nivel_conta` + `xp_conta` — "nível de experiência" permanente do jogador
- `ascensoes` (++) e bônus permanente escalonado via `bonus_ascensao_stats()`

**Regra de ouro:** bônus de ascensão compensa o wipe + um pouco mais (infra já existe — dano/vida/cadência/ouro/cristais/desconto-talentos por nível).

**Gate:** `todos_talentos_liberados()` + `cristais >= ascensao_custo_cristais()`. Custo de ouro deixa de ser exigido (ouro é zerado de qualquer forma) — evita confusão.

**UI:** telegrafar forte — "Ascender ZERA seu ouro e a árvore. Gaste o ouro antes!" Direcionar gasto pré-ascensão para atributos de conta e baús (persistem).

### 2. Soft-cap de renda — segura acúmulo entre ascensões

Aplica no **ganho** da partida = `gold_final - ouro_inicio` (`arena_ouro_inicio`).

- Abaixo do threshold `T` (saldo do banco): ganho 100%. **Novo jogador nunca é afetado.**
- Acima de `T`: `fator = clamp(T / saldo, FATOR_MIN, 1.0)`. Quanto mais rico, menos % converte.
- `ouro_banco = ouro_inicio + round(ganho * fator)`.

Valores iniciais: `T = 200000`, `FATOR_MIN = 0.25`. Ajustáveis.

### 3. Badge de prestígio no ranking

Símbolo + número de ascensões ao lado do nome.

- Migration Supabase: coluna `ascensoes int default 0` na tabela de ranking.
- Enviar `ascensoes` no insert/upsert de score.
- Buscar `ascensoes` no `select` do ranking.
- UI da lista: desenhar símbolo (imagem fornecida pelo usuário) + "x{N}" ao lado do nome. Fallback textual enquanto a imagem não existe.

### 4. Variedade de waves (eventos) — fase 2

Estender `wave_mod_atual` com eventos ocasionais (névoa/alcance reduzido, wave-relâmpago, mini-boss intermediário, etc.). Reaproveita infra existente. Implementar após economia validada.

## Arquivos

- `scripts/salvar.gd` — `ascender()`, `pode_ascender()`, novo `ajustar_ganho_ouro()`, constantes soft-cap.
- `scripts/main.gd` — aplicar soft-cap em `_finalizar_game_over()` / `sair_da_partida()`.
- `scripts/ranking_online.gd` — enviar/buscar `ascensoes`.
- UI ranking — render do badge.
- Migration SQL — coluna `ascensoes`.

## Ordem

1. Prestígio reset (salvar.gd)
2. Soft-cap renda (salvar.gd + main.gd)
3. Badge plumbing (sql + ranking_online + ui)
4. Eventos de wave (fase 2)
