-- BASELINE: public.copy_workout_to_template — definição real exportada em 2026-08-29
--
-- Retorno: UUID (seção 07_FUNCTION confirma "result": "uuid").
-- PostgREST serializa UUID como string — o Flutter faz `result as String`, compatível.
-- SECURITY DEFINER: executa como postgres.
--
-- ──────────────────────────────────────────────────────────────────────────────
-- RISCO FUNCIONAL — coluna created_at ausente em club_workout_exercise_sets
-- ──────────────────────────────────────────────────────────────────────────────
-- A função referencia wes.created_at no branch p_source = 'club':
--   ROW_NUMBER() OVER (ORDER BY MIN(wes.created_at))
--
-- O inventário exportado de club_workout_exercise_sets NÃO inclui coluna
-- created_at — as colunas exportadas terminam em free_name (ordinal_position 15).
-- A tabela possui completed_at (DEFAULT CURRENT_TIMESTAMP) mas não created_at.
--
-- Se o inventário estiver correto, esta linha causaria erro em runtime:
--   ERROR: column "created_at" does not exist
-- para qualquer chamada com p_source = 'club'.
--
-- Possibilidades:
--   A) O inventário está incompleto (created_at existe mas não foi exportado)
--   B) A função está quebrada para p_source = 'club' desde sua criação
--
-- Verificar diretamente:
--   SELECT column_name FROM information_schema.columns
--   WHERE table_name = 'club_workout_exercise_sets' ORDER BY ordinal_position;
--
-- NÃO APLICAR sem supabase db diff prévio.

CREATE OR REPLACE FUNCTION public.copy_workout_to_template(
  p_workout_id uuid,
  p_source     text DEFAULT 'free'::text
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER AS $function$
DECLARE
  v_user_id      UUID := auth.uid();
  v_template_id  UUID;
  v_workout_name TEXT;
BEGIN
  IF p_source = 'club' THEN
    SELECT COALESCE(wt.name, 'Treino copiado')
    INTO v_workout_name
    FROM public.club_user_workouts cuw
    LEFT JOIN public.club_workout_templates wt ON wt.id = cuw.workout_template_id
    WHERE cuw.id = p_workout_id;
  ELSE
    SELECT COALESCE(wt.name, 'Treino copiado')
    INTO v_workout_name
    FROM public.user_workouts uw
    LEFT JOIN public.workout_templates wt ON wt.id = uw.workout_template_id
    WHERE uw.id = p_workout_id;
  END IF;

  INSERT INTO public.workout_templates (user_id, name, is_public)
  VALUES (v_user_id, v_workout_name || ' (cópia)', false)
  RETURNING id INTO v_template_id;

  IF p_source = 'club' THEN
    INSERT INTO public.workout_template_exercises
      (workout_template_id, exercise_id, exercise_db_id, free_name, sets, reps, weight_kg, rest_seconds, sort_order)
    SELECT
      v_template_id,
      wes.exercise_id,
      NULL,
      wes.free_name,
      COUNT(*),
      MAX(wes.reps),
      MAX(wes.weight_kg),
      90,
      -- ATENÇÃO: created_at pode não existir em club_workout_exercise_sets — ver cabeçalho
      ROW_NUMBER() OVER (ORDER BY MIN(wes.created_at))
    FROM public.club_workout_exercise_sets wes
    WHERE wes.user_workout_id = p_workout_id
    GROUP BY wes.exercise_id, wes.free_name;
  ELSE
    INSERT INTO public.workout_template_exercises
      (workout_template_id, exercise_id, exercise_db_id, free_name, sets, reps, weight_kg, rest_seconds, sort_order)
    SELECT
      v_template_id,
      wes.exercise_id,
      wes.exercise_db_id,
      wes.free_name,
      COUNT(*),
      MAX(wes.reps),
      MAX(wes.weight_kg),
      90,
      ROW_NUMBER() OVER (ORDER BY MIN(wes.created_at))
    FROM public.workout_exercise_sets wes
    WHERE wes.user_workout_id = p_workout_id
    GROUP BY wes.exercise_id, wes.exercise_db_id, wes.free_name;
  END IF;

  RETURN v_template_id;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.copy_workout_to_template(uuid, text)
  TO PUBLIC, anon, authenticated, service_role;
