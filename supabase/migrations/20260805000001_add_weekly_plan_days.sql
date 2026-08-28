-- B8: plano semanal com domínio real (BACKLOG_FUNCIONAL.md)
-- Substitui OnboardingPlanStorage (SharedPreferences) por tabela no Supabase.
-- dia_semana: 1=segunda … 7=domingo (convenção ISO, mesma do Dart DateTime.weekday)

CREATE TABLE IF NOT EXISTS public.weekly_plan_days (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  dia_semana  SMALLINT    NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),
  template_id UUID        REFERENCES public.workout_templates(id) ON DELETE SET NULL,
  template_name TEXT,
  tipo        TEXT        NOT NULL DEFAULT 'treino'
              CHECK (tipo IN ('treino', 'descanso')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, dia_semana)
);

CREATE INDEX IF NOT EXISTS weekly_plan_days_user_day_idx
  ON public.weekly_plan_days (user_id, dia_semana);

ALTER TABLE public.weekly_plan_days ENABLE ROW LEVEL SECURITY;

CREATE POLICY "weekly_plan_days_select" ON public.weekly_plan_days
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "weekly_plan_days_insert" ON public.weekly_plan_days
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "weekly_plan_days_update" ON public.weekly_plan_days
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "weekly_plan_days_delete" ON public.weekly_plan_days
  FOR DELETE USING (auth.uid() = user_id);
