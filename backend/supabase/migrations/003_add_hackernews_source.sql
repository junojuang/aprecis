alter table papers
  drop constraint if exists papers_source_check;

alter table papers
  add constraint papers_source_check
  check (source in ('arxiv', 'twitter', 'github', 'rss', 'hackernews'));
