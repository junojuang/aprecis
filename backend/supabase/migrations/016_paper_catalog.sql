-- ─── Paper Catalog: one row per paper that exists in the app ──────────────────
-- Single queryable index of EVERYTHING the app can show: the backend-ingested
-- feed (arXiv / Twitter / GitHub / RSS) AND the hand-curated canon shipped
-- client-side as `loop:` ids. Other tables are partial views of this:
--   • `papers`         — ingested rows only (full pipeline payload)
--   • `curated_papers` — manifest of the canon (no dates / display metadata)
-- This table holds just the lightweight display metadata (title, published
-- date, topic, source) so "what papers do we have?" is a single SELECT.
--
-- Dedupe across ingestion paths is via `canonical_key` (BraceIdentity): the
-- same work ingested as `arxiv:…` and curated as `loop:…` shares one key, so
-- `select distinct on (canonical_key) …` collapses them.

create table if not exists paper_catalog (
  paper_id       text primary key,                 -- app handle: arxiv:… , loop:… , etc.
  canonical_key  text not null,                    -- BraceIdentity key (dedupe across paths)
  title          text not null,
  authors        text[] not null default '{}',
  published_at   timestamptz,                       -- null when only a coarse year is known
  year           int,                               -- fallback for canon works
  source         text not null default 'unknown',   -- arxiv | twitter | github | rss | curated …
  origin         text not null default 'ingested'
                   check (origin in ('ingested', 'curated')),
  topic          text,                              -- similarity-graph cluster, if known
  url            text,
  arxiv_id       text,                              -- e.g. 1706.03762, when applicable
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists paper_catalog_published_idx on paper_catalog (published_at desc nulls last);
create index if not exists paper_catalog_canonical_idx on paper_catalog (canonical_key);
create index if not exists paper_catalog_origin_idx    on paper_catalog (origin);

-- Public read: the iOS app (anon key) reads this for the catalog / "Latest"
-- list. Writes happen only through the service role (which bypasses RLS) or
-- the sync trigger below.
alter table paper_catalog enable row level security;
create policy "paper_catalog_public_read" on paper_catalog for select using (true);

-- ─── Keep the catalog in sync with ingested `papers` ──────────────────────────
-- Every insert/update on `papers` mirrors the display metadata into the
-- catalog. Canonical key is approximated in SQL: arXiv ids normalise to
-- `arxiv:<id>` (version suffix stripped); everything else keys on its id.
create or replace function sync_paper_catalog()
returns trigger
language plpgsql
as $$
begin
  insert into paper_catalog (
    paper_id, canonical_key, title, authors, published_at, year,
    source, origin, topic, url, arxiv_id, updated_at
  ) values (
    new.paper_id,
    case
      when new.paper_id like 'arxiv:%'
        then 'arxiv:' || regexp_replace(lower(split_part(new.paper_id, ':', 2)), 'v[0-9]+$', '')
      else new.paper_id
    end,
    new.title,
    new.authors,
    new.published_at,
    extract(year from new.published_at)::int,
    new.source,
    'ingested',
    new.arxiv_category,
    new.url,
    case when new.paper_id like 'arxiv:%' then split_part(new.paper_id, ':', 2) else null end,
    now()
  )
  on conflict (paper_id) do update set
    title        = excluded.title,
    authors      = excluded.authors,
    published_at = excluded.published_at,
    year         = excluded.year,
    source       = excluded.source,
    topic        = excluded.topic,
    url          = excluded.url,
    arxiv_id     = excluded.arxiv_id,
    updated_at   = now();
  return new;
end;
$$;

drop trigger if exists papers_sync_catalog on papers;
create trigger papers_sync_catalog
  after insert or update on papers
  for each row execute function sync_paper_catalog();

-- ─── Backfill: existing ingested papers ───────────────────────────────────────
insert into paper_catalog (
  paper_id, canonical_key, title, authors, published_at, year,
  source, origin, topic, url, arxiv_id
)
select
  p.paper_id,
  case
    when p.paper_id like 'arxiv:%'
      then 'arxiv:' || regexp_replace(lower(split_part(p.paper_id, ':', 2)), 'v[0-9]+$', '')
    else p.paper_id
  end,
  p.title,
  p.authors,
  p.published_at,
  extract(year from p.published_at)::int,
  p.source,
  'ingested',
  p.arxiv_category,
  p.url,
  case when p.paper_id like 'arxiv:%' then split_part(p.paper_id, ':', 2) else null end
from papers p
on conflict (paper_id) do nothing;

-- ─── Curated canon ────────────────────────────────────────────────────────────
-- The hand-curated `loop:` papers authored in Swift are populated by
-- backend/scripts/seed-paper-catalog.ts (driven by data/curated-paper-catalog.json),
-- matching the convention used for `curated_papers`. Run it after this migration:
--   cd backend && deno run --allow-net --allow-env --allow-read scripts/seed-paper-catalog.ts
