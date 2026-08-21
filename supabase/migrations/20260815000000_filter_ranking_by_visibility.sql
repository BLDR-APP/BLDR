-- Filtra o ranking de acordo com a preferência de privacidade do usuário.
--
-- Estratégia: adicionar coluna `ranking_visible` à tabela bldr_club.club_ranking
-- (denormalizada para evitar cross-schema join em runtime), mantida em sincronia
-- com public.user_profiles.ranking_visible via trigger.
--
-- As queries Flutter adicionam .eq('ranking_visible', true) como camada extra.

-- 1. Adicionar coluna (idempotente)
ALTER TABLE bldr_club.club_ranking
  ADD COLUMN IF NOT EXISTS ranking_visible BOOLEAN NOT NULL DEFAULT TRUE;

-- 2. Backfill a partir do valor já salvo em user_profiles
UPDATE bldr_club.club_ranking cr
SET ranking_visible = COALESCE(up.ranking_visible, TRUE)
FROM public.user_profiles up
WHERE up.id = cr.user_id;

-- 3. Trigger: sincroniza ranking_visible quando user_profiles é atualizado
CREATE OR REPLACE FUNCTION public.sync_ranking_visible()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE bldr_club.club_ranking
  SET ranking_visible = COALESCE(NEW.ranking_visible, TRUE)
  WHERE user_id = NEW.id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_ranking_visible ON public.user_profiles;

CREATE TRIGGER trg_sync_ranking_visible
AFTER UPDATE OF ranking_visible ON public.user_profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_ranking_visible();
