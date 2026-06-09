-- Waitlist for landing-page early-access signups.
-- Idempotent: safe to run on a fresh DB, on the existing project (which
-- already has a waitlist with extra columns), and on re-runs.

create table if not exists public.waitlist (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  created_at timestamptz not null default now()
);

-- Pre-existing schema had name/role/current/goals as required columns.
-- Drop NOT NULL so the email-only client can insert without friction.
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_schema='public' and table_name='waitlist' and column_name='name') then
    alter table public.waitlist alter column name drop not null;
  end if;
  if exists (select 1 from information_schema.columns
             where table_schema='public' and table_name='waitlist' and column_name='role') then
    alter table public.waitlist alter column role drop not null;
  end if;
  if exists (select 1 from information_schema.columns
             where table_schema='public' and table_name='waitlist' and column_name='current') then
    alter table public.waitlist alter column "current" drop not null;
  end if;
  if exists (select 1 from information_schema.columns
             where table_schema='public' and table_name='waitlist' and column_name='goals') then
    alter table public.waitlist alter column goals drop not null;
  end if;
end $$;

-- Case-insensitive dedup. Re-submits hit ON CONFLICT and the client treats
-- 409 as success (already signed up).
create unique index if not exists waitlist_email_lower_key
  on public.waitlist (lower(email));

-- RLS: only allow anon/authenticated to INSERT. No reads, no updates,
-- no deletes from the client. Service-role key bypasses RLS for admin ops.
alter table public.waitlist enable row level security;

drop policy if exists "anon insert waitlist" on public.waitlist;
create policy "anon insert waitlist"
  on public.waitlist
  for insert
  to anon, authenticated
  with check (
    email is not null
    and length(trim(email)) between 3 and 320
    and email like '%_@_%._%'
  );
