CREATE TABLE IF NOT EXISTS public.whats_new_seen (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  whats_new_id UUID NOT NULL,
  seen_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, whats_new_id)
);

ALTER TABLE public.whats_new_seen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuário vê apenas o próprio" ON public.whats_new_seen
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Usuário insere apenas o próprio" ON public.whats_new_seen
  FOR INSERT WITH CHECK (user_id = auth.uid());
