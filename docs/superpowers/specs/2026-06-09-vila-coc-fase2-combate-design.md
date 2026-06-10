# Vila CoC — Fase 2: Combate / Defesa contra Naves (Design)

Data: 2026-06-09
Status: Aprovado (decisões do usuário)

## Objetivo
Naves atacam a vila, defesas atiram automaticamente com stats reais por tipo,
tropas treinadas defendem. Ataque **ligado às waves do jogo principal**.

## Decisões do usuário
1. Ataque ligado às waves: cada wave concluída no tower defense principal
   acumula "poder de invasão". Ao abrir a vila, jogador pode DEFENDER.
2. Defesas com stats reais por tipo (coc_dados.gd): dps, range, alvo, splash, oculta.

## Quem acerta naves (aéreas)
- Acertam (alvo aereo/todos): torre_arqueiros, def_aerea, torre_mago(splash), tesla(oculta).
- Erram (só terrestre): canhao, morteiro, xbow.
→ Jogador precisa construir defesa antiaérea. Fiel ao CoC.

## Fluxo
1. `on_fim_wave(wave)` (chamado por main.gd) → `CocSalvar.raid_pendente += 1 + wave/3`. Salva.
2. `abrir()` → se `raid_pendente > 0`, botão "⚠ DEFENDER (N)" no rodapé.
3. Clique DEFENDER → `_iniciar_raid()`:
   - nº naves = clamp(raid_pendente, 3, 30); hp/dano escalam com wave média.
   - `raid_pendente = 0`; salva; `_state = RAID`.
4. `_process` (RAID): tick combate.
5. Fim: todas naves mortas = VITÓRIA; prefeitura destruída ou timer(90s) = DERROTA
   (perde % de recursos). Estado de HP dos prédios persiste.

## Combate (transiente, em mini_cidade.gd — não persiste durante o tick)
- **Naves**: {px,py,hp,hp_max,alvo_key,atk_cd,dano,vel,dead}. Aéreas.
  Voam de fora em direção ao prédio-alvo (prefere prefeitura/defesas).
  Ao alcance do alvo, dano/s no prédio. Prédio com hp 0 → removido/desativado.
- **Defesas**: cada prédio com `dps` e `alvo ∈ {aereo,todos}` mira a nave mais
  próxima no `range`, cooldown 1s, aplica dps. `splash` atinge naves vizinhas.
  `oculta` (tesla): só ativa quando nave entra no range.
- **Tropas**: `CocSalvar.tropas` viram defensores perto da prefeitura; cada um
  atira na nave mais próxima com `dano_s`. (v1: invulneráveis.)
- **Visual**: linhas de tiro defesa→nave, projéteis, explosões, barras de HP.

## Persistência
- Novo campo `CocSalvar.raid_pendente: int` (salvar/carregar).
- HP dos prédios danificados salvo ao fim do raid (reparar custa ouro, já existe).

## Fora de escopo (v1)
- Tropas morrerem, pathfinding A*, naves variadas com habilidades distintas
  (v1: 1 tipo de nave escalável). Refinar depois.

## Verificação
- Jogar wave no principal → abrir vila → botão DEFENDER aparece.
- Sem def antiaérea → naves destroem prédios → derrota, perde recursos.
- Com torre arqueiro/def aérea/tesla → naves abatidas → vitória.
- Morteiro/canhão não miram naves (só terrestre).
