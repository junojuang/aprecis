-- The graph stage (process-queue, add-paper, backfill scripts) runs as the
-- service role and INSERTs into paper_edges. Migration 009 granted only SELECT
-- to anon/authenticated; the service role had no grant at all, so every
-- citation-edge write failed with "permission denied for table paper_edges".
grant all on table paper_edges to service_role;
