# Vila estilo Clash of Clans — Fase 1 (Design)

Data: 2026-06-09
Status: Aprovado pelo usuário

## Objetivo

Transformar a `mini_cidade.gd` numa vila **idêntica ao Clash of Clans**:
grid isométrico, recursos completos (ouro/elixir/elixir escuro) com coletores,
loja de construção, e quartel que treina tropas de verdade.

Combate (torre atirando, naves atacando 24h, batalha, pesquisa) fica para **Fase 2**.

## Abordagem escolhida (C)

- `coc_dados.gd` — definições/custos/produção dos 22 edifícios, 15 tropas, 6 feitiços. **Já pronto, reusado.**
- `coc_salvar.gd` (autoload `CocSalvar`) — estado: ouro/elixir/escuro/gemas/troféus, slots, fila de treino, construções, níveis. Salva em `coc_save.json`, separado do save de mana. **Já pronto, reusado.**
- `mini_cidade.gd` — **interior reescrito**: grid isométrico + UI (loja, treino, popup). Lê/grava via `CocSalvar` + `DADOS`.

A tela separada `coc_main.gd` (abas) é **descontinuada** — lógica de loja/treino portada para painéis dentro de `mini_cidade.gd`.

## Contrato preservado (não quebrar main.gd)

`mini_cidade.gd` DEVE manter, com as mesmas assinaturas:
- `signal fechado`
- `func abrir(ui_node: Node = null) -> void`
- `func fechar() -> void`
- `func aplicar_bonus_torre(torre: Node) -> void`  *(Fase 2 — manter intacto)*
- `func on_mob_morreu(ui_node: Node, total_kills: int) -> void`  *(Fase 2 — manter intacto)*
- `func on_fim_wave(wave: int, ui_node: Node) -> void`  *(Fase 2 — manter intacto)*

Esses 3 métodos de bônus continuam lendo `Salvar`/`cidade_slots` (economia de mana, intocada).
São território da Fase 2; em Fase 1 ficam como estão (sem efeito sobre a vila CoC nova).

## Componentes Fase 1

### 1. Grid isométrico
- Grid lógico ~14×14 células (config `GRID_N`). Coordenada lógica "gx,gy" preservada como chave (compatível com `CocSalvar.slots`).
- Projeção isométrica (losango / vista 3/4):
  - `iso(gx,gy) -> Vector2` = origem + `((gx-gy)*TILE_W/2, (gx+gy)*TILE_H/2)`
  - inverso `tela->celula` para clique/hover.
- Cada célula = losango (4 pontos), terreno grama com variação por hash.
- Edifícios desenhados como sprite + sombra elíptica, ordenados por (gx+gy) para profundidade correta (painter's algorithm).

### 2. Recursos (ouro / elixir / elixir escuro)
- HUD topo: ícone + valor/capacidade dos 3 recursos + gemas + construtores livres.
- Coletores (`mina_ouro`, `coletor_elixir`, `mina_escura`) acumulam ao longo do tempo (`CocSalvar.tick_recursos`).
- Acúmulo limitado pela capacidade do depósito correspondente.
- Coletor cheio mostra bolha "!" — clique coleta (`CocSalvar.coletar`).

### 3. Loja de construção
- Botão LOJA abre painel categorizado: recurso / defesa / exército / outro.
- Card mostra sprite, nome, custo, descrição. Esmaece se não pode pagar / sem construtor / sem slot.
- Selecionar card → estado PLACING → ghost segue cursor no grid iso → clique em célula vazia constrói.
- Construir gasta recurso + ocupa 1 construtor + timer (`CocSalvar.construcoes`).

### 4. Quartel treina tropas
- Clicar `quartel`/`quartel_escuro` abre painel de treino.
- 15 tropas (custo elixir/escuro, tempo, capacidade). Botão + adiciona à fila do quartel.
- Fila com barra de progresso (timer real via `Time.get_ticks_msec()`).
- Tropa pronta vai para `CocSalvar.tropas` (inventário). Respeita `cap_tropas_total`.

### 5. Popup de edifício
- Clicar edifício existente → menu contextual: MOVER, UPGRADE (custo+timer), REPARAR, COLETAR (se coletor), DEMOLIR.
- Prefeitura (central) e heróis não podem demolir.
- Em construção → mostra timer + opção ACELERAR (gemas).

### 6. Estados (máquina)
`IDLE | SHOP | PLACING | SELECTED | MOVING | TRAIN` — sobre o grid iso.

### 7. Persistência
- Tudo via `CocSalvar` → `coc_save.json`. Save de mana (`salvar.gd`) intocado.
- `abrir()` chama `CocSalvar.carregar()` + `CocSalvar.init_vila_padrao()`.
- `_process` chama os ticks (`tick_recursos`, `tick_construcoes`, `tick_treino`).

## Setup necessário (1×, no editor Godot)
Project Settings → Autoload → adicionar:
`CocSalvar` → `res://scripts/coc/coc_salvar.gd` (nome do nó: `CocSalvar`).

## Fora de escopo (Fase 2)
- Torre central atirando nas naves.
- Naves atacando a vila 24h.
- Batalha (deploy de tropas, estrelas, loot).
- Laboratório / pesquisa.
- Heróis (rei/rainha).

## Testes / verificação
- Abrir vila: prefeitura aparece no centro do grid iso, recursos no topo.
- Esperar: coletores acumulam, bolha "!" aparece, coleta soma recurso.
- Loja: construir mina nova consome recurso + construtor + timer; conclui e fica utilizável.
- Quartel: treinar bárbaro → fila progride → tropa entra no inventário.
- Popup: upgrade/mover/demolir funcionam; prefeitura não demole.
- Fechar/reabrir: estado persiste (coc_save.json).
- Jogo principal (waves/torre) continua rodando sem erro (métodos de bônus intactos).
