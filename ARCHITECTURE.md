# Arquitetura BLDR — Guia de Migração para Clean Architecture

> Status: **Migração concluída (Fases 0–8), exceto o Portal Profissional**
> (adiado a pedido — falta extrair `domain/` dele). Estrutura final: features em
> `lib/features/`, telas cross-feature em `lib/shared/presentation/`,
> `lib/presentation/` extinto. Dívidas registradas na tabela e nas notas.
>
> Dívidas conhecidas da Fase 3:
> - `features/nutrition/presentation/mappers/legacy_ui_maps.dart` é TRANSITÓRIO:
>   converte entidades para os maps que os widgets internos de nutrição ainda
>   renderizam. Remover quando MealTimelineWidget, DailyNutritionOverviewWidget e o
>   modal forem tipados.
> - `firebase_nutrition_search_widget.dart` ainda consulta o Firestore diretamente
>   (stream em tempo real + capitalização própria da query, diferente da busca do
>   catálogo, que usa CAIXA ALTA). Unificar exige decidir o padrão de capitalização
>   da base `alimentos`.
> - `firebase_nutrition_service.dart` legado foi REMOVIDO na Fase 3.
>
> Nota: o `lib/services/auth_service.dart` legado ainda existe porque os services e
> telas de features não migradas (dashboard, progress, club, profile) dependem dele.
> Será removido quando essas features migrarem. As telas do fluxo de auth já não o
> importam; código novo deve usar os use cases de `features/auth/`.
> O app permanece funcional durante toda a migração: código legado e código novo convivem.

## Estrutura alvo (por feature)

```
lib/
  core/
    di/injection.dart      → registro de dependências (get_it)
    errors/failure.dart    → falhas padronizadas
    errors/result.dart     → Result<T> (sucesso/falha sem exceção)
    constants/             → constantes compartilhadas
  features/
    <feature>/
      domain/
        entities/          → classes tipadas, sem dependência de Supabase/Firebase
        repositories/      → interfaces (contratos) dos repositories
        usecases/          → um caso de uso por operação de negócio
      data/
        datasources/       → acesso cru a Supabase/Firestore/APIs externas
        models/            → DTOs com fromJson/toJson, estendem as entities
        repositories/      → implementações das interfaces do domain
      presentation/
        screens/
        widgets/
        controllers/       → ChangeNotifier/Provider; nada de lógica de dados
  models/                  → (legado) migrar para features/<x>/domain/entities
  services/                → (legado) migrar para features/<x>/data
  presentation/            → (legado) migrar para features/<x>/presentation (Fase 8)
  shared/presentation/     → telas cross-feature que NÃO pertencem a uma única
                             feature (dashboard, splash, onboarding)
```

> **Nota sobre a ordem:** as telas são migradas em duas etapas. Primeiro a
> *dependência* (a tela passa a falar com use cases em vez de services) — feito
> fase a fase. Depois o *movimento físico* do arquivo para a pasta da feature —
> concentrado na Fase 8, para não misturar renames com rewire nos diffs e porque
> algumas telas só têm destino claro depois que suas features migram.

## Regras (valem a partir de agora)

1. **Código novo não chama `XService.instance`.** Resolva via `getIt<T>()` ou receba a
   dependência pelo construtor.
2. **UI não conhece Supabase/Firestore.** Telas e widgets só falam com use cases /
   controllers. Imports de `supabase_flutter` ou `cloud_firestore` só em `data/`.
3. **Dados atravessam camadas tipados.** `Map<String, dynamic>` só existe dentro de
   `data/` (parse na borda). Domain e presentation usam entities.
4. **Erros viram `Failure`.** Datasources capturam exceções e repositories retornam
   `Result<T>` (`lib/core/errors/`). Nada de `throw Exception('...$error')` atravessando
   camadas.
5. **Direção de dependência:** `presentation → domain ← data`. O domain não importa nada
   de fora (nem Flutter, idealmente).
6. **Cada feature migrada ganha testes** de unidade nos use cases (repository mockado).

## Fluxo de uma chamada (exemplo alvo — Workouts)

```
WorkoutsScreen
  → WorkoutsController (ChangeNotifier, via Provider)
    → GetWorkoutTemplates (use case, via getIt)
      → WorkoutRepository (interface do domain)
        → WorkoutRepositoryImpl (data)
          → SupabaseWorkoutDatasource  → Supabase
          → ExerciseDbDatasource       → ExerciseDB API
```

## Ordem de migração

| Fase | Escopo | Status |
|------|--------|--------|
| 0 | Limpeza (arquivos " 2"), chave Stripe p/ config | ✅ |
| 1 | DI (get_it), Failure/Result, este documento | ✅ |
| 2 | Auth (piloto): login, cadastro, OTP, senha | ✅ |
| 3 | Nutrition (catálogo/diário no Firestore + XP no Supabase) | ✅ |
| 4a | Workouts: domain + data (repositories delegam ao WorkoutService — strangler) | ✅ |
| 4b | Workouts: rewire das 5 telas/widgets (workouts, weekly plan, create, active, banner/dashboard card) | ✅ |
| 4c | Dissolver WorkoutService em datasources (pendente: 5 widgets de dashboard/progress o usam — migram na Fase 5) | ⬜ |
| 5 | Progress (medidas + água) + Achievements — strangler sobre Progress/AchievementService; telas de progress/dashboard/achievements rewiradas | ✅ |
| 6a | BLDR Club: domain/data (strangler; reutiliza entidades de Workouts) + telas triviais (hub, cardio, progresso) | ✅ |
| 6b | BLDR Club: telas grandes (workout/create, ativo/banner, comunidade, detalhe de desafio, ranking, esportes) | ✅ |
| 6c | Cauda do Club: corrida GPS, HAVOK, notificações, perfil público, arenas/squads/tribunal. `ArenaRepository`/`HavokRepository` transitórios (linhas cruas, telas consomem o contrato direto — tipar depois). Resta só o canal realtime de XP no hub | ✅ |
| 7 | Subscription (Stripe/Apple via `SubscriptionRepository`) + versão do app; notificações classificadas como infra (ficam como services via DI). Portal profissional adiado a pedido | ✅ (exceto portal) |
| 8 | Telas movidas para `features/<x>/presentation/` e `shared/presentation/` (dashboard, splash, onboarding); todos os imports internos convertidos para `package:`. `lib/presentation/` não existe mais | ✅ |

## Notas específicas do projeto

- **Nutrição usa dois backends**: catálogo de alimentos no **Firestore** (`alimentosDB`,
  via `FirebaseNutritionService`) e diário/refeições do usuário no **Supabase**. A
  migração da Fase 3 esconde isso atrás de `FoodRepository` + `NutritionDiaryRepository`.
- **Exercícios têm duas origens**: biblioteca interna (Supabase `exercises`) e ExerciseDB
  (RapidAPI). O enriquecimento feito hoje dentro do `WorkoutService` vira responsabilidade
  do repository na Fase 4.
- `lib/features/professional_portal/` e `lib/features/club/` já seguem parcialmente o
  layout de features — usar como referência de destino, completando o `domain/`.
- Config em `dart_defines.dev.json` (carregado via `rootBundle` no `main.dart`).

## Mini-player global — treino pausado (2026-08-20)

`BldrMiniPlayer` é um `Positioned` pill inserido no Stack de `BldrScreen`
(em `lib/design_system/bldr_components.dart`), acima da navbar (`bottom: 140`).
O estado é gerenciado por `WorkoutSessionProvider` (ChangeNotifier registrado
no `MultiProvider` do `main.dart`).

```
active_workout_screen / club_active_workout_screen
  → _finishWorkout(): sessionProvider.setPausedWorkout(null)

active_workout_card_widget (Dashboard)
  → após load: sessionProvider.setPausedWorkout(firstPaused)

BldrMiniPlayer (Consumer<WorkoutSessionProvider>)
  → isVisible == true → exibe pill com nome e progresso
  → tap "Retomar": provider.hide() → push rota → .then(() => provider.show())
```

Fontes dos dados: `GetPausedWorkouts` use case → `PausedWorkoutSummary`
(entidade com `id, name, source, startedAt, totalExercises, completedExercises`).
Novos arquivos:
- `lib/shared/providers/workout_session_provider.dart`
- `lib/shared/presentation/widgets/bldr_mini_player.dart`

## Apple Watch — arquitetura atual (2026-08-09)

```
iPhone (Flutter)                       Watch (SwiftUI)
────────────────────                   ──────────────────────────────
WatchService                           WatchViewModel (WCSession)
  sendWorkoutState() ─────────────────▶ processarDados() → WorkoutTabView
  sendRunState()     ─────────────────▶ processarDados() → RunTabView (.connected)
  watchActions stream◀─────────────── sendMessage(concluir_serie / finalizar_treino / acao_corrida)

Corrida autônoma (Watch sem iPhone):
  AutonomousRunManager                 RunTabView (.autonomous)
    HKWorkoutSession (wake lock)         AutonomousRunView
    CLLocationManager (GPS)              Text(startDate, .timer) ← @Published startDate
    UserDefaults(group.com.bldr.fitness) ← saveRunDataLocally()

Sincronização pós-corrida:
  WatchViewModel.syncPendingRuns()  ─── session.transferFile() ──▶ AppDelegate (WCSessionDelegate)
  WatchService._listenForRunMessages()  messageStream { type: run_synced, key }
  AppDelegate "com.bldr.fitness/appgroup" MethodChannel
    getAppGroupValue(key) → JSON string
    removeAppGroupValue(key)
  WatchService._processRunFromAppGroup() → SaveRunActivity use case

LiveActivity (iPhone → Lock Screen / Dynamic Island):
  RunLiveActivityService.start/update/pause/resume/end()
    live_activities plugin → ActivityKit → BLDRWorkoutActivity.swift
      activityType == "run" → BLDRRunActivity.swift views
      activityType != "run" → BLDRWorkoutActivity.swift views
```

**Entitlements Watch:** `com.apple.developer.healthkit` + App Group `group.com.bldr.fitness`.
**Info.plist Watch:** gerado via `GENERATE_INFOPLIST_FILE = YES`; usage descriptions em `INFOPLIST_KEY_*` no `project.pbxproj`.
