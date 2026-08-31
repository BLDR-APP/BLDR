-- PROPOSTA REVISAVEL: posts vinculados a exatamente um squad.
-- Baseada no catalogo real exportado em 2026-08-29:
-- bldr_club.arenas(id) e arena_participants(arena_id,user_id,status).
-- NAO APLICAR AUTOMATICAMENTE.

ALTER TABLE public.community_feed
  ADD COLUMN IF NOT EXISTS squad_id UUID;

ALTER TABLE public.community_feed
  DROP CONSTRAINT IF EXISTS community_feed_squad_id_fkey;
ALTER TABLE public.community_feed
  ADD CONSTRAINT community_feed_squad_id_fkey
  FOREIGN KEY (squad_id) REFERENCES bldr_club.arenas(id) ON DELETE CASCADE;

ALTER TABLE public.community_feed
  DROP CONSTRAINT IF EXISTS community_feed_squad_visibility_check;
ALTER TABLE public.community_feed
  ADD CONSTRAINT community_feed_squad_visibility_check CHECK (
    (visibility = 'squad' AND squad_id IS NOT NULL)
    OR (visibility <> 'squad' AND squad_id IS NULL)
  );

CREATE INDEX IF NOT EXISTS community_feed_squad_created
  ON public.community_feed (squad_id, created_at DESC)
  WHERE visibility = 'squad';

DROP POLICY IF EXISTS feed_read_public ON public.community_feed;
CREATE POLICY feed_read_visible
  ON public.community_feed FOR SELECT TO authenticated
  USING (
    visibility = 'public'
    OR user_id = auth.uid()
    OR (
      visibility = 'squad'
      AND EXISTS (
        SELECT 1 FROM bldr_club.arena_participants participant
        WHERE participant.arena_id = squad_id
          AND participant.user_id = auth.uid()
          AND participant.status = 'active'
      )
    )
  );

DROP POLICY IF EXISTS feed_insert_own ON public.community_feed;
CREATE POLICY feed_insert_own
  ON public.community_feed FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND (
      visibility IN ('public', 'private')
      OR (
        visibility = 'squad'
        AND EXISTS (
          SELECT 1 FROM bldr_club.arena_participants participant
          WHERE participant.arena_id = squad_id
            AND participant.user_id = auth.uid()
            AND participant.status = 'active'
        )
      )
    )
  );

DROP POLICY IF EXISTS feed_update_own ON public.community_feed;
CREATE POLICY feed_update_own
  ON public.community_feed FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS feed_delete_own ON public.community_feed;
CREATE POLICY feed_delete_own
  ON public.community_feed FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- Comentarios: somente quem consegue ler o post pode ler/inserir.
DROP POLICY IF EXISTS comments_read ON public.community_comments;
CREATE POLICY comments_read
  ON public.community_comments FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.community_feed feed WHERE feed.id = feed_id)
  );

DROP POLICY IF EXISTS comments_insert_own ON public.community_comments;
CREATE POLICY comments_insert_own
  ON public.community_comments FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (SELECT 1 FROM public.community_feed feed WHERE feed.id = feed_id)
  );

-- Reacoes: mesma regra de leitura do post.
DROP POLICY IF EXISTS reactions_read ON public.community_reactions;
CREATE POLICY reactions_read
  ON public.community_reactions FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.community_feed feed WHERE feed.id = feed_id)
  );

DROP POLICY IF EXISTS reactions_insert ON public.community_reactions;
CREATE POLICY reactions_insert
  ON public.community_reactions FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (SELECT 1 FROM public.community_feed feed WHERE feed.id = feed_id)
  );

-- Validar com tres usuarios authenticated: membro ativo, nao membro e autor.
-- O service_role nao comprova RLS.
