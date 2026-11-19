-- Comunidade v2: estatísticas do perfil social (56:855).
-- PROPOSTA: revisar antes de aplicar.
--
-- Devolve uma linha com:
--   best_prs      até 5 exercícios com o maior e1RM (Epley), do melhor ao pior;
--   active_weeks  semanas com ao menos um treino concluído (FREE e CLUB);
--   achievements  até 12 conquistas, das mais recentes às mais antigas.
--
-- Privacidade: nenhuma linha sem login, com feed_visible = false ou com bloqueio
-- em qualquer direção. O próprio usuário sempre vê os seus dados.
-- Só saem nome do exercício, carga, repetições, e1RM, datas e nome da conquista.

create or replace function public.public_profile_stats(p_user uuid)
returns table (best_prs jsonb, active_weeks integer, achievements jsonb)
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
  workouts as (
    select w.completed_at
    from public.user_workouts w
    where w.user_id = p_user and w.is_completed and w.completed_at is not null
    union all
    select w.completed_at
    from public.club_user_workouts w
    where w.user_id = p_user and w.is_completed and w.completed_at is not null
  ),
  sets as (
    select e.name as exercise, s.weight_kg::numeric as weight_kg, s.reps,
           w.completed_at
    from public.user_workouts w
    join public.workout_exercise_sets s on s.user_workout_id = w.id
    join public.exercises e on e.id = s.exercise_id
    where w.user_id = p_user
      and w.is_completed
      and s.completed_at is not null
      and not s.is_skipped
    union all
    select coalesce(e.name, s.free_name), s.weight_kg, s.reps, w.completed_at
    from public.club_user_workouts w
    join public.club_workout_exercise_sets s on s.user_workout_id = w.id
    left join public.exercises e on e.id = s.exercise_id
    where w.user_id = p_user
      and w.is_completed
      and s.completed_at is not null
      and not s.is_skipped
  ),
  best_per_exercise as (
    select distinct on (lower(btrim(exercise)))
           btrim(exercise) as exercise,
           weight_kg,
           reps,
           round(weight_kg * (1 + reps / 30.0), 1) as e1rm,
           (completed_at at time zone 'America/Sao_Paulo')::date as performed_on
    from sets
    where exercise is not null
      and btrim(exercise) <> ''
      and weight_kg > 0
      and reps > 0
      and completed_at is not null
    order by lower(btrim(exercise)), weight_kg * (1 + reps / 30.0) desc,
             completed_at desc
  ),
  top_prs as (
    select * from best_per_exercise order by e1rm desc, exercise limit 5
  ),
  recent_achievements as (
    select a.achievement_name, a.achieved_at
    from public.user_achievements a
    where a.user_id = p_user
    order by a.achieved_at desc nulls last
    limit 12
  )
  select
    coalesce(
      (select jsonb_agg(
                jsonb_build_object(
                  'exercise', t.exercise,
                  'weight_kg', t.weight_kg,
                  'reps', t.reps,
                  'e1rm', t.e1rm,
                  'performed_on', t.performed_on
                ) order by t.e1rm desc, t.exercise)
       from top_prs t),
      '[]'::jsonb
    ),
    (select count(distinct date_trunc(
              'week', w.completed_at at time zone 'America/Sao_Paulo'))::integer
     from workouts w),
    coalesce(
      (select jsonb_agg(
                jsonb_build_object(
                  'name', r.achievement_name,
                  'achieved_at', r.achieved_at
                ) order by r.achieved_at desc nulls last)
       from recent_achievements r),
      '[]'::jsonb
    )
  where exists (select 1 from allowed);
$$;

revoke all on function public.public_profile_stats(uuid) from public, anon;
grant execute on function public.public_profile_stats(uuid) to authenticated;
