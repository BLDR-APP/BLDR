-- TREINOS_V2.md (P2): persistir carga/reps/descanso de CADA série do template.
-- Antes, a tela "Criar/Editar treino" salvava a média da carga e um único
-- reps/descanso por exercício, perdendo o que o usuário digitou por série.
--
-- Formato: lista JSON de objetos {weight_kg, reps, rest_seconds}, um por série,
-- na ordem das séries. As colunas agregadas (sets, reps, weight_kg,
-- rest_seconds) continuam sendo gravadas para compatibilidade: `sets` passa a
-- ser o tamanho da lista. Templates antigos ficam com set_details = null e o
-- app usa os valores agregados.
--
-- Precisa ser aplicada ANTES do deploy do app que lê/grava a coluna.

alter table public.workout_template_exercises
  add column if not exists set_details jsonb;

comment on column public.workout_template_exercises.set_details is
  'Lista por série: [{weight_kg, reps, rest_seconds}]. Null em templates antigos (usa sets/reps/weight_kg/rest_seconds).';

alter table public.workout_template_exercises
  drop constraint if exists workout_template_exercises_set_details_is_array;

alter table public.workout_template_exercises
  add constraint workout_template_exercises_set_details_is_array
  check (set_details is null or jsonb_typeof(set_details) = 'array');
