# Modularização do menu.gd (design)

Data: 2026-06-12
Status: aprovado pelo usuário — executar fase a fase, cada fase em sessão dedicada

## Problema

`menu.gd` tem ~13.970 linhas e 292 funções: todas as telas do menu (loja,
inventário, baús, talentos, ranking, config, mapas...) num arquivo só.
Dificulta ajustes e aumenta acoplamento — bug em uma tela pode derrubar as
outras porque tudo compartilha o mesmo escopo.

## Medições (2026-06-12)

| Domínio | Linhas aprox. |
|---|---|
| Núcleo do menu + telas diversas ("outros") | 5.917 |
| Inventário + baús | 3.448 |
| Talentos (tela velha) | 1.601 |
| Loja | 1.319 |
| Ranking | 521 |
| Config | 376 |
| Mapas | 340 |
| Comandantes | 184 |
| Discord | 71 |

## Decisões

1. **Tela velha de talentos NÃO migra.** Se o Nexo Estelar (talentos_v2.gd)
   for promovido a oficial, deletam-se ~1.601 linhas de graça. Migrar agora é
   trabalho descartável.
2. **Padrão de módulo**: cada tela vira `scripts/menu/<dominio>.gd`
   (`extends Node`), instanciado pelo menu no `_ready` com referência de volta:
   ```gdscript
   # menu.gd
   var _mod_ranking = preload("res://scripts/menu/ranking.gd").new(self)
   ```
   ```gdscript
   # scripts/menu/ranking.gd
   extends Node
   var m  # menu principal (acesso a _ui_ref, fontes, helpers compartilhados)
   func _init(menu) -> void: m = menu
   ```
3. **Movimentação verbatim**: funções copiadas sem reescrita; referências a
   estado/helpers do menu viram `m.X`. Vars exclusivas do domínio movem para o
   módulo; compartilhadas ficam no menu.
4. **Stubs de delegação** no menu.gd (1 linha por função pública do domínio)
   preservam todos os call sites, connects e `call("...")` existentes.
5. **Cada fase**: extrair → rodar teste headless
   (`tests/test_talentos_v2_parse.tscn` + `tests/test_talentos_layout.gd`) →
   testar manualmente a tela → commit. Nunca duas fases no mesmo commit.

## Fases

### Fase 1 — Ranking (~521 ln, prova o padrão)
Funções (linha em 2026-06-12): `_on_premio_temporada_aplicado` (246),
`_abrir_ranking` (4914), `_fechar_ranking` (5224), `_carregar_ranking` (5602),
`_atualizar_timestamp` (5619), `_ranking_tempo_temporada_texto` (5636),
`_nivel_prestigio` (5650), `_carregar_simbolo_prestigio` (5666),
`_on_ranking_carregado` (5687), `_on_campeoes_temporada_anterior_carregados`
(5697), `_render_campeoes_temporada_anterior` (5701),
`_draw_ranking_campeoes_faixa` (5756), `_popular_lista` (5767).
Vars: todas `_ranking_*`. Cuidado: callbacks conectados ao autoload
`RankingOnline` e `Acessibilidade.processar`.

### Fase 2 — Loja (~1.319 ln)
Funções com `loja|premium|compra|produto|skin` no nome. Cuidado: fluxo de
compra premium (IAP) — testar com DEBUG_PREMIUM antes/depois.

### Fase 3 — Inventário + Baús (~3.448 ln, a maior)
Funções com `inventario|mochila|item|equip|bau|reward`. Subdividir em dois
módulos se conveniente (inventário vs abertura de baús). Cuidado: scroll touch
(`_handle_inventario_wheel` é chamado de `menu._input`).

### Fase 4 — Config + Mapas (~716 ln)
Baixo risco, fechamento.

### Fase 5 — Decisão do Nexo
Promover Nexo → deletar tela velha de talentos + `_handle_talent_map_*` +
calibração (~1.601+ ln) e remover o botão BETA (Nexo vira o caminho padrão).

## Riscos

- Referências por string (`call`, `connect`, `Acessibilidade.processar`) não
  aparecem em busca de símbolo — conferir com grep por nome da função.
- `menu._input` roda antes do GUI (lição do bug do Nexo): handlers movidos
  precisam manter a mesma ordem de chamada.
- Telas desenham via Controls criados em `_ui_ref` (CanvasLayer do menu) —
  módulos continuam criando nele via `m._ui_ref`.

## Critério de aceite por fase

Tela abre, opera e fecha como antes; testes headless passam; nenhum
`Identifier not found` no console; commit isolado com mensagem `refactor(menu)`.
