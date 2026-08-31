-- BASELINE: club_workout_templates, club_user_workouts, club_workout_exercise_sets
--
-- Schema exportado do catálogo em 2026-08-29.
-- Dívida técnica documentada em HAVOK_SPEC.md §10 e em
-- 20260803210324_add_free_name_to_template_exercises.sql.
--
-- ──────────────────────────────────────────────────────────────────────────────
-- DEPENDÊNCIA NÃO INVENTARIADA — BASELINE PARCIALMENTE UTILIZÁVEL
-- ──────────────────────────────────────────────────────────────────────────────
-- club_workout_exercise_sets possui FK:
--   FOREIGN KEY (workout_template_exercise_id)
--   REFERENCES public.club_workout_template_exercises(id) ON DELETE CASCADE
--
-- A tabela club_workout_template_exercises existe no Supabase mas NÃO foi
-- incluída no inventário exportado e NÃO possui migration. Seu baseline
-- precisa ser gerado e aplicado ANTES desta migration em ambientes novos.
-- Em produção, onde a tabela já existe, esta migration é segura graças ao
-- IF NOT EXISTS — mas a FK falhará se a tabela referenciada não existir.
--
-- NÃO APLICAR em ambiente limpo sem gerar baseline de club_workout_template_exercises.
-- NÃO APLICAR sem supabase db diff prévio.
--
-- ──────────────────────────────────────────────────────────────────────────────
-- RISCO DE ACESSO PARA USUÁRIOS anon
-- ──────────────────────────────────────────────────────────────────────────────
-- club_user_workouts (RLS = false): grants para anon e authenticated.
-- Com RLS desabilitado, qualquer requisição com anon key tem acesso irrestrito
-- a TODOS os registros — não apenas aos do próprio usuário.
-- Isso inclui dados de treino de todos os usuários (volume_kg, muscle_groups, etc.).
-- Corrigir antes de qualquer exposição pública da feature de clube.
--
-- club_workout_exercise_sets (RLS = false): mesmo risco.

-- ── 1. club_workout_templates (RLS ativo) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.club_workout_templates (
  id                         UUID        NOT NULL DEFAULT gen_random_uuid(),
  name                       TEXT        NOT NULL,
  description                TEXT,
  workout_type               public.workout_type NOT NULL,
  estimated_duration_minutes INTEGER,
  difficulty_level           INTEGER,
  is_public                  BOOLEAN              DEFAULT false,
  created_by                 UUID,
  created_at                 TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP,
  updated_at                 TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP,
  user_id                    UUID,
  CONSTRAINT club_workout_templates_pkey
    PRIMARY KEY (id),
  -- Duas constraints de difficulty coexistem em produção (inconsistência histórica).
  -- A mais restritiva (1-4) é a efetiva. Não alterar sem avaliar dados existentes.
  CONSTRAINT workout_templates_difficulty_chk
    CHECK (difficulty_level >= 1 AND difficulty_level <= 4),
  CONSTRAINT workout_templates_difficulty_level_check
    CHECK (difficulty_level >= 1 AND difficulty_level <= 5)
);

CREATE INDEX IF NOT EXISTS club_workout_templates_created_by_idx
  ON public.club_workout_templates (created_by);
CREATE INDEX IF NOT EXISTS club_workout_templates_workout_type_idx
  ON public.club_workout_templates (workout_type);

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.club_workout_templates TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.club_workout_templates TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.club_workout_templates TO service_role;

ALTER TABLE public.club_workout_templates ENABLE ROW LEVEL SECURITY;

-- Políticas exportadas (4 policies SELECT redundantes + CRUD — estado real)
DROP POLICY IF EXISTS "club_users_can_select_own_and_public_templates" ON public.club_workout_templates;
CREATE POLICY "club_users_can_select_own_and_public_templates"
  ON public.club_workout_templates FOR SELECT TO authenticated
  USING ((created_by = auth.uid()) OR (is_public = true));

DROP POLICY IF EXISTS "club_users_can_insert_own_templates" ON public.club_workout_templates;
CREATE POLICY "club_users_can_insert_own_templates"
  ON public.club_workout_templates FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "club_users_can_update_own_templates" ON public.club_workout_templates;
CREATE POLICY "club_users_can_update_own_templates"
  ON public.club_workout_templates FOR UPDATE TO authenticated
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "club_users_can_delete_own_templates" ON public.club_workout_templates;
CREATE POLICY "club_users_can_delete_own_templates"
  ON public.club_workout_templates FOR DELETE TO authenticated
  USING (created_by = auth.uid());

-- Políticas legadas (redundantes com as acima — existem em produção, exportadas)
DROP POLICY IF EXISTS "read own templates" ON public.club_workout_templates;
CREATE POLICY "read own templates"
  ON public.club_workout_templates FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "read public templates" ON public.club_workout_templates;
CREATE POLICY "read public templates"
  ON public.club_workout_templates FOR SELECT TO authenticated
  USING (is_public = true);


-- ── 2. club_user_workouts (RLS DESABILITADO em produção) ─────────────────────
-- Sem coluna created_at — diverge do padrão das outras tabelas.
CREATE TABLE IF NOT EXISTS public.club_user_workouts (
  id                     UUID        NOT NULL DEFAULT uuid_generate_v4(),
  user_id                UUID        NOT NULL,
  workout_template_id    UUID,
  name                   TEXT,
  started_at             TIMESTAMPTZ          DEFAULT timezone('utc'::text, now()),
  completed_at           TIMESTAMPTZ,
  total_duration_seconds INTEGER,
  notes                  TEXT,
  is_completed           BOOLEAN              DEFAULT false,
  volume_kg              NUMERIC,
  muscle_groups          TEXT[],
  CONSTRAINT club_user_workouts_pkey
    PRIMARY KEY (id),
  CONSTRAINT club_user_workouts_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT club_user_workouts_workout_template_id_fkey
    FOREIGN KEY (workout_template_id)
    REFERENCES public.club_workout_templates(id) ON DELETE SET NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.club_user_workouts TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.club_user_workouts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.club_user_workouts TO service_role;

-- RLS desabilitado em produção — não ativar aqui sem decisão explícita e testes.
-- As policies abaixo existem no catálogo mas não têm efeito enquanto RLS = false.
DROP POLICY IF EXISTS "Enable insert for users based on user_id" ON public.club_user_workouts;
CREATE POLICY "Enable insert for users based on user_id"
  ON public.club_user_workouts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Enable read access for own club workouts" ON public.club_user_workouts;
CREATE POLICY "Enable read access for own club workouts"
  ON public.club_user_workouts FOR SELECT TO authenticated
  USING (auth.uid() = user_id);


-- ── 3. club_workout_exercise_sets (RLS DESABILITADO em produção) ──────────────
-- Sem coluna created_at — exportação confirma ausência.
-- RISCO FUNCIONAL: copy_workout_to_template referencia wes.created_at nesta tabela
-- (ver baseline_community_07). Se a coluna realmente não existir, a função falha
-- para p_source = 'club'. Ver relatório SCHEMA_DRIFT_REPORT.md §6.
CREATE TABLE IF NOT EXISTS public.club_workout_exercise_sets (
  id                           UUID        NOT NULL DEFAULT gen_random_uuid(),
  user_workout_id              UUID,
  exercise_id                  UUID,
  set_number                   INTEGER     NOT NULL,
  reps                         INTEGER,
  weight_kg                    NUMERIC,
  duration_seconds             INTEGER,
  distance_meters              NUMERIC,
  rest_seconds                 INTEGER,
  completed_at                 TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP,
  notes                        TEXT,
  set_order                    INTEGER,
  workout_template_exercise_id UUID,
  order_index                  INTEGER,
  free_name                    TEXT,
  CONSTRAINT club_workout_exercise_sets_pkey
    PRIMARY KEY (id),
  -- FK para tabela não inventariada — falhará se club_workout_template_exercises não existir
  CONSTRAINT club_wes__template_exercise_fk
    FOREIGN KEY (workout_template_exercise_id)
    REFERENCES public.club_workout_template_exercises(id)
    ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS club_workout_exercise_sets_user_workout_id_idx
  ON public.club_workout_exercise_sets (user_workout_id);
CREATE INDEX IF NOT EXISTS idx_club_wes_template_exercise_id
  ON public.club_workout_exercise_sets (workout_template_exercise_id);

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.club_workout_exercise_sets TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.club_workout_exercise_sets TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.club_workout_exercise_sets TO service_role;

-- RLS desabilitado em produção — não ativar sem decisão explícita.
