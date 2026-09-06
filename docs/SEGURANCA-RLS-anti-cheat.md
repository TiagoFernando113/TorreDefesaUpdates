# Segurança do backend (RLS) + Anti-cheat — relatório e plano

Data: 2026-06-14
Projeto Supabase: `npbqezpfjrjvsqwvgtfy` (torredefesa)

## Resumo

Auditoria de anti-cheat em 3 frentes. Implementado o que é seguro aplicar sem
quebrar clientes já distribuídos; documentado o restante, que exige release
coordenado do cliente antes de virar o RLS.

## O que JÁ foi feito (aplicado e verificado)

### Tier 1 — Save local encriptado  ✅
- `scripts/salvar.gd`: save, checkpoint e contas gravados com
  `FileAccess.open_encrypted_with_pass` (AES). Leitura tem fallback para JSON
  legado (migra na 1ª gravação encriptada).
- Bloqueia edição casual (notepad / save-editor). **Não** protege contra
  atacante dedicado (chave embutida no binário) — isso é esperado para save de
  jogo single-player.
- Teste: `tests/test_save_cripto.tscn`.

### Tier 2 — Validação de ranking no servidor  ✅
- RPC `submit_ranking` (ambos overloads) rejeita:
  - `wave <= 0` ou `wave > 999`  → `wave_invalida`
  - `score < 0` ou `score > wave * 50000` → `score_implausivel`
- **Trigger** `trg_ranking_plausibilidade` em `public.ranking` (BEFORE
  INSERT/UPDATE) aplica os MESMOS limites a QUALQUER escrita — inclusive INSERT
  direto via anon key. Fecha o bypass do RPC sem mexer no RLS, então não quebra
  os caminhos legítimos (avatar/rename/submit). UPDATE que não altera
  wave/score (avatar, ascensoes) passa direto.
- Calibração (dados reais): score/wave legítimo observado ≤ 15.276; limite
  50.000 = 3,3x folga. Recorde de wave atual 151; limite 999 = 6,6x folga.

### Fase B + C — RPCs "porteiro" aplicadas  ✅ (2026-06-20)
- **Fase B** (`usuarios`): `cadastrar_usuario`, `login_usuario`,
  `login_por_player_id`, `buscar_nome_por_email`. Todas SECURITY DEFINER,
  `search_path=public`, **nunca retornam a coluna `senha`**.
  SQL: `docs/sql/fase_b_rpc_contas.sql`. Testado: login certo→linha, errado→null,
  saída sem `senha`.
- **Fase C** (`saves`): `upload_save`, `download_save`, `apagar_save`,
  `limpar_saves_orfaos` + helper interno `_auth_usuario` (revogado do anon).
  Exigem (nome+senha_hash) válidos; derivam `player_id` do servidor.
  SQL: `docs/sql/fase_c_rpc_saves.sql`. Testado: download confere credencial,
  anon não acessa o helper.
- **Aditivo**: cliente ainda usa caminho direto. Faltam passos 2-5 abaixo.

### Passo 3 — cliente migrado p/ RPCs  🟡 PARCIAL (2026-06-20)
Em `ranking_online.gd` já chamam os porteiros (não mais a tabela direta):
- ✅ `registrar_nome` → `rpc/cadastrar_usuario`
- ✅ `verificar_login_hash` → `rpc/login_usuario`
- ✅ `sincronizar_nome` → `rpc/login_por_player_id` (ou `login_usuario`)
- ✅ `upload_save` / `download_save` / `apagar_save_nuvem` / `limpar_saves_orfaos`
  → `rpc/upload_save|download_save|apagar_save|limpar_saves_orfaos`
- Porteiros convertidos p/ `RETURNS TABLE` (resposta array, casa com os handlers).
- Parse OK (projeto sobe). **Falta TESTE ao vivo** (login/cadastro/save com internet).

- ✅ `_limpar_force_sync` → `rpc/limpar_force_sync` (credencial conferida).
- ✅ `adicionar_email` → `rpc/adicionar_email` (credencial conferida).

**Ainda usam acesso DIRETO (converter antes de fechar o RLS):**
- Fluxo Google (`contas.gd`): GET email→nome (já tem `buscar_nome_por_email`),
  PATCH senha por email, POST cadastro. ⚠️ "set-senha por email" é vetor de
  TAKEOVER se virar RPC anon ingênua — precisa verificar o token Google no
  servidor (edge function). Intersecta com "Google login no Android" (não
  resolvido). OPÇÃO p/ lançamento: **desligar login Google** no build e usar só
  nome+senha → some o vetor, fecha `usuarios` mais cedo.
- Rename: PATCH `usuarios` + DELETE `ranking` + rename do save. Precisa RPC
  `renomear_usuario` transacional.

### Passos restantes do lockdown
3b. Converter os caminhos diretos acima (force_sync, email, Google, rename).
4.  Fechar RLS: revogar `SELECT(senha)`/UPDATE/INSERT diretos de `usuarios` e
    `saves` do anon; manter só o necessário via RPC. (Contas de teste serão
    **resetadas** no lançamento → sem janela de espera.)
5.  Rodar `get_advisors` de novo p/ confirmar buracos fechados.

### LOCKDOWN APLICADO ✅ (2026-06-21) — migração `fechar_rls_lockdown`
Migração para login Google-only (Supabase Auth). Buracos críticos FECHADOS:
- **`usuarios`**: dropadas TODAS as policies abertas (select senha, insert, update).
  Anon não lê mais hash de senha. Só funções SECURITY DEFINER acessam (owner).
- **`saves`** (antiga): dropadas as policies anon (insert/select/update). Save de
  nuvem agora é `saves_cloud` (RLS por `auth.uid()`).
- **`ranking`**: leitura pública mantida; removidas as escritas abertas de anon
  (delete/insert/update `true`). Escrita só via RPC `submit_ranking_auth`
  (SECURITY DEFINER, valida) ou dono autenticado (`ranking_owner_update`).

Verificado: `get_advisors security` → nenhum `rls_policy_always_true` em
usuarios/saves/ranking. Restam só menores (arena_sessoes, avaliacoes, beta_skin).

Backend Google novo: `profiles`, `saves_cloud` (RLS por auth.uid()),
`submit_ranking_auth`. Cliente: `auth_supabase.gd` + branches Google em
`ranking_online.gd`. Login antigo (nome+senha) removido da UI.

### Pendências menores (pós-lançamento, baixo risco)
- `arena_sessoes` policy `anon_acesso_total` (ALL true) — se o PvP for usado.
- `avaliacoes` insert anon (spam de feedback).
- `beta_skin` insert anon (resgate de skin grátis).
- `function_search_path_mutable` em funções antigas (hardening).

## Buracos AINDA ABERTOS (precisam de release coordenado)

Causa raiz: a **anon key está embutida no binário distribuído** e as policies de
RLS são `USING true` / `CHECK true`. Qualquer um que extraia a anon key tem hoje:

| Tabela | Acesso `anon` aberto | Impacto |
|---|---|---|
| `usuarios` | SELECT (col. `senha`) | Baixa todos os hashes de senha → personifica qualquer jogador |
| `usuarios` | UPDATE | Altera qualquer conta |
| `saves`    | SELECT/INSERT/UPDATE | Lê/sobrescreve o save de nuvem de qualquer um |
| `ranking`  | DELETE/UPDATE/INSERT | Trigger já barra score/wave implausível; ainda dá p/ apagar/renomear linhas alheias |

Não dá para simplesmente dropar as policies: o cliente legítimo faz
leitura/escrita direta nessas tabelas para **login, cadastro, rename, avatar e
save de nuvem**. Dropar agora quebraria todos os clientes já instalados até
atualizarem.

### Chamadas diretas do cliente que precisam virar RPC (SECURITY DEFINER)
(`scripts/ranking_online.gd`, `scripts/menu/contas.gd`)

- `usuarios`: INSERT cadastro; PATCH (rename/email); SELECT login por
  `?senha=eq.<hash>`; SELECT nome por email (Google).
- `saves`: POST upsert; SELECT por player_id/nome; (download/upload de nuvem).
- `ranking`: PATCH avatar; DELETE+POST do fluxo de rename.

## Plano faseado (remediação)

**Fase B — `usuarios`:**
1. RPCs: `cadastrar_usuario`, `login_usuario(identificador, senha_hash)`,
   `renomear_usuario`, `buscar_nome_por_email(email)` — todos SECURITY DEFINER,
   nunca retornam a coluna `senha`.
2. Cliente passa a usar as RPCs.
3. Após release propagar: `REVOKE SELECT (senha) ON usuarios FROM anon`; remover
   policies de SELECT/UPDATE abertas (manter só o necessário via RPC).

**Fase C — `saves`:**
1. RPCs `upload_save(nome, senha_hash, data)` e `download_save(nome, senha_hash)`
   com checagem de credencial (só o dono lê/escreve o próprio save).
2. Cliente usa as RPCs.
3. Após release: fechar acesso direto anon a `saves`.

**Fase A restante — `ranking` (opcional, baixa prioridade):**
- RPC `atualizar_avatar_ranking` + RPC de rename; depois remover DELETE/UPDATE/
  INSERT diretos do anon (o trigger já cobre o caso de cheat de score).

### Ordem segura para virar o RLS
1. Implementar todas as RPCs (aditivo — não quebra nada).
2. Migrar o cliente para usar só RPCs.
3. **Lançar o update** e esperar a maioria dos jogadores atualizar.
4. Só então remover as policies abertas / revogar grants.

## Notas
- Rotacionar a anon key não resolve sozinho (a nova também vai no binário). A
  proteção real vem de RLS fechado + RPCs com checagem de credencial.
- Anti-cheat 100% (score forjado plausível sob o próprio nome) só com servidor
  autoritativo simulando a partida — fora de escopo para indie.
- Limpeza sugerida: a linha `Mod` (wave 150, score 16M = 106k/wave) é outlier de
  cheat/teste; considerar remover do ranking manualmente.
