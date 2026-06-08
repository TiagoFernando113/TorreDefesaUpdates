# Centro De Tecnologia Navegavel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refatorar a tela de talentos para um Centro de Tecnologia navegavel, sem imagem pronta de constelacao, com progressao clara a partir do nucleo e fusions integradas no mesmo mapa.

**Architecture:** Manter a logica de compra/save em `Salvar.gd`. `menu.gd` continua criando a UI, os hitboxes e o painel de detalhes. `talent_constellation_fundo.gd` desenha somente o mapa visual a partir dos dados de posicao/estado recebidos.

**Tech Stack:** Godot 4.6.2, GDScript, Control Nodes.

---

### Task 1: Corrigir mapa navegavel

- [x] Alterar `C:\TORREDEFENSE\scripts\menu.gd` para o mapa ter largura maior que a tela.
- [x] Remover o reset automatico de `_talent_map_pan` em `_talent_map_rect`.
- [x] Permitir arrastar horizontalmente com mouse/touch sem depender do modo de calibracao.
- [x] Manter painel de detalhes, moedas, abas e botao voltar fixos na tela.

### Task 2: Redesenhar progressao

- [x] Trocar `_TECH_CONSTELLATION_POS` por uma arvore horizontal logica.
- [x] Cada ramo deve iniciar no ponto mais perto do nucleo e avancar para a direita.
- [x] Posicionar fusions nos cruzamentos de ramos.
- [x] Mostrar fusions tambem na aba principal de tecnologias.

### Task 3: Limpar visual

- [x] Remover aparencia de imagem pronta/constelacao quebrada.
- [x] Usar fundo preto estrelado discreto, linhas neon e nos legiveis.
- [x] Reduzir poluicao visual nos labels e no backplate.

### Task 4: Validar

- [x] Rodar Godot headless para detectar erro de parse/import.
- [x] Corrigir erros que bloqueiem abrir o projeto.
- [x] Se possivel, iniciar o jogo e confirmar que a tela de talentos abre sem travar.
