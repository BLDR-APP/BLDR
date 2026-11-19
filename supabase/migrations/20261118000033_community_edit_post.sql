-- Comunidade v2, lote 1: editar o texto do próprio post (D2).
-- PROPOSTA: revisar antes de aplicar.
--
-- A policy sozinha deixaria o autor reescrever todo o payload pelo cliente
-- (volume, PRs, tipo do post). O trigger limita a edição à legenda.

alter table public.community_feed
  add column if not exists edited_at timestamptz;

drop policy if exists feed_update_own on public.community_feed;
create policy feed_update_own
  on public.community_feed for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- SECURITY INVOKER de propósito: current_user continua 'authenticated' em
-- chamadas do app e muda em funções SECURITY DEFINER e no service_role,
-- que seguem livres.
create or replace function public.community_feed_guard_client_update()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if current_user <> 'authenticated' then
    return new;
  end if;

  if new.id is distinct from old.id
     or new.user_id is distinct from old.user_id
     or new.event_type is distinct from old.event_type
     or new.visibility is distinct from old.visibility
     or new.squad_id is distinct from old.squad_id
     or new.created_at is distinct from old.created_at
     or (new.payload - 'caption') is distinct from (old.payload - 'caption') then
    raise exception 'only the post caption can be edited'
      using errcode = '42501';
  end if;

  if char_length(coalesce(new.payload ->> 'caption', '')) > 2000 then
    raise exception 'caption too long' using errcode = '22001';
  end if;

  new.edited_at := now();
  return new;
end;
$$;

drop trigger if exists trg_community_feed_guard_client_update
  on public.community_feed;
create trigger trg_community_feed_guard_client_update
  before update on public.community_feed
  for each row execute function public.community_feed_guard_client_update();
