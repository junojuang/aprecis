-- Record the Apple Sign-In identity on the profile.
-- Supabase Auth already stores the Apple OAuth identity in auth.identities,
-- but Apple only hands the user's full name to the client ONCE (on the first
-- authorization). The iOS app captures it then and writes it here as
-- display_name, alongside the stable Apple user identifier for audit.
alter table public.profiles add column if not exists apple_user_id text;

create index if not exists profiles_apple_user_id_idx
  on public.profiles (apple_user_id);
