-- Track each user's lifetime papers-read count on their profile.
-- Replaces daily_goal storage: daily_goal is now a local-only app setting
-- (UserDefaults), so the profiles table no longer mirrors it.

alter table public.profiles add column if not exists papers_read int not null default 0;
alter table public.profiles drop column if exists daily_goal;

-- Atomic per-user increment. security definer so the +1 happens server-side
-- in one statement (no read-modify-write race from the client); scoped to the
-- caller's own row via auth.uid(). Returns the new running total.
create or replace function public.increment_papers_read()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  new_count int;
begin
  update public.profiles
     set papers_read = papers_read + 1
   where id = auth.uid()
   returning papers_read into new_count;
  return new_count;
end;
$$;

grant execute on function public.increment_papers_read() to authenticated;
