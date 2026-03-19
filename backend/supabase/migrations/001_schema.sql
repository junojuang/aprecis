-- ─── Extensions ───────────────────────────────────────────────────────────────
create extension if not exists "pgmq";
create extension if not exists "pg_cron";

-- ─── Papers ───────────────────────────────────────────────────────────────────
create table if not exists papers (
  paper_id         text primary key,
  title            text not null,
  authors          text[] not null default '{}',
  abstract         text not null default '',
  source           text not null check (source in ('arxiv', 'twitter', 'github', 'rss')),
  url              text not null,
  pdf_url          text,
  published_at     timestamptz not null,
  score            float not null default 0,
  score_breakdown  jsonb not null default '{}',
  status           text not null default 'queued'
                     check (status in ('queued', 'processing', 'processed', 'failed')),
  created_at       timestamptz not null default now()
);

create index if not exists papers_score_idx   on papers (score desc);
create index if not exists papers_status_idx  on papers (status);
create index if not exists papers_created_idx on papers (created_at desc);

-- ─── Processed Content ────────────────────────────────────────────────────────
create table if not exists processed_content (
  paper_id        text primary key references papers (paper_id) on delete cascade,
  headline        text not null,
  why_it_matters  text not null,
  core_ideas      text[] not null default '{}',
  eli5            text not null,
  analogy         text not null,
  visual          jsonb not null default '{}',
  processed_at    timestamptz not null default now()
);

-- ─── Cards ────────────────────────────────────────────────────────────────────
create table if not exists cards (
  paper_id    text primary key references papers (paper_id) on delete cascade,
  title       text not null,
  source      text not null,
  url         text not null,
  cards       jsonb not null default '[]',
  created_at  timestamptz not null default now()
);

create index if not exists cards_created_idx on cards (created_at desc);

-- ─── User Interactions ────────────────────────────────────────────────────────
create table if not exists user_interactions (
  id             bigserial primary key,
  paper_id       text not null references papers (paper_id) on delete cascade,
  action         text not null check (action in ('swiped_left', 'swiped_right', 'saved', 'shared')),
  interacted_at  timestamptz not null default now()
);

create index if not exists interactions_paper_idx  on user_interactions (paper_id);
create index if not exists interactions_action_idx on user_interactions (action);

-- ─── Enable RLS (read-only public access for cards) ──────────────────────────
alter table cards enable row level security;
create policy "cards_public_read" on cards for select using (true);

alter table user_interactions enable row level security;
create policy "interactions_insert" on user_interactions for insert with check (true);

-- ─── PGMQ Queue ───────────────────────────────────────────────────────────────
select pgmq.create('paper_processing');

-- ─── pg_cron Jobs ─────────────────────────────────────────────────────────────
-- Ingest every 90 minutes
select cron.schedule(
  'cron-ingest',
  '*/90 * * * *',
  $$select net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/cron-ingest',
    headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.service_role_key'))
  )$$
);

-- Process queue every 5 minutes
select cron.schedule(
  'process-queue',
  '*/5 * * * *',
  $$select net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/process-queue',
    headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.service_role_key'))
  )$$
);
