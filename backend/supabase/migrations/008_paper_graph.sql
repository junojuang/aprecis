-- ─── Paper Graph: embeddings + citation edges ────────────────────────────────
-- Adds the data layer behind the Explore rails (Builds on / Led to / Adjacent)
-- so every ingested paper gets connections automatically, no hand-curation.

-- pgvector for semantic similarity (Adjacent rail).
create extension if not exists vector;

-- ─── Embeddings + metadata on papers ─────────────────────────────────────────
alter table papers add column if not exists embedding          vector(1536);
alter table papers add column if not exists arxiv_category      text;
alter table papers add column if not exists semantic_scholar_id text;

-- ANN index for cosine kNN. hnsw is exact-ish and fast; falls back gracefully
-- if the build lacks hnsw (older pgvector) — swap to ivfflat then.
create index if not exists papers_embedding_idx
  on papers using hnsw (embedding vector_cosine_ops);

-- ─── Directional citation edges ──────────────────────────────────────────────
-- Only the raw `cites` direction is stored:
--   Builds on(X) = outgoing cites  (from_id = X)
--   Led to(X)    = incoming cites  (to_id   = X)
-- Option 1 from the spec: both endpoints must exist in `papers` (FK enforced),
-- so the rails stay internally consistent. Edges for not-yet-ingested papers
-- appear later as the corpus grows.
create table if not exists paper_edges (
  from_id    text not null references papers (paper_id) on delete cascade,
  to_id      text not null references papers (paper_id) on delete cascade,
  kind       text not null check (kind in ('cites')),
  source     text not null default 'semantic_scholar',
  created_at timestamptz not null default now(),
  primary key (from_id, to_id, kind)
);

create index if not exists paper_edges_to_idx   on paper_edges (to_id, kind);
create index if not exists paper_edges_from_idx on paper_edges (from_id, kind);

-- Public read access (rails are served through the public anon endpoint).
alter table paper_edges enable row level security;
create policy "paper_edges_public_read" on paper_edges for select using (true);

-- ─── Adjacent kNN RPC ────────────────────────────────────────────────────────
-- PostgREST cannot order by `embedding <=> $param`, so kNN goes through an RPC.
-- Returns nearest papers by cosine distance, excluding the focal paper and any
-- ids passed in `exclude_ids` (the citation lineage). `arxiv_category` rides
-- along so the caller can pick a cross-category "surprise" pick without a
-- second round trip.
create or replace function match_papers(
  query_id     text,
  exclude_ids  text[] default '{}',
  match_count  int    default 12
)
returns table (
  paper_id       text,
  title          text,
  arxiv_category text,
  distance       float
)
language sql stable
as $$
  select p.paper_id,
         p.title,
         p.arxiv_category,
         p.embedding <=> q.embedding as distance
  from papers p,
       (select embedding from papers where paper_id = query_id) q
  where p.paper_id <> query_id
    and p.embedding is not null
    and q.embedding is not null
    and not (p.paper_id = any(exclude_ids))
  order by p.embedding <=> q.embedding
  limit match_count;
$$;
