-- Comunidade v2, lote 1 (S14): capa dos desafios.
-- PROPOSTA: revisar antes de aplicar.
--
-- Sem coluna nova: collective_challenges.cover_image_url já existe e
-- create_collective_challenge já recebe p_cover_image_url.
--
-- A capa é enviada antes de o desafio existir, então "criador" é o dono da
-- pasta: challenge-covers/<auth.uid()>/<arquivo>.
-- Se o INSERT no bucket for recusado, criar pelo painel com estes limites e
-- rodar só as policies.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'challenge-covers',
  'challenge-covers',
  true,
  5242880,
  array['image/jpeg', 'image/png']
)
on conflict (id) do nothing;

drop policy if exists challenge_covers_insert_own on storage.objects;
create policy challenge_covers_insert_own
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'challenge-covers'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists challenge_covers_update_own on storage.objects;
create policy challenge_covers_update_own
  on storage.objects for update to authenticated
  using (
    bucket_id = 'challenge-covers'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'challenge-covers'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists challenge_covers_delete_own on storage.objects;
create policy challenge_covers_delete_own
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'challenge-covers'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
