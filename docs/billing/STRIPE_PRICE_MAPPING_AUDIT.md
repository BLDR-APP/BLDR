# Auditoria de Stripe Price IDs para migração RevenueCat

Status: **PASS** — a elegibilidade foi atualizada por leitura no Supabase
Production e as 12 assinaturas restantes foram consultadas uma única vez cada
com uma Restricted API Key de produção.

- Data da auditoria: 2026-08-30 (America/Sao_Paulo).
- Fonte de candidatos: `STRIPE_REVENUECAT_IMPORT_AUDIT.md` e CSV local ignorado.
- Supabase: somente queries `SELECT`.
- RevenueCat: não consultado nem alterado.
- Stripe: 12 leituras `GET /v1/subscriptions/{id}`, todas com HTTP 200; nenhuma
  operação de mutação foi executada.
- Importação: não executada.

## Contagens

- TOTAL ORIGINAL CANDIDATE_ACTIVE: 15
- PILOT ALREADY IMPORTED: 1
- EXCLUDED REVIEW_REQUIRED: 1
- EXCLUDED NULL PERIOD: 2
- CURRENTLY ELIGIBLE REMAINING: 12
- DISTINCT STRIPE PRICE IDS: 1
- UNKNOWN PRICE IDS: 0

`REVIEW_REQUIRED` é contabilizado separadamente porque o registro de
`pedromenindelima@gmail.com` já não integrava os 15 `CANDIDATE_ACTIVE` do CSV.

## Candidatos elegíveis restantes

Todos os registros abaixo foram reconfirmados no Supabase com `status=active`,
período mensal, `current_period_end` futuro e não nulo, cadeia com `auth.users`
válida e `payment_provider=NULL` legado. A leitura Stripe confirmou um único
item por assinatura, price ativo, recorrência mensal, `usage_type=licensed` e
`cancel_at_period_end=false`. IDs de subscription/customer estão mascarados.

| email | auth.users.id | user_subscriptions.id | Stripe subscription | Stripe customer | provider | status | current_period_end (UTC) | período | Price ID |
|---|---|---|---|---|---|---|---|---|---|
| brunnacapanemaa@gmail.com | c61723cf-98e5-4765-9979-bc806bfbd3fd | c29c3ae9-413e-43fd-82a9-16dbf3c34bee | sub_1SQc…vh8r | cus_TNMj…Nf3B | NULL | active | 2026-09-06 22:49:54 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |
| f7t87xgrbq@privaterelay.appleid.com | ea4e3e5a-36ba-4ace-bce5-06520f01d9bd | 001e0845-79e0-4204-b315-ee30ec65b92c | sub_1SS3…Tr91 | cus_TOrG…kREK | NULL | active | 2026-09-10 22:27:09 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |
| josefaleirosjunior@gmail.com | 916479aa-9799-4782-b1a6-ce6ea6f6b9b5 | 7f328237-c42b-4ad2-bc29-05309a2e0915 | sub_1Ted…kKTb | cus_Udvf…3yuC | NULL | active | 2026-09-11 16:07:49 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |
| danivhmenin@gmail.com | 2126a2cd-657d-4f72-a6f9-b36540f17cc5 | d8d5e735-92b4-460b-9ad1-ef86dd037f2b | sub_1SSK…yMDh | cus_TP9D…OvlM | NULL | active | 2026-09-11 16:59:45 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |
| khalil.sophia@icloud.com | 4a4ed139-5f98-46b8-8648-b7f6dc8d628c | b057d5c8-7f61-47d8-89e5-faddf4fd04df | sub_1SKs…2UxR | cus_THQu…PgQV | NULL | active | 2026-09-22 02:44:49 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |
| leomenin@gmail.com | 28b6f1a2-22fd-4b6e-b30a-2247844ad1a1 | 1bf84e77-28e5-4b4d-b8ca-0f644e5e2609 | sub_1Tw0…VpaP | cus_UvsO…PQ2m | NULL | active | 2026-09-22 15:43:09 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |
| gabrielbrandaodelima@gmail.com | 34afd099-a98e-4923-b749-9aff2793de2f | 48fd6723-489b-495f-bed2-45abdbd33570 | sub_1SL6…nSXf | cus_THg0…ZdnB | NULL | active | 2026-09-22 18:21:05 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |
| jjoaolrocha@gmail.com | 194ff474-bf0e-455a-ba3c-e35706d2d9e3 | 43afbc96-c5ed-4863-99d8-38c6e644944d | sub_1SL6…wgYc | cus_THgB…FI0f | NULL | active | 2026-09-22 18:31:48 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |
| pedroviana020104@gmail.com | 2093fa17-1246-4b9b-b0ab-49faf76c78f9 | 24ad33c7-f9b7-4ccd-9350-d781d1a5d588 | sub_1SL7…Tkum | cus_THga…9NVO | NULL | active | 2026-09-22 18:56:49 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |
| bederoma@gmail.com | 78deb91d-f151-4d20-aadd-d7f4405fc99e | d99ed639-6d08-42ac-89c3-314a6c5f96fc | sub_1SLU…IoEv | cus_TI4n…g8t6 | NULL | active | 2026-09-23 19:57:25 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |
| jpfvilandez@gmail.com | 32cb97c7-1ca7-4ee6-aca9-1943a345e1b8 | 0dc10294-b410-4a93-b89d-db319863e288 | sub_1SLU…6jA5 | cus_TI54…l0I0 | NULL | active | 2026-09-23 20:14:40 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |
| jpabreuazevedo@gmail.com | 4f8a8ed9-9105-4f59-9c71-bfb8c895f6ad | c51943bc-6666-4a36-abb5-05286484093b | sub_1SMy…T2Sy | cus_TJc0…krVi | NULL | active | 2026-09-27 22:20:35 | monthly | price_1RzkacRyVeX3wSWABwK43Myq |

## Agrupamento por Price ID

### price_1RzkacRyVeX3wSWABwK43Myq

- PRICE_ID: price_1RzkacRyVeX3wSWABwK43Myq
- CANDIDATE COUNT: 12
- USERS: os 12 usuários listados acima
- BILLING PERIODS: monthly
- CURRENT PERIOD END RANGE: 2026-09-06 22:49:54 UTC a 2026-09-27 22:20:35 UTC
- PRODUCT_ID: prod_SvboaRpgfLOPaY
- STRIPE INTERVAL: month
- STRIPE USAGE TYPE: licensed
- PRICE ACTIVE: YES
- CANCEL_AT_PERIOD_END: false em todos
- ALREADY MAPPED TO BLDR_CLUB IN REVENUECAT: YES (confirmado no piloto)

Nenhuma assinatura possui múltiplos items/prices, price ausente, metered billing,
produto divergente, status incompatível ou cancelamento agendado. A versão atual
do payload Stripe expõe o período no subscription item; a elegibilidade temporal
foi calculada com os `current_period_end` persistidos e reconfirmados no Supabase.

## Classificação

- ELIGIBLE: 12
- REVIEW_REQUIRED: 0
- UNKNOWN PRICE IDS: 0
- Produto/price divergente do piloto: 0

## Confirmações

- PRICE MAPPING AUDIT: PASS
- ELIGIBLE REMAINING: 12
- DISTINCT PRICE IDS: 1
- ALL PRICE IDS KNOWN: YES
- ALL ELIGIBLE PRICE IDS MAPPED TO BLDR_CLUB: YES
- REVENUECAT API CALLED: NO
- STRIPE READ ATTEMPTS: 12 (12 × HTTP 200)
- STRIPE MUTATED: NO
- SUPABASE MUTATED: NO
- IMPORT EXECUTED: NO
