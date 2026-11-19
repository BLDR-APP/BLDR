-- Comunidade v2, lote 1 (S1): aposta e meta diária do squad.
-- PROPOSTA: revisar antes de aplicar.
--
-- As policies de bldr_club.arenas não estão no repositório. O trigger garante a
-- regra "só o criador altera" mesmo que exista uma policy de update mais ampla.
-- Conferir antes:
--   select policyname, cmd, qual, with_check from pg_policies
--   where schemaname = 'bldr_club' and tablename = 'arenas';

alter table bldr_club.arenas
  add column if not exists stake text,
  add column if not exists daily_goal text;

alter table bldr_club.arenas
  drop constraint if exists arenas_stake_length,
  drop constraint if exists arenas_daily_goal_length;

alter table bldr_club.arenas
  add constraint arenas_stake_length
    check (stake is null or char_length(stake) <= 120),
  add constraint arenas_daily_goal_length
    check (daily_goal is null or char_length(daily_goal) <= 120);

create or replace function bldr_club.arenas_guard_stake_goal()
returns trigger
language plpgsql
set search_path = pg_catalog, bldr_club, public
as $$
begin
  if current_user = 'authenticated'
     and (new.stake is distinct from old.stake
          or new.daily_goal is distinct from old.daily_goal)
     and auth.uid() is distinct from old.creator_id then
    raise exception 'only the squad creator can change stake or daily goal'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_arenas_guard_stake_goal on bldr_club.arenas;
create trigger trg_arenas_guard_stake_goal
  before update on bldr_club.arenas
  for each row execute function bldr_club.arenas_guard_stake_goal();
