-- Comunidade: badge CLUB seguro, exclusão própria, bloqueio e denúncia.
-- Revisar antes de aplicar. Esta migration não é executada automaticamente.

CREATE TABLE IF NOT EXISTS public.community_blocks (
  blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT community_blocks_pkey PRIMARY KEY (blocker_id, blocked_id),
  CONSTRAINT community_blocks_not_self CHECK (blocker_id <> blocked_id)
);

ALTER TABLE public.community_blocks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS community_blocks_read_own ON public.community_blocks;
CREATE POLICY community_blocks_read_own
  ON public.community_blocks FOR SELECT TO authenticated
  USING (blocker_id = auth.uid());

DROP POLICY IF EXISTS community_blocks_insert_own ON public.community_blocks;
CREATE POLICY community_blocks_insert_own
  ON public.community_blocks FOR INSERT TO authenticated
  WITH CHECK (blocker_id = auth.uid());

DROP POLICY IF EXISTS community_blocks_delete_own ON public.community_blocks;
CREATE POLICY community_blocks_delete_own
  ON public.community_blocks FOR DELETE TO authenticated
  USING (blocker_id = auth.uid());

GRANT SELECT, INSERT, DELETE ON public.community_blocks TO authenticated;

CREATE TABLE IF NOT EXISTS public.community_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reported_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feed_id UUID NOT NULL REFERENCES public.community_feed(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (
    reason IN ('spam', 'harassment', 'inappropriate_content', 'false_information', 'other')
  ),
  details TEXT CHECK (details IS NULL OR char_length(details) <= 1000),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT community_reports_not_self CHECK (reporter_id <> reported_user_id),
  CONSTRAINT community_reports_one_per_post UNIQUE (reporter_id, feed_id)
);

CREATE INDEX IF NOT EXISTS community_reports_status_created_idx
  ON public.community_reports (status, created_at);

ALTER TABLE public.community_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS community_reports_insert_own ON public.community_reports;
CREATE POLICY community_reports_insert_own
  ON public.community_reports FOR INSERT TO authenticated
  WITH CHECK (
    reporter_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.community_feed feed
      WHERE feed.id = feed_id
        AND feed.user_id = reported_user_id
    )
  );

-- Denúncias não são públicas. Somente o backend com service_role pode revisá-las.
GRANT INSERT ON public.community_reports TO authenticated;

DROP POLICY IF EXISTS feed_delete_own ON public.community_feed;
CREATE POLICY feed_delete_own
  ON public.community_feed FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- Uma relação de bloqueio em qualquer direção oculta os posts entre as partes.
DROP POLICY IF EXISTS feed_hide_blocked_relationships ON public.community_feed;
CREATE POLICY feed_hide_blocked_relationships
  ON public.community_feed AS RESTRICTIVE FOR SELECT TO authenticated
  USING (
    NOT EXISTS (
      SELECT 1
      FROM public.community_blocks block
      WHERE (block.blocker_id = auth.uid() AND block.blocked_id = user_id)
         OR (block.blocker_id = user_id AND block.blocked_id = auth.uid())
    )
  );

-- Expõe apenas o direito ao badge, sem abrir user_subscriptions via RLS.
CREATE OR REPLACE FUNCTION public.community_author_metadata(p_user_ids UUID[])
RETURNS TABLE (user_id UUID, is_club_member BOOLEAN)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT requested.user_id,
         EXISTS (
           SELECT 1
           FROM public.user_subscriptions subscription
           JOIN public.subscription_plans plan ON plan.id = subscription.plan_id
           WHERE subscription.user_id = requested.user_id
             AND subscription.status IN ('active', 'trialing')
             AND plan.plan_type = 'club'
             AND plan.is_active = true
         ) AS is_club_member
  FROM unnest(COALESCE(p_user_ids, ARRAY[]::UUID[])) AS requested(user_id)
  WHERE auth.uid() IS NOT NULL;
$$;

REVOKE ALL ON FUNCTION public.community_author_metadata(UUID[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.community_author_metadata(UUID[]) TO authenticated;

