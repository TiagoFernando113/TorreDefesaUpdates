# Tecnologia Poe Tree Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refazer a aba `TECNOLOGIAS` como uma arvore de talentos visualmente inspirada em Path of Exile, com raiz inferior, galhos ascendentes e nos de fusao ligados por requisitos multiplos.

**Architecture:** Manter toda a logica atual de talentos em `scripts/salvar.gd`. Alterar apenas a construcao visual em `scripts/menu.gd`, calculando posicoes por ID e desenhando linhas a partir dos arrays `req`. Melhorar a camada `scripts/arvore_fundo.gd` para aceitar linhas segmentadas, dando leitura mais organica aos cruzamentos.

**Tech Stack:** Godot 4.6.2, GDScript, Control Nodes existentes.

---

### Task 1: Rede Principal De Tecnologias

**Files:**
- Modify: `C:/TORREDEFENSE/scripts/menu.gd`

- [ ] Add helper data for main/fusion node IDs and major node sizing.
- [ ] Replace the old radial fan rendering with a fixed constellation layout.
- [ ] Draw dependency lines from `Salvar.TALENTOS_INFO[id]["req"]` instead of hardcoding branch-only links.
- [ ] Keep tabs, tooltips, buying logic and save IDs unchanged.

### Task 2: Linha Visual Mais Legivel

**Files:**
- Modify: `C:/TORREDEFENSE/scripts/arvore_fundo.gd`

- [ ] Let `linhas` optionally receive an array of points.
- [ ] Draw each connection as small line segments so crossing paths look intentional.
- [ ] Preserve the old two-point line format for other tabs.

### Task 3: Verificacao

**Files:**
- Test command only.

- [ ] Run Godot headless:

```powershell
& 'C:\Users\jogos\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'C:\TORREDEFENSE' --quit-after 2
```

- [ ] Confirm no parse errors.
