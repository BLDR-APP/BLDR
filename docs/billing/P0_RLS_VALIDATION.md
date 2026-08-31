# Validação do hardening RLS de billing

Escopo da migration:
`20260830000020_harden_subscription_rls.sql`.

Este roteiro não contém credenciais e **não deve ser executado em produção**.
Testes de escrita devem usar Supabase local ou staging descartável e terminar
com rollback ou limpeza dos dados de teste.

## Pré-condições

- Dois usuários de teste autenticados: `USER_A_UUID` e `USER_B_UUID`.
- Uma linha de assinatura pertencente ao usuário A.
- Um plano ativo conhecido em staging.
- JWTs reais dos usuários A e B para validar a API como `authenticated`.
- Service role disponível somente no executor seguro do backend/staging.

Não use service role como evidência dos testes SEC-01 a SEC-08: ela ignora RLS.

## Introspecção após aplicar em local/staging

```sql
select schemaname, tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'user_subscriptions',
    'payment_intents',
    'subscription_plans'
  )
order by tablename, policyname;

select table_name, grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in (
    'user_subscriptions',
    'payment_intents',
    'subscription_plans'
  )
  and grantee in ('anon', 'authenticated', 'service_role')
order by table_name, grantee, privilege_type;

select c.relname, c.relrowsecurity, c.relforcerowsecurity
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'user_subscriptions',
    'payment_intents',
    'subscription_plans'
  );
```

Resultado esperado:

- `user_subscriptions`: apenas SELECT próprio para `authenticated`.
- `payment_intents`: apenas SELECT próprio para `authenticated`.
- `subscription_plans`: SELECT de planos ativos para `public`.
- `anon` sem privilégio em `user_subscriptions` e `payment_intents`.
- `anon` e `authenticated` sem INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES
  ou TRIGGER nas três tabelas.
- Privilégios de `service_role` preservados.

## Testes SECURITY pela API

Execute cada chamada com o JWT indicado e confirme também que a linha original
permaneceu inalterada.

| ID | Identidade | Operação | Resultado esperado |
|---|---|---|---|
| SEC-01 | JWT A | SELECT assinatura de A | Sucesso, somente a linha de A |
| SEC-02 | JWT B | SELECT assinatura de A | Nenhuma linha visível |
| SEC-03 | JWT A | INSERT em `user_subscriptions` | Negado |
| SEC-04 | JWT A | UPDATE de status, plan_id e datas | Negado; dados intactos |
| SEC-05 | JWT A | DELETE da assinatura de A | Negado; linha preservada |
| SEC-06 | anon | SELECT/DML em `user_subscriptions` | Negado |
| SEC-07 | JWT A | INSERT/UPDATE/DELETE em `payment_intents` | Negado |
| SEC-08 | anon/JWT A | INSERT/UPDATE/DELETE em `subscription_plans` | Negado |

## Testes BACKEND

Somente em local/staging e com registros descartáveis:

| ID | Identidade | Operação | Resultado esperado |
|---|---|---|---|
| BE-01 | service role | UPSERT em `user_subscriptions` | Sucesso |
| BE-02 | service role | UPDATE em `user_subscriptions` | Sucesso |
| BE-03 | service role | DELETE do registro descartável | Sucesso |

Depois, executar smoke tests dos fluxos reais:

1. Apple sandbox: compra/restore chega à `verify-apple-receipt` e o backend
   atualiza `user_subscriptions`.
2. Stripe test mode: criação da assinatura funciona e o webhook assinado trata
   `customer.subscription.created`, `updated` e `deleted`.
3. Flutter: Dashboard, CLUB, Treinos, Nutrição, Comunidade e paywall continuam
   lendo o estado da assinatura e os planos ativos.

## Compatibilidade conhecida

`PaymentService.cancelSubscription()` ainda tenta executar UPDATE direto como
usuário autenticado. As telas atuais não chamam esse método; se o fluxo for
reativado, deverá ser movido para backend confiável antes de uso.

O segundo P0 de `verify-apple-receipt` não faz parte desta migration.

## Rollback emergencial

O rollback deve ser usado apenas se um fluxo legítimo e comprovado depender de
escrita do cliente. Antes dele, capture as policies e grants presentes.

1. Restaurar temporariamente a policy anterior apenas na tabela afetada.
2. Restaurar somente os privilégios estritamente necessários ao fluxo provado.
3. Reexecutar SEC-01 a SEC-08.
4. Registrar incidente, responsável e prazo para remover novamente a escrita.

Não há rollback de dados porque a migration não altera linhas.
