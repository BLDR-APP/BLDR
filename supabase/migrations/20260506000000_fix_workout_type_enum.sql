-- Adds missing workout_type enum values so the app can save workouts
-- categorized as HIIT, Mobility, or Mixed.
-- 'strength' is added defensively in case the DB was created without it.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'strength'
      AND enumtypid = 'public.workout_type'::regtype
  ) THEN
    ALTER TYPE public.workout_type ADD VALUE 'strength';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'hiit'
      AND enumtypid = 'public.workout_type'::regtype
  ) THEN
    ALTER TYPE public.workout_type ADD VALUE 'hiit';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'mobility'
      AND enumtypid = 'public.workout_type'::regtype
  ) THEN
    ALTER TYPE public.workout_type ADD VALUE 'mobility';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'mixed'
      AND enumtypid = 'public.workout_type'::regtype
  ) THEN
    ALTER TYPE public.workout_type ADD VALUE 'mixed';
  END IF;
END $$;
