# PR2 — Auditoria e proposta de schema RevenueCat

Status: **proposta não aplicada**.

## Estado local auditado

- `billing_period`: enum local com `monthly` e `annual`.
- `subscription_status`: `active`, `canceled`, `past_due`, `unpaid`, `trialing`.
- `subscription_plan_type`: `core`, `club` (o enum real se chama
  `subscription_plan_type`, não `plan_type`).
- `user_subscriptions`: mantém identidade, plano, campos Stripe, status,
  período, datas de ciclo, trial e cancelamento. O código local também evidencia
  drift de Production, pois `verify-apple-receipt` usa `payment_provider` e
  `apple_product_id` é conhecido em Production, mas ambos não aparecem na
  migration-base local.
- RLS endurecido pelo PR1: `authenticated` possui somente `SELECT` da própria
  assinatura e do próprio payment intent; planos ativos permanecem legíveis.
- Escritores atuais: `verify-apple-receipt` e `stripe-webhook` usam
  `service_role`. Leitores/gates usam `status`, `plan_id`, `billing_period` e as
  datas existentes.
- Dependências SQL adicionais: cron de arenas e função do card Community fazem
  join por `plan_id`, `plan_type` e status. Nenhum desses contratos é alterado.

## Payload RevenueCat validado

A documentação oficial atual define `event.id` como identificador único e
informa que retries reutilizam o mesmo ID e `event_timestamp_ms`. Eventos de
ciclo incluem `app_user_id`, `original_app_user_id`, `aliases`, `product_id`,
`entitlement_ids`, `store`, `purchased_at_ms` e `expiration_at_ms`.

O BLDR não precisa persistir `revenuecat_original_app_user_id`: a fundação não
cria usuários anônimos e o App User ID canônico é o UUID do Supabase. O futuro
webhook ainda deverá consultar `original_app_user_id` e `aliases` no payload ao
resolver identidade, mas persistir cópias históricas não é necessário para o
mirror atual.

Referências oficiais:

- https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields
- https://www.revenuecat.com/docs/integrations/webhooks/sample-events

## Schema proposto

Novas colunas nullable em `user_subscriptions`:

- `revenuecat_app_user_id UUID`: identidade canônica, limitada ao mesmo
  `user_id` da assinatura.
- `revenuecat_entitlement_id TEXT`: entitlement refletido; quando preenchido,
  deve ser `bldr_club`.
- `revenuecat_product_id TEXT`: identificador comercial recebido no evento.
- `revenuecat_store TEXT`: origem conforme RevenueCat. Sem enum/check fechado,
  pois a lista de stores é externa e pode evoluir.
- `revenuecat_last_event_id TEXT` e `revenuecat_last_event_at TIMESTAMPTZ`:
  checkpoint observável da última atualização aceita.
- `will_renew BOOLEAN`: nullable distingue “desconhecido/legado” de `false`.

Reutilização segura:

- `current_period_start` recebe futuramente `purchased_at_ms` quando aplicável.
- `current_period_end` recebe futuramente `expiration_at_ms`.
- `status` e `billing_period` continuam sendo os contratos dos gates atuais.
- `apple_product_id` pode continuar representando o produto Apple legado; o
  campo neutro `revenuecat_product_id` evita atribuir produtos de outras stores
  a uma coluna Apple.
- `plan_id` não é alterado nem inferido neste PR.

Os checks são `NOT VALID`: não escaneiam nem reescrevem as 99 linhas legadas,
mas passam a proteger qualquer linha nova ou atualizada. A validação formal
poderá ocorrer após revisão do futuro backfill.

## Idempotência

`revenuecat_last_event_id` sozinho não é suficiente. Exemplo: processar E1,
depois E2, e depois receber retry de E1 faria o checkpoint conter E2 e permitiria
E1 novamente. Por isso a migration propõe `revenuecat_processed_events`, com
`event_id` como chave primária. O futuro webhook poderá reservar o ID na mesma
transação da atualização do mirror; conflito de chave identifica retry.

A tabela separa a identidade externa da identidade resolvida:

- `revenuecat_app_user_id TEXT`: valor bruto do evento, sem presumir UUID;
- `canonical_user_id UUID`: `auth.users.id` resolvido pelo futuro webhook;
- `payload JSONB`: evento original necessário para auditoria e reprocessamento
  controlado.

O índice da identidade bruta é justificável para localizar eventos históricos,
migrados ou associados por aliases durante auditorias. O índice do UUID canônico
atende consultas e reprocessamentos por usuário BLDR. O payload fica restrito ao
backend: a tabela tem RLS habilitado, nenhum policy para cliente, privilégios
revogados de `anon`/`authenticated` e escrita concedida a `service_role`.

Como o payload pode conter atributos do assinante, o futuro webhook não deverá
registrá-lo em logs. Retenção e eventual expurgo devem ser definidos antes do
cutover, sem reduzir a capacidade de auditoria exigida neste PR.

Eventos fora de ordem ainda exigirão que o webhook compare
`event_timestamp_ms` com `revenuecat_last_event_at` antes de atualizar o mirror;
o ledger resolve duplicidade, enquanto o timestamp resolve ordenação.

## Compatibilidade e impacto

- As sete colunas são nullable e não possuem default: as 99 linhas existentes
  permanecem com os mesmos valores e significado.
- Nenhum `UPDATE`, backfill, import ou reconciliação é executado.
- Nenhuma coluna, enum ou valor legado é removido ou renomeado.
- A adição de `weekly` é estritamente aditiva.
- Policies e grants das três tabelas legadas não são recriados nem modificados.
- Apple, Stripe, Flutter, gates e Edge Functions permanecem inalterados.
- A migration usa guards contra drift (`IF NOT EXISTS`) e não deve ser aplicada
  via `supabase db push`; o SQL deve ser revisado e executado isoladamente apenas
  após aprovação.

## Validação pós-aplicação planejada

Antes de qualquer rollout do webhook:

1. repetir o roteiro autenticado do PR1 para SELECT próprio e bloqueio de DML;
2. confirmar isolamento entre dois JWTs;
3. confirmar `payment_intents` read-only e planos ativos legíveis;
4. testar INSERT/UPDATE/DELETE do ledger e do mirror com `service_role` em uma
   transação revertida;
5. confirmar contagem e hashes funcionais das 99 linhas legadas antes/depois.
