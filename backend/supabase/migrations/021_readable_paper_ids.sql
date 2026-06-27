-- Standardise public paper_id values to readable slugs.
--
-- Keep scholarly identity in `canonical_key` / `arxiv_id`; keep `paper_id` as
-- the clean app handle used in URLs, saves, progress, web lesson routing, and
-- related rails. This migration merges duplicate handles for the same work,
-- e.g. `loop:vision:controlnet` + `arxiv:2302.05543` -> `controlnet`.

create temporary table _paper_id_renames (
  old_id text primary key,
  new_id text not null,
  priority int not null default 100
) on commit drop;

insert into _paper_id_renames (old_id, new_id, priority) values
  ('loop:foundational:perceptron', 'perceptron', 20),
  ('rosenblatt:1958', 'perceptron', 10),
  ('loop:foundational:backprop', 'backprop', 20),
  ('rumelhart:1986', 'backprop', 10),
  ('loop:foundational:lenet', 'lenet', 20),
  ('lecun:1998', 'lenet', 10),
  ('loop:foundational:alexnet', 'alexnet', 20),
  ('krizhevsky:2012', 'alexnet', 10),
  ('loop:foundational:word2vec', 'word2vec', 20),
  ('arxiv:1301.3781', 'word2vec', 10),
  ('loop:foundational:seq2seq', 'seq2seq', 20),
  ('arxiv:1409.3215', 'seq2seq', 10),
  ('loop:foundational:gans', 'gans', 20),
  ('arxiv:1406.2661', 'gans', 10),
  ('loop:foundational:resnet', 'resnet', 20),
  ('arxiv:1512.03385', 'resnet', 10),
  ('loop:foundational:attention', 'attention', 20),
  ('arxiv:1706.03762', 'attention', 10),
  ('loop:foundational:gpt3', 'gpt3', 20),
  ('arxiv:2005.14165', 'gpt3', 10),
  ('loop:foundational:bert', 'bert', 20),
  ('arxiv:1810.04805', 'bert', 10),
  ('loop:foundational:instructgpt', 'instructgpt', 20),
  ('arxiv:2203.02155', 'instructgpt', 10),
  ('loop:foundational:chain-of-thought', 'chain-of-thought', 20),
  ('arxiv:2201.11903', 'chain-of-thought', 10),
  ('loop:foundational:scratchpad', 'scratchpad', 20),
  ('arxiv:2112.00114', 'scratchpad', 10),
  ('loop:foundational:self-consistency', 'self-consistency', 20),
  ('arxiv:2203.11171', 'self-consistency', 10),
  ('loop:foundational:tot', 'tree-of-thoughts', 20),
  ('arxiv:2305.10601', 'tree-of-thoughts', 10),
  ('loop:foundational:least-to-most', 'least-to-most', 20),
  ('arxiv:2205.10625', 'least-to-most', 10),
  ('loop:foundational:react', 'react', 20),
  ('arxiv:2210.03629', 'react', 10),
  ('loop:foundational:toolformer', 'toolformer', 20),
  ('arxiv:2302.04761', 'toolformer', 10),
  ('loop:foundational:grokking', 'grokking', 20),
  ('arxiv:2201.02177', 'grokking', 10),
  ('loop:foundational:deepseek-r1', 'deepseek-r1', 20),
  ('arxiv:2501.12948', 'deepseek-r1', 10),
  ('loop:vision:vit', 'vit', 20),
  ('arxiv:2010.11929', 'vit', 10),
  ('loop:vision:ddpm', 'ddpm', 20),
  ('arxiv:2006.11239', 'ddpm', 10),
  ('loop:vision:clip', 'clip', 20),
  ('arxiv:2103.00020', 'clip', 10),
  ('loop:vision:sd', 'stable-diffusion', 20),
  ('arxiv:2112.10752', 'stable-diffusion', 10),
  ('loop:vision:controlnet', 'controlnet', 20),
  ('arxiv:2302.05543', 'controlnet', 10),
  ('loop:vision:sam', 'sam', 20),
  ('arxiv:2304.02643', 'sam', 10),
  ('loop:language:t5', 't5', 20),
  ('arxiv:1910.10683', 't5', 10),
  ('loop:language:chinchilla', 'chinchilla', 20),
  ('arxiv:2203.15556', 'chinchilla', 10),
  ('loop:language:palm', 'palm', 20),
  ('arxiv:2204.02311', 'palm', 10),
  ('loop:language:llama', 'llama', 20),
  ('arxiv:2302.13971', 'llama', 10),
  ('loop:language:mixtral', 'mixtral', 20),
  ('arxiv:2401.04088', 'mixtral', 10),
  ('loop:reasoning:reflexion', 'reflexion', 20),
  ('arxiv:2303.11366', 'reflexion', 10),
  ('loop:systems:flashattention', 'flashattention', 20),
  ('arxiv:2205.14135', 'flashattention', 10),
  ('domingos:2012', 'useful-things-ml', 10),
  ('loop:domingos', 'useful-things-ml', 20),
  ('arxiv:2401.06816', 'creative-writing-homogenization', 10)
on conflict (old_id) do update set
  new_id = excluded.new_id,
  priority = excluded.priority;

-- New `papers` rows must exist before FK-backed tables can point at them.
with ranked as (
  select
    m.new_id,
    p.*,
    row_number() over (partition by m.new_id order by m.priority) as rn
  from _paper_id_renames m
  join papers p on p.paper_id = m.old_id
  where not exists (select 1 from papers existing where existing.paper_id = m.new_id)
)
insert into papers (
  paper_id, title, authors, abstract, source, url, pdf_url, published_at,
  score, score_breakdown, status, created_at, embedding, arxiv_category,
  semantic_scholar_id
)
select
  new_id, title, authors, abstract, source, url, pdf_url, published_at,
  score, score_breakdown, status, created_at, embedding, arxiv_category,
  semantic_scholar_id
from ranked
where rn = 1
on conflict (paper_id) do nothing;

with ranked as (
  select
    m.new_id,
    c.*,
    row_number() over (
      partition by m.new_id
      order by case when c.web_lesson_url is not null then 0 else 1 end, m.priority
    ) as rn
  from _paper_id_renames m
  join cards c on c.paper_id = m.old_id
)
insert into cards (
  paper_id, title, source, url, cards, created_at, blueprint, web_lesson_url
)
select
  new_id, title, source, url, cards, created_at, blueprint, web_lesson_url
from ranked
where rn = 1
on conflict (paper_id) do update set
  title = excluded.title,
  source = excluded.source,
  url = excluded.url,
  cards = excluded.cards,
  created_at = excluded.created_at,
  blueprint = excluded.blueprint,
  web_lesson_url = coalesce(excluded.web_lesson_url, cards.web_lesson_url);

with ranked as (
  select
    m.new_id,
    pc.*,
    row_number() over (
      partition by m.new_id
      order by
        case when pc.web_lesson_url is not null then 0 else 1 end,
        case when pc.origin = 'curated' then 0 else 1 end,
        m.priority
    ) as rn
  from _paper_id_renames m
  join paper_catalog pc on pc.paper_id = m.old_id
)
insert into paper_catalog (
  paper_id, canonical_key, title, authors, published_at, year, source, origin,
  topic, url, arxiv_id, created_at, updated_at, web_lesson_url
)
select
  new_id, canonical_key, title, authors, published_at, year, source, origin,
  topic, url, arxiv_id, created_at, now(), web_lesson_url
from ranked
where rn = 1
on conflict (paper_id) do update set
  canonical_key = excluded.canonical_key,
  title = excluded.title,
  authors = excluded.authors,
  published_at = excluded.published_at,
  year = excluded.year,
  source = excluded.source,
  origin = excluded.origin,
  topic = excluded.topic,
  url = excluded.url,
  arxiv_id = excluded.arxiv_id,
  updated_at = now(),
  web_lesson_url = coalesce(excluded.web_lesson_url, paper_catalog.web_lesson_url);

with ranked as (
  select
    m.new_id,
    pc.*,
    row_number() over (partition by m.new_id order by m.priority) as rn
  from _paper_id_renames m
  join processed_content pc on pc.paper_id = m.old_id
)
insert into processed_content (
  paper_id, headline, why_it_matters, core_ideas, eli5, analogy, visual,
  processed_at
)
select
  new_id, headline, why_it_matters, core_ideas, eli5, analogy, visual,
  processed_at
from ranked
where rn = 1
on conflict (paper_id) do update set
  headline = excluded.headline,
  why_it_matters = excluded.why_it_matters,
  core_ideas = excluded.core_ideas,
  eli5 = excluded.eli5,
  analogy = excluded.analogy,
  visual = excluded.visual,
  processed_at = excluded.processed_at;

-- Rebuild graph edges under the new ids, dropping self-edges created by merges.
create temporary table _paper_edges_renamed on commit drop as
select distinct
  coalesce(from_map.new_id, e.from_id) as from_id,
  coalesce(to_map.new_id, e.to_id) as to_id,
  e.kind,
  e.source,
  min(e.created_at) as created_at
from paper_edges e
left join _paper_id_renames from_map on from_map.old_id = e.from_id
left join _paper_id_renames to_map on to_map.old_id = e.to_id
group by 1, 2, 3, 4
having coalesce(from_map.new_id, e.from_id) <> coalesce(to_map.new_id, e.to_id);

delete from paper_edges e
using _paper_id_renames m
where e.from_id = m.old_id or e.to_id = m.old_id;

insert into paper_edges (from_id, to_id, kind, source, created_at)
select from_id, to_id, kind, source, created_at
from _paper_edges_renamed
on conflict (from_id, to_id, kind) do nothing;

update user_interactions ui
set paper_id = m.new_id
from _paper_id_renames m
where ui.paper_id = m.old_id;

with ranked as (
  select
    m.new_id,
    cp.*,
    row_number() over (partition by m.new_id order by cp.catalog_order nulls last, m.priority) as rn
  from _paper_id_renames m
  join curated_papers cp on cp.paper_id = m.old_id
)
insert into curated_papers (
  paper_id, title, canonical_key, served_paper_id, catalog_order, recorded_at,
  updated_at
)
select
  new_id,
  title,
  canonical_key,
  coalesce(served_map.new_id, served_paper_id),
  catalog_order,
  recorded_at,
  now()
from ranked
left join _paper_id_renames served_map on served_map.old_id = ranked.served_paper_id
where rn = 1
on conflict (paper_id) do update set
  title = excluded.title,
  canonical_key = excluded.canonical_key,
  served_paper_id = excluded.served_paper_id,
  catalog_order = excluded.catalog_order,
  updated_at = now();

delete from processed_content pc using _paper_id_renames m where pc.paper_id = m.old_id;
delete from cards c using _paper_id_renames m where c.paper_id = m.old_id;
delete from paper_catalog pc using _paper_id_renames m where pc.paper_id = m.old_id;
delete from curated_papers cp using _paper_id_renames m where cp.paper_id = m.old_id;
delete from papers p using _paper_id_renames m where p.paper_id = m.old_id;

-- From now on, newly ingested arXiv papers also get readable catalog ids when
-- no curated slug is known. The raw arXiv id still lives in canonical_key.
create or replace function readable_paper_slug(raw_id text, raw_title text)
returns text
language plpgsql
immutable
as $$
declare
  title_slug text;
begin
  if raw_id not like 'arxiv:%' then
    return raw_id;
  end if;

  title_slug := lower(coalesce(raw_title, raw_id));
  title_slug := regexp_replace(title_slug, '\([^)]*\)', '', 'g');
  title_slug := regexp_replace(title_slug, '[^a-z0-9]+', '-', 'g');
  title_slug := regexp_replace(title_slug, '(^-|-$)', '', 'g');
  title_slug := regexp_replace(title_slug, '-+', '-', 'g');
  title_slug := left(title_slug, 80);
  title_slug := regexp_replace(title_slug, '-$', '');

  return coalesce(nullif(title_slug, ''), replace(raw_id, ':', '-'));
end;
$$;

create or replace function sync_paper_catalog()
returns trigger
language plpgsql
as $$
declare
  catalog_id text;
begin
  catalog_id := readable_paper_slug(new.paper_id, new.title);

  insert into paper_catalog (
    paper_id, canonical_key, title, authors, published_at, year,
    source, origin, topic, url, arxiv_id, updated_at
  ) values (
    catalog_id,
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
