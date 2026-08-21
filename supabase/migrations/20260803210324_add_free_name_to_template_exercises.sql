-- BACKLOG_FUNCIONAL.md B5 — treino gerado pelo HAVOK usa exercícios de nome
-- livre (Gemini nunca fez match contra exercise_id/exercise_db_id). Sem uma
-- coluna de nome livre, o exercício não sobrevive ao round-trip
-- template -> sessão, e a UI de treino ativo funde tudo sob chave ''.
--
-- free_name entra em duas camadas:
-- 1. workout_template_exercises / club_workout_template_exercises — onde o
--    exercício gerado é salvo como template.
-- 2. workout_exercise_sets / club_workout_exercise_sets — para onde o nome
--    precisa ser copiado quando uma sessão é iniciada a partir do template
--    (workout_service.dart clona os exercícios do template para a sessão).
--
-- club_workout_template_exercises e club_workout_exercise_sets foram criadas
-- fora de migration (dívida técnica documentada em HAVOK_SPEC.md §10) — o
-- DO block confirma que a tabela existe antes de alterá-la, para não quebrar
-- em ambientes onde ela não foi criada.

ALTER TABLE IF EXISTS public.workout_template_exercises
  ADD COLUMN IF NOT EXISTS free_name TEXT;

ALTER TABLE IF EXISTS public.workout_exercise_sets
  ADD COLUMN IF NOT EXISTS free_name TEXT;

DO $$
BEGIN
  IF to_regclass('public.club_workout_template_exercises') IS NOT NULL THEN
    ALTER TABLE public.club_workout_template_exercises
      ADD COLUMN IF NOT EXISTS free_name TEXT;
  END IF;

  IF to_regclass('public.club_workout_exercise_sets') IS NOT NULL THEN
    ALTER TABLE public.club_workout_exercise_sets
      ADD COLUMN IF NOT EXISTS free_name TEXT;
  END IF;
END $$;
