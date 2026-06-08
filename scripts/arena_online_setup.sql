-- Tabela de sessões de matchmaking para o Modo Arena
-- Executar no Supabase SQL Editor

create table if not exists arena_sessoes (
  id           uuid         default gen_random_uuid() primary key,
  player_id    text         not null,
  nome         text         not null default '',
  status       text         not null default 'buscando',  -- buscando | em_partida | finalizada
  matched_with text         not null default '',
  score        integer      not null default 0,
  wave         integer      not null default 1,
  hp           integer      not null default 100,
  criado_em    timestamptz  not null default now(),
  atualizado_em timestamptz not null default now()
);

-- Índices para as queries de matchmaking
create index if not exists idx_arena_sessoes_status       on arena_sessoes (status);
create index if not exists idx_arena_sessoes_player_id    on arena_sessoes (player_id);
create index if not exists idx_arena_sessoes_criado_em    on arena_sessoes (criado_em);

-- Permite acesso anônimo (mesmo padrão do resto do projeto)
alter table arena_sessoes enable row level security;

drop policy if exists "anon_acesso_total" on arena_sessoes;
create policy "anon_acesso_total" on arena_sessoes
  for all using (true) with check (true);

-- Limpeza automática: remove sessões com mais de 10 minutos (cron via pg_cron se disponível)
-- Se não tiver pg_cron, a limpeza é feita pelo cliente ao iniciar.
