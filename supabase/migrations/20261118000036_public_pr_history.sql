-- Comunidade v2, lote 1 (S13): evolução do PR no sheet 22:419.
-- PROPOSTA: revisar antes de aplicar.
--
-- Fonte: séries concluídas (FREE e CLUB). `personal_records` não é usada porque
-- não tem baseline no repositório. p_exercise é o NOME do exercício, único dado
-- que o post guarda (`exercise_name`).
--
-- Privacidade: vazio se feed_visible = false, se houver bloqueio em qualquer
-- direção ou sem login. O próprio usuário sempre vê o seu histórico.
-- Retorna a melhor série de cada dia (e1RM de Epley), no máximo 20 dias.

create or replace function public.public_pr_history(p_user uuid, p_exercise text)
returns table (performed_on date, weight_kg numeric, reps integer, e1rm numeric)
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  with allowed as (
    select 1
    where auth.uid() is not null
      and (
        auth.uid() = p_user
        or (
          exists (
            select 1 from public.user_profiles up
            where up.id = p_user and up.feed_visible
          )
          and not exists (
            select 1 from public.community_blocks b
            where (b.blocker_id = auth.uid() and b.blocked_id = p_user)
               or (b.blocker_id = p_user and b.blocked_id = auth.uid())
          )
        )
      )
  ),
  sets as (
    select w.completed_at, s.weight_kg::numeric as weight_kg, s.reps
    from public.user_workouts w
    join public.workout_exercise_sets s on s.user_workout_id = w.id
    join public.exercises e on e.id = s.exercise_id
    where w.user_id = p_user
      and w.is_completed
      and s.completed_at is not null
      and not s.is_skipped
      and lower(btrim(e.name)) = lower(btrim(p_exercise))
    union all
    select w.completed_at, s.weight_kg, s.reps
    from public.club_user_workouts w
    join public.club_workout_exercise_sets s on s.user_workout_id = w.id
    left join public.exercises e on e.id = s.exercise_id
    where w.user_id = p_user
      and w.is_completed
      and s.completed_at is not null
      and not s.is_skipped
      and lower(btrim(coalesce(e.name, s.free_name))) = lower(btrim(p_exercise))
  ),
  scored as (
    select (completed_at at time zone 'America/Sao_Paulo')::date as performed_on,
           weight_kg,
           reps,
           round(weight_kg * (1 + reps / 30.0), 1) as e1rm
    from sets
    where weight_kg > 0 and reps > 0 and completed_at is not null
      and exists (select 1 from allowed)
  ),
  best as (
    select distinct on (performed_on) performed_on, weight_kg, reps, e1rm
    from scored
    order by performed_on desc, e1rm desc
  )
  select performed_on, weight_kg, reps, e1rm
  from best
  order by performed_on desc
  limit 20;
$$;

revoke all on function public.public_pr_history(uuid, text) from public, anon;
grant execute on function public.public_pr_history(uuid, text) to authenticated;
