# BLDR — Inventário de Auditoria (pré-redesign)

> Retrato do código em **01/08/2026**, branch `main` (commit `8244848`).
> Documento **descritivo**: nenhuma solução é proposta aqui e nenhum arquivo de
> UI foi alterado para produzi-lo.
>
> Método: leitura direta dos arquivos + varredura de imports. Onde não encontrei
> evidência, está escrito **NÃO ENCONTRADO** — não há inferência.

**Achado que atravessa o documento inteiro:** o `CLAUDE.md` manda compor as telas
a partir de `lib/theme/bldr_tokens.dart` e `lib/widgets/bldr_components.dart`.
**Nenhum dos dois arquivos existe.** Não há design system implementado hoje: o
que existe é `lib/theme/app_theme.dart` (paleta antiga, "Luxury Athletic") e
**704 ocorrências de `Color(0x…)` inline** espalhadas por 100+ arquivos.

---

## 1. Mapa de telas

### 1.1 Telas do REDESIGN_SPEC.md

| Tela no SPEC | Arquivo real | Linhas | Tipo | Estado |
|---|---|---|---|---|
| Dashboard (D1–D9) | [dashboard.dart](lib/shared/presentation/dashboard/dashboard.dart) | 486 | `StatefulWidget` + `TickerProviderStateMixin`, sem controller | ✅ |
| Treinos (T1–T9) | [workouts_screen.dart](lib/features/workouts/presentation/workouts_screen/workouts_screen.dart) | 1109 | `StatefulWidget`, sem controller | ✅ |
| Meu Plano (P1–P5) | [weekly_plan_screen.dart](lib/features/workouts/presentation/workouts_screen/weekly_plan_screen.dart) | 1353 | `StatefulWidget`, sem controller | ✅ |
| Nutrição (N1–N9) | [nutrition_screen.dart](lib/features/nutrition/presentation/nutrition_screen/nutrition_screen.dart) | 373 | `StatefulWidget` | ✅ |
| Adicionar alimento (N10–N16) | [firebase_add_food_modal_widget.dart](lib/features/nutrition/presentation/nutrition_screen/widgets/Firebase/firebase_add_food_modal_widget.dart) | 1266 | `StatefulWidget` (bottom sheet) | ✅ |
| Formulário manual (N17–N22) | idem acima (mesmo arquivo, aba "Manual") | — | — | ✅ |
| BLDR Club — Hub (C1–C5) | [bldr_club_screen.dart](lib/features/club/presentation/bldr_club/bldr_club_screen.dart) | 609 | `StatefulWidget` + 8 sub-widgets privados | ✅ |
| BLDR Club — Treinos (CT1–CT7) | [club_workout_screen.dart](lib/features/club/presentation/bldr_club/club_workout_screen.dart) | **3041** | `StatefulWidget` + 17 classes privadas no mesmo arquivo | ✅ |
| BLDR Club — Meu Plano (CP1–CP5) | **é a MESMA** [weekly_plan_screen.dart](lib/features/workouts/presentation/workouts_screen/weekly_plan_screen.dart) | 1353 | — | ⚠️ compartilhada |
| BLDR Club — Esportes (CE1–CE5) | [esportes_screen.dart](lib/features/club/presentation/bldr_club/esportes_screen.dart) | 1079 | `StatefulWidget` | ✅ |
| Round Timer (CR1–CR5) | [round_timer_screen.dart](lib/features/club/presentation/bldr_club/trackers/round_timer_screen.dart) | 734 | `StatefulWidget` | ✅ |
| Match Tracker (CM1–CM5) | [match_tracker_screen.dart](lib/features/club/presentation/bldr_club/trackers/match_tracker_screen.dart) | 914 | `StatefulWidget` | ✅ |
| Protocolo — detalhe do dia (CX1–CX4) | [plano_performance_detail_screen.dart](lib/features/club/presentation/bldr_club/plano_performance_detail_screen.dart) | 372 | `StatefulWidget` | ✅ |
| Comunidade (CC1–CC5) | [comunidade_screen.dart](lib/features/club/presentation/bldr_club/comunidade_screen.dart) | **2834** | `StatefulWidget` + `TabController` + 10 classes privadas | ✅ |
| Competição (CQ1–CQ5) | [competition_hub_screen.dart](lib/features/club/presentation/bldr_club/competition_hub_screen.dart) | 335 | `StatefulWidget` | ✅ |
| Perfil (PF1–PF9) | [profile_screen.dart](lib/features/profile/presentation/profile_drawer/profile_screen.dart) | 1703 | `StatefulWidget` | ✅ |
| **Configurações (S1–S9)** | — | — | — | **NÃO ENCONTRADA** |
| Progresso — 4 abas (PG/PC/PT/PN) | [progress_screen.dart](lib/features/progress/presentation/progress_screen/progress_screen.dart) | 468 | `StatefulWidget` + `TabController` | ✅ |

**Nenhuma tela do app usa controller.** O `ARCHITECTURE.md` prevê
`presentation/controllers/` (ChangeNotifier/Provider); esse diretório **não
existe em nenhuma feature**. Todo estado de tela é `setState` dentro do `State`.
A única exceção é o `AchievementProvider` (`ChangeNotifier` global, registrado no
`main.dart:67`), que é fila de toasts, não estado de tela.

**Configurações (S1–S9) não existe como tela.** Hoje o bloco de configurações
está dentro do `profile_screen.dart`: "Refazer Onboarding" em `profile_screen.dart:1533`,
"Sair" em `:1617`, "Excluir Conta" em `:1654`. Não há rota registrada em
[app_routes.dart](lib/routes/app_routes.dart) e **não há widget de versão do app
no Perfil** (S9) — `package_info` não é referenciado no arquivo.

### 1.2 Widgets internos por tela, e o que é compartilhado

#### Dashboard
Compõe 8 widgets, **todos exclusivos** (`shared/presentation/dashboard/widgets/`):
`greeting_header_widget` · `today_metrics_widget` · `active_workout_card_widget`
(762 l.) · `goal_card_widget` · `nutrition_progress_widget` ·
`consistency_heatmap_widget` · `achievements_widget` · `partnership_widget`.
`quick_actions_widget.dart` está no diretório mas **não é importado por ninguém**.

#### Treinos
`current_week_card_widget` (485 l., exclusivo) · `workout_card_widget`
(exclusivo) · `continue_workout_card` (**compartilhado** —
`lib/widgets/continue_workout_card.dart`, usado também em
`club_workout_screen.dart:1377`). Navega para `active_workout_screen`,
`create_workout_screen`, `weekly_plan_screen`, `workout_photo_review_screen`.
`featured_workouts_widget`, `workout_search_bar_widget`,
`exercise_categories_widget` e `active_workout_banner_widget` (1339 l.!) estão no
diretório mas **são código morto** (ver 1.4).

#### Meu Plano
Nenhum widget externo além de `muscle_visualizer_widget` (**compartilhado**,
`lib/widgets/`, 3 importadores). Todo o resto é `_build…` privado, incluindo um
`_DashedCirclePainter` local (`:1327`) duplicado em `club_workout_screen.dart:3015`
e em `current_week_card_widget.dart:459`.

#### Nutrição
`daily_nutrition_overview_widget` (765 l.) · `meal_timeline_widget` (560 l.) ·
`water_intake_widget` (504 l.) · `firebase_add_food_modal_widget` (1266 l.) ·
`food_categories_modal`. Todos exclusivos da tela.
`firebase_nutrition_search_widget` e `barcode_scanner_page` são chamados de
dentro do modal. **`add_food_modal_widget.dart` (672 l.) é código morto.**

#### BLDR Club — Hub
`panther_fab` (**compartilhado** — importado de `havok_hub.dart`),
`level_up_modal`, `smart_club_slider` (443 l.), `competition_hub_screen`.
`_Header`, `_LevelProgressCard`, `_GoldRadialBackground`, `_RadialBlob` são
classes privadas do arquivo — e `_GoldRadialBackground`/`_RadialBlob` estão
**duplicadas ipsis litteris** em `club_workout_screen.dart:2953`,
`esportes_screen.dart:1027` e `plano_performance_detail_screen.dart:338`.

#### BLDR Club — Treinos
Além do `continue_workout_card` compartilhado, importa **`weekly_plan_screen`**
(`:21`) e `club_active_workout_screen` (3 importadores). Os 17 sub-widgets
(`_ClubCurrentWeekCard`, `_ProgramCard`, `_CardioCard`, `_PersonalWorkoutTile`,
`_LibraryTile`…) vivem dentro do próprio arquivo de 3041 linhas.
Todo o diretório `bldr_club/widgets/club_*` (7 arquivos) é **código morto**.

#### Esportes / Trackers
`esportes_screen` importa `run_card_widget`, `round_timer_screen`,
`match_tracker_screen`, `tracker_storage` (**compartilhado**, 6 importadores) e
`plano_performance_detail_screen`. **`plano_performance_detail_screen` importa de
volta o `esportes_screen`** (`:3`) — ciclo de imports entre telas.
`tracker_share_screen` é **compartilhado** por 5 trackers.

#### Perfil
`profile_header_widget` · `profile_section_widget` · `edit_profile_dialog_widget` ·
`confirmation_dialog_widget` — os 4 são compartilhados com
`profile_drawer.dart`, **que é código morto** (nenhum importador). Na prática,
exclusivos.

#### Progresso
8 widgets, **todos exclusivos**: `progress_overview_widget` ·
`achievements_gallery_widget` · `goal_tracking_widget` (818 l.) ·
`measurements_chart_widget` (762 l.) · `photo_progress_widget` (785 l.) ·
`nutrition_analytics_widget` (817 l.) · `workout_progress_widget` (514 l.) ·
`export_progress_widget`. `daily_sleep_overview_widget` está comentado
(`progress_screen.dart:22`).

### 1.3 Risco de efeito colateral — o que é compartilhado de verdade

| Compartilhado | Onde | Consequência de mexer |
|---|---|---|
| **`weekly_plan_screen.dart`** | Treinos (`:22`) **e** Club → Treinos (`:21`) | P1–P5 e CP1–CP5 são **o mesmo arquivo**. Não dá para redesenhar "Meu Plano" e "Club → Meu Plano" separadamente sem antes bifurcar. |
| `continue_workout_card.dart` | Treinos, Club → Treinos, (+1) | G2/G3 mudam as duas telas juntas |
| `tracker_storage.dart` | 6 trackers | Só dado, sem UI — risco baixo |
| `tracker_share_screen.dart` | 5 trackers | Tela de share única |
| `custom_icon_widget.dart` (2189 l.) | 77 arquivos via `app_export.dart` | Mapa string→`IconData`; qualquer troca de família de ícones passa por aqui |
| `app_theme.dart` | 28 importadores diretos + 77 via `app_export` | Único ponto global de cor/tipografia |
| `havok_hub.dart` (as cores) | 6 arquivos | Ver §2b |
| `panther_fab.dart` | Hub do Club | Paywall hardcoded (ver §2b) |
| `achievement_badge.dart` | 4 telas | PF5/PG3/PG4 tocam as 4 |
| `legacy_ui_maps.dart` (workouts) | **8 arquivos** | Ver §4 |

### 1.4 Telas fora do escopo do SPEC

**Existem no código, funcionam, não estão no SPEC:**

| Tela | Arquivo | Linhas |
|---|---|---|
| Login / Cadastro / OTP / Nova senha / Confirmação | `features/auth/presentation/` (8 arquivos) | ~1.900 |
| Splash | `shared/presentation/splash_screen/` | 351 |
| Onboarding (15 etapas) | `shared/presentation/onboarding_flow/` + 9 widgets | 1636 + ~1.100 |
| Onboarding — conclusão | `shared/presentation/onboarding_completion_screen.dart` | — |
| Checkout / assinatura | `features/subscription/presentation/checkout_screen/` + 4 widgets | 838 + ~600 |
| Treino ativo (grátis) | `workouts_screen/active_workout_screen.dart` | 1548 |
| Treino ativo (Club) | `bldr_club/club_active_workout_screen.dart` | 1764 |
| Criar treino (grátis / Club) | `create_workout_screen.dart` / `club_create_workout_screen.dart` | 1574 / 1308 |
| Revisão de foto de treino (×2) | `workout_photo_review_screen.dart` / `club_…` | 602 / 633 |
| Ranking | `bldr_club/ranking_screen.dart` | 989 |
| Detalhe de desafio coletivo | `collective_challenge_detail_screen.dart` | 2048 |
| Arena: detalhes / criar / config / tribunal / histórico / entrar | 6 arquivos em `bldr_club/` | ~2.700 |
| Corrida GPS: tracker / detalhe / lista / share | `bldr_club/corrida/` | ~1.400 |
| Notificações | `bldr_club/notifications_screen.dart` | 506 |
| Perfil público | `bldr_club/public_profile_screen.dart` | 670 |
| Cardio do Club | `club_cardio_session_screen.dart` | 683 |
| Check-in (sheet) | `create_checkin_sheet.dart` | 393 |
| Trackers **não citados**: WOD, Pool, Yoga, Session hub | `bldr_club/trackers/` | ~1.900 |
| HAVOK: hub, treino livre, biblioteca de treinos, receitas ×2, detalhe | `bldr_club/havok/` | ~1.100 |
| Programas do Club | `club/programs_page.dart`, `program_detail_page.dart` | ~600 |
| **Portal profissional inteiro** (9 telas + 2 widgets) | `features/professional_portal/presentation/` | ~2.200 |

O Portal Profissional é o maior bloco fora do escopo: ~2.200 linhas, **sem camada
`domain/`** (adiado a pedido, `ARCHITECTURE.md` linha 103). Se G1–G10 forem
aplicados globalmente via `AppTheme`, ele muda de aparência sem ninguém ter
revisado o resultado.

**Código morto encontrado (24 arquivos sem nenhum importador):**
`workouts_screen/widgets/active_workout_banner_widget.dart` (1339 l.) ·
`bldr_club/widgets/active_workout_banner_club.dart` (1392 l.) ·
`nutrition_screen/widgets/add_food_modal_widget.dart` (672 l.) ·
`profile_drawer/profile_drawer.dart` (1409 l.) ·
`bldr_club/trackers/session_tracker_hub_screen.dart` ·
`bldr_club/corrida/activity_list_screen.dart` ·
`bldr_club/widgets/{club_featured_workouts, club_featured_programs, club_workout_card, club_program_card, club_exercise_categories, club_workout_search_bar, survivor_card, level_progress_bar, program_card}.dart` ·
`workouts_screen/widgets/{featured_workouts, workout_search_bar, exercise_categories}.dart` ·
`dashboard/widgets/quick_actions_widget.dart` ·
`checkout_screen/widgets/coupon_widget.dart` ·
`auth/…/bldr_logo_widget.dart` ·
`widgets/{custom_image_widget, loading_indicator_widget}.dart` ·
`core/constants/onboarding_constants.dart`.

**Isso soma ~7.500 linhas de UI morta.** Duas delas têm consequência funcional
direta, documentada em §2 (B2).

---

## 2. Status dos itens [F]

### Prioridade 1 — Bugs

---

#### B1. Duração média = 0m [PT3] — **JÁ EXISTE (bug localizado)**

**Causa raiz: [progress_service.dart:262–331](lib/services/progress_service.dart:262).**

`ProgressService.getWorkoutProgress()` consulta **apenas a tabela
`user_workouts`** (treinos grátis):

- `:280` — `from('user_workouts')` → `total_workouts`
- `:287` — `from('user_workouts')` → `completed_workouts`
- `:298–303` — `from('user_workouts').select('total_duration_seconds')`

Já a lista "Treinos Recentes" logo abaixo, no mesmo widget, é a **união de duas
fontes** ([workout_progress_widget.dart:52–62](lib/features/progress/presentation/progress_screen/widgets/workout_progress_widget.dart:52)):
`GetWorkoutHistory` (`user_workouts`) **+** `GetClubWorkoutHistory`
(`club_user_workouts`).

→ Um treino do Club de 53 min é gravado em `club_user_workouts.total_duration_seconds`
([club_workouts_service.dart:223](lib/services/club_workouts_service.dart:223)),
**aparece na lista** e **não entra na média**. Se o usuário só treina pelo Club,
numerador = 0 e a média é literalmente `0m`.

**Segundo defeito, independente, no mesmo cálculo** —
[progress_service.dart:326–329](lib/services/progress_service.dart:326):

```dart
'average_workout_duration_minutes':
  completedWorkouts > 0 ? ((totalWorkoutTime / completedWorkouts) / 60).round() : 0,
```

`totalWorkoutTime` soma só linhas com `.not('total_duration_seconds', 'is', null)`
(`:303`), mas divide por `completedWorkouts`, que **conta todas** as concluídas.
É exatamente a hipótese do backlog ("divisão por total de treinos do período em
vez de treinos com duração registrada") — e ela está correta, só não é a causa
principal.

Consumo do valor: `workout_progress_widget.dart:128–129` → renderizado em `:317–318`.

---

#### B2. Contadores de conquista inconsistentes [PG5] — **JÁ EXISTE (bug localizado)**

**A hipótese do backlog (`==` em vez de `>=`) está errada.** Verifiquei
[achievement_service.dart:335–373](lib/services/achievement_service.dart:335):
todas as comparações mensuráveis usam `>=`. O único `==` é
`trained_on_date` (`:345`), que é comparação de data e está correto.

**Causa raiz real — a barra e o desbloqueio leem fontes diferentes.**

O card em `achievements_gallery_widget.dart` mostra "26/10" porque:

1. A barra vem do **contexto ao vivo**:
   `_currentValue()` ([achievements_gallery_widget.dart:334–345](lib/features/progress/presentation/progress_screen/widgets/achievements_gallery_widget.dart:334))
   lê `GetWorkoutAchievementContext`, e `_fetchWorkoutContext`
   ([achievement_service.dart:140–157](lib/services/achievement_service.dart:140))
   soma `user_workouts` **+** `club_user_workouts` → 26.
2. O estado "obtido" vem **só da tabela** `user_achievements`:
   `_isUnlocked()` ([achievements_gallery_widget.dart:69–70](lib/features/progress/presentation/progress_screen/widgets/achievements_gallery_widget.dart:69))
   → `_unlockedNames.contains(...)`. **A galeria nunca chama
   `CheckAndUnlockAchievements`.**

Ou seja: se a linha nunca foi inserida em `user_achievements`, o card fica
"pendente com barra cheia" para sempre, mesmo com o critério cumprido.

**Por que a linha não é inserida — três motivos empilhados:**

a) **O gatilho de treino mais usado está em código morto.**
   `checkAchievements('workout')` existe em três lugares:
   - [active_workout_banner_widget.dart:486](lib/features/workouts/presentation/workouts_screen/widgets/active_workout_banner_widget.dart:486) → **arquivo sem nenhum importador (código morto)**
   - [active_workout_card_widget.dart:726](lib/shared/presentation/dashboard/widgets/active_workout_card_widget.dart:726) → vivo, mas só dispara se o treino for finalizado **pelo card do Dashboard**
   - `onboarding_flow.dart:638` → trigger `'onboarding'`

   Quem finaliza pela tela de treino ativo **não dispara nada**:
   [active_workout_screen.dart:344–351](lib/features/workouts/presentation/workouts_screen/active_workout_screen.dart:344) chama `CompleteWorkout` e volta, sem `checkAchievements`.

b) **O trigger `'bldr_club'` nunca é disparado no app.** Nenhum arquivo chama
   `checkAchievements('bldr_club')`. `club_active_workout_screen.dart:377–386`
   chama `CompleteClubWorkout` e comenta *"falha silenciosa, como no original"*.
   Todas as conquistas de `_bldrClubCriteria`
   ([achievement_service.dart:96–99](lib/services/achievement_service.dart:96):
   `bldr_workout_total`, `bldr_streak_days`, `duel_wins`, `ranking_position`,
   `club_member`, `club_level`, `total_xp`) dependem exclusivamente do backfill.

c) **O backfill roda uma vez por instalação e nunca mais.**
   [achievement_provider.dart:82–94](lib/features/achievements/presentation/achievements/achievement_provider.dart:82):
   grava `bldr_ach_backfill_v2` em `SharedPreferences` e retorna cedo em toda
   execução seguinte. Quem passou de 10 treinos **depois** do backfill fica preso.

Há ainda um `_isChecking` global ([achievement_provider.dart:101](lib/features/achievements/presentation/achievements/achievement_provider.dart:101))
que descarta silenciosamente qualquer checagem concorrente.

O toast depende do canal Realtime em `user_achievements`
([achievement_provider.dart:30–47](lib/features/achievements/presentation/achievements/achievement_provider.dart:30)),
portanto herda o mesmo problema.

---

#### B3. Treino com duração 0min no histórico — **PARCIAL**

A duração é calculada **na hora de completar**, a partir de `started_at`:
[club_workouts_service.dart:216–217](lib/services/club_workouts_service.dart:216)
e [workout_service.dart:388](lib/services/workout_service.dart:388). Não há
nenhuma validação de piso, nem no service nem no use case
(`CompleteWorkout`, `workout_usecases.dart:72`). Iniciar e finalizar em segundos
grava `0` legitimamente. A renderização em
[workout_progress_widget.dart:437](lib/features/progress/presentation/progress_screen/widgets/workout_progress_widget.dart:437)
não filtra. **Falta: a decisão de produto + o guard.**

---

### Prioridade 2 — Habilitam o redesign

---

#### F1. Ícone de atividade por dia [CT1, CP2] — **PARCIAL (assimétrico entre telas)**

**Resposta direta às perguntas do briefing:**

> *O app já detecta corrida/musculação/outro?*

Sim, mas **por heurística de string, não por campo tipado**, e só dentro do
`club_workout_screen.dart`.

> *Onde isso é gravado e sob qual nome de campo?*

Duas fontes, nenhuma com campo dedicado nos treinos:

| Fonte | Tabela | Campo | Como o tipo é obtido |
|---|---|---|---|
| Treinos do Club | `public.club_user_workouts` | **não existe campo de tipo** | `contains()` sobre `notes` ou, em fallback, sobre `name` — [club_workout_screen.dart:1785–1799](lib/features/club/presentation/bldr_club/club_workout_screen.dart:1785) |
| Atividades avulsas (corrida GPS, esporte) | `bldr_club.user_activities` | **`activity_type`** (string livre) | `contains('run'/'corrida'/'sport'/'esporte')`, com fallback para corrida — [club_workout_screen.dart:1822–1830](lib/features/club/presentation/bldr_club/club_workout_screen.dart:1822) |
| Treinos pessoais | `public.user_workouts` → `workout_templates` | `workout_type` | **não é usado** para o ícone; assume `_ActivityType.workout` — [club_workout_screen.dart:1814](lib/features/club/presentation/bldr_club/club_workout_screen.dart:1814) |

O enum é local e privado:
`enum _ActivityType { workout, running, sport, yoga, none }`
([club_workout_screen.dart:1644](lib/features/club/presentation/bldr_club/club_workout_screen.dart:1644)) —
note que ele tem **`yoga`**, que não consta no contrato sugerido pelo backlog.

O caminho até a UI existe inteiro: `activityByDay` (`:1777`) → `_ClubWeekDay.activityType`
(`:1650`, `:1869`) → `_buildDot(status, activityType)` (`:2355`) →
`_activityIcon()` (`:2418`) → `Icons.directions_run` / `self_improvement` /
`local_fire_department` / `fitness_center`.

**Contrato de domínio:** existe a entidade `ClubActivity` com `activityType`
tipado, montada em
[club_repositories_impl.dart:191–199](lib/features/club/data/repositories/club_repositories_impl.dart:191),
servida por `GetClubActivitiesBetween`. O datasource
[supabase_club_datasource.dart:60–72](lib/features/club/data/datasources/supabase_club_datasource.dart:60)
inclusive documenta a intenção: *"SEM filtrar `is_completed` (a tela usa treinos
em andamento para inferir o tipo de atividade do dia)"*.

**Onde NÃO existe:**
- [current_week_card_widget.dart:8–24](lib/features/workouts/presentation/workouts_screen/widgets/current_week_card_widget.dart:8) — `_WeekDay` só tem `_DayStatus`; `_buildDot(status)` (`:406`) não recebe tipo de atividade. **CT1 na tela de Treinos: NÃO EXISTE.**
- [weekly_plan_screen.dart:18–20](lib/features/workouts/presentation/workouts_screen/weekly_plan_screen.dart:18) — `PlanDay` idem. **CP2: NÃO EXISTE.**

---

#### F2. XP e métrica por dia na timeline [CP3] — **NÃO EXISTE**

`PlanDay` ([weekly_plan_screen.dart:20](lib/features/workouts/presentation/workouts_screen/weekly_plan_screen.dart:20))
não carrega XP nem métrica. O XP **agregado da semana** existe
(`GetClubXpBetween`, usado em `club_workout_screen.dart:1763` → `_weekXp`), mas é
um único inteiro do período, não por dia. A duração por sessão está em
`WorkoutSession.totalDurationSeconds`
([workout_models.dart:112](lib/features/workouts/data/models/workout_models.dart:112))
e a distância em `user_activities.distance_meters`
([run_card_widget.dart:108](lib/features/club/presentation/bldr_club/corrida/run_card_widget.dart:108)) —
os dados brutos existem, a agregação por dia não.

#### F3. Atividades extras na timeline [CP4, CP5] — **PARCIAL**

O conceito de "extra" **já existe no card de semana do Club**:
`extraByDay` / `_extraActivitiesCount`
([club_workout_screen.dart:1819–1836](lib/features/club/presentation/bldr_club/club_workout_screen.dart:1819)),
e o contador do plano é explicitamente separado (`_gymWorkoutsCount` é clampado
em `effectiveFreq`, `:1891`). Registro manual de check-in existe
([create_checkin_sheet.dart:150](lib/features/club/presentation/bldr_club/create_checkin_sheet.dart:150),
grava `duration_minutes`), mas é escopo de arena/tribunal, não da timeline.
**Falta:** trazer o conceito para `weekly_plan_screen` e o botão "Registrar extra".

#### F4. Gráfico dos últimos 7 dias no Dashboard [D7] — **PARCIAL**

`consistency_heatmap_widget.dart` já monta uma grade de 14 dias em 2 linhas de 7
(`_buildGrid2Rows`, `:162`) e o Dashboard já o renderiza. O dado por dia
(`Map<'yyyy-MM-dd', int>`) existe em `_generateHeatmapData`
([workout_progress_widget.dart:96–113](lib/features/progress/presentation/progress_screen/widgets/workout_progress_widget.dart:96)) — mas
**conta sessões, não volume nem duração**, que é o que D7 pede. `fl_chart ^1.1.1`
já está no `pubspec.yaml:46`.

#### F5. Resumo de alimentos na linha da refeição [N8] — **PARCIAL**

O widget já renderiza chips de alimento quando há itens e cai em
`'Nenhum alimento'` quando não há
([meal_timeline_widget.dart:300–313](lib/features/nutrition/presentation/nutrition_screen/widgets/meal_timeline_widget.dart:300)).
O dado necessário existe tipado: `MealEntry.foodName` e `MealEntry.macros.calories`
([meal_entry.dart](lib/features/nutrition/domain/entities/meal_entry.dart)).
**Falta:** o formato "primeiros nomes · total kcal" numa linha só.

#### F6. Feed com descrição real [CC4] — **NÃO EXISTE**

A string é gerada por classificação grosseira do campo `reason` do evento de XP:
[comunidade_screen.dart:447](lib/features/club/presentation/bldr_club/comunidade_screen.dart:447)
— `if (r.contains('treino') || r.contains('workout')) return 'concluiu um treino';`.
O nome do treino, a distância e a conquista **não trafegam** no evento; a fonte é
`bldr_club.xp_events`, que só tem `user_id`, `delta` e `reason`
([supabase_club_datasource.dart:100–106](lib/features/club/data/datasources/supabase_club_datasource.dart:100)).
O fallback "Atleta" está em `comunidade_screen.dart:88`.

#### F7. Reação com estado persistido [CC5] — **PARCIAL**

A tabela `bldr_club.xp_reactions` existe, com leitura agregada
(`reactionCounts`, [supabase_challenges_datasource.dart:30–40](lib/features/club/data/datasources/supabase_challenges_datasource.dart:30))
e escrita ([`:45`](lib/features/club/data/datasources/supabase_challenges_datasource.dart:45)).
O contador chega à tela via `ClubActivityItem.reactionCount`
([challenge_repository_impl.dart:79](lib/features/club/data/repositories/challenge_repository_impl.dart:79)).
**Falta exatamente o que o backlog descreve:** não há consulta que diga *se o
usuário atual já reagiu*. A tela usa um optimistic-increment local
([comunidade_screen.dart:252](lib/features/club/presentation/bldr_club/comunidade_screen.dart:252))
que se perde no reload.

#### F8. Checklist de exercício no protocolo [CX3, CX4] — **NÃO EXISTE**

Grep por `checkbox|Checkbox|concluido` em
[plano_performance_detail_screen.dart](lib/features/club/presentation/bldr_club/plano_performance_detail_screen.dart):
**zero ocorrências**. A tela é read-only sobre o payload do plano.

#### F9. Ranking interno do squad [CQ3] — **PARCIAL**

`ArenaRepository.participantsCombined(arenaId, {required orderBy})`
([arena_repository.dart:41–43](lib/features/club/domain/repositories/arena_repository.dart:41))
já retorna participantes ordenados por vidas/pontos com `name` e `avatar`
anexados; `membersCombined` (`:44`) traz `user_id`/`status`/`name`/`avatar`.
**Falta:** a métrica *por modo de jogo* (dias de treino / XP / km) que as barras
comparativas exigem — o repository devolve vidas e pontos, não isso. E são
`Map<String, dynamic>` crus (ver §4).

#### F10. Próxima conquista com critério [PF6] — **PARCIAL**

Os três insumos existem em `achievements_gallery_widget.dart`: catálogo com
`criteria_type`/`criteria_value` (`:223–224`), conjunto de desbloqueadas (`:61`) e
valor atual via `_currentValue()` (`:334`). **Falta:** o cálculo de "qual falta
menos" e a exibição no Perfil — e há um limite duro: `_measurable`
([achievements_gallery_widget.dart:325–328](lib/features/progress/presentation/progress_screen/widgets/achievements_gallery_widget.dart:325))
só cobre `workout_count`, `hiit_workout_count` e `consecutive_days`. Para os
demais critérios não há valor atual disponível na presentation.

---

### Prioridade 3 — Telas e seções novas

| # | Item | Status | Evidência |
|---|---|---|---|
| **F11** | Configurações → Metas [S5] | **PARCIAL** | Os alvos são lidos de `onboarding_data` (`target_protein`, `target_carbs`, `target_fat`, `target_calories`) em [daily_nutrition_overview_widget.dart:70–72](lib/features/nutrition/presentation/nutrition_screen/widgets/daily_nutrition_overview_widget.dart:70) e [nutrition_analytics_widget.dart:70](lib/features/progress/presentation/progress_screen/widgets/nutrition_analytics_widget.dart:70). Existe `goal_tracking_widget.dart` (818 l.) em Progresso, sobre a tabela `user_goals`. **Falta:** tela de edição e o vínculo entre `user_goals` e o `onboarding_data` que a nutrição realmente consome. |
| **F12** | Integrações [S6] | **PARCIAL** | Existe `oura_api_service.dart` e `strava-auth` (edge function). O `daily_sleep_overview_widget` está **comentado** ([progress_screen.dart:21–22](lib/features/progress/presentation/progress_screen/progress_screen.dart:21)). Apple Saúde: **NÃO ENCONTRADO** — nenhum `health`/`HealthKit` no `pubspec.yaml`. |
| **F13** | Privacidade [S7] | **NÃO EXISTE** | Nenhum campo de visibilidade em `user_profiles` referenciado no código. O ranking expõe nome real sem opção ([ranking_screen.dart](lib/features/club/presentation/bldr_club/ranking_screen.dart)). |
| **F14** | Central de ajuda e Termos [S8] | **NÃO ENCONTRADO** | Nenhuma rota, tela ou URL de termos em `lib/`. |
| **F15** | Progresso → Corpo [PC4–PC7] | **JÁ EXISTE, em grande parte** | PC4: `LineChart` real com `fl_chart` — [measurements_chart_widget.dart:518–600](lib/features/progress/presentation/progress_screen/widgets/measurements_chart_widget.dart:518); variação no período em `_buildProgressSummary()` (`:315`). PC5: galeria de fotos em `_buildPhotoGallery()` ([photo_progress_widget.dart:606](lib/features/progress/presentation/progress_screen/widgets/photo_progress_widget.dart:606)) — grid, não carrossel. PC6: comparação antes/depois **já implementada** (`_buildCompareFrame`, `:386`, com guard de "ao menos 2 fotos", `:338`). PC7: `_buildRecentMeasurements()` (`measurements_chart_widget.dart:616`). **O backlog superestima o trabalho aqui: é majoritariamente reorganização visual.** |
| **F16** | Progresso → Nutrição [PN3–PN7] | **PARCIAL, mais adiantado que o backlog sugere** | PN3: `_buildCalorieChart()` ([nutrition_analytics_widget.dart:433](lib/features/progress/presentation/progress_screen/widgets/nutrition_analytics_widget.dart:433)) + meta em `:323`. PN7: `_buildRecentMeals()` (`:634`) com alimentos e calorias (`:693`). PN6: o card a remover é `_buildNutritionTips()` (`:744`, título em `:777`). **NÃO EXISTE:** PN4 (média de macros no período) e PN5 (evolução do IQD — o IQD é calculado só para o dia atual, ver F17). |
| **F17** | IQD em tempo real no formulário [N22] | **PARCIAL** | `IqdCalculatorService.calculate()` é **função pura e síncrona** ([iqd_calculator_service.dart:9–42](lib/services/iqd_calculator_service.dart:9)) — recalcular a cada keystroke é trivial. Já é importada pelo próprio modal ([firebase_add_food_modal_widget.dart](lib/features/nutrition/presentation/nutrition_screen/widgets/Firebase/firebase_add_food_modal_widget.dart)). **Falta:** o rodapé fixo e o wiring dos controllers. |
| **F18** | Histórico de sets/partidas no Match Tracker [CM4, CM5] | **PARCIAL** | `tracker_storage.dart` já persiste sessões (usado por 6 trackers) e há `_PostSessionSheet` ([match_tracker_screen.dart:632](lib/features/club/presentation/bldr_club/trackers/match_tracker_screen.dart:632)). **Falta:** acúmulo de sets durante a partida e a listagem de partidas anteriores. Note que CR5 (histórico do Round Timer) é marcado **[V]** no SPEC, sugerindo que lá o dado já é exibido — no Match Tracker não é. |
| **F19** | BLDR Run — stats inline [CE1] | **PARCIAL** | `distance_meters` e `pace_text` já vêm da linha e são renderizados no card expandido ([run_card_widget.dart:108–110, 315–372](lib/features/club/presentation/bldr_club/corrida/run_card_widget.dart:108)). **Falta:** "volume da semana" (agregação) e a promoção desses números para o card principal. |
| **F20** | Esportes — resumo semanal [CE5] | **PARCIAL** | `GetClubXpBetween` dá o XP do período e `GetClubActivitiesBetween` dá as sessões (ambos usados em `club_workout_screen.dart:1755–1766`). **Falta:** tempo ativo agregado, recorde pessoal, e a superfície em `esportes_screen`. |
| **F21** | Operação da semana no hub [C5] | **NÃO EXISTE** | O hub tem só a linha de squad ([bldr_club_screen.dart:401](lib/features/club/presentation/bldr_club/bldr_club_screen.dart:401)). Nenhum conceito de "objetivo semanal com recompensa em XP" no `domain/` do Club. |

**Itens [F] do SPEC sem entrada no backlog:**

- **T5** (área de capa preparada para foto real do treino) — **NÃO EXISTE** campo de imagem em `WorkoutTemplate` ([workout_template.dart](lib/features/workouts/domain/entities/workout_template.dart)). Existe, porém, `workout_photo_service.dart` + edge function `analyze-workout-photo` (Claude Haiku 4.5), que **lê** foto de ficha para criar treino — é outra coisa.
- **N16** (foto do prato com identificação automática) — **NÃO ENCONTRADO.** Nenhuma edge function de análise de foto de comida; `analyze-workout-photo` é de ficha de treino.
- **PG5** e **PT3** → ver B2 e B1.

---

## 2b. HAVOK — verificação do relatório de estado atual

### 2b.1 Seção 9 — Bloqueadores

| # | Item | Ainda é verdade? | Evidência |
|---|---|---|---|
| 1 | Paywall real | **SIM, verbatim** | [panther_fab.dart:17](lib/features/club/presentation/bldr_club/havok/widgets/panther_fab.dart:17): `final bool isPremiumUser = true;` com o comentário *"Substitua esta variável pela sua lógica real"*. O branch `else` (`:27`) é um `print("Navegando para a tela de Upsell Premium...")` com o `Navigator.push` comentado. |
| 2 | Rate limit por plano | **SIM** | Nenhuma checagem de cota em `gerar-treino-havok/index.ts`, `gerar-treino-livre/index.ts` ou `gerar-receita-havok/index.ts`. Nenhuma tabela de contagem. `HavokRepositoryImpl` só faz `functions.invoke`. |
| 3 | Superfície de erro | **SIM — e são 6 telas, não 4** | `Result`/`Failure` chegam à tela e são descartados: [free_workout_screen.dart:46–48](lib/features/club/presentation/bldr_club/havok/free_workout_screen.dart:46) (`print`), [workout_library_screen.dart:66–73](lib/features/club/presentation/bldr_club/havok/workout_library_screen.dart:66) (`print`), [havok_hub.dart:223](lib/features/club/presentation/bldr_club/havok/havok_hub.dart:223) (`} catch (e) { print(e); }`), [havok_hub.dart:49](lib/features/club/presentation/bldr_club/havok/havok_hub.dart:49) (`catch (_)`), [havok_hub.dart:134](lib/features/club/presentation/bldr_club/havok/havok_hub.dart:134), [recipe_library_screen.dart:66](lib/features/club/presentation/bldr_club/havok/recipe_library_screen.dart:66), [recipe_results_screen.dart:38](lib/features/club/presentation/bldr_club/havok/recipe_results_screen.dart:38). O `_guard` do repository ([havok_repository_impl.dart:16–33](lib/features/club/data/repositories/havok_repository_impl.dart:16)) produz `Failure.message` em pt-BR corretamente — a mensagem existe e é jogada fora. |
| 4 | Migrações versionadas | **SIM** | `supabase/migrations/` tem **6 arquivos**; `grep -rl "havok_workouts\|havok_recipes"` retorna **nenhum**. As tabelas do schema `bldr_club` referenciadas em [havok_repository_impl.dart:69, 80](lib/features/club/data/repositories/havok_repository_impl.dart:69) não têm migration. O mesmo vale para `bldr_club.user_activities`, `bldr_club.xp_events` e `bldr_club.xp_reactions`. |
| 5 | Testes | **SIM** | `test/features/` tem 5 arquivos (auth, nutrition, workouts, progress, club) — **nenhum menciona HAVOK**. `grep -ri havok test/` → vazio. |

### 2b.2 Seção 10 — Dívidas técnicas

| Item do HAVOK_SPEC | Ainda é verdade? | Evidência |
|---|---|---|
| `havok_hub.dart:42` usa `UserService.instance` na presentation | **SIM**, linha **42** exata | [havok_hub.dart:42](lib/features/club/presentation/bldr_club/havok/havok_hub.dart:42): `final profile = await UserService.instance.getCurrentUserProfile();` (import em `:12`). Viola a regra 1 do `CLAUDE.md`. |
| `GenerateHavokWorkout` retorna `Result<void>` e descarta o treino | **SIM** | [havok_repository.dart:12](lib/features/club/domain/repositories/havok_repository.dart:12): `Future<Result<void>> generateHavokWorkout();` — comentário no próprio contrato: *"salvo pela edge function"*. Impl em [havok_repository_impl.dart:57–58](lib/features/club/data/repositories/havok_repository_impl.dart:57) descarta o `Map` retornado por `_invoke`. `workout_library_screen.dart:58` refaz o SELECT via `myWorkouts()`. |
| Parsing frágil; `repeticoes` castado para `String` | **SIM** | [workout_detail_screen.dart:32](lib/features/club/presentation/bldr_club/havok/workout_detail_screen.dart:32): `final String reps = exercise['repeticoes'] ?? '0';` — se o Gemini devolver `12` (número), lança `type 'int' is not a subtype of type 'String'`. `SavedWorkout.fromMap` em [workout_library_screen.dart:22](lib/features/club/presentation/bldr_club/havok/workout_library_screen.dart:22) e `SavedRecipe.fromMap` em [recipe_library_screen.dart:24](lib/features/club/presentation/bldr_club/havok/recipe_library_screen.dart:24) idem. |
| JSON sem contrato forte (falta `responseMimeType` + schema) | **SIM** | `grep -n "responseMimeType\|responseSchema"` nas três functions Gemini → **zero**. A URL montada é `…:generateContent?key=` sem `generationConfig` estruturado ([gerar-treino-havok/index.ts:139](supabase/functions/gerar-treino-havok/index.ts), [gerar-treino-livre/index.ts:66](supabase/functions/gerar-treino-livre/index.ts), [gerar-receita-havok/index.ts:92](supabase/functions/gerar-receita-havok/index.ts)). |
| `gerar-treino-havok` e `gerar-treino-livre` ~90% iguais | **PARCIALMENTE** — hoje divergiram | 197 vs. 107 linhas. O `diff` mostra que a diferença é um bloco de ~88 linhas (`generateHavokPrompt`, colado de um `havok_prompt.js`) presente só no primeiro; o resto (CORS, chamada Gemini, parse) é idêntico. A duplicação real é do **arcabouço**, não do prompt. |
| `gerar-plano-performance` está em `UserService` | **SIM** | [user_service.dart:235](lib/services/user_service.dart:235) — única invocação da function; não passa pelo `HavokRepository`. |
| Cores `goldColor` etc. dentro de `havok_hub.dart` | **SIM** — ver 2b.4 | |

### 2b.3 Cadeia de execução (§8.1) — o que falta

**Estado atual:** um treino gerado pelo HAVOK é uma linha em
`bldr_club.havok_workouts` com payload JSON. `workout_library_screen` lista, e
`workout_detail_screen` **renderiza uma `ListView` de exercícios e acaba ali** —
verifiquei o arquivo inteiro (73 linhas): não há `ElevatedButton`, `onTap`, nem
`Navigator.push` fora do `AppBar`. É literalmente uma lista sem saída, como o
diagnóstico afirma.

**O que falta, concretamente, para virar template executável:**

1. **Um conversor** `payload HAVOK (Map)` → `WorkoutTemplate` + `List<TemplateExercise>`.
   Não existe nenhum mapper nesse sentido em `lib/features/club/` nem em
   `lib/features/workouts/`. É a única peça realmente nova.
2. **Persistência do template.** Não é nova.
3. **Entrada no plano.** Não é nova.
4. **Início da sessão.** Não é nova.

**O que já existe em `features/workouts/` e é reaproveitável direto**
([workout_usecases.dart](lib/features/workouts/domain/usecases/workout_usecases.dart)):

| Etapa | Classe pronta | Linha |
|---|---|---|
| Criar template | `CreateWorkoutTemplate` → `Result<WorkoutTemplate>` | `:36–41` |
| Ler com exercícios | `GetTemplateWithExercises` | `:28–33` |
| Iniciar sessão | `StartWorkout` → `Result<WorkoutSession>` | `:61–70` |
| Registrar série | `LogWorkoutSet` / `CompleteWorkoutSet` / `UndoWorkoutSet` | `:83–107` |
| Finalizar | `CompleteWorkout` | `:72–81` |
| Sessão ativa | `HasActiveWorkout` / `GetActiveWorkoutDetails` / `WatchActiveWorkout` | `:109–128` |
| Config do plano semanal | `GetWeeklyPlanConfig` / `SaveWeeklyPlanConfig` | `:178–195` |
| Semana concluída | `GetWeekCompletedWorkouts` | `:197–204` |

Entidades já tipadas: `WorkoutTemplate`, `TemplateExercise`, `WorkoutSession`,
`WorkoutSet`, `WeeklyPlanConfig` (`features/workouts/domain/entities/`).
Telas de execução prontas: `active_workout_screen.dart` (1548 l., recebe
`workoutId` + `workoutName` por rota, [app_routes.dart](lib/routes/app_routes.dart)).

**Resumo:** dos 4 elos da cadeia, **3 estão construídos e testados**
(`test/features/workouts/workout_models_test.dart`). O bloqueio é o elo 1 — o
mapeamento do JSON do Gemini para as entidades — que hoje nem tem contrato forte
do lado do modelo (ver dívida do `responseMimeType`).

**Ponto adicional:** a §7.1 (onboarding gerar plano de verdade) confirma-se como
promessa vazia — [onboarding_flow.dart:1269](lib/shared/presentation/onboarding_flow/onboarding_flow.dart:1269)
(*"Configurando seu treino com a IA HAVOK."*) e `:790` (*"Treino gerado pelo
HAVOK"*) são textos de tela de pergunta; não há chamada a
`GenerateHavokWorkout` em nenhum ponto do arquivo.

**§7.3 Match tracker:** confirmado exatamente como descrito. O texto *"Gerar
ficha de treino com Havok"* está em
[match_tracker_screen.dart:836](lib/features/club/presentation/bldr_club/trackers/match_tracker_screen.dart:836)
e o handler é
[match_tracker_screen.dart:202–206](lib/features/club/presentation/bldr_club/trackers/match_tracker_screen.dart:202):

```dart
onOpenProtocol: () {
  // Pop the bottom sheet, then pop the tracker → lands on EsportesScreen
  Navigator.of(context).pop();
  Navigator.of(context).pop();
},
```

**§7.3 Arena:** *"DIRETRIZES DO HAVOK"* em
[arena_details_screen.dart:162](lib/features/club/presentation/bldr_club/arena_details_screen.dart:162)
é texto estático montado por modo de jogo (`:144`), sem chamada de IA. Confirmado.

### 2b.4 As cores do `havok_hub.dart`

**Onde vivem hoje** — [havok_hub.dart:14–17](lib/features/club/presentation/bldr_club/havok/havok_hub.dart:14),
como constantes **top-level públicas** de um arquivo de tela:

```dart
// --- CORES ---
const Color goldColor = Color(0xFFD4AF37);
const Color darkBackgroundColor = Color(0xFF121212);
const Color cardBackgroundColor = Color(0xFF1E1E1E);
```

**Quantos arquivos importam de lá: 6.**

| Arquivo | Comentário no import |
|---|---|
| [free_workout_screen.dart](lib/features/club/presentation/bldr_club/havok/free_workout_screen.dart) | — |
| [workout_detail_screen.dart:2](lib/features/club/presentation/bldr_club/havok/workout_detail_screen.dart:2) | *"Importa para usar as cores consistentes"* |
| [recipe_library_screen.dart](lib/features/club/presentation/bldr_club/havok/recipe_library_screen.dart) | — |
| [recipe_results_screen.dart](lib/features/club/presentation/bldr_club/havok/recipe_results_screen.dart) | — |
| [workout_library_screen.dart](lib/features/club/presentation/bldr_club/havok/workout_library_screen.dart) | — |
| [panther_fab.dart:2](lib/features/club/presentation/bldr_club/havok/widgets/panther_fab.dart:2) | *"Importa a tela do Hub que criamos"* |

Os 6 estão dentro de `havok/` — o acoplamento invertido é real, mas está contido
na pasta. `panther_fab.dart` é o que sangra para fora: é importado por
[bldr_club_screen.dart:10](lib/features/club/presentation/bldr_club/bldr_club_screen.dart:10),
arrastando `havok_hub.dart` (e o `model_viewer_plus`) para o hub do Club.

Os três valores são **idênticos** a constantes já existentes em `AppTheme`:
`goldColor` == `AppTheme.accentGold` (`app_theme.dart:11`),
`darkBackgroundColor` == `AppTheme.surfaceDark` (`:12`),
`cardBackgroundColor` == `AppTheme.cardDark` (`:24`).

---

## 3. Estado visual atual

### 3.1 Cores — as três convivem

**a) `AppTheme`** ([app_theme.dart:9–29](lib/theme/app_theme.dart:9)) — 17
constantes estáticas, paleta *"Luxury Athletic"*. Importado direto por 28
arquivos e indiretamente por 77 (via `core/app_export.dart:5`). Contém
explicitamente as cores que o `DESIGN_SYSTEM.md` §2 manda eliminar:

```dart
static const Color successGreen = Color(0xFF4CAF50);
static const Color warningAmber = Color(0xFFFF9800);
static const Color errorRed     = Color(0xFFF44336);
```

`successGreen` inclusive ocupa o slot `tertiary` do `ColorScheme`
(`app_theme.dart:44–47`), então vaza para componentes Material que ninguém
estilizou à mão.

**b) Constantes espalhadas por arquivo.** Cada tela grande define a sua própria
paleta privada no topo do `State`. Exemplo em
[club_workout_screen.dart:1677–1682](lib/features/club/presentation/bldr_club/club_workout_screen.dart:1677):

```dart
static const _gold       = Color(0xFFD4AF37);
static const _goldBg     = Color(0x1FD4AF37);
static const _borderGold = Color(0x40D4AF37);
static const _card       = Color(0xFF1E1C18);
static const _muted      = Color(0xFF888070);
static const _red        = Color(0xFFC84040);
```

Note `_card = 0xFF1E1C18` — **não** é `AppTheme.cardDark` (`0xFF1E1E1E`) nem
`cardBackgroundColor` do HAVOK. São três "cinza de card" ligeiramente diferentes.

**c) Hex inline no meio do `build()`.** **704 ocorrências de `Color(0x…)` em
`lib/`.** Concentração:

| Arquivo | Ocorrências |
|---|---|
| `club_workout_screen.dart` | 66 |
| `comunidade_screen.dart` | 49 |
| `daily_nutrition_overview_widget.dart` | 35 |
| `meal_timeline_widget.dart` | 32 |
| `esportes_screen.dart` | 31 |
| `app_theme.dart` | 23 |
| `water_intake_widget.dart` | 22 |
| `workouts_screen.dart` | 21 |
| `weekly_plan_screen.dart` / `level_up_modal.dart` | 20 cada |

**Ou seja: 97% dos hex do app estão fora do `AppTheme`.** G1–G4 não são
alcançáveis mudando um arquivo.

### 3.2 Tipografia

**Pacote:** `google_fonts: ^6.1.0` ([pubspec.yaml:48](pubspec.yaml)). **Não há
seção `fonts:` no `pubspec.yaml`** — nada é empacotado localmente; tudo é baixado
em runtime.

**Três famílias, todas em [app_theme.dart](lib/theme/app_theme.dart):**

| Família | Onde | Papel |
|---|---|---|
| `GoogleFonts.inter` | 24 chamadas (`:68` a `:493`) | Componentes: AppBar, BottomNav, botões, inputs, tabs, tooltips, snackbars |
| `GoogleFonts.montserrat` | 15 chamadas (`:516` a `:609`) | Todo o `TextTheme` (display/headline/title/body/label) |
| `GoogleFonts.jetBrainsMono` | a partir de `:619` | Tema de dados/monoespaçado |

**Conflito com o design system:** o `DESIGN_SYSTEM.md` §3 fixa peso máximo 600.
O `app_theme.dart` usa `FontWeight.w700` no `TextTheme` e as telas usam `w700`
e até `w900` — ex.: [match_tracker_screen.dart:231](lib/features/club/presentation/bldr_club/trackers/match_tracker_screen.dart:231)
(`fontWeight: FontWeight.w900`), `achievements_gallery_widget.dart:141, 162`
(`w700`).

### 3.3 Ícones

**Três sistemas simultâneos:**

1. **`CustomIconWidget`** ([custom_icon_widget.dart](lib/widgets/custom_icon_widget.dart),
   **2189 linhas**) — um `Map<String, IconData>` gigante construído **dentro do
   `build()`** (`:15`), mapeando ~2.100 nomes para `Icons.*`. Exportado por
   `app_export.dart:3` → disponível em 77 arquivos. É o padrão nas telas antigas
   (Dashboard, Progresso, Nutrição, Perfil).
2. **`Icons.*` direto** — o padrão nas telas do Club. Em `club_workout_screen.dart`
   há ~40 usos diretos.
3. **`font_awesome_flutter: ^10.7.0`** ([pubspec.yaml:88](pubspec.yaml)) e
   `cupertino_icons: ^1.0.2` (`:39`) declarados.

Reconstruir um mapa de 2.100 entradas a cada `build()` é, além de tudo, um custo
de frame desnecessário em telas que rolam.

### 3.4 Componentes reutilizados — **praticamente não existem**

**Não há `bldr_components.dart`. Não há um único widget genérico de card, botão
ou chip.** Cada tela monta o seu, em métodos privados `_build…`:

| Padrão | Implementações independentes encontradas |
|---|---|
| Chip / pill de stat | `_StatPill` (`club_workout_screen.dart:2433`), `_infoChip` (`:732`), `_summaryChip` (`weekly_plan_screen.dart:339`), `_buildMetricSelector` (`measurements_chart_widget.dart:258`, `nutrition_analytics_widget.dart:222`) |
| Card de treino | `WorkoutCardWidget`, `_PersonalWorkoutTile` (`:2774`), `_LibraryTile` (`:2476`), `ClubWorkoutCardWidget` (morto), `_CardioCard` (`:2711`) |
| Card de programa | `_ProgramCard` (`:2574`), `_ProgramCardFallback` (`:2670`), `program_card.dart` (morto), `club_program_card_widget.dart` (morto) |
| Fundo com glow dourado | `_GoldRadialBackground` + `_RadialBlob` — **copiado em 4 arquivos**: `bldr_club_screen.dart:570/586`, `club_workout_screen.dart:2953/2972`, `esportes_screen.dart:1027/1045`, `plano_performance_detail_screen.dart:338/353`. `comunidade_screen.dart:2792/2809` tem a mesma coisa com outro nome (`_GoldRadialBg`/`_Blob`). |
| Círculo tracejado (dia de descanso) | `_DashedCirclePainter` — **3 cópias**: `weekly_plan_screen.dart:1327`, `club_workout_screen.dart:3015`, `current_week_card_widget.dart:459` |
| Botão primário | Nenhum. `ElevatedButton` com `styleFrom` inline em cada uso. |

Os únicos reutilizados de verdade: `CustomIconWidget`, `ContinueWorkoutCard`,
`AchievementBadge`, `MuscleVisualizerWidget`, `CustomErrorWidget` — 5 widgets num
app de 87 mil linhas.

**Ironia útil para o redesign:** `_GoldRadialBackground` já é, na prática, o G1 do
SPEC — implementado 5 vezes.

### 3.5 Layout

`sizer: ^3.1.3` ([pubspec.yaml:42](pubspec.yaml)) é o sistema de medida
dominante: `4.w`, `2.h`, `5.w` aparecem em praticamente todo widget de
Dashboard/Progresso/Nutrição/Perfil. As telas do Club usam **pixels fixos**
(`const SizedBox(height: 20)`). São dois sistemas de espaçamento incompatíveis
convivendo — qualquer token de spacing do design system terá de escolher um.

---

## 4. Riscos de um redesign puramente visual

### R1 — `legacy_ui_maps.dart`: a UI é tipada por convenção de string

Três mappers transitórios convertem entidade → `Map<String, dynamic>` porque os
widgets ainda leem por chave:

- [nutrition/presentation/mappers/legacy_ui_maps.dart](lib/features/nutrition/presentation/mappers/legacy_ui_maps.dart) — 5 importadores
- [workouts/presentation/mappers/legacy_ui_maps.dart](lib/features/workouts/presentation/mappers/legacy_ui_maps.dart) — **8 importadores**
- [club/presentation/mappers/legacy_ui_maps.dart](lib/features/club/presentation/mappers/legacy_ui_maps.dart) — 2
- [achievements/presentation/mappers/legacy_ui_maps.dart](lib/features/achievements/presentation/mappers/legacy_ui_maps.dart)

**Risco:** o compilador não protege nada aqui. Renomear `'estimated_duration_minutes'`
ao reorganizar um card, ou trocar um `workout['name']` por `workout['title']` num
`_build…`, compila e falha em runtime — provavelmente com um `null` silencioso
(a maioria dos acessos tem `?? 30`, `?? 0`, `?? ''`). Um "0 min" ou um card vazio
em produção não gera stack trace.

O mapper de nutrição tem um agravante: `legacyMapToFoodItem`
([legacy_ui_maps.dart:28–47](lib/features/nutrition/presentation/mappers/legacy_ui_maps.dart:28))
aceita **duas grafias** para o mesmo campo (`'sodium_per_100g'` **ou** `'sodium'`,
idem `fiber` e `added_sugar`). São exatamente os três insumos do IQD
(`iqd_calculator_service.dart:9–13`). Mexer no formulário manual (N17–N21) sem
saber disso pode zerar silenciosamente o IQD.

### R2 — `ArenaRepository`: telas consomem linhas cruas sem use case

O contrato declara isso explicitamente
([arena_repository.dart:5–12](lib/features/club/domain/repositories/arena_repository.dart:5)):

> *"os métodos trafegam linhas cruas (`Map<String, dynamic>`) em vez de entidades…
> As telas desta cauda consomem o contrato diretamente via getIt (sem camada de
> use cases)"*

São **12 importadores**. Chaves são compostas em runtime — `participantsCombined`
promete "chaves extras: `name`, `avatar`"; `tribunalFeed` promete
"`tribunal_votes` embutidos e `user_profiles` anexado por post".

**Risco:** as telas afetadas são Competição (CQ1–CQ5), Arena (fora do escopo mas
alcançada por G1–G10), Tribunal, Squad settings. **CQ3 e F9 mexem exatamente
nessa superfície.** Nada nesse caminho é coberto por teste.

### R3 — `weekly_plan_screen.dart` é uma tela para dois destinos

Já em §1.3, mas repito porque é o risco mais concreto: P1–P5 (Meu Plano) e
CP1–CP5 (Club → Meu Plano) descrevem o **mesmo arquivo de 1353 linhas**, e as
duas listas **não são idênticas** (CP2–CP5 pedem ícone de atividade, XP por dia,
extras e botão de registro; P1–P5 não). Implementar CP* muda também a tela de
Treinos, e vice-versa.

### R4 — `bldr_club_screen.dart` mantém canal Realtime do Supabase

Registrado no `ESTRUTURA.md:131`. Confirmado: `AchievementProvider` também mantém
um ([achievement_provider.dart:33–47](lib/features/achievements/presentation/achievements/achievement_provider.dart:33),
canal `user_achievements:$userId`). **Risco:** reestruturar a árvore de widgets
do hub (C1–C4) sem cuidado com `initState`/`dispose` pode duplicar ou vazar
subscription. G5 (tab bar flutuante sobre conteúdo rolável) mexe justamente na
hierarquia de `Scaffold`/`Stack` dessas telas.

### R5 — Arquivos gigantes sem separação entre estado e apresentação

`club_workout_screen.dart` tem 3041 linhas com 17 classes e a lógica de montagem
da semana (`_load()`, `:1728–1930`) misturada ao layout.
`comunidade_screen.dart` tem 2834. `profile_screen.dart`, 1703. **Nenhuma tela do
app tem controller** — não existe `presentation/controllers/` em feature alguma,
apesar do `ARCHITECTURE.md:47` prevê-lo.

**Risco:** não há como tocar só o layout. Qualquer item [V] nessas telas edita o
mesmo `State` que contém a regra de negócio. E as regras estão lá: a inferência
de tipo de atividade (§F1), a contagem de treinos da semana, o clamp
`_gymWorkoutsCount.clamp(0, effectiveFreq)` (`:1891`).

### R6 — ~7.500 linhas de UI morta que parecem vivas

Os 24 arquivos listados em §1.4 compilam, aparecem na busca e têm nomes
plausíveis. Dois casos são armadilhas específicas:

- `active_workout_banner_widget.dart` (1339 l.) e `active_workout_banner_club.dart`
  (1392 l.) — **são a versão mais completa do banner de treino ativo**, com
  `checkAchievements` e `CompleteWorkout`, e não são renderizados. Redesenhar
  "o banner de treino ativo" tem chance real de acertar o arquivo errado; o vivo
  é o `_buildActiveWorkoutBanner()` privado dentro de `workouts_screen.dart:667`.
- `profile_drawer.dart` (1409 l.) — importa os 4 widgets do Perfil. Mexer neles
  "para os dois lugares" é trabalho jogado fora.

### R7 — `AppTheme` carrega as cores que o design system proíbe

`successGreen`, `warningAmber` e `errorRed` estão nos `ColorScheme` claro e
escuro (`app_theme.dart:44–48, 292…`). G4 ("eliminar verde, azul, laranja, roxo,
ciano e rosa") toca a base do tema — e componentes Material não estilizados
(`SnackBar` de erro, `TextField` inválido, `Switch` ativo) puxam dali. **Trocar
`errorRed` afeta também o `--danger` legítimo de S2 ("Excluir conta").**

### R8 — Testes: o inverso do risco esperado

**Não existe nenhum teste de widget que dependa de estrutura visual.** Auditei
`test/` inteiro:

| Arquivo | Linhas | Tipo |
|---|---|---|
| `test/features/auth/auth_usecases_test.dart` | 239 | unidade, repository fake |
| `test/features/nutrition/nutrition_usecases_test.dart` | 259 | unidade |
| `test/features/club/club_usecases_test.dart` | 190 | unidade |
| `test/features/workouts/workout_models_test.dart` | 119 | unidade (mapeamento) |
| `test/features/progress/progress_test.dart` | 102 | unidade |
| **`test/widget_test.dart`** | 30 | **contra-teste** |

`test/widget_test.dart` é o **template padrão do `flutter create`, nunca
adaptado**: monta `MyApp()` e procura um contador com `find.text('0')` e
`find.byIcon(Icons.add)`. Não corresponde a nada neste app. Ele **não é rodado**
pelo comando de validação do `CLAUDE.md` (`flutter test test/features`) — o que
significa que hoje está quebrado ou passando por acidente, sem ninguém saber.

**A leitura correta do risco se inverte:** o redesign não vai quebrar teste
nenhum — porque **nenhuma tela tem cobertura**. As 87 mil linhas de UI, incluindo
toda a lógica de montagem de semana, cálculo de progresso e inferência de tipo de
atividade que vive dentro dos `State`, são verificadas apenas por inspeção
manual. Os 939 pontos de teste cobrem use cases e mappers, ou seja, exatamente a
camada que um item [V] não deveria tocar.

### R9 — Ciclos e acoplamentos que dificultam extrair componentes

- `plano_performance_detail_screen.dart:3` importa `esportes_screen.dart`, que
  importa `plano_performance_detail_screen.dart:9`. **Ciclo.**
- `bldr_club_screen.dart:10` → `panther_fab.dart:2` → `havok_hub.dart` (que puxa
  `model_viewer_plus` e `UserService`).
- `comunidade_screen.dart:10` importa `ranking_screen.dart` só para reaproveitar
  `RankingEntry` e `DuelModal` (`show RankingEntry, DuelModal`) — tipo de domínio
  morando em arquivo de tela.
- `workouts_screen.dart:17` importa `club_active_workout_screen.dart` — a tela de
  treinos grátis depende da do Club.

### R10 — Dois sistemas de medida

`sizer` (`4.w`, `2.h`) nas telas antigas vs. pixels fixos nas do Club (§3.5).
Um token de spacing único terá de escolher um dos dois, e a conversão não é
mecânica: `sizer` é proporcional à tela, pixel não. **Telas com layout apertado
podem quebrar em aparelhos pequenos ou grandes conforme a direção da conversão.**

---

## Apêndice — números do retrato

| Métrica | Valor |
|---|---|
| Linhas de Dart em `lib/` | 87.094 |
| Arquivos `.dart` em `lib/` | 236 |
| Arquivos de UI sem nenhum importador (código morto) | 24 (~7.500 l.) |
| Ocorrências de `Color(0x…)` | 704 |
| Ocorrências fora do `AppTheme` | 681 (97%) |
| Telas com controller | 0 |
| Widgets genuinamente reutilizados entre telas | 5 |
| Cópias do fundo com glow dourado | 5 |
| Cópias do `_DashedCirclePainter` | 3 |
| Testes de unidade | 5 arquivos, 909 linhas |
| Testes de widget úteis | 0 (`widget_test.dart` é o template do `flutter create`) |
| Migrations versionadas | 6 (nenhuma cobre o schema `bldr_club`) |
| Telas no REDESIGN_SPEC | 17 (16 existem, 1 a criar) |
| Telas no código fora do SPEC | ~45 |
