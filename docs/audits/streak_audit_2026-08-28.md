# Auditoria do Sistema de Streak — BLDR
**Data:** 2026-08-28  
**Escopo:** Diagnóstico completo, sem alterações de código.

---

## Arquivos relevantes identificados

**Use cases:**
- `lib/features/workouts/domain/usecases/workout_usecases.dart` — `GetCurrentStreak`
- `lib/features/club/domain/usecases/club_usecases.dart` — `GetConsolidatedWorkoutHistory`

**Datasources/services:**
- `lib/services/workout_service.dart`
- `lib/services/club_workouts_service.dart`

**Apresentação:**
- `lib/shared/presentation/dashboard/widgets/today_metrics_widget.dart`
- `lib/shared/presentation/dashboard/dashboard.dart`
- `lib/features/profile/presentation/profile_drawer/profile_screen.dart`
- `lib/features/club/presentation/bldr_club/havok/havok_sheet.dart`
- `lib/features/club/domain/usecases/generate_havok_insight.dart`

---

## A. Cálculo

### Há quatro implementações distintas no app — não uma fonte única

| Local | Use case usado | Limite | Fontes |
|---|---|---|---|
| `GetCurrentStreak` (use case canônico) | próprio | **200 personal + 200 club** | pessoal + clube |
| `TodayMetricsWidget._loadStreak()` | `GetConsolidatedWorkoutHistory` | **30** | pessoal + clube |
| `dashboard.dart` (review modal) | `GetWorkoutHistory` (default 20) | **20** | **só pessoal** |
| HAVOK `_isStreakAtRisk` | `GetConsolidatedWorkoutHistory(limit: 1)` | **1** | pessoal + clube |

### Algoritmo central (idêntico nas variantes principais)

```dart
// 1. Converte completedAt → dia local
final dt = w.completedAt?.toLocal();
if (dt != null) workedDays.add(DateTime(dt.year, dt.month, dt.day));

// 2. Conta dias consecutivos regressivamente a partir de hoje
var day = DateTime(now.year, now.month, now.day);
while (workedDays.contains(day)) {
  streak++;
  day = day.subtract(Duration(days: 1));
}
```

### Tabelas consultadas
`user_workouts` e `club_user_workouts`

### Limite de registros
- `GetCurrentStreak`: 200 por fonte (400 total) — suficiente para ~13 meses de treino diário
- `TodayMetricsWidget`: **apenas 30** → **BUG #1**
- Dashboard review: **apenas 20**, **apenas pessoal** → **BUG #2**

### Timezone na leitura
`.toLocal()` aplicado consistentemente em todas as variantes. Correto.

### completedAt null
Tratado com `?.toLocal()` e verificação `if (dt != null)` — treinos sem data são ignorados. Correto.

### Dia de descanso planejado
**Não quebra o streak.** O algoritmo ignora o plano semanal por completo — só verifica se há `completed_at` naquele dia.

---

## B. Salvamento

| Local | `.toUtc()` aplicado? |
|---|---|
| `workout_service.dart` — `completeWorkout()` linha 592 | ✅ `now.toUtc().toIso8601String()` |
| `workout_service.dart` — `completeWorkoutWithAnalytics()` linha 556 | ✅ `now.toUtc().toIso8601String()` |
| `club_workouts_service.dart` — `completeWorkout()` linha 274 | ✅ `now.toUtc().toIso8601String()` |
| `club_workouts_service.dart` — `logCardioActivity()` linha 769 | ❌ **`now.toIso8601String()` SEM `.toUtc()`** → **BUG #3** |

**Detalhe do BUG #3:** Para usuários em UTC-3 (Brasília), um treino de cardio registrado às 21h+ local é salvo sem offset UTC. O Postgres interpreta o timestamp como UTC, deslocando o registro 3h para o futuro. Em datas limítrofes, o treino pode "aparecer" no dia seguinte, quebrando o streak.

---

## C. Persistência

- O streak **não é salvo em nenhuma coluna do banco**. Sempre calculado on-demand em Dart a cada abertura de tela.
- **Sem cache local** — nenhuma referência a SharedPreferences, Hive ou similar para streak.
- Consequência: toda abertura do Dashboard dispara duas queries ao Supabase. Em conexões lentas, o chip exibe `0` enquanto carrega.

---

## D. Exibição

O streak aparece em **4 lugares** na UI:

1. **Dashboard → chip `TodayMetricsWidget`** (`today_metrics_widget.dart:164`)  
   Usa `GetConsolidatedWorkoutHistory(limit: 30)` com lógica inline — **implementação própria**.

2. **Dashboard → critério para review modal** (`dashboard.dart:152`)  
   Usa `GetWorkoutHistory` legado (só `user_workouts`, limit 20) — **implementação própria, fonte incompleta**.

3. **Perfil → card de stats** (`profile_screen.dart:224`)  
   Usa `GetCurrentStreak` (use case canônico). ✅

4. **HAVOK context** (`generate_havok_insight.dart:122`)  
   Usa `GetCurrentStreak` (use case canônico). ✅

**Problema:** o chip do Dashboard usa implementação com limit 30, enquanto Perfil e HAVOK usam `GetCurrentStreak` (limit 200). Um usuário com streak de 31+ dias vê valores diferentes entre as telas → **BUG #4**.

---

## E. Edge Cases

### Dois treinos no mesmo dia
Sem problema. O `Set<DateTime>` deduplica automaticamente — dois registros com `completedAt` no mesmo dia local resultam no mesmo `DateTime(y, m, d)`.

### Treino perto da meia-noite
Depende do salvamento. `completeWorkout` usa `now.toUtc()`, então um treino terminado às 23:59 local (UTC-3) é salvo como `02:59 UTC do dia seguinte`. Na leitura, `.toLocal()` converte de volta para 23:59 local — correto. Funciona desde que o device esteja no fuso correto.

Caso patológico: device com fuso errado configurado → `completed_at` salvo incorretamente → `.toLocal()` não consegue corrigir → streak pode quebrar.

### completed_at < started_at (bug conhecido)
O streak usa **apenas** `completedAt` — `started_at` não entra no cálculo. Se `completedAt` for um valor válido (mesmo invertido em relação a `started_at`), o dia conta normalmente para o streak. O bug de timestamps invertidos afeta `total_duration_seconds` (poderia ser negativo, mas o `clamp(60, 86400)` garante mínimo de 60s), não o streak.

---

## Resumo dos Bugs

| # | Severidade | Arquivo | Linha | Descrição |
|---|---|---|---|---|
| 1 | 🔴 Alto | `today_metrics_widget.dart` | 103–105 | Limit 30 no cálculo de streak do Dashboard. Usuário com streak ≥ 31 dias vê o chip zerado ou truncado. |
| 2 | 🟡 Médio | `dashboard.dart` | ~125–162 | Critério do review modal usa `GetWorkoutHistory` (só `user_workouts`, limit 20). Usuários que treinam exclusivamente pelo Club nunca recebem o review de 5 dias. |
| 3 | 🟡 Médio | `club_workouts_service.dart` | 769 | `logCardioActivity` salva `completed_at` sem `.toUtc()`. Treinos de cardio após 21h local podem aparecer com a data do dia seguinte no banco (UTC-3). |
| 4 | 🟠 Médio | `today_metrics_widget.dart`, `dashboard.dart` | — | Quatro lógicas de streak independentes. Dashboard (chip) e Perfil podem exibir valores diferentes para o mesmo usuário. |

---

## Queries para verificação no banco

Rodar no Dashboard do Supabase → SQL Editor:

```sql
-- Últimos 10 treinos concluídos com timestamps no horário de Brasília
SELECT id, name,
  started_at AT TIME ZONE 'America/Sao_Paulo' AS started_br,
  completed_at AT TIME ZONE 'America/Sao_Paulo' AS completed_br,
  completed_at - started_at AS duracao
FROM user_workouts
WHERE is_completed = true
ORDER BY started_at DESC
LIMIT 10;

-- Quantidade de registros com completed_at < started_at (bug conhecido)
SELECT COUNT(*) AS registros_invertidos
FROM user_workouts
WHERE completed_at < started_at
  AND is_completed = true;

-- Treinos de cardio sem UTC (club_user_workouts)
SELECT id, notes, started_at, completed_at,
  completed_at - started_at AS duracao
FROM club_user_workouts
WHERE is_completed = true
  AND notes IN ('corrida', 'hiit', 'yoga', 'pilates', 'cardio')
ORDER BY completed_at DESC
LIMIT 10;
```

---

## Prioridade de correção sugerida

1. **Bug #1** — uma linha: mudar `limit: 30` para `limit: 200` (ou usar `GetCurrentStreak` diretamente)
2. **Bug #3** — uma palavra: adicionar `.toUtc()` em `logCardioActivity`
3. **Bug #4** — refatorar `TodayMetricsWidget` e `dashboard.dart` para delegar a `GetCurrentStreak`
4. **Bug #2** — substituir `GetWorkoutHistory` por `GetCurrentStreak` no critério do review modal
