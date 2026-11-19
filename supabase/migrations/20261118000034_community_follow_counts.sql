-- Comunidade v2, lote 1 (S11): contadores de seguidores do perfil social.
-- PROPOSTA: revisar antes de aplicar.
--
-- Não conta perfis com bloqueio em qualquer direção com p_user. Se quem
-- consulta e p_user têm bloqueio entre si, devolve zero.

create or replace function public.follow_counts(p_user uuid)
returns table (followers bigint, following bigint)
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  with blocked as (
    select blocked_id as user_id from public.community_blocks where blocker_id = p_user
    union
    select blocker_id from public.community_blocks where blocked_id = p_user
  ),
  visible as (
    select auth.uid() is not null
       and (auth.uid() = p_user
            or not exists (select 1 from blocked b where b.user_id = auth.uid())) as ok
  )
  select
    case when v.ok then (
      select count(*) from public.community_follows f
      where f.followed_id = p_user
        and not exists (select 1 from blocked b where b.user_id = f.follower_id)
    ) else 0 end,
    case when v.ok then (
      select count(*) from public.community_follows f
      where f.follower_id = p_user
        and not exists (select 1 from blocked b where b.user_id = f.followed_id)
    ) else 0 end
  from visible v;
$$;

revoke all on function public.follow_counts(uuid) from public, anon;
grant execute on function public.follow_counts(uuid) to authenticated;
