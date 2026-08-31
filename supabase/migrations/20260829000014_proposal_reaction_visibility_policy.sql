-- PROPOSTA REVISAVEL: impedir reacao em posts que o usuario nao pode ler.
-- NAO APLICAR AUTOMATICAMENTE.
--
-- Esta policy cobre posts publicos e privados do proprio autor. Posts de squad
-- devem ser adicionados somente depois que arenas/arena_participants forem
-- exportadas do Supabase real e a relacao do post com um squad for versionada.

DROP POLICY IF EXISTS reactions_insert ON public.community_reactions;
CREATE POLICY reactions_insert
  ON public.community_reactions FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.community_feed feed
      WHERE feed.id = feed_id
        AND (feed.visibility = 'public' OR feed.user_id = auth.uid())
    )
  );
