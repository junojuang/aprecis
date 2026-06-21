-- Server-driven bespoke lessons. When set, the iOS app renders this paper's
-- lesson from a self-contained web bundle (HTML/CSS/JS) in a WKWebView instead
-- of a native SwiftUI reader. This lets new premium lessons ship as data
-- (upload bundle to Storage, set this URL) with no App Store update.
--
-- Convention: a single self-contained .html (or an index.html in a per-paper
-- folder) uploaded to the public `web-lessons` Storage bucket, e.g.
--   https://<project>.supabase.co/storage/v1/object/public/web-lessons/grokking/index.html
alter table cards
  add column if not exists web_lesson_url text;
