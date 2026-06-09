-- Store the user's email on their profile row.
-- Supabase Auth already keeps the email in auth.users.email (captured from the
-- Apple id_token at sign-in, including Hide-My-Email relay addresses). This
-- mirrors it onto public.profiles so it shows up alongside display_name and is
-- queryable without joining the auth schema.

alter table public.profiles add column if not exists email text;

-- Recreate the new-user trigger so it copies email (and any name Supabase
-- received in the OAuth metadata) onto the profile at creation time.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    nullif(trim(coalesce(new.raw_user_meta_data->>'full_name',
                         new.raw_user_meta_data->>'name', '')), '')
  )
  on conflict (id) do update
    set email = excluded.email;
  return new;
end;
$$;

-- Backfill email for every existing profile from auth.users.
update public.profiles p
   set email = u.email
  from auth.users u
 where u.id = p.id
   and p.email is distinct from u.email;
