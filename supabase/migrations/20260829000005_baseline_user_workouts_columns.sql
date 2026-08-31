-- BASELINE: colunas adicionais em public.user_workouts
--
-- A migration base 20250816004909_bldr_fitness_complete.sql criou user_workouts
-- sem as colunas name, volume_kg e muscle_groups. Estas existem em produção
-- conforme exportação do catálogo (section 02_COLUMN, ordinal_position 4, 10, 11).
--
-- ADD COLUMN IF NOT EXISTS é seguro para colunas inexistentes.
-- Se a coluna já existir com tipo diferente, este comando falha silenciosamente
-- (IF NOT EXISTS ignora sem erro, mas o tipo divergente permanece).
-- Confirmar tipos antes de aplicar:
--   SELECT column_name, data_type FROM information_schema.columns
--   WHERE table_name = 'user_workouts' AND column_name IN ('name','volume_kg','muscle_groups');

ALTER TABLE public.user_workouts
  ADD COLUMN IF NOT EXISTS name          TEXT,
  ADD COLUMN IF NOT EXISTS volume_kg     NUMERIC,
  ADD COLUMN IF NOT EXISTS muscle_groups TEXT[];
