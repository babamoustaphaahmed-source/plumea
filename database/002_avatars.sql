-- Espace de stockage des photos de profil (public en lecture)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  2097152,
  array['image/jpeg', 'image/png']
)
on conflict (id) do nothing;

-- Tout le monde peut voir les photos de profil
create policy "avatars_lecture"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- Un membre ne peut écrire que dans son propre dossier (nommé avec son identifiant)
create policy "avatars_ajout"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_remplacement"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_suppression"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );