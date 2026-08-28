-- ============================================================
-- Rodar MANUALMENTE no SQL Editor do Supabase de GESTÃO
-- (projeto separado do BLDR — nunca no projeto BLDR)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.feedback (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo           TEXT NOT NULL CHECK (tipo IN
                 ('bug','sugestao','reclamacao','outro')),
  mensagem       TEXT NOT NULL,
  screenshot_url TEXT,
  user_email     TEXT,
  user_name      TEXT,
  app_version    TEXT,
  platform       TEXT,
  protocolo      TEXT UNIQUE,
  status         TEXT NOT NULL DEFAULT 'novo'
                 CHECK (status IN ('novo','em_analise','resolvido')),
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE SEQUENCE IF NOT EXISTS feedback_protocolo_seq START 1000;

CREATE OR REPLACE FUNCTION generate_protocolo()
RETURNS TRIGGER AS $$
BEGIN
  NEW.protocolo := 'BLD-' ||
    TO_CHAR(NOW(), 'YYYY') || '-' ||
    LPAD(NEXTVAL('feedback_protocolo_seq')::TEXT, 4, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_protocolo ON public.feedback;
CREATE TRIGGER set_protocolo
  BEFORE INSERT ON public.feedback
  FOR EACH ROW EXECUTE FUNCTION generate_protocolo();
