-- Server-driven web lessons for the CURATED canon (the hand-written `loop:`
-- papers). Unlike ingested feed papers (which carry web_lesson_url on `cards`,
-- see migration 019), curated loops have no `cards` row, they render from
-- content shipped in the app. This column lets a curated loop be upgraded to a
-- premium web bundle with no App Store update: set the URL here and the client
-- fetches it via GET /serve-cards/web-lessons.
--
-- Keyed by the app's paper_id (e.g. 'loop:foundational:grokking'), so the client
-- looks it up directly. paper_catalog already has a public read policy.
alter table paper_catalog
  add column if not exists web_lesson_url text;
