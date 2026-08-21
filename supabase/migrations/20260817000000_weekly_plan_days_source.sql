-- Adiciona coluna source em weekly_plan_days para distinguir templates HAVOK
-- de templates criados pelo usuário no picker manual.
ALTER TABLE public.weekly_plan_days
  ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'user';
