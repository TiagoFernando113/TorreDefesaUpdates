# Login com Google via Supabase Auth — Design

Data: 2026-06-20
Projeto Supabase: `npbqezpfjrjvsqwvgtfy` (torredefesa)
Status: aprovado (usuário delegou: "só resolve")

## Objetivo

Substituir o login caseiro (tabela `usuarios` com hash de senha + acesso anon
às tabelas) por **Supabase Auth (GoTrue) com Google OAuth**, fechando o RLS de
forma natural via `auth.uid()`. Resolve de uma vez:
- o vazamento de hash de senha (a tabela de senha some);
- o login Google quebrado/insguro (quem valida o Google passa a ser o servidor);
- o login Google no Android (deep link no lugar do loopback de PC);
- o CLIENT_SECRET embutido no binário (vai para o painel do Supabase).

## Decisões (travadas no brainstorming)

1. **Só Google** no lançamento. Sem email/senha, sem nome/senha caseiro.
2. **Jogar sem conta** continua, porém **100% local** (sem nuvem/ranking).
3. 1º login Google → jogador escolhe um **apelido** (campo público do ranking).
4. **Reset**: contas de teste antigas (`usuarios`/`saves`/`ranking`) não migram.
   Todo mundo entra fresco. (Eram contas de teste do dev.)
5. Aparelho **lembra** a sessão (refresh token salvo criptografado → auto-login).

## Fora de escopo (YAGNI)

- Login email/senha.
- Migração das contas antigas.
- Vincular conta antiga (nome+senha) a uma conta Google.

## Arquitetura

### Identidade
- GoTrue gera, por jogador, um **UUID estável** (`auth.uid()`) + JWT
  (access token curto + refresh token longo).
- Google OAuth configurado **no painel do Supabase** (Auth → Providers →
  Google). O Supabase guarda o client secret; o jogo nunca o vê.

### Banco (migração)
- **Nova tabela `profiles`**: `id uuid PK references auth.users(id)`,
  `apelido text`, `avatar_idx int`, `criado_em timestamptz`,
  `atualizado_em timestamptz`. RLS: dono lê/escreve o próprio (`auth.uid() = id`);
  leitura pública do `apelido`/`avatar_idx` para mostrar no ranking.
- **`saves`**: re-chavear para `user_id uuid references auth.users(id)` (PK).
  RLS: `auth.uid() = user_id` para SELECT/INSERT/UPDATE/DELETE.
- **`ranking`**: passar a referenciar `user_id uuid` (dono). SELECT público;
  INSERT/UPDATE só do dono (`auth.uid() = user_id`). Mantém `nome` (apelido
  desnormalizado) + `avatar_idx` para exibição. Trigger de plausibilidade de
  score/wave (já existe) permanece.
- **Remover** ao final: tabela `usuarios` e os porteiros caseiros
  (`login_usuario`, `cadastrar_usuario`, `login_por_player_id`,
  `buscar_nome_por_email`, `upload_save`, `download_save`, `apagar_save`,
  `limpar_saves_orfaos`, `_auth_usuario`). Eram do caminho nome+senha.
- `submit_ranking` (RPC) reescrito para `SECURITY INVOKER` usando `auth.uid()`
  (ou mantido `DEFINER` derivando o dono do JWT). Decidir na implementação.

### Fluxo OAuth (PKCE, browser do sistema)
1. Jogo gera `code_verifier`/`code_challenge` (PKCE) e abre no navegador a URL
   `…/auth/v1/authorize?provider=google&redirect_to=<deep link>&code_challenge=…`.
2. Jogador loga no Google. Supabase redireciona para o **deep link** do app
   com `?code=…`.
3. App captura o deep link, troca o `code` por sessão em
   `…/auth/v1/token?grant_type=pkce` → recebe access + refresh token.
4. Tokens salvos **criptografados** (reusar AES de `salvar.gd`).
5. Em todas as chamadas: header `Authorization: Bearer <access_token>`.
6. Access expirou → renova via `…/auth/v1/token?grant_type=refresh_token`.

#### Captura do redirect por plataforma
- **Android**: deep link via custom scheme (ex.: `cyron://auth`) declarado no
  `AndroidManifest` (intent-filter). Config no export do Godot.
- **PC (Windows/itch)**: reusar o servidor loopback que já existe em
  `google_auth.gd` como `redirect_to=http://127.0.0.1:<porta>` OU o mesmo custom
  scheme via protocolo registrado. Loopback é o caminho de menor atrito no PC.

### Módulos no cliente (Godot) — isolados
- **NOVO `scripts/auth_supabase.gd`** (autoload `Auth`): toda a lógica GoTrue
  (abrir OAuth, capturar redirect, trocar code, guardar/renovar token, logout).
  Exposto via API simples: `entrar_google()`, `sessao_valida()`,
  `bearer()`, `sair()`, sinais `login_ok`/`login_falhou`.
- **`ranking_online.gd`**: trocar `apikey/anon` por `Auth.bearer()` nas chamadas;
  saves/ranking passam a usar `auth.uid()` (RLS). Remover os porteiros.
- **`scripts/menu/contas.gd`**: tela deslogada = botão "Entrar com Google" +
  "Jogar sem conta". Pós-login novo → tela de escolha de apelido.
- **`scripts/salvar.gd`**: guardar/ler tokens criptografados; `player_id` vira o
  `auth.uid()`.
- **Remover/aposentar**: `google_auth.gd` antigo (loopback + CLIENT_SECRET) —
  o secret sai do binário (passa pro Supabase). Manter só o helper de loopback
  se reaproveitado no PC.

## Tarefas que SÓ o usuário faz (painel — guiado clique a clique)
1. **Google Cloud Console**: no OAuth client existente, adicionar a redirect URI
   do Supabase: `https://npbqezpfjrjvsqwvgtfy.supabase.co/auth/v1/callback`.
2. **Supabase → Auth → Providers → Google**: ligar e colar Client ID + Secret.
3. **Supabase → Auth → URL Configuration**: adicionar os redirect permitidos
   (deep link do Android + loopback do PC).

## Reset (no lançamento)
- Apagar linhas de `usuarios`, `saves`, `ranking` de teste (ou dropar/migrar
  `usuarios`). Fazer **só na virada do lançamento**, não agora.

## Testes
- Headless não cobre OAuth (precisa navegador + redirect). Plano:
  - Parse-check de todos os scripts (test_parse_menu).
  - Teste manual no PC: entrar com Google → escolher apelido → salvar → fechar →
    reabrir (auto-login) → save volta → aparece no ranking.
  - Teste manual no Android (APK debug): mesmo fluxo + deep link.
- Testes de unidade do que der (parse de token, expiração, montagem de URL PKCE).

## Riscos
- OAuth + deep link é chato de acertar e difícil de testar sem device.
- Re-chavear `saves`/`ranking` para `auth.uid()` toca dados — fazer com reset.
- Renovação de token / expiração mal feita = jogador "cai" da conta.
- Dependência de config no painel (sem isso, nada loga).

## Ordem de implementação (alto nível)
1. DB: `profiles` + RLS, `saves`/`ranking` com `user_id` + RLS (em branch/reset).
2. Painel: ligar Google provider (usuário, guiado).
3. `auth_supabase.gd` (OAuth PKCE + token) — PC primeiro (loopback).
4. Ligar `contas.gd` + escolha de apelido.
5. `ranking_online.gd` + saves usando Bearer/auth.uid(); remover porteiros.
6. Android: deep link no export + teste em APK.
7. Fechar RLS / dropar `usuarios` + porteiros. Rodar `get_advisors`.
