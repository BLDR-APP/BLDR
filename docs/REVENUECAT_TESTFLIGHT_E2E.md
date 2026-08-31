# RevenueCat iOS — TestFlight E2E

Este roteiro valida a mesma arquitetura que será promovida para a App Store.
Execute somente em build TestFlight com `REVENUECAT_BILLING_ENABLED=true`, chave
pública iOS e sessão Supabase autenticada. Não use chaves secretas, recibos em
logs, nem a conta de produção de outro usuário.

## Pré-condições

- Offering `default` publicada no RevenueCat com `$rc_weekly`, `$rc_monthly` e
  `$rc_annual`, associados respectivamente a `CLUBWEEKLY`, `MENSAL` e `ANUAL`.
- Entitlement `bldr_club` associado a todos os produtos.
- Apple Server Notifications V2 e o webhook RevenueCat → Supabase ativos.
- Uma conta Apple sandbox/TestFlight e uma conta BLDR de teste; registrar o UUID
  mascarado no relatório de execução.
- Confirmar no build que `REVENUECAT_BILLING_ENABLED=true` e que somente a
  Public SDK Key iOS está presente.

## Roteiro de execução externo

| Caso | Ação | Resultado esperado no app | Verificação RevenueCat/Supabase |
| --- | --- | --- | --- |
| A | Abrir o app já autenticado | SDK identifica o UUID Supabase, sem paywall automático | Customer usa o UUID canônico; nenhum ID anônimo |
| B | Abrir o paywall | Preços e moeda vêm da App Store; anual selecionado se disponível | Offering `default` e packages corretos |
| C | Comprar semanal | CTA fica bloqueado durante a compra; CLUB libera somente com `bldr_club` ativo | CustomerInfo ativo; webhook espelha evento sem conceder indevidamente |
| D | Comprar mensal em conta separada | Mesmo comportamento, produto `MENSAL` | Produto, expiração e renovação coerentes |
| E | Comprar anual em conta separada | Mesmo comportamento, produto `ANUAL` | Produto, expiração e renovação coerentes |
| F | Cancelar a tela da Apple | Nenhum acesso, sem erro técnico genérico | Nenhuma transação/entitlement novo |
| G | Induzir pendência (quando suportado) | Estado pendente não libera CLUB | CustomerInfo não ativo até confirmação da loja |
| H | Erro/indisponibilidade de Offering | Erro com retry; nenhuma tela de Stripe/Apple legado | Nenhuma compra alternativa iniciada |
| I | Restaurar compras manualmente | Só libera se `bldr_club` estiver ativo | CustomerInfo atualizado; sem `syncPurchases()` genérico |
| J | Resgatar Offer Code | Ação é distinta de restaurar e não concede sem entitlement | CustomerInfo após conclusão da loja |
| K | Trocar sessão BLDR A → B | B recebe `Purchases.logIn(B)`; A não contamina B | App User ID final é B, sem anônimo |
| L | Logout/login | Sem sessão não há compra/configuração anônima; relogin restaura UUID correto | Sem `$RCAnonymousID` canônico |
| M | Background/foreground durante compra | Não duplica CTA nem requisição | Uma tentativa comercial por toque |
| N | Assinatura expirada/revogada | CLUB deixa de ser concedido conforme CustomerInfo | Entitlement e mirror coerentes |
| O | Assinatura Apple legada elegível | Coordinator iOS segue claim/evidência; não roda em Android | State machine com lease, 7 dias e máximo 3 tentativas |
| P | Acompanhar webhook | Eventos autenticados chegam, HMAC/replay válidos | Ledger idempotente; sem duplicidade comercial |
| Q | Smoke de regressão | Dashboard, Treinos, Clube e ranking usam o mesmo acesso canônico | `ResolveClubAccess` é a decisão de acesso |

## Critérios de aprovação

- Nenhuma compra nova usa Stripe ou o fluxo Apple legado quando a flag está
  ativa.
- Nenhum preço, desconto, período de teste ou moeda é inventado pelo cliente.
- Um cancelamento, pendência ou falha nunca concede CLUB.
- Um sucesso só é aceito após CustomerInfo indicar `bldr_club` ativo para o UUID
  Supabase autenticado.
- Não há `syncPurchases()` automático, restore automático ou compra duplicada.

Todos os casos acima que envolvem App Store são **EXTERNAL STORE E2E REQUIRED**.
