# Jogabilidade em partida — Painel de Comando + Cartas-Habilidade + Armas

Data: 2026-06-14
Status: design aprovado (revisão do usuário pendente)

## Problema

Hoje as **cartas** misturam dois papéis: stat plano (+25 dano, +40 vida) E
habilidades (veneno, fusões). Isso deixa o pool diluído de cartas "chatas" e não
sobra espaço pra um sistema ativo em partida sem conflitar com as cartas. As
**armas** estão desbalanceadas (ex: Sniper fraca vs horda) e a escolha de arma é
determinística (mostra as 5 comuns sempre).

## Visão (separação de papéis)

- **Painel de Comando** = os NÚMEROS base da torre (ativo, gasta ouro, per-run).
- **Cartas** = HABILIDADES / identidade de build (sem stat plano).
- **Armas** = formato do tiro (4 aleatórias na escolha; rebalanceadas).
- **Fusão** = "rotas" reveladas conforme o jogador adquire as peças.

Regra de ouro anti-conflito: **número plano → painel (ouro). Mecânica/efeito →
carta.** Ex: `+vida` = painel; `vampirismo` (rouba vida) = carta.

---

## Pilar 1 — Painel de Comando ("Núcleo de Comando")

Per-run; reseta a cada partida nova (igual `_cartas_colhidas`).

**Trilhas de stat** (clica → paga ouro → +1 nível; custo escala):
| Trilha | Efeito / nível |
|---|---|
| Dano | +dano |
| Cadência | +tiros/s |
| Vida | +HP máx (+ regen leve) |
| Alcance | +alcance (cap 450) |

- Custo por nível: `base * growth^nível` (afinar no plano). **Cap de níveis** por
  trilha pra veterano não maxar na wave 1 (run começa com o banco inteiro como
  ouro — ver Economia).
- Gasto reduz o ganho que vai pro banco no fim (`ganho = gold - inicio`) →
  custo de oportunidade real vs reroll/banco.
- Reusa `torre.aplicar_carta("dano"/"cadencia"/"vida"/"alcance", val)`.

**Comandos táticos** (toggle, sem ouro):
- **Prioridade de Alvo**: perto / forte / rápido / menor-HP.
- **Postura**: Agressiva (+dano, −defesa) / Defensiva (+redução dano, +regen,
  −dano) / Equilibrada. Alterna na hora — alavanca momentânea, não stat
  permanente (não pisa nas trilhas). A Defensiva embute o −dano% do antigo
  "Escudo Arcano".

**UI**: painel recolhível no HUD, acessível DURANTE a wave (tempo real). Mobile +
desktop. Não pausa a partida (diferente da escolha de carta).

---

## Pilar 2 — Cartas = só habilidades

**REMOVE do pool** (vira trilha do painel): `dano_m`, `dano_g`, `cad_m`, `cad_g`,
`range_m`, `range_g`, `vida_m`, `vida_g`.

**Reabsorve**: `regen` → trilha Vida (cada nível dá regen leve). `escudo` →
Postura Defensiva. `vel` (projétil sônico) → **cortar** (stat de pouco impacto).

**MANTÉM como carta-habilidade** (~22): pierce, multi, fragmento, raio, corrente,
brasa, veneno, critico, explosao, chama, overdrive, armadura_i, bencao,
recuperacao, tempestade, fissura, cacador, rajada, carga, gelo, ouro, saque.

**NOVAS** (fase futura): vampirismo (lifesteal) e outras especialidades.

**Ajustes necessários**:
- Fallback do pool (hoje cai em dano/cadência/vida comuns) → passa a usar
  habilidades comuns/incomuns.
- Talentos de pick de carta (M1 +1 carta, M4 dupla escolha) seguem funcionando.
- Gates seguem ok (pierce→fragmento; pierce continua carta).

---

## Pilar 3 — Armas

- Escolha mostra **4 armas aleatórias** do pool elegível. Na 1ª escolha tudo entra
  no sorteio; nas revisões (wave ≥ 20) mantém a atual + 3 sorteadas.
- **Retier**: `gemea` (Canhão Gêmeo) passa de lendária → **comum**.
- **Arma nova — Lança-Chamas** (`lanca_chamas`, comum): cone/jato curto na direção
  do focus-aim. Cadência alta, dano baixo por tick, alcance curto (~0.5). Acerta
  todos no cone + aplica queimadura. Papel: tipo Escopeta mas contínuo + fogo.
  Novo `modo` em `torre._atirar`.
- Resultado: **7 comuns / 4 lendárias** (11 armas). Lendárias seguem na wave 100.
  Mais variedade no reroll cedo (4 de 7).
- **Rebalance** (números afina no plano/playtest):
  - **Sniper**: fura a LINHA inteira sem decaimento (pierce alto/infinito) +
    cadência 0.35 → 0.45. Vira "alinhou, ceifou" — sinergia com o focus-aim manual.
  - **Metralhadora**: hoje DPS ≈ Padrão. Dar ramp (esquenta → +cadência ao
    segurar fogo) ou +dano leve.
  - Demais: revisão de balance (DPS-alvo por arma).
- **Reroll de arma**: re-sorteia **só armas** (`_mostrar_escolha_arma`), custa
  **cristais** (10 / 20 / 40, escala no mesmo choice; cap 3). Diferente do reroll
  de carta (ouro, 200/300…). `mostrar_cartas` ganha flag `modo_arma`; novo
  `reroll_armas()` no main; checa `Salvar.cristais`.

---

## Pilar 4 — Fusão por rotas

- FUSÃO só aparece quando o jogador JÁ tem o parceiro (rota): tem a arma →
  carta-elemento mostra FUSÃO; tem o elemento → arma mostra FUSÃO. Sem parceiro =
  nada. (JÁ implementado em `main.sinergia_para_carta`.)
- **Expandir** a matriz arma × elemento além de Ricochete + Brasa (o sistema já
  suporta via `FUSOES_ARMA`).
- **Nova fusão — Chamas Tóxicas** (`lanca_chamas` + Veneno ×N): o jato deixa uma
  **poça tóxica-flamejante** no chão = dano em área contínuo (queima + veneno) por
  alguns segundos. "O Campo de Gelo, só que de fogo." Reusa `_explosao_fogo_at` +
  aplicação de veneno.

---

## Futuro (mais para frente)

- **Tecnologias buffam o painel**: o Centro de Tecnologia (meta) passa a
  fortalecer o painel entre runs — ex.: destravar trilha extra, baratear níveis,
  aumentar o cap de nível, liberar um comando tático novo. Meta-progressão que dá
  poder de longo prazo ao painel sem mexer nas cartas.
- **Tecnologia turbina fusão** — ex.: tech "Praga Infernal" faz a fusão Chamas
  Tóxicas **se espalhar de mob em mob**, raio maior, +DoT. A versão fim-de-jogo
  ("muito foda") de uma fusão, destravada via meta-progressão.
- Novas cartas-habilidade (vampirismo etc.) + mais rotas de fusão.

---

## Economia / balance

- Painel vira a **única fonte de stat** mid-run → recalibrar a curva de poder
  (antes as cartas davam dano/cadência/vida).
- Run começa com o banco inteiro como ouro → custo das trilhas escala forte + cap
  de níveis, senão veterano maxa na wave 1.
- Reroll de arma (cristais) = novo ralo de cristais (que hoje só acumulam).

## Testes (headless)

- Pool de cartas NÃO contém stat cards removidas.
- Painel aplica dano/cadência/vida/alcance via `torre.aplicar_carta`.
- Reroll de arma re-sorteia só armas e debita cristais (cap 3); reroll de carta
  segue em ouro.
- Fusão-rota: badge só com parceiro (1ª escolha de arma sem cartas = sem FUSÃO).
- Retier: 6 comuns / 4 lendárias; escolha mostra 4.

## Fases de implementação

1. **Painel** (trilhas de stat + comandos táticos) + remover stat cards + ajustar
   fallback/talentos/regen/escudo.
2. **Armas**: retier 6/4 + rebalance Sniper/Metralhadora + reroll por cristais.
3. **Fusão rotas** expandida (mais combos arma×elemento).
4. **Futuro**: tecnologias buffam painel + cartas novas (vampirismo).
