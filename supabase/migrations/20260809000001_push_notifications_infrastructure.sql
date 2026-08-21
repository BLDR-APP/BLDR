-- push_notifications_log: histórico de pushes enviados pelo sistema de gestão
CREATE TABLE IF NOT EXISTS public.push_notifications_log (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title          TEXT        NOT NULL,
  body           TEXT        NOT NULL,
  type           TEXT,
  target_mode    TEXT        NOT NULL,
  target_segment JSONB,
  sent_count     INT         DEFAULT 0,
  failed_count   INT         DEFAULT 0,
  sent_by        TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: apenas service role pode ler/inserir (app Flutter nunca acessa esta tabela)
ALTER TABLE public.push_notifications_log ENABLE ROW LEVEL SECURITY;
-- Nenhuma policy pública — service role bypassa RLS por padrão

-- platform_type: distingue iOS de Android para segmentação de push
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS platform_type TEXT
  CHECK (platform_type IN ('ios', 'android', 'web'));
