-- PROPOSTA REVISÁVEL — comentários com no máximo dois níveis.
-- NÃO APLICAR AUTOMATICAMENTE.

ALTER TABLE public.community_comments
  ADD COLUMN parent_id UUID REFERENCES public.community_comments(id)
    ON DELETE CASCADE,
  ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE INDEX community_comments_feed_created_idx
  ON public.community_comments (feed_id, created_at);
CREATE INDEX community_comments_parent_created_idx
  ON public.community_comments (parent_id, created_at)
  WHERE parent_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.validate_community_comment_parent()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
DECLARE parent_row public.community_comments;
BEGIN
  IF NEW.parent_id IS NULL THEN RETURN NEW; END IF;
  SELECT * INTO parent_row FROM public.community_comments WHERE id = NEW.parent_id;
  IF parent_row.id IS NULL OR parent_row.feed_id <> NEW.feed_id THEN
    RAISE EXCEPTION 'invalid comment parent';
  END IF;
  IF parent_row.parent_id IS NOT NULL THEN
    RAISE EXCEPTION 'comment nesting is limited to two levels';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER community_comments_validate_parent
  BEFORE INSERT OR UPDATE OF parent_id, feed_id ON public.community_comments
  FOR EACH ROW EXECUTE FUNCTION public.validate_community_comment_parent();

DROP POLICY IF EXISTS comments_read ON public.community_comments;
CREATE POLICY comments_read ON public.community_comments
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.community_feed f
      WHERE f.id = feed_id AND (f.visibility = 'public' OR f.user_id = auth.uid())
    )
  );

CREATE POLICY comments_insert_own ON public.community_comments
  FOR INSERT TO authenticated WITH CHECK (
    user_id = auth.uid() AND EXISTS (
      SELECT 1 FROM public.community_feed f
      WHERE f.id = feed_id AND (f.visibility = 'public' OR f.user_id = auth.uid())
    )
  );

CREATE POLICY comments_update_own ON public.community_comments
  FOR UPDATE TO authenticated USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY comments_delete_own_or_post_owner ON public.community_comments
  FOR DELETE TO authenticated USING (
    user_id = auth.uid() OR EXISTS (
      SELECT 1 FROM public.community_feed f
      WHERE f.id = feed_id AND f.user_id = auth.uid()
    )
  );

-- Policies para visibility='squad' serão adicionadas somente depois do
-- vínculo feed↔squad e da membership serem versionados e revisados.
