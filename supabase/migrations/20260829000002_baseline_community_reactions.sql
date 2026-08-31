-- BASELINE: public.community_reactions
--
-- Schema exportado do catálogo em 2026-08-29. Depende de 20260829000001.
--
-- CONSTRAINT UNIQUE confirmada: (feed_id, user_id, emoji) — seção 03_CONSTRAINT.
-- O toggle de reação no Flutter faz DELETE + INSERT manualmente, o que é
-- compatível com esta constraint. Não alterar para UPSERT sem testar race condition.
--
-- CHECK de emoji confirmado: ARRAY['🔥','💪','⚡','🏆'] — seção 03_CONSTRAINT.
--
-- IDEMPOTÊNCIA: mesmo aviso do baseline_01 se aplica a policies.
-- NÃO APLICAR sem supabase db diff prévio.

CREATE TABLE IF NOT EXISTS public.community_reactions (
  id         UUID        NOT NULL DEFAULT gen_random_uuid(),
  feed_id    UUID        NOT NULL,
  user_id    UUID        NOT NULL,
  emoji      TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT community_reactions_pkey
    PRIMARY KEY (id),
  CONSTRAINT community_reactions_feed_id_fkey
    FOREIGN KEY (feed_id) REFERENCES public.community_feed(id) ON DELETE CASCADE,
  CONSTRAINT community_reactions_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT community_reactions_feed_id_user_id_emoji_key
    UNIQUE (feed_id, user_id, emoji),
  CONSTRAINT community_reactions_emoji_check
    CHECK (emoji = ANY (ARRAY['🔥'::text, '💪'::text, '⚡'::text, '🏆'::text]))
);

GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.community_reactions TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.community_reactions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
  ON public.community_reactions TO service_role;

ALTER TABLE public.community_reactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS reactions_read ON public.community_reactions;
CREATE POLICY reactions_read
  ON public.community_reactions FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS reactions_insert ON public.community_reactions;
CREATE POLICY reactions_insert
  ON public.community_reactions FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS reactions_delete_own ON public.community_reactions;
CREATE POLICY reactions_delete_own
  ON public.community_reactions FOR DELETE TO authenticated
  USING (user_id = auth.uid());
