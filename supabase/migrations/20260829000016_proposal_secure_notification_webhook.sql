-- PROPOSTA REVISAVEL: remove JWT service_role do trigger de notificacoes.
-- NAO APLICAR AUTOMATICAMENTE.
--
-- Ordem obrigatoria:
-- 1. Rotacionar/revogar a chave service_role exposta.
-- 2. Criar o mesmo segredo aleatorio em:
--    - Edge Function secret: BLDR_CLUB_WEBHOOK_SECRET
--    - Vault secret: BLDR_CLUB_WEBHOOK_SECRET
-- 3. Fazer deploy da Edge Function bldr-club-notifier atualizada.
-- 4. Aplicar esta migration e testar com usuario authenticated.
--
-- O trigger tribunal-notification tambem continha a chave exposta e precisa ser
-- reconfigurado separadamente junto da Edge Function notify-squad.

CREATE OR REPLACE FUNCTION bldr_club.send_notification_webhook()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = bldr_club, public, vault, net
AS $$
DECLARE
  webhook_secret TEXT;
BEGIN
  SELECT decrypted_secret INTO webhook_secret
  FROM vault.decrypted_secrets
  WHERE name = 'BLDR_CLUB_WEBHOOK_SECRET'
  LIMIT 1;

  IF webhook_secret IS NULL OR webhook_secret = '' THEN
    RAISE EXCEPTION 'Vault secret BLDR_CLUB_WEBHOOK_SECRET ausente';
  END IF;

  PERFORM net.http_post(
    url := 'https://vhxwujoymxkxyiognual.supabase.co/functions/v1/bldr-club-notifier',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || webhook_secret
    ),
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', to_jsonb(NEW)
    ),
    timeout_milliseconds := 10000
  );
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION bldr_club.send_notification_webhook() FROM PUBLIC;

DROP TRIGGER IF EXISTS "send-bldr-push" ON bldr_club.notifications;
CREATE TRIGGER "send-bldr-push"
AFTER INSERT ON bldr_club.notifications
FOR EACH ROW EXECUTE FUNCTION bldr_club.send_notification_webhook();
