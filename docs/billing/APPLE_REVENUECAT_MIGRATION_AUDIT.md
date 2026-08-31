# Apple legacy → RevenueCat — auditoria técnica read-only

Data da auditoria: 2026-08-30 (America/Sao_Paulo)  
Escopo: código local e consultas `SELECT` no Supabase Production. Nenhuma compra, restauração, sincronização, chamada à Apple/RevenueCat ou escrita em Production foi executada.

## Resumo executivo

- Há 82 registros identificáveis como Apple legado. Todos têm cadeia válida `auth.users` → `user_profiles` → `user_subscriptions`, produto `MENSAL`, período `monthly` e status armazenado `active`.
- Apenas 3 têm `current_period_end` futuro. Um desses 3 também contém `stripe_subscription_id`, portanto exige revisão; sob a regra mínima segura, restam 2 candidatos Apple ativos.
- Os outros 79 registros estão expirados apesar de continuarem com `status=active`. O gate atual usa somente o status, sem validar `current_period_end`, e pode manter acesso indevido.
- `syncPurchasesForMigration()` existe, está protegido pela feature flag/configuração/identidade RevenueCat e não possui call site de produção. Não existe marcador one-shot server-side.
- A Edge Function `verify-apple-receipt` publicada em Production é **UNSAFE**. Além de confiar no `user_id` do body, possui um bypass de `21002` que fabrica sucesso e expiração de 30 dias e grava `user_subscriptions` com service-role.
- Existe drift crítico: a função publicada não corresponde ao arquivo local. O deployment tem o bypass `21002`, `plan_id` fixo, `apple_product_id`, `billing_period` e `onConflict: user_id`; o arquivo local não contém esses comportamentos e tenta usar o produto Apple como `plan_id`.

## 1. Fluxo Apple atual

Fluxo observado:

`App Store` → `in_app_purchase` → `PaymentService.purchaseStream` → `PaymentService._verifyPurchase()` → `verify-apple-receipt` → `user_subscriptions` → `GetCurrentSubscription`/`UserSubscription.hasClubAccess` → gates.

### Arquivos e responsabilidades

- `lib/services/payment_service.dart`: StoreKit, consulta de produtos, início de compra, listener de transações, envio do receipt à Edge Function e leitura da assinatura.
- `lib/features/subscription/data/repositories/subscription_repository_impl.dart`: adapter do serviço legado para o domínio.
- `lib/features/subscription/domain/usecases/subscription_usecases.dart`: use cases de planos, compra Apple e streams de sucesso/erro.
- `lib/features/subscription/presentation/checkout_screen.dart`: compra Apple mensal/anual e listeners de resultado.
- `lib/features/subscription/presentation/paywall_screen.dart`: compra semanal/mensal/anual e listeners de resultado.
- `supabase/functions/verify-apple-receipt/index.ts`: fonte local da validação legada; diverge do deployment.
- `supabase/config.toml`: `verify_jwt=true` para a função.
- `lib/models/subscription_plan.dart`: `UserSubscription.hasClubAccess`.
- Telas que consultam `GetCurrentSubscription`: dashboard, ranking, treinos, nutrição, perfil/settings e HAVOK/CLUB.

### Call sites

- `verify-apple-receipt`: 1 call site — `PaymentService._verifyPurchase()`.
- `purchaseStream`: 1 assinatura — construtor singleton de `PaymentService`.
- A assinatura do stream não é retida/cancelada; a instância é singleton.

### Compra e eventos

- Compra nova: a tela escolhe o identificador (`CLUBWEEKLY`, `MENSAL` ou `ANUAL`), `processApplePurchase()` consulta o produto e chama `buyNonConsumable()`.
- `pending`: apenas log; não há estado de UI específico emitido.
- `error`: registra erro e conclui a transação caso `pendingCompletePurchase`; não emite `_purchaseErrorController` nesse ramo.
- `purchased` e `restored`: seguem o mesmo caminho, `_verifyPurchase()`.
- `canceled`: não há tratamento explícito.
- Em validação bem-sucedida, chama `completePurchase()` e emite sucesso. Em falha, não conclui a transação para permitir nova entrega pelo StoreKit e emite erro.
- Não foi encontrado botão funcional de restore legado. O texto de restauração no paywall não possui ação. Eventos `restored` são tratados caso o StoreKit os entregue por outro caminho.

### Dados e identidade enviados

- `user_id`: `Supabase auth.currentUser.id` no app.
- `receipt_data`: `PurchaseDetails.verificationData.serverVerificationData`.
- `product_id`: `PurchaseDetails.productID`.
- Authorization: access token da sessão Supabase.
- Não são enviados `transaction_id` nem `original_transaction_id`.

### Gates atuais

`PaymentService.getCurrentUserSubscription()` filtra apenas `status active/trialing`. `UserSubscription.hasClubAccess` também considera somente esses status. Nenhum dos dois exige `current_period_end > now()`. Portanto, os 79 registros Apple expirados podem ser interpretados como CLUB pelo fluxo legado.

## 2. Auditoria de `verify-apple-receipt`

### Input e autenticação

- Body aceito: `receipt_data`, `user_id`, `product_id`.
- Obrigatórios: `receipt_data` e `user_id`; `product_id` é opcional na prática.
- Nenhum identificador de transação é aceito.
- O gateway está configurado localmente com `verify_jwt=true`, o que exige um JWT válido para invocação normal.
- A função não deriva o UUID do JWT, não compara `JWT.sub` com `body.user_id` e aceita um UUID arbitrário fornecido pelo cliente autenticado.

Conclusão: o JWT restringe a chamada a alguém autenticado, mas não associa o receipt ao usuário cujo registro será alterado.

### Validação Apple publicada em Production

- Usa `https://buy.itunes.apple.com/verifyReceipt` e faz fallback para sandbox em `21007`.
- Aceita `status=0`.
- Em `21002`, o deployment **força sucesso**, usa o `product_id` fornecido pelo cliente e fabrica `expires_date_ms = agora + 30 dias`.
- Seleciona `latest_receipt_info[0]`; não ordena nem determina de forma robusta a transação vigente.
- Não valida bundle ID, product ID permitido, subscription group, ambiente, expiração futura, cancellation/revocation, ownership, `transaction_id` ou `original_transaction_id`.
- Não verifica que o produto retornado pela Apple corresponde ao produto do request.

### Persistência publicada

- Usa `SUPABASE_SERVICE_ROLE_KEY`.
- Faz `upsert` em `user_subscriptions` com conflito em `user_id`.
- Escreve `user_id` do body, `plan_id` fixo, `apple_product_id`, `status=active`, `current_period_end`, `payment_provider=apple_iap`, `billing_period` e `updated_at`.
- Não persiste receipt, `transaction_id` ou `original_transaction_id`.
- Não existe proteção contra replay ou associação da mesma transação/receipt a outro usuário.
- Não existe unicidade por `original_transaction_id` porque esse valor sequer é armazenado.

### Drift deployment × repositório

O deployment de Production (publicado há cerca de nove meses no momento da auditoria) diverge do arquivo local:

- deployment contém bypass de `21002`; fonte local não contém;
- deployment usa `plan_id` UUID fixo; fonte local usa `latestTransaction.product_id` como `plan_id`;
- deployment escreve `apple_product_id` e `billing_period`; fonte local não;
- deployment especifica `onConflict: user_id`; fonte local não;
- deployment registra `user_id` e produto em log; fonte local atual não possui esse log.

Esse drift impede tratar a fonte local como prova do comportamento de Production.

### Classificação

**VERIFY_APPLE_RECEIPT_SECURITY: UNSAFE**

Riscos concretos:

1. Um usuário autenticado pode indicar outro `user_id` no body.
2. O bypass `21002` publicado permite transformar recibo rejeitado/local em assinatura ativa fabricada.
3. O `product_id` do cliente influencia o bypass e não é validado contra allowlist/receipt.
4. Replay e reutilização entre usuários não são impedidos.
5. Revogação, cancelamento, ownership e identidade original da transação não são validados.
6. `status=active` é gravado mesmo sem comprovar vigência comercial robusta.
7. A escrita service-role contorna RLS corretamente endurecido no PR1; portanto o risco persiste apesar da proteção contra DML do cliente.
8. A função retorna mensagens internas de erro ao cliente e registra identificadores desnecessários.

## 3. Apple legado em Production

Critério de descoberta: `payment_provider='apple_iap' OR apple_product_id IS NOT NULL`.

Snapshot read-only:

- Apple rows total: 82
- Cadeia `auth.users` válida: 82
- `user_profiles` correspondente: 82
- Status armazenado: 82 `active`
- Produto: 82 `MENSAL`
- Billing period: 82 `monthly`
- `current_period_end` futuro: 3
- `current_period_end` expirado: 79
- `current_period_end` nulo: 0
- Com `stripe_subscription_id`: 1
- RevenueCat mirror preenchido: 0

Classificação mutuamente exclusiva recomendada:

- `APPLE_CANDIDATE_ACTIVE`: 2 — identidade válida, Apple coerente, status compatível, fim futuro e sem conflito Stripe.
- `APPLE_HISTORICAL_OR_EXPIRED`: 79 — fim no passado; não executar sync automático com base apenas no banco.
- `APPLE_REVIEW_REQUIRED`: 1 — fim futuro, mas o mesmo registro também possui `stripe_subscription_id`; identidade comercial híbrida deve ser resolvida antes de qualquer sync.
- `APPLE_NOT_ELIGIBLE`: 0 — reservado a cadeia de identidade inválida, origem/produto impossível ou ausência de fim; nenhum caso adicional encontrado.

Observação: os dois candidatos ativos sem conflito foram identificados somente por UUID mascarado no trabalho de auditoria. Nenhum dado pessoal ou receipt foi versionado.

## 4. Comportamento real de `syncPurchasesForMigration`

- Implementação: `RevenueCatServiceImpl.syncPurchasesForMigration()`.
- Exige `eligible=true`.
- `_requireReady()` exige feature flag habilitada, SDK configurado e `_identifiedUserId` conhecido.
- O fluxo de configuração/lifecycle exige sessão Supabase com UUID válido e configura/login do SDK diretamente com esse UUID; o fluxo BLDR não chama `Purchases.logOut()` e não cria identidade anônima.
- A chamada executa `Purchases.syncPurchases()`, depois `getCustomerInfo()`, mapeia e publica o resultado.
- Erros viram `Failure`; não existe retry automático dentro do método.
- A fila `_serial` evita corrida entre operações RevenueCat na instância.
- O booleano `eligible` é fornecido pelo chamador; não há consulta server-side nem prova persistente de elegibilidade dentro do método.
- Não há call site de produção. Ocorrências fora da implementação/interface existem apenas em testes.
- `RevenueCatLifecycle` configura/limpa contexto conforme a sessão, mas não chama sync.
- Com `REVENUECAT_BILLING_ENABLED=false`, o SDK permanece fora do billing normal.

**SYNC_PURCHASES CURRENTLY AUTOMATIC: NO**  
**SYNC_PURCHASES CURRENT CALL SITES: nenhum em código de produção**

## 5. Regra segura de elegibilidade proposta

Não basta o app passar `eligible=true`. A decisão deve ser emitida atomicamente pelo backend e vinculada a `auth.uid()`.

Pré-condições recomendadas:

1. sessão Supabase válida e não em transição de logout/troca de conta;
2. UUID Supabase válido;
3. RevenueCat configurado e App User ID exatamente igual ao UUID Supabase atual;
4. registro server-side classificado `APPLE_CANDIDATE_ACTIVE`, sem Stripe e sem ambiguidade;
5. estado de migração elegível e ainda não concluído;
6. aquisição atômica de uma tentativa/lease pelo backend antes do sync;
7. revalidação da mesma identidade imediatamente antes e depois de `syncPurchases()`;
8. `completed` somente após `getCustomerInfo()` confirmar `bldr_club` no usuário esperado.

Não executar em todo launch. O disparo deve ocorrer em uma jornada controlada, com mensagem clara, observabilidade e retry deliberado. Falha, indisponibilidade ou ausência do entitlement não devem conceder acesso nem marcar conclusão silenciosamente.

## 6. Marcador one-shot e idempotência

### Opções

- Campo em `user_subscriptions`: simples, mas mistura orquestração de migração com o mirror comercial e é inadequado para histórico/conflitos.
- Tabela dedicada: separa estado, permite auditoria, lease, tentativas e erros sanitizados.
- Metadata/profile: mistura conceitos e tende a expor escrita/leitura indevida.
- Somente local: insuficiente após reinstalação, troca de dispositivo ou uso simultâneo.
- Server + cache local: servidor é autoridade; cache local evita UI repetitiva, mas nunca decide elegibilidade.

### Recomendação

Criar futuramente uma tabela dedicada, por exemplo `apple_revenuecat_migration_state`, com chave canônica `user_id`, estado, contagem de tentativas, lease/expiração de tentativa, timestamps, erro sanitizado e confirmação do App User ID. Escrita somente por backend/service-role/RPC segura; cliente autenticado no máximo lê a própria linha.

Estados recomendados: `pending`, `in_progress`, `completed`, `failed_retriable`, `review_required`, `not_eligible`. `attempted` isoladamente não distingue tentativa ainda em voo de falha recuperável.

Comportamentos:

- reinstalação/troca de aparelho: o estado server-side permanece;
- dois dispositivos: claim atômico/lease impede sync concorrente;
- logout/troca A→B: validar novamente sessão e RevenueCat App User ID; cancelar a jornada de A;
- sync falha/RevenueCat indisponível: `failed_retriable`, sem loop automático;
- sync sem entitlement: `review_required` ou falha controlada, não `completed`;
- assinatura já presente: `getCustomerInfo()` confirma e permite concluir sem nova repetição desnecessária.

## 7. `syncPurchases` versus Restore Purchases

- `syncPurchases`: ferramenta interna e controlada para migração de receipt do StoreKit para o RevenueCat; limitada à coorte elegível e ao marcador server-side.
- Restore Purchases: ação explícita do usuário para recuperar compras legítimas, inclusive após reinstalação/troca de aparelho.

O futuro botão **Restaurar compras** deve permanecer disponível independentemente do marcador one-shot. O marcador de migração não pode bloquear restore legítimo. A fundação RevenueCat já implementa `restorePurchases()`, mas não há call site funcional de UI hoje; o texto exibido no paywall não está ligado a uma ação.

## 8. Cutover e aposentadoria do legado

### Antes do cutover

- manter o billing legado funcionando;
- manter feature flag RevenueCat desligada no fluxo comercial normal;
- executar migração controlada apenas após o próximo PR de segurança/idempotência;
- enquanto compras legadas ainda forem possíveis, `verify-apple-receipt` é operacionalmente necessário, embora o deployment atual seja inseguro e demande tratamento P0 separado antes de qualquer espera prolongada.

### No cutover

- RevenueCat passa a autoridade comercial Apple;
- compra usa packages/offerings RevenueCat;
- restore usa RevenueCat;
- gate usa o resultado canônico definido para RevenueCat/Supabase mirror;
- impedir novas invocações do fluxo legado na mesma janela controlada.

### Depois do cutover

- desabilitar/remover o deployment de `verify-apple-receipt` após confirmar que não há transações legadas pendentes que dependam dele;
- retirar o listener `in_app_purchase` e o código de compra/verificação legado quando seguro;
- preservar somente o que ainda for necessário para code redemption até existir substituto deliberado.

Call sites/camadas a remover ou desativar:

- assinatura de `purchaseStream` no construtor de `PaymentService`;
- `PaymentService.fetchAppleProducts`, `processApplePurchase`, `_handlePurchaseUpdates` e `_verifyPurchase`;
- endpoint `_verifyPurchase` → `verify-apple-receipt`;
- `SubscriptionRepository.processApplePurchase` e implementação;
- `ProcessApplePurchase` e listeners legados de sucesso/erro;
- handlers de compra Apple em `checkout_screen.dart` e `paywall_screen.dart`;
- substituir o texto de restore por ação RevenueCat explícita;
- reavaliar `presentCodeRedemptionSheet` separadamente, sem confundi-lo com restore.

**Se `verify-apple-receipt` permanecer acessível depois do cutover, a vulnerabilidade ainda poderá alterar `user_subscriptions`: YES.** A função publicada aceita `user_id` do body, possui bypass `21002` e escreve com service-role, contornando RLS. Remover apenas os call sites do app reduz exposição acidental, mas não neutraliza o endpoint público conhecido.

## Resultado solicitado

APPLE ROWS TOTAL: 82  
APPLE TEMPORALLY ACTIVE: 3  
APPLE MIGRATION CANDIDATES: 2  
APPLE REVIEW_REQUIRED: 1  
APPLE PRODUCT IDS: MENSAL  
VERIFY_APPLE_RECEIPT CALL SITES: 1  
VERIFY_APPLE_RECEIPT SECURITY: UNSAFE  
REPLAY/ASSOCIATION RISK: YES  
SYNC_PURCHASES IMPLEMENTED: YES  
SYNC_PURCHASES CURRENTLY AUTOMATIC: NO  
SYNC_PURCHASES CURRENT CALL SITES: nenhum em produção  
ONE-SHOT SERVER MARKER EXISTS: NO  
RECOMMENDED MIGRATION STATE STORAGE: tabela dedicada server-side + cache local não autoritativo  
RESTORE REMAINS USER-TRIGGERED: YES  
VERIFY_APPLE_RECEIPT REQUIRED BEFORE CUTOVER: YES, enquanto compras/transações legadas ainda dependerem dele; o deployment atual exige mitigação P0  
VERIFY_APPLE_RECEIPT REQUIRED AFTER CUTOVER: NO  
PRODUCTION WRITES: NO  
REVENUECAT API CALLED: NO  
APPLE API CALLED: NO  
CUTOVER PERFORMED: NO

## Próxima etapa proposta — somente uma

**PR Apple P0 — endurecer `verify-apple-receipt` antes da migração.** Primeiro versionar a definição realmente publicada e substituir o bypass/associação insegura por validação que derive `user_id` do JWT, valide integralmente receipt/produto/bundle/vigência/revogação e imponha ownership/idempotência por identificador de transação. O PR deve incluir migration revisável para ownership/idempotência se necessária, testes de abuso e plano de rollout/rollback. Não iniciar sync Apple nem criar o marcador de migração até esse P0 estar aplicado e validado.
