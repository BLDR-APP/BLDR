# Apple legacy → RevenueCat — estado server-side da migração

Status: proposta local para revisão. Nenhum SQL deste PR foi aplicado em Production.

## Decisão arquitetural

O estado one-shot fica em `public.apple_revenuecat_migrations`, separado de
`user_subscriptions`. A tabela comercial não é usada como máquina de estados da
migração e não é modificada por esta infraestrutura.

A chave canônica é `user_id`, com FK para `auth.users.id`. Esse mesmo UUID será o
RevenueCat App User ID. `legacy_subscription_id` referencia a assinatura auditada,
mas pode ser nulo para estados administrativos como `not_eligible`.

Foram incluídos quatro campos além do mínimo:

- `claim_id`: token opaco de uma tentativa específica; impede que uma resposta
  antiga conclua uma tentativa mais recente.
- `claim_expires_at`: lease que evita `in_progress` permanente após encerramento
  do app, perda de rede ou indisponibilidade.
- `revenuecat_app_user_id`: assertion persistida depois que o backend confiável
  verificou que o CustomerInfo pertence ao UUID Supabase canônico. Uma constraint
  exige igualdade com `user_id`.
- `revenuecat_entitlement_verified_at`: registra quando o backend confiável fez
  a verificação autoritativa de `bldr_club`; `completed` não é válido sem essa
  assertion.
- `revenuecat_entitlement_active`: estado comercial comprovado, separado do
  estado operacional; permanece `NULL` até a reconciliação.
- `reconciliation_result`: somente `active_entitlement` ou
  `inactive_entitlement` em rows concluídas.

Não foi criada coluna para entitlement porque existe apenas um entitlement
canônico aceito (`bldr_club`) e a função de conclusão o valida explicitamente.

## Estados

- `eligible`: classificado server-side e pronto para uma primeira claim.
- `in_progress`: existe uma claim exclusiva com lease ativa.
- `completed`: o backend comprovou histórico Apple ligado a `bldr_club` e
  classificou o entitlement como ativo **ou inativo**.
- `failed`: tentativa terminou com código sanitizado e requer autorização
  explícita para retry.
- `review_required`: ambiguidade comercial ou de identidade; sem sync automático.
- `not_eligible`: classificação conclusiva para não participar da migração.

Estados comerciais (`active`, `canceled` etc.) não são usados nesta tabela.
`completed` não volta a `eligible` por nenhuma RPC criada neste PR.

As constraints são bidirecionais: somente `in_progress` pode manter
`claim_id/claim_expires_at`; somente `completed` pode manter `completed_at`,
  `revenuecat_app_user_id`, `revenuecat_entitlement_verified_at`,
  `revenuecat_entitlement_active` e `reconciliation_result`. Fora desses
estados, os respectivos campos permanecem obrigatoriamente nulos.

## Segurança

- RLS habilitado.
- `anon`: nenhum privilégio.
- `authenticated`: somente `SELECT` da própria row via `auth.uid()`.
- `authenticated`: sem `INSERT`, `UPDATE`, `DELETE` e sem `EXECUTE` nas RPCs.
- `service_role`: acesso à tabela e às três RPCs server-side.

As RPCs recebem `p_user_id` porque são exclusivamente backend/service-role. Um
futuro endpoint autenticado deve validar o JWT, derivar `auth.users.id` e só então
chamar a RPC; nunca deve repassar um UUID arbitrário fornecido pelo body.

## Transições atômicas

### Claim

`claim_apple_revenuecat_migration` executa um único `UPDATE ... WHERE` e retorna
um `claim_id`. A primeira claim muda `eligible → in_progress`, incrementa
`attempt_count` e cria lease de 15 minutos. Uma segunda claim durante a lease não
atualiza a row e retorna `claimed=false`.

`failed → in_progress` só ocorre quando o backend confiável passa
`p_allow_failed_retry=true`. Não existe retry automático no Flutter.

Uma row `in_progress` com lease expirada pode ser reclamada. Cada reclaim recebe
novo `claim_id`, invalida respostas da tentativa anterior e incrementa
`attempt_count`. O intervalo permitido é de 60 a 3600 segundos.

### Sucesso

`complete_apple_revenuecat_migration` não consulta RevenueCat. Ela somente valida
e persiste uma assertion recebida do backend confiável. Antes da chamada, esse
backend deve verificar autoritativamente CustomerInfo/RevenueCat — ou evidência
server-side equivalente — e confirmar simultaneamente:

- status `in_progress` e lease ainda válida;
- `claim_id` da tentativa atual;
- RevenueCat App User ID exatamente igual ao UUID Supabase;
- entitlement exatamente `bldr_club`, com evidência histórica Apple, e seu
  estado ativo/inativo;
- timestamp de verificação posterior à claim e não mais de cinco minutos no futuro.

`syncPurchases()` terminar sem exception não satisfaz esse contrato.

### Falha

`fail_apple_revenuecat_migration` aceita apenas a claim atual ainda não expirada e
código normalizado em `[A-Z0-9_:-]`, com no máximo 64 caracteres. Nenhuma mensagem
sensível ou erro bruto de SDK deve ser persistido.

## Resolução de UUID

Uma consulta read-only ao catálogo de Production confirmou duas definições de
`gen_random_uuid()`: `extensions.gen_random_uuid()` e
`pg_catalog.gen_random_uuid()`. Com o `search_path = pg_catalog, public, auth`, a
definição visível é a de `pg_catalog`. A migration usa explicitamente
`pg_catalog.gen_random_uuid()` para eliminar ambiguidade.

## Protocolo futuro — não implementado neste PR

1. Validar a sessão Supabase.
2. Configurar RevenueCat com App User ID igual ao UUID Supabase.
3. Um backend confiável confirma `eligible`.
4. O backend obtém a claim atômica e entrega autorização efêmera ao client.
5. Somente então o client chama `syncPurchasesForMigration(eligible: true)`.
6. O client lê CustomerInfo e envia o resultado ao backend.
7. O backend valida novamente identidade e entitlement `bldr_club`.
8. O backend conclui a claim atual como `completed`.

Nenhuma dessas conexões com Flutter ou RevenueCat foi feita neste PR.

## Semântica de falhas futuras

- RevenueCat indisponível ou exception no sync: `failed` com código sanitizado.
- Sync sem `bldr_club`: não concluir; usar `failed` ou `review_required` conforme
  regra operacional futura.
- Sessão Supabase mudou: abortar; não concluir a claim do usuário anterior.
- App User ID divergente: abortar e encaminhar para revisão.
- App fechado durante `in_progress`: a lease expira após 15 minutos e permite
  reclaim controlado; não há scheduler neste PR.
- Resposta atrasada de tentativa antiga: `claim_id` não confere e é rejeitada.

## Restore Purchases

Restore é independente desta máquina de estados. `completed`, `failed`,
`review_required` ou qualquer outro status de migração não pode esconder nem
bloquear a ação manual **Restore Purchases**. Migração one-shot e recuperação
explícita de compras legítimas têm finalidades distintas.

## Seed controlado

O arquivo `docs/billing/apple_revenuecat_migration_seed.sql` fixa explicitamente
os 82 pares técnicos `user_id`/`legacy_subscription_id` e o status esperado
(81 `eligible`, 1 `review_required`),
sem e-mails ou receipts. A seleção ao vivo precisa ser idêntica ao conjunto
fixado nos dois sentidos; manter apenas as mesmas contagens não é suficiente.

O script aceita as três rows do seed anterior somente se identidade, assinatura
e status coincidirem exatamente; qualquer outra row preexistente falha fechado.
Ele repete a seleção imediatamente antes do INSERT, não usa
`ON CONFLICT`, opera em transação serializable e termina com `ROLLBACK`. A row
`review_required` registra a exclusão da migração automática, mas esse status
não é aceito pela RPC de claim. O seed não foi executado.

Antes de qualquer seed futuro, revisar os IDs retornados por essa seleção,
repetir a auditoria da coorte e obter autorização separada. O
`current_period_end` não participa da seleção porque foi provado não confiável.

## Testes

- `supabase/tests/apple_revenuecat_migration_state_contract_test.ts`: testes
  locais estáticos do isolamento, RLS/ACL, RPCs, claim, prova de entitlement e
  seed fail-closed.
- `supabase/tests/apple_revenuecat_migration_state_integration.sql`: roteiro
  transacional para uma instância Supabase local/efêmera; cobre claim, dupla
  claim, claim expirada, invariantes estruturais, tentativas, conclusão, falha,
  retry explícito, RLS/ACL, isolamento e ausência de alteração em
  `user_subscriptions`. Sempre termina em `ROLLBACK`.

O ambiente atual não possui Supabase CLI/PostgreSQL local; portanto o teste SQL
de integração foi preparado, mas não executado contra Production nem contra uma
base remota.

## Resultado

MIGRATION TABLE CREATED LOCALLY: YES (arquivo SQL; banco não alterado)  
RLS ENABLED: YES  
AUTHENTICATED WRITE ACCESS: NO  
SERVICE-SIDE ATOMIC CLAIM: YES  
CONCURRENT CLAIM PROTECTED: YES  
ATTEMPT COUNT SUPPORTED: YES  
COMPLETED REQUIRES ENTITLEMENT VERIFICATION BY FUTURE FLOW: YES  
STALE IN_PROGRESS POLICY DEFINED: YES  
RESTORE INDEPENDENT FROM MIGRATION STATE: YES  
APPLE CANDIDATE SEED PREPARED: YES  
APPLE CANDIDATE SEED EXECUTED: NO  
SYNC_PURCHASES EXECUTED: NO  
USER_SUBSCRIPTIONS MODIFIED: NO  
PRODUCTION WRITES: NO  
CUTOVER PERFORMED: NO

## Arquivos

- `supabase/migrations/20260830000023_apple_revenuecat_migration_state.sql`
- `docs/billing/apple_revenuecat_migration_seed.sql`
- `supabase/tests/apple_revenuecat_migration_state_contract_test.ts`
- `supabase/tests/apple_revenuecat_migration_state_integration.sql`
- `docs/billing/APPLE_REVENUECAT_MIGRATION_STATE.md`

## SQL de Production para revisão

O SQL exato proposto é o conteúdo integral de
`supabase/migrations/20260830000023_apple_revenuecat_migration_state.sql`.
Não usar `supabase db push`; não aplicar junto com o seed; não registrar migration
history manualmente. A aplicação manual só pode ocorrer após aprovação separada.
