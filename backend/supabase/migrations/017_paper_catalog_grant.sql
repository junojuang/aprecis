-- paper_catalog (migration 016) was created without inherited default
-- privileges, so writes failed with "permission denied for table paper_catalog".
-- The service role (seed-paper-catalog.ts and the papers→catalog sync trigger)
-- needs full access; anon/authenticated need SELECT to read the catalog (the
-- RLS policy already restricts them to read-only).
grant all on table paper_catalog to service_role;
grant select on table paper_catalog to anon, authenticated;
