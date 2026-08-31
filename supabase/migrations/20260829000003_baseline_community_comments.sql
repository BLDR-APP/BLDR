-- BASELINE: public.community_comments
--
-- Schema exportado do catálogo em 2026-08-29. Depende de 20260829000001.
--
-- ATENÇÃO — coluna é "body" (não "content"). Limite: 300 caracteres (CHECK exportado).
--
-- POLICY ausente: somente SELECT existe (comments_read para authenticated).
-- Não há policies de INSERT, UPDATE nem DELETE exportadas do catálogo.
-- Isso significa que, com RLS ativo, usuários autenticados não conseguem
-- escrever comentários via PostgREST. Comportamento intencional ou dívida?
-- Registrar como ponto de revisão antes de ativar feature no Flutter.
--
-- NÃO APLICAR sem supabase db diff prévio.

CREATE TABLE IF NOT EXISTS public.community_comments (
  id         UUID        NOT NULL DEFAULT gen_random_uuid(),
  feed_id    UUID        NOT NULL,
  user_id    UUID        NOT NULL,
  body       TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT community_comments_pkey
    PRIMARY KEY (id),
  CONSTRAINT community_comments_feed_id_fkey
    FOREIGN KEY (feed_id) REFERENCES public.community_feed(id) ON DELETE CASCADE,
  CONSTRAINT community_comments_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT community_comments_body_check
    CHECK (char_length(body) <= 300)
);

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.community_comments TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.community_comments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.community_comments TO service_role;

ALTER TABLE public.community_comments ENABLE ROW LEVEL SECURITY;

-- Apenas a policy SELECT foi exportada do catálogo.
-- Policies de escrita ausentes em produção — não adicionar aqui sem decisão explícita.
DROP POLICY IF EXISTS comments_read ON public.community_comments;
CREATE POLICY comments_read
  ON public.community_comments FOR SELECT TO authenticated
  USING (true);
