# Sistema de Login / Conta (design v1)

Data: 2026-06-12
Status: aprovado — métodos: e-mail (OTP) + jogar offline; visual estilo Grok/xAI

## Objetivo

Tela de login dark minimalista (referência: print do Grok — título central
"Faça login na sua conta", botões arredondados empilhados) usando o Supabase
Auth do projeto (já usado pelo ranking). V1 entrega identidade verificada;
fundação para save na nuvem, compras restauráveis e social.

## Decisões

- **Métodos v1**: "Entrar com e-mail" (OTP — código de 6 dígitos por e-mail,
  sem senha) e "Jogar offline" (mantém o fluxo atual de perfil local intacto).
- **Google/Apple/X**: fase 2 — exigem apps externos criados pelo usuário
  (Google Cloud Console; Apple paga US$99/ano; X dev portal). UI já deixa
  espaço para os botões.
- **Onde aparece**: primeiro boot (antes do menu) + botão ENTRAR/CONTA no
  perfil/config. Jogar offline nunca é bloqueado.
- **Vínculo**: conta logada ↔ player_id do ranking (nome travado por user_id).

## Arquitetura

- `scripts/auth.gd` (autoload novo `Auth`):
  - `solicitar_otp(email)` → POST `{SUPABASE_URL}/auth/v1/otp` {email}
  - `verificar_otp(email, codigo)` → POST `/auth/v1/verify`
    {email, token, type:"email"} → {access_token, refresh_token, user}
  - Sessão persistida em `user://sessao.json`; refresh automático via
    `/auth/v1/token?grant_type=refresh_token` quando expirar.
  - Sinais: `logado(user)`, `deslogado`, `erro(msg)`.
  - Reusar URL/anon key já presentes no projeto (ver ranking_online.gd /
    chave_tts.gd — conferir onde estão hoje).
- `scripts/menu/login.gd` (módulo padrão `var m`): tela visual
  - Fundo escuro, título central, botões arredondados (StyleBoxFlat
    corner_radius alto, branco/cinza sobre preto como na referência).
  - Estados: escolha de método → campo e-mail → campo código (6 dígitos) →
    sucesso/erro. LineEdit nativo para inputs.
  - "Jogar offline" → fluxo atual de nome de jogador.
- Ranking: quando logado, requests levam `Authorization: Bearer <token>`;
  no Supabase, coluna `user_id` na tabela de ranking + RLS: update do próprio
  nome/score só com user_id correspondente (migração SQL via MCP Supabase).

## Fases

1. Auth.gd + persistência de sessão + testes headless do flow OTP (mock).
2. Tela de login (visual Grok) + integração primeiro boot/config.
3. Vínculo ranking (migração SQL: user_id + RLS) — validar que jogadores
   offline continuam aparecendo (modo legado).
4. (Futuro) Google OAuth, save na nuvem.

## Riscos

- E-mails do Supabase free têm limite/hora — exibir cooldown no reenvio.
- Jogadores offline existentes: nada muda; login é opt-in.
- NUNCA gravar tokens no save compartilhado (sessao.json separado).

## Critério de aceite v1

Login por e-mail funcionando de ponta a ponta no jogo real; sessão sobrevive
a restart; "SAIR DA CONTA" desloga; jogar offline intacto; ranking aceita
ambos os modos.
