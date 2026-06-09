-- ─── Curated paper registry ──────────────────────────────────────────────────
-- Audit / track record of every hand-curated paper shipped client-side in the
-- iOS app (the `loop:` canon). This table does NOT serve content — the real
-- decks live in `papers` / `cards`. It is a manifest: which papers are curated,
-- in what catalog order, their title, and how they map to a served row.
--
-- Source of truth for the id list: data/curated-paper-catalog.json
-- Populated by backend/scripts/seed-curated-registry.ts.

create table if not exists curated_papers (
  paper_id        text primary key,       -- curated loop id, e.g. loop:foundational:perceptron
  title           text not null,
  canonical_key   text,                   -- BraceIdentity canonical key; links to a `papers` row when seeded
  served_paper_id text,                   -- backend paper_id of the served deck, if one exists
  catalog_order   int  not null default 0,-- position in the shipped iOS catalog
  recorded_at     timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists curated_papers_canonical_idx on curated_papers (canonical_key);

-- Audit table: service-role only. No public select policy → the anon key
-- (iOS app) cannot read it; it is purely an internal record.
alter table curated_papers enable row level security;
