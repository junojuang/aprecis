-- paper_edges: RLS policy allows the rows, but the anon/authenticated roles
-- still need a table-level GRANT for PostgREST to read it. (Migration 008
-- enabled RLS + a select policy but missed the grant.)
grant select on paper_edges to anon, authenticated;
