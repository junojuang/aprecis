-- ─── Dedupe paper_catalog: one row per work ──────────────────────────────────
-- Migration 016 both (a) backfilled ingested rows from `papers` and (b) the
-- seed script added the hand-curated canon. Six canon works existed in BOTH
-- (same canonical_key, different paper_id), so the catalog showed duplicates —
-- an `arxiv:…` (ingested) row and a `loop:…` (curated) row for the same paper.
--
-- The Swift-authored curated row is authoritative (cleaner title/topic), so we
-- drop the ingested duplicate wherever a curated row covers the same work.

delete from paper_catalog pc
using paper_catalog cur
where pc.origin = 'ingested'
  and cur.origin = 'curated'
  and cur.canonical_key = pc.canonical_key
  and cur.paper_id <> pc.paper_id;

-- Keep it that way: when an ingested paper lands whose work is already covered
-- by a curated row, the trigger must NOT insert a second row. Replaces the
-- sync function from migration 016 with a curated-aware version.
create or replace function sync_paper_catalog()
returns trigger
language plpgsql
as $$
declare
  ck text := case
    when new.paper_id like 'arxiv:%'
      then 'arxiv:' || regexp_replace(lower(split_part(new.paper_id, ':', 2)), 'v[0-9]+$', '')
    else new.paper_id
  end;
begin
  -- A curated (Swift-authored) row already represents this work → leave it be.
  if exists (
    select 1 from paper_catalog
    where canonical_key = ck
      and origin = 'curated'
      and paper_id <> new.paper_id
  ) then
    return new;
  end if;

  insert into paper_catalog (
    paper_id, canonical_key, title, authors, published_at, year,
    source, origin, topic, url, arxiv_id, updated_at
  ) values (
    new.paper_id,
    ck,
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
