-- BLDR Challenges V1: timezone IANA e writers server-authoritative.
-- Prospectiva: não faz backfill nem recalcula challenges históricos.

alter table public.user_profiles
  add column if not exists timezone text;

create or replace function public.validate_user_timezone()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if new.timezone is not null
     and (
       new.timezone !~ '^[A-Za-z][A-Za-z_+-]*(/[A-Za-z][A-Za-z_+-]*)+$'
       or not exists (select 1 from pg_timezone_names where name = new.timezone)
     ) then
    raise exception 'timezone must be a valid IANA identifier';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_validate_user_timezone on public.user_profiles;
create trigger trg_validate_user_timezone
before insert or update of timezone on public.user_profiles
for each row execute function public.validate_user_timezone();

-- O cliente apenas lê challenges/participações. Join, leave e create usam RPCs.
alter table bldr_club.collective_challenges enable row level security;
alter table bldr_club.collective_challenge_participants enable row level security;
revoke insert, update, delete on bldr_club.collective_challenges from anon, authenticated;
revoke insert, update, delete on bldr_club.collective_challenge_participants from anon, authenticated;
grant select on bldr_club.collective_challenges, bldr_club.collective_challenge_participants to authenticated;

-- Um treino não pode contribuir duas vezes para o mesmo desafio/origem.
create table if not exists bldr_club.collective_workout_progress_events (
  challenge_id uuid not null references bldr_club.collective_challenges(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  source text not null,
  workout_id uuid not null,
  processed_at timestamptz not null default current_timestamp,
  primary key (challenge_id, user_id, source, workout_id)
);

alter table bldr_club.collective_workout_progress_events enable row level security;
revoke all on bldr_club.collective_workout_progress_events from anon, authenticated;

-- Substitui somente o antigo writer de XP, que misturava XP, workouts e streak.
drop trigger if exists trg_propagate_xp_to_collective on bldr_club.xp_events;
drop trigger if exists trg_collective_xp_progress on bldr_club.xp_events;

create or replace function bldr_club.apply_collective_xp_total_progress()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, bldr_club, public, auth
as $$
declare
  v_challenge_id uuid;
begin
  if new.delta <= 0 or new.reason = 'challenge_reward' then
    return new;
  end if;

  for v_challenge_id in
    select c.id
    from bldr_club.collective_challenges c
    join bldr_club.collective_challenge_participants p
      on p.challenge_id = c.id
    where c.status = 'active'
      and c.challenge_type = 'xp_total'
      and p.user_id = new.user_id
      and new.created_at >= c.starts_at
      and new.created_at <= c.ends_at
      and (
        c.allowed_sources is null
        or c.allowed_sources = '[]'::jsonb
        or c.allowed_sources ? new.reason
      )
  loop
    update bldr_club.collective_challenge_participants
    set contribution = contribution + new.delta
    where challenge_id = v_challenge_id and user_id = new.user_id;
  end loop;

  return new;
end;
$$;

create trigger trg_collective_xp_total_progress
after insert on bldr_club.xp_events
for each row execute function bldr_club.apply_collective_xp_total_progress();

create or replace function bldr_club.canonical_streak_for_challenge(
  p_user_id uuid,
  p_started_at timestamptz,
  p_ended_at timestamptz
)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, bldr_club, public, auth
as $$
declare
  v_timezone text := 'UTC';
  v_max integer := 0;
begin
  select up.timezone into v_timezone
  from public.user_profiles up
  where up.id = p_user_id;

  if v_timezone is null
     or not exists (select 1 from pg_timezone_names where name = v_timezone) then
    v_timezone := 'UTC';
  end if;

  with workout_days as (
    select (uw.completed_at at time zone v_timezone)::date as local_day
    from public.user_workouts uw
    where uw.user_id = p_user_id
      and uw.is_completed = true
      and uw.completed_at is not null
      and uw.completed_at >= p_started_at
      and uw.completed_at <= p_ended_at
    union
    select (cw.completed_at at time zone v_timezone)::date as local_day
    from public.club_user_workouts cw
    where cw.user_id = p_user_id
      and cw.is_completed = true
      and cw.completed_at is not null
      and cw.completed_at >= p_started_at
      and cw.completed_at <= p_ended_at
  ), grouped as (
    select local_day,
           local_day - (row_number() over (order by local_day))::integer as streak_group
    from workout_days
  )
  select coalesce(max(days), 0) into v_max
  from (select count(*)::integer as days from grouped group by streak_group) runs;

  return v_max;
end;
$$;

create or replace function bldr_club.apply_collective_workout_progress()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, bldr_club, public, auth
as $$
declare
  v_challenge record;
  v_rows integer;
  v_streak integer;
begin
  if not new.is_completed or new.completed_at is null then
    return new;
  end if;

  -- Updates posteriores do mesmo treino não voltam a contar: o ledger é a
  -- única autoridade de idempotência para cada desafio/origem/treino.
  for v_challenge in
    select c.id, c.challenge_type, c.starts_at, c.ends_at
    from bldr_club.collective_challenges c
    join bldr_club.collective_challenge_participants p
      on p.challenge_id = c.id
    where c.status = 'active'
      and c.challenge_type in ('workouts', 'streak')
      and p.user_id = new.user_id
      and new.completed_at >= c.starts_at
      and new.completed_at <= c.ends_at
  loop
    insert into bldr_club.collective_workout_progress_events
      (challenge_id, user_id, source, workout_id)
    values (v_challenge.id, new.user_id, tg_table_name, new.id)
    on conflict do nothing;

    get diagnostics v_rows = row_count;
    if v_rows <> 1 then
      continue;
    end if;

    if v_challenge.challenge_type = 'workouts' then
      update bldr_club.collective_challenge_participants
      set contribution = contribution + 1
      where challenge_id = v_challenge.id and user_id = new.user_id;
    else
      v_streak := bldr_club.canonical_streak_for_challenge(
        new.user_id,
        v_challenge.starts_at,
        least(v_challenge.ends_at, new.completed_at)
      );
      update bldr_club.collective_challenge_participants
      set contribution = greatest(contribution, v_streak)
      where challenge_id = v_challenge.id and user_id = new.user_id;
    end if;
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_collective_personal_workout_progress on public.user_workouts;
create trigger trg_collective_personal_workout_progress
after insert or update of is_completed, completed_at on public.user_workouts
for each row execute function bldr_club.apply_collective_workout_progress();

drop trigger if exists trg_collective_club_workout_progress on public.club_user_workouts;
create trigger trg_collective_club_workout_progress
after insert or update of is_completed, completed_at on public.club_user_workouts
for each row execute function bldr_club.apply_collective_workout_progress();

-- Mantém milestones, recompensa e expiração existentes como os únicos donos
-- da transição de status. Este trigger só soma contribuições para challenges
-- ainda ativos, preservando divergências históricas intencionalmente.
create or replace function bldr_club.sync_collective_progress()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, bldr_club, public, auth
as $$
declare
  v_challenge_id uuid := coalesce(new.challenge_id, old.challenge_id);
begin
  update bldr_club.collective_challenges c
  set current_value = coalesce((
    select sum(p.contribution)::integer
    from bldr_club.collective_challenge_participants p
    where p.challenge_id = v_challenge_id
  ), 0)
  where c.id = v_challenge_id and c.status = 'active';
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_collective_progress on bldr_club.collective_challenge_participants;
create trigger trg_collective_progress
after insert or update or delete on bldr_club.collective_challenge_participants
for each row execute function bldr_club.sync_collective_progress();

create or replace function bldr_club.join_collective_challenge(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, bldr_club, public, auth
as $$
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if not exists (
    select 1 from bldr_club.collective_challenges
    where id = p_challenge_id
      and status = 'active'
      and starts_at <= current_timestamp
      and ends_at > current_timestamp
  ) then
    raise exception 'challenge is not joinable';
  end if;

  insert into bldr_club.collective_challenge_participants
    (challenge_id, user_id, contribution)
  values (p_challenge_id, auth.uid(), 0)
  -- Não depende do nome/forma da constraint legada: qualquer violação de
  -- unicidade para a mesma participação torna o join idempotente.
  on conflict do nothing;
end;
$$;

create or replace function bldr_club.leave_collective_challenge(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, bldr_club, public, auth
as $$
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if not exists (
    select 1 from bldr_club.collective_challenges
    where id = p_challenge_id
      and status = 'active'
      and ends_at > current_timestamp
  ) then
    raise exception 'challenge is not leaveable';
  end if;

  delete from bldr_club.collective_challenge_participants
  where challenge_id = p_challenge_id and user_id = auth.uid();
end;
$$;

-- Assinatura compatível com o cliente atual, mas recompensas de usuários são
-- explicitamente recusadas; apenas o fluxo oficial poderá concedê-las depois.
drop function if exists bldr_club.create_collective_challenge(
  text, text, text, numeric, integer, text, text, timestamptz, text[]
);

create or replace function bldr_club.create_collective_challenge(
  p_title text,
  p_description text,
  p_challenge_type text,
  p_target_value integer,
  p_reward_xp integer,
  p_reward_badge text,
  p_cover_image_url text,
  p_ends_at timestamptz,
  p_allowed_sources text[] default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, bldr_club, public, auth
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if p_challenge_type not in ('xp_total', 'workouts', 'streak') then
    raise exception 'unsupported challenge type';
  end if;
  if length(trim(p_title)) not between 3 and 80
     or p_target_value is null
     or p_target_value <= 0
     or p_ends_at <= current_timestamp then
    raise exception 'invalid challenge payload';
  end if;
  if coalesce(p_reward_xp, 0) <> 0
     or nullif(trim(coalesce(p_reward_badge, '')), '') is not null then
    raise exception 'user-created challenges cannot define rewards';
  end if;

  insert into bldr_club.collective_challenges (
    title, description, challenge_type, target_value, current_value,
    reward_xp, reward_badge, cover_image_url, starts_at, ends_at,
    status, created_by, is_official, allowed_sources
  ) values (
    trim(p_title), nullif(trim(p_description), ''), p_challenge_type,
    p_target_value, 0, 0, null, p_cover_image_url, current_timestamp,
    p_ends_at, 'active', auth.uid(), false, to_jsonb(p_allowed_sources)
  ) returning id into v_id;

  return v_id;
end;
$$;

-- A tela existente permite editar fontes/meta do próprio desafio. Como UPDATE
-- direto é revogado ao cliente, preservamos essa capacidade por uma RPC com
-- escopo estrito: somente criador, desafio ativo e não oficial. A meta nunca
-- pode ser reduzida abaixo do progresso já canônico.
create or replace function bldr_club.update_collective_challenge_settings(
  p_challenge_id uuid,
  p_allowed_sources text[] default null,
  p_target_value integer default null
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, bldr_club, public, auth
as $$
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;

  update bldr_club.collective_challenges
  set allowed_sources = to_jsonb(p_allowed_sources),
      target_value = coalesce(p_target_value, target_value)
  where id = p_challenge_id
    and created_by = auth.uid()
    and is_official = false
    and status = 'active'
    and (p_target_value is null or p_target_value > current_value)
    and (p_target_value is null or p_target_value > 0);

  if not found then
    raise exception 'challenge settings cannot be updated';
  end if;
end;
$$;

revoke all on function public.validate_user_timezone() from public;
revoke all on function bldr_club.apply_collective_xp_total_progress() from public;
revoke all on function bldr_club.apply_collective_workout_progress() from public;
revoke all on function bldr_club.sync_collective_progress() from public;
revoke all on function bldr_club.canonical_streak_for_challenge(uuid, timestamptz, timestamptz) from public;
revoke all on function bldr_club.join_collective_challenge(uuid) from public, anon;
revoke all on function bldr_club.leave_collective_challenge(uuid) from public, anon;
revoke all on function bldr_club.create_collective_challenge(text, text, text, integer, integer, text, text, timestamptz, text[]) from public, anon;
revoke all on function bldr_club.update_collective_challenge_settings(uuid, text[], integer) from public, anon;
grant execute on function bldr_club.join_collective_challenge(uuid) to authenticated, service_role;
grant execute on function bldr_club.leave_collective_challenge(uuid) to authenticated, service_role;
grant execute on function bldr_club.create_collective_challenge(text, text, text, integer, integer, text, text, timestamptz, text[]) to authenticated, service_role;
grant execute on function bldr_club.update_collective_challenge_settings(uuid, text[], integer) to authenticated, service_role;
