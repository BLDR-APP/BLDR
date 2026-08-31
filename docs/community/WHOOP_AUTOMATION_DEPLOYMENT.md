# WHOOP — implantação da detecção automática

Status: código pronto para revisão. Nada deste fluxo foi aplicado ou implantado
automaticamente.

## Ordem segura

1. Revisar e aplicar somente
   `20260829000018_proposal_wearable_activity_confirmation.sql`.
2. Reimplantar `whoop-workouts` para ativar a reconciliação idempotente.
3. Implantar somente a nova Edge Function `whoop-webhook`, com `Verify JWT` desligado.
   A função não é pública de fato: ela rejeita requisições sem a assinatura HMAC
   oficial da WHOOP.
4. No WHOOP Developer Dashboard, cadastrar a URL abaixo como webhook **v2**:
   `https://<PROJECT_REF>.supabase.co/functions/v1/whoop-webhook`.
5. Não alterar `WHOOP_CLIENT_SECRET`. A mesma secret já usada pelo OAuth é usada
   internamente para validar a assinatura do webhook.
6. Não implantar `bldr-club-notifier` neste fluxo. A notificação inserida usa o
   mecanismo de push que já está ativo no banco.

## Teste funcional

1. Entrar no aplicativo com usuário `authenticated` e WHOOP conectada.
2. Criar ou editar uma atividade curta no aplicativo WHOOP.
3. Aguardar o processamento `SCORED`.
4. Confirmar no Supabase que existe uma única row em `wearable_activities` para
   o `external_activity_id`.
5. Confirmar o recebimento da push “Treino detectado pela WHOOP”.
6. Abrir a push e escolher o treino planejado ou “atividade externa”.
7. Verificar `completed_at`, XP retornado pela RPC, workout card, semana atual e
   streak no aplicativo.
8. Reenviar o mesmo webhook e confirmar que não há atividade, treino, XP ou push
   duplicados.

## Comportamentos deliberados

- A detecção não concede XP sozinha.
- O usuário precisa confirmar qual treino foi realizado.
- A atividade é registrada no horário real da WHOOP, mesmo se confirmada depois.
- Uma atividade excluída na WHOOP antes da confirmação deixa de ser confirmável.
- Se ela já tiver sido confirmada, uma exclusão posterior na WHOOP é registrada,
  mas não revoga automaticamente treino ou XP. Essa reversão exige regra de
  produto e auditoria próprias.
- A função `whoop-workouts` continua sendo a reconciliação sob demanda quando o
  usuário abre o seletor de atividades. O webhook é o caminho em tempo real.
