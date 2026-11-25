-- Types
create type public.work_type as enum ('roman', 'poeme', 'fable', 'theatre');
create type public.work_status as enum ('brouillon', 'en_attente', 'publie', 'rejete');

-- Fonctions utilitaires pour les règles de sécurité
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and statut = 'actif'
  );
$$;

create or replace function public.is_author()
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'auteur' and statut = 'actif'
  );
$$;

-- Table des oeuvres
create table public.works (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  titre text not null check (char_length(titre) between 1 and 150),
  type public.work_type not null,
  resume text not null default '',
  langue text not null default 'fr',
  cover_path text,
  pdf_path text,
  nb_pages integer,
  droits_certifies boolean not null default false,
  statut public.work_status not null default 'brouillon',
  motif_rejet text,
  nb_vues integer not null default 0,
  nb_telechargements integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  validated_at timestamptz
);

create index works_statut_idx on public.works (statut, created_at desc);
create index works_author_idx on public.works (author_id);

-- Mise à jour automatique de la date de modification
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger works_updated_at
  before update on public.works
  for each row execute function public.touch_updated_at();

-- Sécurité
alter table public.works enable row level security;

-- Lecture : oeuvres publiées pour tous les membres, oeuvres personnelles pour l'auteur, tout pour l'admin
create policy "works_lecture"
  on public.works for select
  to authenticated
  using (statut = 'publie' or author_id = auth.uid() or public.is_admin());

-- Création : un auteur actif, uniquement en brouillon ou en attente, avec la case des droits cochée pour soumettre
create policy "works_creation"
  on public.works for insert
  to authenticated
  with check (
    author_id = auth.uid()
    and public.is_author()
    and statut in ('brouillon', 'en_attente')
    and (statut = 'brouillon' or droits_certifies)
  );

-- Modification : l'auteur sur ses oeuvres, sans jamais pouvoir publier lui-même
create policy "works_modification"
  on public.works for update
  to authenticated
  using (author_id = auth.uid() and public.is_author())
  with check (
    author_id = auth.uid()
    and statut in ('brouillon', 'en_attente')
    and (statut = 'brouillon' or droits_certifies)
  );

-- Suppression : l'auteur sur ses oeuvres
create policy "works_suppression"
  on public.works for delete
  to authenticated
  using (author_id = auth.uid());

-- Colonnes que l'application a le droit d'écrire
revoke insert, update on public.works from authenticated;
grant insert (
  author_id, titre, type, resume, langue,
  cover_path, pdf_path, nb_pages, droits_certifies, statut
) on public.works to authenticated;
grant update (
  titre, type, resume, langue,
  cover_path, pdf_path, nb_pages, droits_certifies, statut
) on public.works to authenticated;

-- Espaces de stockage
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('covers', 'covers', true, 5242880, array['image/jpeg', 'image/png']),
  ('pdfs', 'pdfs', false, 20971520, array['application/pdf'])
on conflict (id) do nothing;

-- Couvertures : lecture publique, écriture dans son propre dossier
create policy "covers_lecture"
  on storage.objects for select
  using (bucket_id = 'covers');

create policy "covers_ajout"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'covers'
    and (storage.foldername(name))[1] = auth.uid()::text
    and public.is_author()
  );

create policy "covers_remplacement"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'covers'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "covers_suppression"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'covers'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- PDF : lecture seulement si l'oeuvre est publiée, ou pour son auteur, ou pour l'admin
create policy "pdfs_lecture"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'pdfs'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
      or exists (
        select 1 from public.works w
        where w.pdf_path = name and w.statut = 'publie'
      )
    )
  );

create policy "pdfs_ajout"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'pdfs'
    and (storage.foldername(name))[1] = auth.uid()::text
    and public.is_author()
  );

create policy "pdfs_remplacement"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'pdfs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "pdfs_suppression"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'pdfs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );