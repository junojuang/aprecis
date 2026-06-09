-- curated_papers is an audit table: the service role (seed scripts, backend)
-- needs full access; anon/authenticated get nothing (no public exposure).
-- Migration 010's create table did not inherit default privileges.
grant all on table curated_papers to service_role;
