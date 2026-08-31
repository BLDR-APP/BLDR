-- PROPOSTA REVISÁVEL — Fase 4: social graph público.
-- NÃO APLICAR AUTOMATICAMENTE.
-- Regra aprovada: seguir não exige aprovação; a aba Seguindo mostra
-- somente posts públicos dos perfis seguidos.

CREATE TABLE public.community_follows (
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  followed_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT community_follows_pkey PRIMARY KEY (follower_id, followed_id),
  CONSTRAINT community_follows_not_self CHECK (follower_id <> followed_id)
);

CREATE INDEX community_follows_followed_created_idx
  ON public.community_follows (followed_id, created_at DESC);

ALTER TABLE public.community_follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY community_follows_read_authenticated
  ON public.community_follows FOR SELECT TO authenticated
  USING (true);

CREATE POLICY community_follows_insert_own
  ON public.community_follows FOR INSERT TO authenticated
  WITH CHECK (follower_id = auth.uid());

CREATE POLICY community_follows_delete_own
  ON public.community_follows FOR DELETE TO authenticated
  USING (follower_id = auth.uid());

GRANT SELECT, INSERT, DELETE ON public.community_follows TO authenticated;

-- Antes de aplicar, validar com dois usuários authenticated:
-- seguir/deixar de seguir, impedir auto-follow e impedir escrita em nome de outro.
