-- 002_avatars_storage.sql
-- Avatars bucket + RLS-style storage policies (15_STORAGE.md - Bucket 01).
-- Path convention: avatars/{user_id}/profile.jpg

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do nothing;

-- A user may upload/replace/delete only files under their own user_id folder.
create policy "avatar_insert_own_folder"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatar_update_own_folder"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatar_delete_own_folder"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Read: any authenticated user may view avatars (needed to show family
-- members' avatars once the Family feature lands) — 15_STORAGE.md notes
-- avatars are viewable "inside authorized family context"; a stricter
-- family-scoped read policy replaces this one in the Family phase.
create policy "avatar_read_authenticated"
  on storage.objects for select
  using (bucket_id = 'avatars' and auth.role() = 'authenticated');
