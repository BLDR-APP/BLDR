-- B13 (BACKLOG_FUNCIONAL.md) — remove a chave service_role do trigger
-- `tribunal-notification`. PROPOSTA: NÃO APLICAR sem os passos 0–3 abaixo.
--
-- O trigger foi criado pelo painel (Database Webhook) e não está no repo.
-- Antes de aplicar, conferir a definição real com:
--
--   select tgname, tgrelid::regclass, pg_get_triggerdef(oid)
--   from pg_trigger where tgname = 'tribunal-notification';
--
-- Esperado: AFTER INSERT em bldr_club.tribunal_posts executando
-- supabase_functions.http_request('<url>/functions/v1/notify-squad', 'POST',
-- '{"Authorization":"Bearer eyJ...service_role..."}', ...). Se a tabela, o
-- evento ou a URL forem outros, ajustar o CREATE TRIGGER abaixo.
--
-- Ordem:
-- 0. Baixar a função: `supabase functions download notify-squad` e fazê-la
--    validar `Authorization: Bearer <NOTIFY_SQUAD_WEBHOOK_SECRET>` (mesmo
--    padrão de bldr-club-notifier) antes de ler o payload.
-- 1. Gerar um segredo aleatório (`openssl rand -hex 32`) e gravá-lo em:
--    - Edge Function secret: NOTIFY_SQUAD_WEBHOOK_SECRET
--    - Vault: select vault.create_secret('<segredo>', 'NOTIFY_SQUAD_WEBHOOK_SECRET');
-- 2. Deploy de notify-squad.
-- 3. Aplicar esta migration e testar um check-in/chat no squad.
-- (Rotação das chaves e do JWT secret: ver plano no fim do arquivo.)

create or replace function bldr_club.send_tribunal_webhook()
returns trigger
language plpgsql
security definer
set search_path = bldr_club, public, vault, net
as $$
declare
  webhook_secret text;
begin
  select decrypted_secret into webhook_secret
  from vault.decrypted_secrets
  where name = 'NOTIFY_SQUAD_WEBHOOK_SECRET'
  limit 1;

  -- Sem segredo, não notifica, mas também não derruba o check-in/chat.
  if webhook_secret is null or webhook_secret = '' then
    raise warning 'Vault secret NOTIFY_SQUAD_WEBHOOK_SECRET ausente';
    return new;
  end if;

  perform net.http_post(
    url := 'https://vhxwujoymxkxyiognual.supabase.co/functions/v1/notify-squad',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || webhook_secret
    ),
    -- Mesmo formato do Database Webhook, para notify-squad não mudar o parse.
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', to_jsonb(new),
      'old_record', null
    ),
    timeout_milliseconds := 10000
  );
  return new;
end;
$$;

revoke all on function bldr_club.send_tribunal_webhook() from public;

drop trigger if exists "tribunal-notification" on bldr_club.tribunal_posts;
create trigger "tribunal-notification"
after insert on bldr_club.tribunal_posts
for each row execute function bldr_club.send_tribunal_webhook();

-- Conferência depois de aplicar (não deve aparecer nenhum "eyJ"):
--   select tgname, pg_get_triggerdef(oid) from pg_trigger
--   where pg_get_triggerdef(oid) ilike '%eyJ%';
--   select proname from pg_proc where prosrc ilike '%eyJhbGci%';
--
-- Plano de rotação (fora desta migration, no painel):
-- a. Criar a chave publicável (sb_publishable_...) e uma secreta (sb_secret_...).
-- b. App: trocar SUPABASE_ANON_KEY pela publicável em dart_defines e publicar
--    build nas lojas. Usuários com build antigo param de funcionar no passo e.
-- c. Edge Functions (25 usam SUPABASE_SERVICE_ROLE_KEY): passar a usar a chave
--    secreta nova (secret próprio) e redeploy.
-- d. Conferir a 000016 (send-bldr-push) aplicada e nenhum outro "eyJ" no banco.
-- e. Desativar as chaves legadas (anon + service_role) e rotacionar o JWT secret.
