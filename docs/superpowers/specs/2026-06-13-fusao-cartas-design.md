# Sistema de Fusão de Cartas — Arma × Elemento (design)

Data: 2026-06-13
Status: aprovado — implementar incremental, Fase 1 primeiro

## Visão

Cartas se combinam por ACÚMULO para desbloquear "fusões" que transformam o
formato/natureza do tiro da torre. Cada run vira uma build memorável. Reaproveita
a engine de gate que já existe (Fragmento aparece após Perfurante×3; Corrente
exige Perfurante×3 + Raio×3).

Princípios destilados de jogos de referência (pesquisa 2026-06-13):
- **Threshold claro** (Vampire Survivors / Bloons): junta X de um elemento +
  a arma-chave → evolução. Chart no pause mostra o que falta.
- **Limitação que força escolha** (Bloons crosspath): ARMA é exclusiva — pegou
  uma, as outras somem do pool. Não dá pra ter tudo.
- **Resultado transformador, não incremental** (Magicka / RoR2): a fusão muda
  COMO se joga (bolas de fogo que explodem), não só "+dano".
- **Reações elementais** (Genshin): aplicar elemento B sobre inimigo já afetado
  por elemento A dispara reação (Fogo sobre Congelado = Derrete).

Benefícios de design:
- Objetivo de longo prazo na run (caçar as peças da fusão).
- Sumidouro de Cytron (reroll buscando cartas certas combate inflação).
- Rejogabilidade alta (muitas builds distintas).

## Eixos

### ARMAS (exclusivas — escolheu 1, as outras somem do sorteio)
Define o FORMATO do tiro. Aparecem cedo (min_wave 3-5).

| Arma | Tiro |
|---|---|
| Padrão (sem carta) | 1 projétil teleguiado |
| **Ricochete** (Bala Saltitante — já existe) | quica de mob em mob |
| Escopeta | leque de 6, alcance curto, dano alto |
| Sniper | 1 tiro lento, dano enorme, alcance máx, perfura |
| Metralhadora | cadência altíssima, dano baixo/tiro |
| Laser | feixe contínuo no alvo (sem projétil) |

### ELEMENTOS (empilháveis — cada pick fortalece; threshold 5 = fusão)
Define a NATUREZA do dano.

| Elemento | Carta empilhável | Efeito base por pick |
|---|---|---|
| **Fogo** | Brasa | +queimadura nos tiros |
| Gelo | Geada | +lentidão nos tiros |
| Veneno | Toxina | +DoT nos tiros (já tem base) |
| Elétrico | Faísca | +chance de cadeia |
| Arcano | Eco | +dano puro |

## Matriz de FUSÕES (Arma + 5× Elemento)

Estilo Vampire Survivors. Cada célula = build transformadora com visual próprio.

| Arma ↓ / Elem → | Fogo | Gelo | Veneno | Elétrico |
|---|---|---|---|---|
| **Ricochete** | 🔥 **Bolas de Fogo** (quica + explode em área) | ❄️ Granizo (quica congelando) | ☠️ Praga Saltante (quica espalhando veneno) | ⚡ Raio Saltante (quica eletrizando) |
| **Escopeta** | Dragão (leque flamejante) | Sopro Glacial (cone que congela) | Nuvem Tóxica (leque envenena área) | Descarga (leque elétrico) |
| **Sniper** | Bala Incendiária | Lança de Gelo (perfura congelando) | Dardo Tóxico | Railgun |
| **Metralhadora** | Chuva de Brasas | Tempestade de Neve | Rajada Tóxica | Tesla Gun (balas saltam) |

(Laser × elementos = fase futura)

## REAÇÕES elementais (camada extra — Genshin)

Independente de fusão: aplicar elemento sobre inimigo já afetado por outro.
- **Fogo sobre Congelado** = DERRETE (dano massivo único)
- **Elétrico sobre Envenenado** = DETONA (explode o veneno em área)
- **Fogo sobre Envenenado** = COMBUSTÃO (queima espalha mais rápido)

Aproveita gelo/veneno que já existem no jogo.

## Fase 1 — prova de conceito: BOLAS DE FOGO (implementar agora)

- **Carta `Brasa`** (efeito `brasa`): empilhável, máx 5, incomum, min_wave 3.
  Cada pick adiciona queimadura aos tiros (sistema da queima do talento p5).
- **Gate**: `brasa_count >= 5` E `ricochete_count > 0` → `fogo_fusao` na torre.
- **Efeito (projetil.gd)**: projétil vira bola de fogo (visual laranja, núcleo
  maior); ao acertar explode em área (~72px): dano de área + queimadura forte
  (15/s por 3s) em todos no raio; mantém o quique do Ricochete.
- **HUD**: `_checar_identidade_build` → "MESTRE DAS CHAMAS".

### Arquitetura Fase 1
- `main.gd CARTAS`: carta `brasa`.
- `torre.gd`: `brasa_count`, `fogo_fusao`, `aplicar_carta("brasa")`,
  `_checar_fusao_fogo()`, extras no disparo.
- `projetil.gd`: `fogo_fusao`, `_explosao_fogo_at(pos)`, visual no `_draw`.
- `main.gd`: identidade "MESTRE DAS CHAMAS".

## Fases futuras

- **Fase 2**: elementos Gelo/Veneno/Elétrico empilháveis + reações elementais
  (Derrete, Detona).
- **Fase 3**: armas Escopeta/Sniper/Metralhadora + exclusividade no sorteio
  (escolheu arma → outras somem).
- **Fase 4**: matriz completa de fusões com visual único cada + CHART de
  progresso na tela de cartas ("Fogo 3/5 · falta arma Ricochete") estilo VS.
- **Fase 5**: Laser + fusões dele; combos proibidos (Magicka) se necessário
  pra balanço.

## Critério de aceite Fase 1

5× Brasa + Ricochete numa run → tiros viram bolas de fogo que explodem em área;
HUD "MESTRE DAS CHAMAS"; sem regressão; parse + smoke test OK; validado in-game.
