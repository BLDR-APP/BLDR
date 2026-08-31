-- PROPOSTA REVISAVEL: impedir que a mesma atividade de wearable seja
-- publicada mais de uma vez pelo mesmo usuario.
--
-- NAO APLICAR AUTOMATICAMENTE. Esta migration depende do payload v1 com:
-- payload.wearable.provider e payload.wearable.external_activity_id.
-- Verificar duplicatas antes da aplicacao; CREATE UNIQUE INDEX falhara se
-- dados historicos repetidos existirem.

CREATE UNIQUE INDEX IF NOT EXISTS community_feed_wearable_activity_unique
  ON public.community_feed (
    user_id,
    ((payload -> 'wearable' ->> 'provider')),
    ((payload -> 'wearable' ->> 'external_activity_id'))
  )
  WHERE event_type = 'wearable_activity'
    AND payload -> 'wearable' ->> 'provider' IS NOT NULL
    AND payload -> 'wearable' ->> 'external_activity_id' IS NOT NULL;

-- Rollback estrutural:
-- DROP INDEX IF EXISTS public.community_feed_wearable_activity_unique;
