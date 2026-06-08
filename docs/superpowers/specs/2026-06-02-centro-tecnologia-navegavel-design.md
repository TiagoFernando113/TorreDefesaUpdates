# Centro de Tecnologia Navegavel

## Objetivo

Substituir a tela atual de talentos por um Centro de Tecnologia maior que a tela, navegavel por arraste no mouse e no dedo. O sistema deve parecer uma arvore de talentos de jogo, com rotas claras, requisitos cruzados e nos de fusao, sem voltar para a bagunca visual de costelacao ou bolinhas soltas.

## Direcao Aprovada

O modelo base e o mockup `docs/superpowers/mockups/talent_tree_direction_v6.html`.

A arvore comeca em um talento inicial e abre em rotas horizontais:

- Arsenal: dano, projeteis, alvo e poder ofensivo.
- Controle: gelo, raio, veneno, lentidao e paralisia.
- Bastion: defesa, economia, sobrevivencia e boss.

Alguns pontos especiais sao `FUSAO`. Uma fusao so fica liberada quando duas rotas exigidas chegam nela. Exemplo: `Fusao Crio-Plasma` exige progresso em Arsenal e Controle.

## Navegacao

O mapa da arvore deve ser maior que a tela.

No PC:

- arrastar com o mouse move o mapa;
- roda do mouse pode mover verticalmente se houver area;
- o clique em talento nao deve ser confundido com arraste.

No celular:

- arrastar com o dedo move o mapa;
- tocar em um talento seleciona o talento;
- sem zoom nesta primeira versao, para reduzir bugs.

HUD, carteira, painel de detalhes e botao Voltar ficam fixos por cima do mapa.

## Layout

A tela deve manter o estilo do menu principal: fundo preto espacial com estrelas, neon ciano, roxo, dourado e laranja. Nao usar imagem pronta de constelacao como base principal.

Elementos:

- topo com titulo `CENTRO DE TECNOLOGIA`;
- carteira fixa com Cytron e Cristais;
- painel lateral esquerdo com detalhes do talento selecionado;
- area central navegavel com as rotas;
- legenda pequena para comprado, liberado, bloqueado e fusao;
- botao `VOLTAR` fixo.

## Regras De Talentos

Cada talento visivel pode ter niveis internos. Isso permite manter o mapa limpo sem precisar desenhar 59 bolinhas.

Estados:

- comprado: ativo na conta;
- liberado: requisitos cumpridos, pode comprar;
- bloqueado: requisitos pendentes;
- fusao: exige duas entradas diferentes.

O jogador sempre deve iniciar pelos talentos mais proximos do nucleo inicial. Talentos mais distantes dependem dos anteriores na mesma rota ou de uma fusao.

## Dados

A estrutura de dados deve permitir:

- id do talento;
- nome;
- rota;
- descricao;
- custo;
- nivel atual;
- nivel maximo;
- requisitos;
- posicao no mapa;
- tipo normal ou fusao;
- efeitos aplicados.

As posicoes devem ser relativas ao mapa, nao a tela, para funcionar com arraste.

## Fora De Escopo Agora

Nao mudar balanceamento final de todos os talentos nesta etapa.
Nao refazer a logica de save alem do necessario para preservar compra/nivel.
Nao implementar zoom.
Nao criar editor visual de posicoes agora.

## Verificacao

Validar:

- abrir a tela de talentos sem erro;
- arrastar no PC;
- tocar/arrastar no celular sem perder selecao;
- selecionar talento e atualizar painel;
- comprar talento liberado;
- bloquear talento sem requisito;
- fusao exigir duas rotas;
- voltar para o menu/inventario sem travar.
