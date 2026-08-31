# Fase 2 — Relatório de Drift: Community + Club Tables

> **Status: INCOMPLETO** — dependências transitivas e policies de storage não inventariadas.
> Nenhuma migration deve ser aplicada ao Supabase sem os itens pendentes resolvidos (§9).
>
> **Data do inventário:** 2026-08-29  
> **Método:** exportação direta do catálogo pg_catalog via SQL fornecido pelo usuário  
> **Nenhuma mutation foi aplicada ao Supabase.**

---

## 1. Objetos confirmados no Supabase sem migration correspondente

| # | Objeto | Tipo | Baseline gerado |
|---|--------|------|-----------------|
| D-01 | `public.community_feed` | TABLE | `20260829000001` |
| D-02 | `public.community_reactions` | TABLE | `20260829000002` |
| D-03 | `public.community_comments` | TABLE | `20260829000003` |
| D-04 | `public.club_workout_templates` | TABLE | `20260829000004` |
| D-05 | `public.club_user_workouts` | TABLE | `20260829000004` |
| D-06 | `public.club_workout_exercise_sets` | TABLE | `20260829000004` |
| D-07 | `public.ranking_volume` | FUNCTION | `20260829000006` |
| D-08 | `public.ranking_consistency` | FUNCTION | `20260829000006` |
| D-09 | `public.ranking_progression` | FUNCTION | `20260829000006` |
| D-10 | `public.copy_workout_to_template` | FUNCTION | `20260829000007` |
| D-11 | `storage/community-posts` | BUCKET | `20260829000008` (parcial) |

---

## 2. Colunas ausentes na migration base

| # | Tabela | Colunas ausentes | Baseline |
|---|--------|-----------------|---------|
| C-01 | `public.user_workouts` | `name TEXT`, `volume_kg NUMERIC`, `muscle_groups TEXT[]` | `20260829000005` |

A migration `20250816004909_bldr_fitness_complete.sql` não incluiu essas colunas, que existem em produção conforme ordinal_position 4, 10 e 11 exportados.

---

## 3. Configuração de RLS exportada do catálogo

> **AVISO:** a tabela abaixo descreve o que o catálogo reporta, não o comportamento verificado.
> Somente testes com sessões reais `authenticated` (não service_role) comprovam acesso efetivo.
> service_role bypassa RLS e não serve como evidência de bloqueio ou permissão.

| Tabela | RLS ativado | Policies exportadas | Risco identificado |
|--------|-------------|--------------------|--------------------|
| `community_feed` | Sim | SELECT (public/próprio), INSERT (próprio) | — |
| `community_reactions` | Sim | SELECT (todos), INSERT (próprio), DELETE (próprio) | — |
| `community_comments` | Sim | SELECT (authenticated) apenas | ⚠️ Sem INSERT/DELETE — escrita bloqueada por RLS |
| `club_workout_templates` | Sim | SELECT (4 policies redundantes), CRUD (próprio) | — |
| `club_user_workouts` | **NÃO** | INSERT e SELECT exportadas (inativas) | ⚠️ Ver §4 |
| `club_workout_exercise_sets` | **NÃO** | Nenhuma exportada | ⚠️ Ver §4 |
| `user_workouts` | Sim | ALL (próprio), DELETE (público via uid) | — |
| `club_workout_templates` (storage) | — | Não inventariadas | ⚠️ Ver §5 |

---

## 4. Risco de acesso com RLS desabilitado

`club_user_workouts` e `club_workout_exercise_sets` têm `rls_enabled = false` com grants para `anon`, `authenticated` e `service_role`.

Com RLS desabilitado, **qualquer requisição com anon key tem acesso irrestrito a todos os registros** — incluindo dados de treino (volume_kg, muscle_groups, completed_at) de todos os usuários. A limitação "authenticated" nas policies exportadas não tem efeito enquanto RLS está desligado.

O risco não se limita a usuários autenticados. Qualquer cliente com a chave pública (anon key) pode ler e escrever sem restrição de linha.

**Ação necessária antes de qualquer exposição pública da feature de clube:**
- Habilitar RLS com `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`
- Verificar policies existentes e ativá-las
- Testar com sessão autenticada (não service_role)

---

## 5. Dependências não inventariadas — baselines bloqueados

| Tabela não inventariada | Quem depende | Baseline afetado | Status |
|------------------------|-------------|-----------------|--------|
| `public.club_workout_template_exercises` | FK em `club_workout_exercise_sets` | `20260829000004` | ❌ Baseline parcialmente inutilizável em ambiente limpo |
| `public.personal_records` | `ranking_progression` RPC | `20260829000006` | ❌ Função falha se tabela não existir |

`club_workout_template_exercises` é mencionada em `20260803210324` mas sua criação não existe em nenhuma migration. `personal_records` não aparece em nenhuma migration nem no código Dart examinado.

---

## 6. Problemas funcionais identificados

### 6a. `copy_workout_to_template` — coluna `created_at` ausente em `club_workout_exercise_sets`

A função exportada referencia `wes.created_at` no branch `p_source = 'club'`:
```sql
ROW_NUMBER() OVER (ORDER BY MIN(wes.created_at))
```

O inventário exportado de `club_workout_exercise_sets` **não inclui coluna `created_at`**. As colunas terminam em `free_name` (ordinal_position 15); `completed_at` existe (DEFAULT CURRENT_TIMESTAMP) mas `created_at` não foi exportado.

**Duas possibilidades:**
- **A)** O inventário está incompleto — `created_at` existe mas não foi capturado pela query
- **B)** A função está quebrada para `p_source = 'club'` desde sua criação

**Verificar antes de usar a função com `p_source = 'club'`:**
```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'club_workout_exercise_sets'
ORDER BY ordinal_position;
```

Se `created_at` não existir, a função precisa ser corrigida para usar `completed_at` ou `set_number` como critério de ordenação.

### 6b. Policies de storage não inventariadas para `community-posts`

O inventário exportado (section 06_POLICY em `storage.objects`) contém apenas policies dos buckets `Images` e `proofs`. Nenhuma policy foi exportada para `community-posts`.

Com `public = true`, leitura é aberta. Mas o comportamento de INSERT (upload de fotos pelo Flutter) não pode ser verificado sem consulta direta às policies de storage.

**Verificar:**
```sql
SELECT * FROM storage.policies WHERE bucket_id = 'community-posts';
```

---

## 7. Problema de privacidade/produto — `ranking_visible` não filtrado nas RPCs

A migration `20260815000000_filter_ranking_by_visibility.sql` adicionou `ranking_visible` à tabela `bldr_club.club_ranking` com um trigger de sincronização a partir de `user_profiles.ranking_visible`.

Porém as três RPCs exportadas (`ranking_volume`, `ranking_consistency`, `ranking_progression`) fazem JOIN direto em `user_profiles` e **não filtram por `ranking_visible` nem por qualquer coluna de privacidade**. Usuários que optaram por não aparecer no ranking continuam visíveis nas RPCs.

A migration de filtro afeta apenas a tabela `bldr_club.club_ranking`, que não é utilizada por nenhuma das três RPCs. O efeito prático da migration é nulo para o ranking público.

**Ação necessária:** decidir se as RPCs devem incluir `WHERE up.ranking_visible = TRUE` (requer confirmar que `user_profiles.ranking_visible` representa a intenção correta) e testar comportamento com usuário que desativou visibilidade.

---

## 8. Inconsistências estruturais em produção

| # | Problema | Detalhes |
|---|---------|---------|
| I-01 | Duas constraints `difficulty_level` conflitantes em `club_workout_templates` | `workout_templates_difficulty_chk` (1–4) e `workout_templates_difficulty_level_check` (1–5) coexistem; a mais restritiva (1–4) é a efetiva |
| I-02 | 4 policies SELECT redundantes em `club_workout_templates` | Cobertura sobreposta: todas são PERMISSIVE, portanto não causam conflito, mas dificultam auditoria |
| I-03 | Policies de INSERT/DELETE ausentes em `community_comments` | Comportamento atual: apenas leitura possível via RLS |
| I-04 | Policies inativas em `club_user_workouts` | RLS desabilitado, policies não têm efeito |

---

## 9. Ordem de revisão e pré-requisitos

Os baselines abaixo **NÃO devem ser aplicados** até os pendentes serem resolvidos:

| Baseline | Pré-requisito |
|---------|--------------|
| `20260829000004` | Gerar e aplicar baseline de `club_workout_template_exercises` |
| `20260829000006` | Gerar e aplicar baseline de `personal_records`; verificar `created_at` em `club_workout_exercise_sets` (§6a) |
| `20260829000008` | Inventariar policies de storage para `community-posts` (§6b) |

Ordem segura para os demais (em ambiente limpo):
1. `20260829000001` — `community_feed`
2. `20260829000002` — `community_reactions`
3. `20260829000003` — `community_comments`
4. `20260829000005` — colunas em `user_workouts`
5. `20260829000007` — `copy_workout_to_template` (verificar §6a antes)

---

## 10. Nota sobre idempotência dos baselines

`CREATE TABLE IF NOT EXISTS` **não reconcilia divergências**: se a tabela existir com schema diferente do baseline (coluna faltando, tipo diferente, constraint ausente), o comando é ignorado silenciosamente sem erro e sem correção.

`DROP POLICY IF EXISTS` + `CREATE POLICY` **modifica objetos existentes** e não é sem efeito colateral em produção — se a policy existir com definição diferente, ela é substituída. Confirmar equivalência antes de aplicar.

`ADD COLUMN IF NOT EXISTS` é seguro para adicionar colunas ausentes, mas não verifica nem corrige tipo ou default divergentes.

---

## 11. Estratégia de rollback

Baselines já aplicados a um ambiente com dados **não devem usar DROP TABLE ou DROP ... CASCADE**, pois descartariam dados irreversível e silenciosamente.

Para ambientes de staging/dev sem dados críticos:
```sql
-- Funções: reversível sem perda de dados
DROP FUNCTION IF EXISTS public.ranking_volume(text);
DROP FUNCTION IF EXISTS public.ranking_consistency(text);
DROP FUNCTION IF EXISTS public.ranking_progression(text);
DROP FUNCTION IF EXISTS public.copy_workout_to_template(uuid, text);

-- Colunas: reversível, mas destrói dados da coluna
ALTER TABLE public.user_workouts
  DROP COLUMN IF EXISTS name,
  DROP COLUMN IF EXISTS volume_kg,
  DROP COLUMN IF EXISTS muscle_groups;
```

Para tabelas com dados, o rollback requer:
1. Exportar dados (`pg_dump -t community_feed ...`)
2. Executar `DROP TABLE ... CASCADE` (ambiente de staging)
3. Importar dados se necessário

**Em produção:** não existe rollback não-destrutivo para `CREATE TABLE`. A estratégia correta é manter as tabelas e aplicar correções via novas migrations.

---

## 12. Complemento de Fase 1 — correção de `RankingEntry`

Durante o inventário da Fase 2, foi identificado que `RankingEntry.fromRow` lia campos inexistentes nas RPCs reais (`position`, `display_name`, `value`), causando crash em produção. A correção foi aplicada:

- [`lib/features/community/domain/entities/ranking_entry.dart`](../../lib/features/community/domain/entities/ranking_entry.dart) — `fromRow` lê `full_name`/`username` → `displayName`, `total` → `value`; `position` calculado externamente
- [`lib/features/community/data/repositories/community_feed_repository_impl.dart`](../../lib/features/community/data/repositories/community_feed_repository_impl.dart) — posição calculada via índice da lista

**A Fase 1 não está totalmente validada** porque esta correção não foi testada em ambiente real com dados do Supabase. Os 16 testes unitários passam com fake repository, mas o comportamento do ranking com dados reais (RPCs retornando `full_name`/`username` null, `total` zero, ordenação) precisa de validação manual.

---

*Fase 2 incompleta — ver §9 para itens pendentes.*
