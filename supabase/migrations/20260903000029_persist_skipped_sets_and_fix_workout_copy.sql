BEGIN;

-- Persist explicit skipped-set state for FREE workouts.
ALTER TABLE public.workout_exercise_sets
ADD COLUMN IF NOT EXISTS is_skipped boolean NOT NULL DEFAULT false;

-- Persist explicit skipped-set state for CLUB workouts.
ALTER TABLE public.club_workout_exercise_sets
ADD COLUMN IF NOT EXISTS is_skipped boolean NOT NULL DEFAULT false;

-- A skipped set must never be considered completed.
ALTER TABLE public.workout_exercise_sets
DROP CONSTRAINT IF EXISTS workout_exercise_sets_skip_not_completed;

ALTER TABLE public.workout_exercise_sets
ADD CONSTRAINT workout_exercise_sets_skip_not_completed
CHECK (NOT is_skipped OR completed_at IS NULL);

ALTER TABLE public.club_workout_exercise_sets
DROP CONSTRAINT IF EXISTS club_workout_exercise_sets_skip_not_completed;

ALTER TABLE public.club_workout_exercise_sets
ADD CONSTRAINT club_workout_exercise_sets_skip_not_completed
CHECK (NOT is_skipped OR completed_at IS NULL);

COMMENT ON COLUMN public.workout_exercise_sets.is_skipped IS
'True when the set was intentionally skipped. Skipped sets are processed for workout progression/resume but must not count toward completion, volume, PRs, XP, or performance analytics.';

COMMENT ON COLUMN public.club_workout_exercise_sets.is_skipped IS
'True when the set was intentionally skipped. Skipped sets are processed for workout progression/resume but must not count toward completion, volume, PRs, XP, or performance analytics.';


-- Keep the repository definition of copy_workout_to_template aligned
-- with the version already deployed and validated in Production.
CREATE OR REPLACE FUNCTION public.copy_workout_to_template(
    p_workout_id uuid,
    p_source text DEFAULT 'free'::text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_user_id uuid := auth.uid();
    v_template_id uuid;
    v_workout_name text;
    v_workout_type public.workout_type;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'not authenticated';
    END IF;

    IF p_source NOT IN ('free', 'club') THEN
        RAISE EXCEPTION 'invalid workout source: %', p_source;
    END IF;

    IF p_source = 'club' THEN
        SELECT
            COALESCE(cuw.name, cwt.name, 'Treino copiado'),
            cwt.workout_type
        INTO
            v_workout_name,
            v_workout_type
        FROM public.club_user_workouts cuw
        LEFT JOIN public.club_workout_templates cwt
            ON cwt.id = cuw.workout_template_id
        WHERE cuw.id = p_workout_id;
    ELSE
        SELECT
            COALESCE(uw.name, wt.name, 'Treino copiado'),
            wt.workout_type
        INTO
            v_workout_name,
            v_workout_type
        FROM public.user_workouts uw
        LEFT JOIN public.workout_templates wt
            ON wt.id = uw.workout_template_id
        WHERE uw.id = p_workout_id;
    END IF;

    IF v_workout_name IS NULL THEN
        RAISE EXCEPTION 'workout not found';
    END IF;

    IF v_workout_type IS NULL THEN
        RAISE EXCEPTION 'workout type not found';
    END IF;

    INSERT INTO public.workout_templates (
        name,
        workout_type,
        is_public,
        created_by,
        source
    )
    VALUES (
        v_workout_name || ' (cópia)',
        v_workout_type,
        false,
        v_user_id,
        'user'
    )
    RETURNING id INTO v_template_id;

    IF p_source = 'club' THEN
        INSERT INTO public.workout_template_exercises (
            workout_template_id,
            exercise_id,
            exercise_db_id,
            free_name,
            sets,
            reps,
            weight_kg,
            rest_seconds,
            order_index
        )
        SELECT
            v_template_id,
            wes.exercise_id,
            NULL::text,
            wes.free_name,
            COUNT(*)::integer,
            MAX(wes.reps),
            MAX(wes.weight_kg),
            COALESCE(MAX(wes.rest_seconds), 90),
            wes.order_index
        FROM public.club_workout_exercise_sets wes
        WHERE wes.user_workout_id = p_workout_id
          AND wes.completed_at IS NOT NULL
          AND wes.is_skipped = false
          AND wes.order_index IS NOT NULL
        GROUP BY
            wes.order_index,
            wes.exercise_id,
            wes.free_name
        ORDER BY wes.order_index;
    ELSE
        INSERT INTO public.workout_template_exercises (
            workout_template_id,
            exercise_id,
            exercise_db_id,
            free_name,
            sets,
            reps,
            weight_kg,
            rest_seconds,
            order_index
        )
        SELECT
            v_template_id,
            wes.exercise_id,
            wes.exercise_db_id,
            wes.free_name,
            COUNT(*)::integer,
            MAX(wes.reps),
            MAX(wes.weight_kg),
            COALESCE(MAX(wes.rest_seconds), 90),
            wes.order_index
        FROM public.workout_exercise_sets wes
        WHERE wes.user_workout_id = p_workout_id
          AND wes.completed_at IS NOT NULL
          AND wes.is_skipped = false
          AND wes.order_index IS NOT NULL
        GROUP BY
            wes.order_index,
            wes.exercise_id,
            wes.exercise_db_id,
            wes.free_name
        ORDER BY wes.order_index;
    END IF;

    RETURN v_template_id;
END;
$function$;

COMMIT;
