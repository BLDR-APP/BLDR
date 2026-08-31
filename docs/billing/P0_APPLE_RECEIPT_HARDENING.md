# P0 — Apple legacy `verify-apple-receipt` hardening

Data: 2026-08-31  
Estado: implementado e testado localmente; **não publicado em Production**.

## Escopo e estado preservado

Este PR endurece somente a Edge Function Apple legada. Não altera RevenueCat, Stripe, Google Play, gates, feature flags, Flutter, paywall, compra, restore, schema ou dados.

O único call site Flutter, `PaymentService._verifyPurchase()`, já envia:

- `Authorization: Bearer <Supabase access token>`;
- `receipt_data`;
- `product_id` obtido do `PurchaseDetails`;
- `user_id` da sessão, mantido temporariamente por compatibilidade.

Portanto, nenhuma mudança de cliente foi necessária.

## Drift preservado e documentado

### Fonte local anterior

A fonte local anterior:

- consultava Apple Production e fazia fallback para Sandbox em `21007`;
- aceitava `user_id` do body sem vinculá-lo ao JWT;
- não validava bundle, allowlist de produto, revogação ou IDs de transação;
- tentava gravar o `product_id` Apple diretamente em `plan_id`;
- não representava integralmente o deployment de Production.

### Deployment auditado em Production

A implementação publicada, auditada read-only antes deste PR:

- contém bypass explícito de `21002`;
- converte `21002` em sucesso e fabrica aproximadamente 30 dias de acesso;
- usa o `product_id` fornecido pelo cliente no resultado fabricado;
- aceita `user_id` do body sem compará-lo ao JWT;
- grava com service-role;
- usa `plan_id` fixo `d082af8c-216a-4499-a1f6-1fb84ac08a5f`;
- escreve `apple_product_id`, `billing_period` e usa `onConflict: user_id`.

O patch local passa a representar o contrato de persistência legítimo do deployment, mas remove integralmente o bypass e fecha a associação de identidade.

## Contrato seguro final

### Autenticação e identidade

1. Apenas `POST` é aceito; `OPTIONS` permanece disponível para CORS.
2. O header `Authorization: Bearer` é obrigatório.
3. O access token é validado por `Supabase Auth getUser()`.
4. O usuário canônico é exclusivamente `auth.users.id` retornado pelo JWT.
5. Se `body.user_id` estiver presente, deve ser idêntico ao UUID autenticado.
6. Mismatch retorna `403` antes da consulta Apple e antes de qualquer escrita.
7. Service-role existe somente dentro da função e recebe o UUID canônico já validado.

### Validação Apple fail-closed

- Consulta primeiro `https://buy.itunes.apple.com/verifyReceipt`.
- Faz fallback para Sandbox apenas quando Production retorna `21007`.
- Qualquer outro status Apple, inclusive `21002`, falha sem escrita.
- Exige `status=0`.
- Exige `receipt.bundle_id = com.bldr-fitness.app`, conforme o bundle real do projeto.
- Allowlist legada: `MENSAL` e `ANUAL`, conforme StoreKit/configuração e call sites reais.
- Exige que o produto solicitado exista dentro das transações do receipt.
- Seleciona a transação compatível com maior `expires_date_ms`.
- Exige expiração válida e futura derivada da Apple.
- Rejeita transação com `cancellation_date` ou `cancellation_date_ms`.
- Exige `transaction_id` e `original_transaction_id` presentes.
- Resposta incompleta, parsing inválido ou produto desconhecido falham sem escrita.

`transaction_id` e `original_transaction_id` são validados, mas ainda não persistidos porque o schema atual não os possui. Ownership/replay durável por transação exige migration própria e permanece como hardening futuro; não foi incluído silenciosamente neste P0.

### Persistência

Somente após todas as validações, a função faz `upsert` por `user_id` com:

- `user_id`: UUID canônico do JWT;
- `plan_id`: UUID do plano legado já usado em Production;
- `apple_product_id`: produto validado no receipt;
- `status`: `active`, somente porque a expiração Apple comprovada é futura;
- `current_period_end`: derivado exclusivamente de `expires_date_ms`;
- `payment_provider`: `apple_iap`;
- `billing_period`: `monthly` para `MENSAL`, `annual` para `ANUAL`;
- `updated_at`: horário do servidor.

Nenhum caminho inventa expiração, produto, transação ou estado comercial.

## Testes

Arquivo: `supabase/functions/verify-apple-receipt/logic_test.ts`

Resultado: **12 passed, 0 failed**.

Cobertura:

1. JWT ausente → `401`, zero escrita.
2. JWT inválido → `401`, zero escrita.
3. `body.user_id != JWT user` → `403`, zero escrita.
4. Apple `21002` → `422`, zero escrita.
5. erro Apple genérico → zero escrita.
6. resposta incompleta → zero escrita.
7. produto desconhecido → zero escrita.
8. expiração ausente/inválida → zero escrita.
9. receipt válido → atualiza somente o usuário autenticado.
10. service-role não pode ser direcionada pelo body a outro usuário.
11. cancelamento ou expiração não criam acesso sintético.
12. `21007` preserva fallback legítimo Production → Sandbox.

Validações executadas:

```text
deno fmt --check supabase/functions/verify-apple-receipt
deno check supabase/functions/verify-apple-receipt/index.ts \
  supabase/functions/verify-apple-receipt/logic_test.ts
deno test supabase/functions/verify-apple-receipt/logic_test.ts
```

A busca por `21002`, `30 days`, `30 * 24`, `mock`, `fallback`, `fake`, `simulated` e `verify-apple-receipt` não encontrou bypass no código executável. `21002` e produtos inválidos permanecem somente como casos de teste de rejeição.

## Arquivos alterados

- `supabase/functions/verify-apple-receipt/index.ts`
- `supabase/functions/verify-apple-receipt/logic.ts`
- `supabase/functions/verify-apple-receipt/logic_test.ts`
- `docs/billing/P0_APPLE_RECEIPT_HARDENING.md`

Flutter não foi alterado.

## Deployment manual — não executado

Não usar `supabase db push` e não alterar migration history.

Quando houver autorização explícita:

1. No Supabase Dashboard do projeto BLDR APP Production, abrir **Edge Functions → verify-apple-receipt → Code**.
2. Confirmar que o deployment atual ainda é a versão vulnerável documentada e não houve mudança concorrente.
3. Substituir `index.ts` exatamente pelo arquivo local revisado.
4. Adicionar `logic.ts` exatamente como o arquivo local revisado.
5. Não publicar `logic_test.ts`; ele é somente teste local.
6. Em **Settings**, confirmar que a verificação JWT continua habilitada. Não desabilitar `verify_jwt`.
7. Confirmar que os secrets existentes `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` e `APPLE_SHARED_SECRET` estão disponíveis, sem ler, copiar ou rotacionar valores.
8. Revisar o diff no Dashboard e confirmar ausência de qualquer bypass `21002` ou geração sintética de expiração.
9. Fazer um único deploy controlado da função; não alterar outras Edge Functions.
10. Após o deploy, verificar logs sem receipts/tokens e executar smoke controlado: request sem JWT deve falhar; request autenticada com usuário divergente deve falhar; compra/restore Apple legítimo deve ser testado separadamente em Sandbox com uma conta autorizada.
11. Em qualquer regressão do fluxo Apple válido, interromper novos testes e avaliar rollback da função, sem modificar dados de assinatura automaticamente.

## Resultado final

PRODUCTION 21002 BYPASS IDENTIFIED: YES  
21002 BYPASS REMOVED LOCALLY: YES  
FABRICATED 30-DAY ACCESS POSSIBLE AFTER PATCH: NO  
JWT REQUIRED: YES  
CANONICAL USER FROM JWT: YES  
BODY USER ID TRUSTED: NO  
USER ID MISMATCH REJECTED: YES  
INVALID APPLE RECEIPT CAN GRANT ACCESS: NO  
UNKNOWN PRODUCT CAN GRANT ACCESS: NO  
SERVICE ROLE STILL SERVER-ONLY: YES  
LEGACY VALID APPLE FLOW PRESERVED: YES  
REVENUECAT FLOW CHANGED: NO  
SYNC_PURCHASES EXECUTED: NO  
PRODUCTION DEPLOYED: NO  
CUTOVER PERFORMED: NO

## Risco residual deliberadamente fora deste PR

Sem persistir e impor ownership único por `original_transaction_id`, este patch não entrega idempotência/anti-replay durável entre contas. Ele elimina a escolha arbitrária de usuário pelo body e o bypass crítico imediato, mas o próximo hardening deverá propor schema e rollout revisáveis antes da migração Apple via `syncPurchases()`.
