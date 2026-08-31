# Auditoria Stripe legado → RevenueCat

Status: **auditoria READ-ONLY concluída; nenhuma importação executada**.

- Fonte: Supabase Production, `public.user_subscriptions` e `auth.users`.
- Data da leitura: 2026-08-31 01:27:15 UTC.
- Escopo: rows com `stripe_subscription_id IS NOT NULL`.
- O Stripe e o RevenueCat não foram consultados.
- Tokens Stripe aparecem completos somente no CSV local candidato.

## Resultado

- STRIPE ROWS TOTAL: 18
- VALID AUTH USER CHAIN: 18
- CANDIDATE_ACTIVE: 15
- CANDIDATE_INACTIVE: 2
- REVIEW_REQUIRED: 1
- DUPLICATE STRIPE SUBSCRIPTION IDS: 0 grupos
- DUPLICATE USER IDS: 0 grupos
- CUSTOMER ID INCONSISTENCIES: 0 rows
- CSV CANDIDATES GENERATED: 15

## Critérios aplicados

1. `REVIEW_REQUIRED` tem precedência quando falta a cadeia com `auth.users`, o
   token não começa com `sub_`, existe duplicidade de token/usuário ou há uma
   incompatibilidade estrutural de provider.
2. `CANDIDATE_ACTIVE`: `active`/`trialing` e término nulo ou futuro.
3. Demais registros são `CANDIDATE_INACTIVE`.
4. `stripe_customer_id` foi auditado separadamente e não excluiu registros.
5. A coluna `cancel_at_period_end` não existe no schema real e aparece como N/A.

## Registros auditados

| subscription row | user_id / App User ID | subscription token | customer ID | status | período | início | fim | cancel_at_period_end | plan_id | payment_provider | auth user | classificação | observação |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 43afbc96-c5ed-4863-99d8-38c6e644944d | 194ff474-bf0e-455a-ba3c-e35706d2d9e3 | sub_1SL6…wgYc | cus_THgB…FI0f | active | monthly | 2026-08-22 18:31:48+00 | 2026-09-22 18:31:48+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| 24ad33c7-f9b7-4ccd-9350-d781d1a5d588 | 2093fa17-1246-4b9b-b0ab-49faf76c78f9 | sub_1SL7…Tkum | cus_THga…9NVO | active | monthly | 2026-08-22 18:56:49+00 | 2026-09-22 18:56:49+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| d8d5e735-92b4-460b-9ad1-ef86dd037f2b | 2126a2cd-657d-4f72-a6f9-b36540f17cc5 | sub_1SSK…yMDh | cus_TP9D…OvlM | active | monthly | 2026-08-11 16:59:45+00 | 2026-09-11 16:59:45+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| 1bf84e77-28e5-4b4d-b8ca-0f644e5e2609 | 28b6f1a2-22fd-4b6e-b30a-2247844ad1a1 | sub_1Tw0…VpaP | cus_UvsO…PQ2m | active | monthly | 2026-08-22 15:43:09+00 | 2026-09-22 15:43:09+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| b6a4a342-1534-4272-b2f9-2ce8df36b0a5 | 2d3d5915-92f6-450d-bd6a-0f59f3aad11c | sub_1TTD…8ocW | cus_US7S…z7My | active | monthly | — | — | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | Período ausente; candidato somente pela regra expressa de término nulo. |
| 0dc10294-b410-4a93-b89d-db319863e288 | 32cb97c7-1ca7-4ee6-aca9-1943a345e1b8 | sub_1SLU…6jA5 | cus_TI54…l0I0 | active | monthly | 2026-08-23 20:14:40+00 | 2026-09-23 20:14:40+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| 48fd6723-489b-495f-bed2-45abdbd33570 | 34afd099-a98e-4923-b749-9aff2793de2f | sub_1SL6…nSXf | cus_THg0…ZdnB | active | monthly | 2026-08-22 18:21:05+00 | 2026-09-22 18:21:05+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| b057d5c8-7f61-47d8-89e5-faddf4fd04df | 4a4ed139-5f98-46b8-8648-b7f6dc8d628c | sub_1SKs…2UxR | cus_THQu…PgQV | active | monthly | 2026-08-22 02:44:49+00 | 2026-09-22 02:44:49+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| c51943bc-6666-4a36-abb5-05286484093b | 4f8a8ed9-9105-4f59-9c71-bfb8c895f6ad | sub_1SMy…T2Sy | cus_TJc0…krVi | active | monthly | 2026-08-27 22:20:35+00 | 2026-09-27 22:20:35+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| d08e4c02-7b43-4fd9-8a1c-495fa44e72de | 752eb5dd-3477-4e61-a3b8-322b84af61d7 | sub_1TTT…9Ut6 | cus_USOe…Hq5m | active | monthly | 2026-08-04 21:17:59+00 | 2026-09-04 21:17:59+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| d99ed639-6d08-42ac-89c3-314a6c5f96fc | 78deb91d-f151-4d20-aadd-d7f4405fc99e | sub_1SLU…IoEv | cus_TI4n…g8t6 | active | monthly | 2026-08-23 19:57:25+00 | 2026-09-23 19:57:25+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| 7f328237-c42b-4ad2-bc29-05309a2e0915 | 916479aa-9799-4782-b1a6-ce6ea6f6b9b5 | sub_1Ted…kKTb | cus_Udvf…3yuC | active | monthly | 2026-08-11 16:07:49+00 | 2026-09-11 16:07:49+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| a2c08649-0369-4f77-a044-ece275ab0f2e | 99cec582-5cbd-4331-9e6c-5d0b0b091096 | sub_1T4q…NzVr | cus_U2wp…YxXq | active | annual | 2026-02-25 23:01:48+00 | — | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | Término ausente; candidato somente pela regra expressa de término nulo. |
| c29c3ae9-413e-43fd-82a9-16dbf3c34bee | c61723cf-98e5-4765-9979-bc806bfbd3fd | sub_1SQc…vh8r | cus_TNMj…Nf3B | active | monthly | 2026-08-06 22:49:54+00 | 2026-09-06 22:49:54+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| 001e0845-79e0-4204-b315-ee30ec65b92c | ea4e3e5a-36ba-4ace-bce5-06520f01d9bd | sub_1SS3…Tr91 | cus_TOrG…kREK | active | monthly | 2026-08-10 22:27:09+00 | 2026-09-10 22:27:09+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_ACTIVE | — |
| 10d3b0ba-f826-41f8-8d2c-0488d8726d2b | 7c469388-f758-47d4-9a8b-6b4635cf4677 | sub_1Tdu…BHNX | cus_UdBH…NWgw | canceled | monthly | 2026-06-02 16:12:30+00 | 2026-07-02 16:12:30+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_INACTIVE | — |
| 65562cd0-058b-441f-ba6d-5af870716309 | e1dacd0c-6d8e-40b9-8072-c1a6f75d50bf | sub_1TcE…xRvf | cus_UbR6…mqIb | canceled | monthly | 2026-05-29 00:31:05+00 | 2026-06-29 00:31:08+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | NULL | YES | CANDIDATE_INACTIVE | — |
| d7e51335-0060-4450-94c9-0a813c5eec68 | f07554fd-d1f0-485e-868f-d8cff67a141d | sub_1SHt…OJuG | cus_TEM1…bQi8 | active | monthly | 2026-08-13 21:30:48+00 | 2026-09-13 21:30:48+00 | N/A | d082af8c-216a-4499-a1f6-1fb84ac08a5f | apple_iap | YES | REVIEW_REQUIRED | `payment_provider=apple_iap` apesar do token Stripe. |

## Riscos e decisões antes da importação

- O registro `d7e51335-0060-4450-94c9-0a813c5eec68` precisa de revisão porque
  mistura token Stripe com `payment_provider=apple_iap`. Ele não está no CSV.
- Dois candidatos ativos têm `current_period_end` nulo. Foram incluídos porque a
  regra solicitada considera término nulo ativo, mas devem ser confirmados numa
  etapa futura antes da importação efetiva.
- Os demais providers nulos refletem o legado e não foram usados para exclusão.
- O CSV contém credenciais de importação operacionais e não deve ser publicado,
  anexado a issues ou exposto em logs.

## Confirmações

- PRODUCTION WRITES: NO
- STRIPE API CALLED: NO
- REVENUECAT API CALLED: NO
- IMPORT EXECUTED: NO
