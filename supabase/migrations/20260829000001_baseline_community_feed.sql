-- BASELINE: public.community_feed
--
-- Tabela existente no Supabase sem migration correspondente.
-- Schema exportado do catálogo pg_catalog em 2026-08-29.
-- Fonte: inventário direto (section 02_COLUMN, 03_CONSTRAINT, 04_INDEX, 06_POLICY).
--
-- IDEMPOTÊNCIA: CREATE TABLE IF NOT EXISTS não reconcilia colunas divergentes.
-- Se a tabela já existir com schema diferente, esta migration não detecta nem
-- corrige o drift — exige inspeção manual prévia.
--
-- POLICIES: DROP POLICY IF EXISTS + CREATE POLICY modifica objetos existentes.
-- Não é sem efeito colateral se a tabela já tiver policies em produção.
-- Aplicar em produção apenas após confirmar que as policies abaixo são idênticas
-- às existentes (verificar com: SELECT * FROM pg_policies WHERE tablename = 'community_feed').
--
-- NÃO APLICAR sem supabase db diff prévio.

CREATE TABLE IF NOT EXISTS public.community_feed (
  id          UUID        NOT NULL DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL,
  event_type  TEXT        NOT NULL,
  payload     JSONB       NOT NULL DEFAULT '{}'::jsonb,
  visibility  TEXT        NOT NULL DEFAULT 'public'::text,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT community_feed_pkey
    PRIMARY KEY (id),
  CONSTRAINT community_feed_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices exportados do catálogo (section 04_INDEX)
CREATE INDEX IF NOT EXISTS community_feed_created
  ON public.community_feed (created_at DESC)
  WHERE (visibility = 'public'::text);

CREATE INDEX IF NOT EXISTS community_feed_public_created
  ON public.community_feed (created_at DESC)
  WHERE (visibility = 'public'::text);

CREATE INDEX IF NOT EXISTS community_feed_user_created
  ON public.community_feed (user_id, created_at DESC);

-- Grants exportados (section 08_TABLE_GRANT — anon, authenticated, service_role)
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.community_feed TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.community_feed TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.community_feed TO service_role;

-- RLS: exportado como rls_enabled = true (section 01_TABLE)
ALTER TABLE public.community_feed ENABLE ROW LEVEL SECURITY;

-- Policies exportadas (section 06_POLICY)
-- AVISO: DROP + CREATE altera estado existente — não é idempotente em sentido estrito.
DROP POLICY IF EXISTS feed_read_public ON public.community_feed;
CREATE POLICY feed_read_public
  ON public.community_feed FOR SELECT TO authenticated
  USING ((visibility = 'public'::text) OR (user_id = auth.uid()));

DROP POLICY IF EXISTS feed_insert_own ON public.community_feed;
CREATE POLICY feed_insert_own
  ON public.community_feed FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
