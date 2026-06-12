# Talentos V2 — "Nexo Estelar" (design)

Data: 2026-06-11
Status: aprovado (abordagem A — web radial estilo PoE/Stellaris, carta branca criativa)

## Objetivo

Tela de talentos alternativa, visualmente rica, baseada nos grandes jogos de árvore
de talentos (Path of Exile / Stellaris), respeitando a estética neon-espacial do
Cyron Defense. Roda EM PARALELO com a tela atual — botão "✦ NEXO (BETA)" na tela
de talentos antiga abre a nova. Reverter = remover botão. Zero mudança de dados.

## Princípios

- **Mesmos dados, mesma persistência.** Lê `Salvar.TALENTOS_INFO` e usa apenas a
  API existente: `talento_ativo`, `requisitos_talento`, `custo_efetivo_talento`,
  `pode_comprar_talento`, `comprar_talento`, `redefinir_talentos`. Progresso vale
  nas duas telas.
- **Arquivo novo autocontido**: `scripts/talentos_v2.gd` (Control fullscreen,
  desenho 100% programático via `_draw`, padrão do projeto).
- **Hook mínimo no menu.gd**: ~15 linhas em `_abrir_talentos` criando o botão BETA.

## Layout (espaço-mundo, raiz no centro)

- Raiz em (0,0). 10 ramos (p, b, t, e, g, r, s, m, x, f) irradiando a cada 36°,
  começando em -90° (ataque para cima).
- Espiral galáctica: cada tier soma +7° de offset angular no braço.
- Raios por tier: T1=170, T2=290, T3=410, T4=530, T5=650 px.
- Anel interno (r≈95): 7 nós — 4 situacionais (cazador, exter, anti_t, purif) +
  3 legado (veteran, genoci, sobrev) espaçados uniformemente.
- Fusões (colosso, predador, alquim, tita, relamp, canhao_g): posição = média
  angular/radial dos pais (reqs de `TALENTOS_INFO` + `TALENTOS_REQ_EXTRA`),
  empurrada +40px para fora. Links tracejados para cada pai.

## Câmera

- Pan por arrasto (mouse/touch) com inércia leve; zoom 0.45–1.6 por scroll +
  botões +/− na tela (mobile-friendly). Início: zoom 0.8 centrado na raiz com
  animação de abertura (zoom-in 0.3→0.8 + nós aparecendo em onda radial).
- Transform: `tela = (mundo - cam) * zoom + viewport/2`.

## Camadas visuais (_draw)

1. **Fundo**: vinheta radial escura; starfield 3 camadas com parallax no pan;
   nebulosa por ramo (blobs alpha ~0.05 na cor do ramo atrás de cada braço).
2. **Grid polar fantasma**: anéis nos raios dos tiers + 10 raios, alpha 0.04.
3. **Links**: curvas (arcos seguindo a espiral). Estados — bloqueado: linha fina
   escura; disponível: pulso "respirando"; comprado: linha grossa gradiente na cor
   do ramo + partículas de energia fluindo raiz→ponta.
4. **Nós**: círculo base + glifo geométrico do ramo + anéis de estado. Nós major
   (T4/T5/fusões) maiores com hexágono externo girando devagar.
   - comprado: preenchido, glow forte, anel pulsante, badge ✓
   - disponível: borda acesa, pulso, partícula orbitando
   - bloqueado: apagado, glifo esmaecido
   - legado não conquistado: cadeado
5. **Partículas de compra**: flash radial 0.15s → shockwave 0.4s → 16 fagulhas na
   cor do ramo → link do pai acende em 0.3s. Som: `Som.talento_ramo()` /
   `talento_fusao()` (fusões) / `talento_especial()` (legado/situacional).
6. **UI screen-space**: header (💎 cristais, X/55 nós, botão FECHAR, reset com
   dupla confirmação); painel lateral do nó selecionado (nome, desc, efeito,
   custo efetivo, botão DESBLOQUEAR verde/cinza com motivo do bloqueio);
   labels de % por ramo visíveis em zoom distante.

## Glifos por ramo (desenho primitivo)

p=chama, r=escudo, f=diamante, e=raio, s=gota tóxica, m=carta, g=floco de neve,
b=garra tripla, t=ampulheta, x=dado. Fusões=estrela 4 pontas; legado=louros;
situacional=alvo.

## Interação

- Tap/clique nó → seleciona (anel de seleção) + painel lateral desliza.
- Clique duplo em nó comprável → compra direta.
- Compra falha mostra motivo no painel ("Faltam N cristais", "Requer X").
- Hitbox mínima 44px de tela (mobile).
- ESC/botão FECHAR → fecha overlay e devolve a tela antiga intacta.

## Performance

- redraw ~30fps via acumulador em `_process` (imediato durante drag).
- Partículas máx ~120 simultâneas. Culling: nós/links fora da tela não desenham.

## Fora de escopo

- Mudanças de balanceamento, custos ou efeitos.
- Substituir a tela antiga (decisão só depois do teste do usuário).
- Pinch zoom nativo (v2 usa botões +/− e scroll).

## Critério de aceite

- Abrir pelo botão BETA, navegar (pan/zoom), comprar talento com animação,
  progresso refletido na tela antiga e vice-versa, fechar sem vazamento de nós.
- Projeto continua parseando sem erros.
