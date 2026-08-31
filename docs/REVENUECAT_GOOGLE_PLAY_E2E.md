# RevenueCat Android — Google Play E2E

Este roteiro é para Internal/Closed Testing com
`REVENUECAT_BILLING_ENABLED=true` e a Public SDK Key Android. Ele não altera a
arquitetura: compras novas usam somente RevenueCat → Google Play.

## Pré-condições

- Package Android: `com.bldr_fitness.app`.
- Offering `default`: `$rc_weekly`, `$rc_monthly`, `$rc_annual`.
- Produtos/base plans: `bldr_club_weekly` / `club-weekly`,
  `bldr_club_monthly` / `club-monthly`, `annual` / `club-annual`.
- Entitlement `bldr_club`, credencial de serviço Google e RTDN configurados no
  RevenueCat; webhook RevenueCat → Supabase ativo.
- Conta Google tester e conta BLDR de teste separadas de contas reais.

## Roteiro de execução externo

| Caso | Ação | Resultado esperado |
| --- | --- | --- |
| A | Login BLDR e abertura do app | SDK configurado somente após UUID Supabase conhecido, sem identidade anônima |
| B | Abrir paywall | Offering `default`, preços/moeda da Play Store e anual selecionado quando disponível |
| C | Comprar weekly | Produto/base plan corretos; acesso apenas após `bldr_club` ativo |
| D | Comprar monthly | `bldr_club_monthly` / `club-monthly` reconhecidos e renovação coerente |
| E | Comprar annual | `annual` / `club-annual` reconhecidos e renovação coerente |
| F | Cancelar compra | Loading encerra; nenhum acesso e nenhum fallback legado |
| G | Pending/deferred | Não concede acesso antecipado; UI permite atualização posterior |
| H | Restore explícito | Somente CustomerInfo ativo libera CLUB; não há restore no launch |
| I | Trocar sessão A → B | `logIn(B)` direto, sem `logOut()` e sem callback tardio de A afetar B |
| J | Falha de SDK/Offering/package | Erro com retry; não chama Stripe, Apple legado ou concessão artificial |
| K | Background/foreground | Uma compra por CTA, sem duplicação |
| L | Cancelar/revogar na Play Store | CustomerInfo e acesso convergem após evento RTDN |
| M | Webhook Supabase | Evento autenticado/HMAC/idempotente atualiza somente mirror server-side |
| N | Smoke de telas CLUB | Dashboard, Treinos, Clube, ranking e HAVOK seguem `ResolveClubAccess` |
| O | Build de release | Nenhum secret server-side no bundle; apenas Public SDK Key Android |

## Critérios de aprovação

- Produtos, base plans, localizedPrice e currencyCode vêm de `StoreProduct`.
- `bldr_club` é o único entitlement de acesso.
- Compra/restore/cancelamento/pending têm o comportamento descrito sem fallback
  silencioso ao billing legado.
- Android não inicia coordinator nem `syncPurchases()` de migração Apple.

Os casos que dependem da Google Play Store e RTDN são **EXTERNAL STORE E2E REQUIRED**.
