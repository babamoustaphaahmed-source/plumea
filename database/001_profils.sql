-- Types
create type public.user_role as enum ('lecteur', 'auteur', 'admin');
create type public.user_status as enum ('actif', 'suspendu');

-- Table des profils
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nom text not null default '',
  photo_url text,
  bio text,
  role public.user_role not null default 'lecteur',
  statut public.user_status not null default 'actif',
  created_at timestamptz not null default now()
);

-- Sécurité : activer les règles ligne par ligne
alter table public.profiles enable row level security;

-- Tout membre connecté peut lire les profils
create policy "profiles_lecture"
  on public.profiles for select
  to authenticated
  using (true);

-- Un membre ne peut modifier que son propre profil...
create policy "profiles_modification"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ...et uniquement ces colonnes (jamais role ni statut)
revoke update on public.profiles from authenticated;
grant update (nom, photo_url, bio) on public.profiles to authenticated;

-- Création automatique du profil à l'inscription
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  role_choisi public.user_role := 'lecteur';
begin
  if new.raw_user_meta_data ->> 'role' = 'auteur' then
    role_choisi := 'auteur';
  end if;

  insert into public.profiles (id, nom, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nom', ''),
    role_choisi
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();