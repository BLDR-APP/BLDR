# Resultado da importação Stripe legado → RevenueCat

Status: **PASS** — os 12 candidatos finais e exclusivamente autorizados foram
importados sequencialmente. Cada candidato recebeu exatamente uma chamada
inicial `POST /v1/receipts`; não houve retry, concorrência ou bulk import.

## Pre-check

- TARGET CANDIDATES: 12
- UUIDs distintos: 12
- Stripe subscription IDs distintos: 12
- Piloto `filipefreitas97@outlook.com` presente: NO
- Registro `REVIEW_REQUIRED` presente: NO
- Registros com período nulo/expirado: 0
- Elegíveis temporalmente no Supabase: 12
- Price ID esperado: `price_1RzkacRyVeX3wSWABwK43Myq`
- RevenueCat Stripe Public API Key: disponível e validada sem exposição
- PRECHECK: PASS

## Resultado consolidado

- IMPORT ATTEMPTED: 12
- IMPORT HTTP 200: 12
- IMPORT FAILED: 0
- IMPORT NOT ATTEMPTED: 0
- RC CUSTOMERS FOUND: 12
- APP USER ID MATCH: 12
- STRIPE SUBSCRIPTIONS RECOGNIZED: 12
- BLDR_CLUB ACTIVE: 12
- ENTITLEMENT FAILURES: 0
- ANONYMOUS CANONICAL IDS: 0
- EXPIRATION CONSISTENT: 12
- RENEWAL STATE CONSISTENT: 12

## Validação sanitizada por usuário

| USER/EMAIL | UUID MASKED | SUB MASKED | HTTP | RC CUSTOMER | PRODUCT OK | BLDR_CLUB | EXPIRATION | RENEWAL |
|---|---|---|---:|---|---|---|---|---|
| jjoaolrocha@gmail.com | 194ff474…d9e3 | sub_1SL6…wgYc | 200 | YES | YES | ACTIVE | OK | OK |
| pedroviana020104@gmail.com | 2093fa17…78f9 | sub_1SL7…Tkum | 200 | YES | YES | ACTIVE | OK | OK |
| danivhmenin@gmail.com | 2126a2cd…7cc5 | sub_1SSK…yMDh | 200 | YES | YES | ACTIVE | OK | OK |
| leomenin@gmail.com | 28b6f1a2…d1a1 | sub_1Tw0…VpaP | 200 | YES | YES | ACTIVE | OK | OK |
| jpfvilandez@gmail.com | 32cb97c7…e1b8 | sub_1SLU…6jA5 | 200 | YES | YES | ACTIVE | OK | OK |
| gabrielbrandaodelima@gmail.com | 34afd099…de2f | sub_1SL6…nSXf | 200 | YES | YES | ACTIVE | OK | OK |
| khalil.sophia@icloud.com | 4a4ed139…628c | sub_1SKs…2UxR | 200 | YES | YES | ACTIVE | OK | OK |
| jpabreuazevedo@gmail.com | 4f8a8ed9…f6ad | sub_1SMy…T2Sy | 200 | YES | YES | ACTIVE | OK | OK |
| bederoma@gmail.com | 78deb91d…c99e | sub_1SLU…IoEv | 200 | YES | YES | ACTIVE | OK | OK |
| josefaleirosjunior@gmail.com | 916479aa…b9b5 | sub_1Ted…kKTb | 200 | YES | YES | ACTIVE | OK | OK |
| brunnacapanemaa@gmail.com | c61723cf…d3fd | sub_1SQc…vh8r | 200 | YES | YES | ACTIVE | OK | OK |
| f7t87xgrbq@privaterelay.appleid.com | ea4e3e5a…d9bd | sub_1SS3…Tr91 | 200 | YES | YES | ACTIVE | OK | OK |

Cada resposta retornou `original_app_user_id` exatamente igual ao UUID Supabase
enviado, uma subscription Stripe associada ao produto esperado, entitlement
`bldr_club` com expiração compatível, ausência de falha de cobrança/cancelamento
e nenhum alias `$RCAnonymousID` como identidade canônica.

## Limites preservados

- Nenhum endpoint Stripe de escrita foi chamado.
- Nenhuma subscription, customer, price, product ou cobrança Stripe foi criado,
  atualizado ou cancelado.
- O Supabase foi usado somente no pre-check com `SELECT`; o mirror RevenueCat não
  foi preenchido manualmente.
- O webhook RevenueCat → Supabase não foi alterado e permanece SANDBOX ONLY.
- Nenhum usuário além dos 12 alvos foi enviado.
- Apple não foi processado.
- Billing, gates, feature flags e cutover permaneceram inalterados.

## Confirmações finais

- STRIPE BILLING MUTATED: NO
- SUPABASE MUTATED: NO
- OTHER USERS IMPORTED: 0
- CUTOVER PERFORMED: NO
- STRIPE LEGACY ELIGIBLE MIGRATION: PASS
