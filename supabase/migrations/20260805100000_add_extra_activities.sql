-- F3: atividades extras (fora do plano semanal)
CREATE TABLE IF NOT EXISTS public.extra_activities (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date          DATE NOT NULL,
  activity_type TEXT NOT NULL DEFAULT 'outro',
  duration_min  INT,
  notes         TEXT,
  xp_earned     INT NOT NULL DEFAULT 50,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS extra_activities_user_date
  ON public.extra_activities (user_id, date);

ALTER TABLE public.extra_activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user own select" ON public.extra_activities
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "user own insert" ON public.extra_activities
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "user own delete" ON public.extra_activities
  FOR DELETE USING (user_id = auth.uid());
