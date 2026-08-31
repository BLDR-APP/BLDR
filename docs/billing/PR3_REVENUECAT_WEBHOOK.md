# PR3 — RevenueCat webhook para Supabase

Status: **implementado localmente, não aplicado e não implantado**.

## Arquitetura

```text
RevenueCat
  -> Authorization: REVENUECAT_WEBHOOK_AUTH
  -> X-RevenueCat-Webhook-Signature: HMAC-SHA256
  -> revenuecat-webhook (Verify JWT OFF; autenticação própria)
     -> parsing e normalização defensivos
     -> auth.admin.getUserById para candidatos UUID
     -> RPC process_revenuecat_event (service_role)
        -> claim de event.id no ledger
        -> decisão de ordenação comercial
        -> update/insert do mirror
        -> uma única transação PostgreSQL
```

A função nunca usa JWT de usuário. As duas camadas são obrigatórias: o header
`Authorization` e a assinatura HMAC oficial. A assinatura é calculada sobre os
bytes crus recebidos (`<t>.<raw_body>`) antes de qualquer `JSON.parse`, comparada
em tempo constante e aceita somente dentro de uma janela de 5 minutos. Secrets,
assinaturas e payloads não aparecem em logs. O payload tem limite de 1 MB e é
persistido integralmente no ledger apenas depois de autenticação e validação
estrutural. Retries recebem uma nova assinatura, mas continuam idempotentes pela
chave `event.id` no ledger.

## Identidade

Ordem de resolução:

1. `app_user_id` UUID existente em `auth.users`;
2. `original_app_user_id` UUID existente;
3. aliases UUID existentes, na ordem recebida;
4. para `TRANSFER`, destinos antes das origens.

Um identificador apenas “parecer UUID” não basta: a função confirma a existência
por `auth.admin.getUserById`, e a RPC repete a garantia consultando `auth.users`.
Se nada resolver, o evento é gravado com `canonical_user_id = NULL` e nenhuma
assinatura é alterada.

`TRANSFER` é sempre ledger-only. O evento não contém sozinho estado comercial
suficiente para conceder ou revogar o entitlement; o evento de compra/entitlement
subsequente é a autoridade.

## Idempotência e atomicidade

`process_revenuecat_event` é `SECURITY DEFINER`, executável apenas por
`service_role`. Ela insere `event_id` com `ON CONFLICT DO NOTHING`. Duplicatas
retornam sucesso sem atualizar o mirror. Claim do ledger e atualização da
assinatura ocorrem na mesma transação da chamada RPC; qualquer erro desfaz ambos.

## Ordenação

Não se usa apenas o timestamp do webhook:

1. `current_period_end` comercial é a barreira principal;
2. um evento cujo período termina antes do período já refletido é ledger-only;
3. dentro do mesmo período — ou quando faltam datas — `event_timestamp_ms` é
   desempate;
4. a semântica do tipo determina status e renovação antes de chegar à RPC.

Assim, uma expiração antiga não derruba uma renovação com término posterior,
enquanto cancelamento e uncancellation do mesmo ciclo podem ser ordenados.

## Mapping

| Evento | Mirror |
|---|---|
| `INITIAL_PURCHASE` | `active`/`trialing`, `will_renew=true` |
| `RENEWAL` | `active`/`trialing`, novo período, renovação ativa |
| `CANCELLATION` | mantém acesso até expiração futura; `will_renew=false` |
| `UNCANCELLATION` | restaura `will_renew=true` |
| `EXPIRATION` | `canceled`, sem renovação |
| `BILLING_ISSUE` | mantém acesso se expiração/grace vigente; senão `past_due` |
| `NON_RENEWING_PURCHASE` | acesso até expiração, sem renovação |
| `SUBSCRIPTION_PAUSED` | acesso até expiração, sem renovação |
| `SUBSCRIPTION_EXTENDED` | estende período sem presumir mudança em renovação |
| `PRODUCT_CHANGE` | ledger-only até evento comercial autoritativo |
| `TRANSFER` | ledger-only |
| outros | ledger-only |

Somente eventos contendo `bldr_club` em `entitlement_id`/`entitlement_ids`
podem atualizar o mirror. Produtos atuais: `CLUBWEEKLY`, `MENSAL`, `ANUAL`.
Quando o produto é desconhecido, duração entre compra e expiração é usada apenas
dentro de faixas conservadoras.

Campos Stripe, Apple e `plan_id` de rows existentes nunca são alterados. Para
uma nova row, a RPC exige estado comercial completo e exige exatamente um plano
CLUB ativo; zero ou múltiplos planos produzem ledger-only. Eventos sem expiração
não concedem nem revogam acesso por inferência. Cancelamentos incompletos podem
apenas registrar `will_renew=false` em uma row já existente.

## Configuração necessária para deploy controlado futuro

- secret `REVENUECAT_WEBHOOK_AUTH` contendo exatamente o valor completo do
  header `Authorization` configurado no RevenueCat;
- secret `REVENUECAT_WEBHOOK_SIGNING_SECRET` contendo o signing secret do
  webhook no RevenueCat Dashboard;
- `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` fornecidos pelo ambiente;
- aplicar e revisar primeiro
  `20260830000022_process_revenuecat_event_rpc.sql`;
- implantar `revenuecat-webhook` com Verify JWT OFF;
- só depois configurar a URL no RevenueCat Dashboard.

Nenhuma dessas ações foi executada neste PR.

## Testes e riscos restantes

Fixtures cobrem Authorization, HMAC válida/inválida, replay expirado, alteração
do raw body, retry com nova assinatura, compra inicial, renewal, cancellation futura,
uncancellation, expiration, billing issue, product change, períodos, resolução
direta/alias/não resolvida, transfer, entitlement alheio, retry e evento fora de
ordem. O contrato atômico precisa ainda de teste integrado em Supabase local ou
staging depois que a RPC proposta for aprovada e aplicada nesse ambiente.

Riscos restantes:

- confirmar que há exatamente um plano CLUB ativo antes do deploy;
- definir política de retenção do payload JSONB;
- validar fixtures oficiais adicionais do Dashboard RevenueCat;
- testar concorrência real de dois requests com o mesmo `event.id` em staging;
- revisar semântica de grace period por store antes do cutover.
