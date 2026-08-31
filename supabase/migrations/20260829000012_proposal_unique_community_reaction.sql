-- PROPOSTA REVISAVEL: uma reacao por usuario/post.
-- Regra de produto confirmada em 2026-08-29.
--
-- NAO APLICAR AUTOMATICAMENTE. Antes da revisao, executar a consulta abaixo
-- com um usuario authenticated e confirmar o impacto da deduplicacao:
--   SELECT feed_id, user_id, count(*)
--   FROM public.community_reactions
--   GROUP BY feed_id, user_id HAVING count(*) > 1;
--
-- Havendo duplicatas, preserva a reacao mais recente (created_at, depois id).

WITH ranked AS (
  SELECT id,
         row_number() OVER (
           PARTITION BY feed_id, user_id
           ORDER BY created_at DESC, id DESC
         ) AS position
  FROM public.community_reactions
)
DELETE FROM public.community_reactions reaction
USING ranked
WHERE reaction.id = ranked.id
  AND ranked.position > 1;

ALTER TABLE public.community_reactions
  DROP CONSTRAINT IF EXISTS community_reactions_feed_id_user_id_emoji_key;

ALTER TABLE public.community_reactions
  ADD CONSTRAINT community_reactions_feed_id_user_id_key
  UNIQUE (feed_id, user_id);

-- Rollback estrutural (nao restaura reacoes removidas pela deduplicacao):
-- ALTER TABLE public.community_reactions
--   DROP CONSTRAINT IF EXISTS community_reactions_feed_id_user_id_key;
-- ALTER TABLE public.community_reactions
--   ADD CONSTRAINT community_reactions_feed_id_user_id_emoji_key
--   UNIQUE (feed_id, user_id, emoji);
