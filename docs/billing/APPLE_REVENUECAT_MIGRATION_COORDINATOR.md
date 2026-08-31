# Apple legacy → RevenueCat — coordenador controlado

Status: implementação local, sem deploy e sem execução de candidato.

## Contrato

`apple-revenuecat-migration` aceita somente `POST` autenticado e deriva o UUID
canônico por `auth.getUser()`. O body nunca escolhe `user_id`.

- `claim`: aceita `eligible` ou `in_progress` com lease expirada, usa lease de 900 segundos e chama a
  RPC com `p_allow_failed_retry = false`.
- `verify_and_complete`: recebe apenas `claim_id`, revalida row/lease, consulta
  RevenueCat no backend e só então chama a RPC de completion.
- `fail`: recebe `claim_id` e apenas `RC_SYNC_FAILED`; textos arbitrários do
  client não atravessam a borda.

`review_required`, `completed`, `failed` e claims ainda vivas não são
claimables nesta primeira versão. Não existe retry automático.

## Verificação RevenueCat

A implementação usa exclusivamente endpoints `GET` read-only da API v2:

- `/customers/{customer_id}/subscriptions` para localizar histórico;
- `/subscriptions/{subscription_id}/entitlements` para provar que a assinatura
  Apple concedeu o resource ID configurado de `bldr_club`;
- `/customers/{customer_id}/active_entitlements` para classificar o entitlement
  comprovado como ativo ou inativo.

`project_id` e o resource ID interno do entitlement (`entl...`) vêm somente de
configuração server-side. `customer_id` é sempre o UUID Supabase derivado do JWT.
O endpoint v1 `/v1/subscribers/{app_user_id}` não é usado porque possui semântica
Get or Create Customer.

Ausência de active entitlement só resulta em `inactive_entitlement` quando a
assinatura Apple e sua associação ao entitlement foram comprovadas. Customer
404 ou ausência dessa associação resulta em `RC_NO_PURCHASE_EVIDENCE` e `failed`,
nunca em `completed`. Erro HTTP, paginação inválida ou payload malformado falha
fechado sem consumir a claim.

O backend exige:

1. resposta HTTP 200 e shape v2 válido;
2. lista completa de páginas consultada com host/projeto/customer fixos;
3. resource ID configurado do BLDR CLUB ligado a uma assinatura Apple;
4. claim ainda viva quando a RPC atômica de completion for executada.

A lookup key lógica `bldr_club` não é comparada com o resource ID `entl...`.
Ela é enviada somente à RPC como assertion canônica já exigida pela infraestrutura.

Falha de rede ou HTTP RevenueCat mantém o claim até expirar. Falta de evidência
ou identidade divergente produz `failed` com código server-side sanitizado.

## Secret para futuro deploy

- `REVENUECAT_SECRET_API_KEY`: chave v2 server-side com somente
  `customer_information:customers:read` e
  `customer_information:subscriptions:read`;
- `REVENUECAT_PROJECT_ID`: ID do projeto RevenueCat;
- `REVENUECAT_BLDR_CLUB_ENTITLEMENT_ID`: resource ID interno (`entl...`) do
  entitlement BLDR CLUB.

Nenhum valor real foi configurado. Essas configurações não devem ser adicionadas
ao Flutter, `dart_defines`, repositório ou logs. Os secrets Supabase já esperados
continuam `SUPABASE_URL`, `SUPABASE_ANON_KEY` e `SUPABASE_SERVICE_ROLE_KEY`.

## Flutter

`RunAppleRevenueCatMigration` é acionado em background pelo lifecycle depois que
a sessão e a identidade RevenueCat estão configuradas. Não bloqueia o startup,
não tem UI e não participa de purchase/restore. A ordem é:

1. validar sessão e identidade RevenueCat;
2. obter claim no backend;
3. revalidar identidade e sessão;
4. executar `syncPurchasesForMigration(eligible: true)` uma única vez;
5. revalidar que a sessão não mudou;
6. pedir `verify_and_complete` ao backend, que conclui active ou inactive.

O CustomerInfo local não marca a migração como concluída. Restore Purchases
permanece totalmente separado.

## Pendências antes da primeira execução

1. revisão de código;
2. criar/configurar as três variáveis RevenueCat apenas no Supabase;
3. deploy manual da Edge Function com Verify JWT habilitado ou, se desabilitado,
   preservar obrigatoriamente a validação interna `auth.getUser()`;
4. validação negativa pós-deploy;
5. autorização específica para expor/invocar o use case para um candidato.

Nenhum desses passos foi executado neste trabalho.
