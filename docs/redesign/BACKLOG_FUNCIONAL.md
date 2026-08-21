# BLDR — Backlog Funcional

Última auditoria: 2026-08-09 (Code verificou código real). Atualizado 2026-08-09 (Watch App UI + compilação).
Itens marcados ✅ foram confirmados no código, não apenas declarados.

---

## Prioridade 1 — Bugs ativos

### B1. Duração média calculando 0 [PT3]

**✅ Corrigido (2026-08-05).**
`progress_service.dart`: query agora filtra `.gt('total_duration_seconds', 0)` (era apenas `not null`).
Denominador mudou de `completedWorkouts` para `workoutsWithDuration` (count dos retornos da query).
Retorna `null` em vez de `0` quando nenhum treino qualifica.
5 testes unitários adicionados em `test/features/progress/progress_test.dart` (grupo B1).

### B2. Conquistas inconsistentes [PG5]

**✅ Corrigido (2026-08-05).**

1. `active_workout_screen._finishWorkout()` agora dispara `CheckAndUnlockAchievements('workout')` via `unawaited`.
2. `club_active_workout_screen._finishWorkout()` dispara `CheckAndUnlockAchievements('bldr_club')` via `unawaited`.
3. `firebase_add_food_modal_widget` dispara `CheckAndUnlockAchievements('nutrition')` após `LogMeal` bem-sucedido.
4. Backfill incremental: removida a chave `bldr_ach_backfill_v2` — roda a cada início de sessão, mas `checkAndUnlock` já filtra conquistas já obtidas.
5. `_isChecking` já tinha `try/finally` — não trava.
6. Realtime já estava habilitado em `user_achievements` — confirmado via Dashboard (erro 42710). Migration `20260805000002` é no-op idempotente, não precisa ser aplicada.
7. Race condition corrigida: `_subscribeRealtime()` agora awaited com `Completer` + timeout de 5s.
8. Status do canal logado: `[ACH-REALTIME] status: ...` visível no console.
9. Toast redesenhado: glass card com barra de progresso, XP badge, suporte a épicas e dots para fila. Textos com `TextDecoration.none` explícito para evitar herança de sublinhado do DefaultTextStyle.
10. `_isRelevantForTrigger('nutrition')` expandido para incluir `calorie_goal_reached`, `calorie_goal_reached_consecutive_days`, `macro_goal_reached`.
11. `_fetchNutritionContext` reescrito para ler do **Firestore** (`user_meals` collection) — a versão anterior consultava o Supabase, que está vazio para nutrição. Cada doc tem `date`, `calories`, `protein`, `carbs`, `fat` inline. Metas lidas de `user_profiles.onboarding_data` no Supabase.
12. `_fetchWorkoutContext` agora popula `max_bench_press` via lookup em `exercise_templates` + `workout_exercise_sets`.
13. `_fetchBldrClubContext` agora calcula `bldr_streak_days` real (era hardcoded 0); `club_user_workouts` inclui `completed_at`.
14. `_evaluateCondition` ganhou 3 novos casos: `calorie_goal_reached`, `calorie_goal_reached_consecutive_days`, `macro_goal_reached`.
15. Helper `_computeStreak()` extraído para reutilização entre workout e club streak.

### B3. Treino com 0min salvo [histórico]

**✅ Corrigido (2026-08-05).**
Guard de 60s adicionado em `workout_service.dart:completeWorkout()` e
`club_workouts_service.dart:completeClubWorkout()`. Ambos já calculavam
duration via `now.difference(startedAt).inSeconds` (DB-side, nunca 0 por
falha de timer). Guard: se `rawDuration < 60`, salva 60s.
Nota: o "0min" visível em histórico vem de B1 (denominador errado em
`progress_service.dart`) — não de falha de cálculo aqui.

### B4. ✅ RESOLVIDO — Metas nutricionais divergentes

Dashboard e tela de Nutrição usam GetNutritionGoals da mesma fonte.
Confirmado no código.

### B5. ✅ RESOLVIDO — Treino HAVOK não podia ser executado

free_name em TemplateExercise, agrupamento corrigido.

### B6. ✅ RESOLVIDO — Artefato não persistia entre sessões

artifact.data salvo em havok_messages.

### B7. ✅ Corrigido (2026-08-05) — Streak divergente entre telas

`GetCurrentStreak` agora usado em todas as telas:

- `havok_sheet.dart` e `widget_data_service.dart` — já usavam
- `progress_overview_widget.dart` — algoritmo inline com limit:30 substituído por `getIt<GetCurrentStreak>()()`
- `profile_screen.dart` — cálculo inline com limit:1000 substituído por `getIt<GetCurrentStreak>()()`

Todas as telas e o widget iOS leem o mesmo valor de streak.

### B8. Plano semanal sem domínio real [pós L4]

**✅ Implementado e corrigido (2026-08-05).**
Tabela `weekly_plan_days` criada e já populada com dados reais do onboarding.
Use cases `SaveWeeklyPlan` / `GetWeeklyPlan` registrados no DI.
`onboarding_completion_screen.dart` persiste no Supabase após o onboarding.
`active_workout_card_widget.dart` e `widget_data_service.dart` leem de `GetWeeklyPlan()`.

**Bug corrigido:** `WeeklyPlanRepositoryImpl.getWeeklyPlan()` só criava `WorkoutTemplate`
quando `template_id != null`, descartando o nome mesmo quando `template_name` estava presente.
Todos os registros têm `template_id = NULL` (onboarding não vincula UUID de template).
Fix: criar `WorkoutTemplate` quando `template_name` não-vazio, mesmo sem `template_id`.
Efeito: widget iOS grande agora exibe o treino do dia corretamente.
Limitação: botão "Iniciar" no widget não aparece enquanto `template_id` for null — requer
que o onboarding salve o `template_id` real do treino gerado (decisão de produto pendente).

### B9. Carrossel de conquistas na tela de perfil

**✅ Implementado (2026-08-05).**
Grid hardcoded de 10 badges substituído por carrossel dinâmico com todas as 34 conquistas do catálogo.

- Catálogo e conquistas desbloqueadas carregados em paralelo no `_loadProfileData` via Supabase.
- `PageView` com 2 linhas × 5 colunas por página (10/página → 4 páginas para 34 badges).
- Altura calculada dinamicamente via `LayoutBuilder` (evita corte em qualquer tamanho de tela).
- Contador `X/34` no cabeçalho ao lado do título "Conquistas".
- Indicadores de página animados (pill dourado = atual, cinza = demais).
- Usa `AchievementBadge` com `icon_name` real do banco — elimina ícones hardcoded.

---

## Prioridade 2 — Habilitam o redesign

### F1. Ícone por tipo de atividade [CT1, CP2]

**✅ Implementado (2026-08-05).**
`ActivityType` enum em `lib/features/workouts/domain/entities/activity_type.dart`:
9 tipos (musculacao, corrida, hiit, yoga, pilates, natacao, ciclismo, esporte, outro).
`fromString()` mapeia valores legados do banco (`strength`→musculacao, `run`→corrida).
`PlanDay` ganhou campo `activityType: ActivityType?`.
Mapeamento:

- Treino pessoal: `ActivityType.fromString(workoutType)`
- Treino Club: `ActivityType.fromString(notes)` (dívida técnica abaixo)
- Descanso/extra: derivado da ExtraActivity

⚠️ **Dívida técnica:** `club_user_workouts` usa a coluna `notes` como
veículo de activityType (gravado em `club_workouts_service.dart:720`).
Criar coluna `activity_type TEXT` em `club_user_workouts` e migrar dados
quando conveniente — evitaria conflito se notes for usado para anotações reais.

### F2. XP e métrica por dia na timeline [CP3]

**✅ Implementado (2026-08-05).**

- XP do dia via `bldr_club.xp_events` com range `[dayStart, dayEnd)` para cada um dos 7 dias (7 queries em paralelo com `Future.wait`).
- Exibido como "XP do dia" (não por treino — sem source_id mapeado); honesto quanto à fonte agregada.
- Card de dia concluído: ícone ActivityType + métrica (`45 min` ou `5.2 km`) + `+XP XP` dourado (9px w600).
- Bloco de resumo semanal: XP total da semana substitui placeholder "Em breve".

### F3. Atividades extras na timeline [CP4, CP5]

**✅ Implementado (2026-08-05).**

- Migration: `supabase/migrations/20260805100000_add_extra_activities.sql` — tabela `extra_activities` com RLS user_id=auth.uid().
- Entidade `ExtraActivity`, repositório `ExtraActivityRepository`, impl `ExtraActivityRepositoryImpl`.
- Use cases: `LogExtraActivity`, `GetExtraActivities` — registrados em `injection.dart`.
- `LogExtraActivity` insere em `extra_activities` + `bldr_club.xp_events` (delta=50, reason='extra_activity').
- Botão "Registrar extra" ativado (era opacity:0.5, sem lógica): abre bottom sheet com chips de ActivityType, slider de duração (15–120 min, step 15) e campo de notas.
- Timeline: dia com atividade extra mostra card com ícone + badge "Extra" + "+50 XP" dourado.
- Dias de descanso, perdidos, hoje e futuros recebem `extraActivity` do carregamento paralelo.

### F4. Gráfico dos últimos 7 dias no Dashboard [D7]

**✅ Implementado (2026-08-05).**
`ConsistencyHeatmapWidget` atualizado: barras agora proporcionais à duração em
minutos por dia (era contagem de sessões). Nenhuma query nova — o loop existente
no `_load()` já itera sobre `total_duration_seconds`, adicionou-se `_dayDurationMinutes`
como mapa paralelo ao `_dayCount`. Melhorias visuais:

- Barra vazia: altura 4px + opacidade reduzida (surface)
- Barra com treino: altura proporcional à duração, goldBright
- Labels de dia embaixo (S/T/Q/Q/S/S/D), dia atual em dourado bold
- Formato do total no header: `XXm` ou `XhYY`

### F5. ✅ RESOLVIDO — Resumo de alimentos na refeição [N8]

meal_timeline_widget.dart implementa _mealSummary() com nomes + calorias.
Confirmado no código.

### F6. Feed com descrição real da atividade [CC4]

**✅ Implementado (2026-08-05).**
`_formatAction()` em `comunidade_screen.dart` expandido com mapeamento explícito
de `reason` para texto descritivo. Matches exatos por valor de reason:
`workout_completed`→"concluiu um treino de musculação", `club_workout_completed`→
"concluiu um treino no BLDR Club", `extra_activity`→"registrou uma atividade extra",
`achievement_unlocked`→"desbloqueou uma conquista", etc.
**Limitação:** `xp_events.reason` não carrega o nome do treino específico (sem
`source_id` no schema). Nome do treino requereria JOIN em `user_workouts` — decisão
de produto se vale o custo.

### F7. Reação com estado persistido [CC5]

**✅ Implementado (2026-08-05).**

- `myReactions(userId, eventIds)` adicionado ao datasource — lê `xp_reactions` filtrado pelo usuário atual → retorna `Set<String>` de event_ids.
- `removeReaction(userId, eventId)` adicionado ao datasource (delete por user_id + event_id).
- Use cases: `GetMyReactions`, `RemoveReactionFromXpEvent` — registrados no DI.
- `_fetchCommunityFeed()`: após carregar o feed, busca reações do usuário e inicializa `_reacted` com estado persistido (sobrescreve o volátil).
- `_sendMotivation()`: toggle completo — insere se não reagiu, remove se já reagiu; estado otimista com reversão em caso de falha de rede.

### F8. Checklist de exercício no protocolo [CX3, CX4]

**✅ Implementado (sessão anterior).**
`plano_performance_detail_screen.dart`: protocolo estruturado (`exercicios` list com `nome/series/reps/descanso/observacoes`).
Checkbox local por exercício (`_checked` map + `_checkKey`), progresso `_doneCount / total`, barra de progresso no header, footer com botão "Dia concluído" ativado só quando 100%. GestureDetector + AnimatedOpacity nos cards.

### F9. Ranking interno do squad [CQ3] + CQ1, CQ2, CQ4, CQ5

**✅ Implementado (2026-08-05).**
`_ParticipantTile` em `arena_details_screen.dart` refatorado:

- `maxScore` calculado do `active` list antes do `SliverList` (`.clamp(1.0, …)` evita divisão por zero)
- `LinearProgressIndicator` proporcional a `score / maxScore`, oculto no modo `survivor`
- Cor da barra por modo: cyanAccent (roadrunner), orangeAccent (hustle), dourado (outros)
- Destaque do usuário: borda verde + `#rank` em verde quando `isMe`
- Ordenação: já vinha de `participantsCombined(orderBy: 'current_score')` — mantido sem alteração

**CQ1–CQ5 — competition_hub_screen + create_arena_screen (2026-08-05):**
- CQ1: card "ALISTAR-SE AGORA" migrado para glass neutro com gold border (sem cyanAccent)
- CQ2: card "CRIAR OPERAÇÃO" mantém gold tint (já estava correto)
- CQ3: squad list usa ícone por modo (Icons.dangerous/emoji_events/directions_run/bolt) em vez de barra colorida
- CQ4: nova seção "MODOS DE JOGO" em competition_hub_screen — 4 linhas ícone + nome + desc, paleta neutra
- CQ5: modo padrão em create_arena_screen mudou para `'hustle'`; `_getModeColor()` removida; `_ModeCard` usa gold para estado selecionado — ícone distingue o modo (DESIGN_SYSTEM §11)

### F10. Próxima conquista com critério [PF6]

**✅ Implementado (2026-08-05).**
`_buildNextAchievement()` em `profile_screen.dart`: card abaixo do carrossel de badges.
Lógica: filtra conquistas não obtidas, calcula % de progresso com dados já na tela
(`_totalWorkouts` → workout_count/consecutive_days, `_currentStreak` → bldr_streak_days).
Exibe a conquista com maior % de progresso (mais próxima), com:

- Nome da conquista + critério em linguagem natural (pt-BR)
- Barra de progresso LinearProgressIndicator + "XX%" em dourado
- Critérios mapeados: workout_count, consecutive_days, bldr_streak_days, calorie_goal, meal_logged, total_xp, club_level, bldr_workout_total
**Limitação:** conquistas com critério não mapeável (ex: max_weight_bench_press, ranking_position) não aparecem como candidato — o contexto completo exigiria chamar achievement_service.

---

## Prioridade 3 — Telas e seções novas

### F11. Configurações — Metas [S5]

**✅ Implementado (2026-08-05).**
`lib/features/profile/presentation/goals_screen.dart` — tela completa.

- Seção PESO: peso atual (read-only de user_measurements), peso alvo editável, chips Leve/Moderado/Agressivo
- Seção NUTRIÇÃO: meta calórica calculada ou personalizada, macros (g) com % em tempo real, validação de soma
- Camada domain: `UserGoals` entity, `GetUserGoals`/`SaveUserGoals` use cases, `getFullGoals`/`saveFullGoals` no `NutritionGoalsRepository`
- Camada data: `SupabaseNutritionGoalsDatasource` estendido — lê `onboarding_data` + `target_weight_kg` + peso atual de `user_measurements`; salva mergendo no mesmo JSON + coluna `target_weight_kg`
- Rodapé: "Alterações afetam Dashboard, Nutrição e o contexto do HAVOK."
- Linha em settings_screen.dart ativada (sem disabled / badge)

### F12. Configurações — Integrações [S6]

**✅ Implementado (2026-08-05). Atualizado (2026-08-09).**
Seção "Integrações" separada em `settings_screen.dart` (antes estava misturada em "Aplicativo").

- Whoop conectado: linha "Whoop" com badge dourado "Conectado" + subtítulo "Recovery, Strain e Sleep sincronizados" + botão "Desconectar" inline
- Whoop desconectado: subtítulo "Conecte seu Whoop" → abre WhoopConnectScreen
- **Apple Health** (antes "Apple Saúde"): card agora ativo e dinâmico (iOS only):
  - Não autorizado → subtítulo "Conecte para sincronizar FC e calorias" + `onTap` abre diálogo de permissão do sistema via `HealthKitService.requestPermission()`
  - Autorizado → badge "Conectado" dourado + subtítulo "FC, calorias e treinos sincronizados"
  - Status verificado no `initState` via `HealthKitService.isAuthorized()` → `checkPermission` no método Swift
  - `HealthKitService.swift` ganhou `checkPermission()` que lê `authorizationStatus(for: caloriesType)`; `AppDelegate.swift` roteia o método channel
- Relógios e wearables: placeholder disabled + badge "Em breve" [F]

### F13. Configurações — Privacidade [S7]

**✅ Implementado (2026-08-05).** ⚠️ Bloqueador de loja resolvido.
`lib/features/profile/presentation/privacy_screen.dart` — tela completa.

- Identidade: toggle Nome real / Apelido (campo com máx. 20 chars); toggle foto pública / só squad
- Feed: toggle aparecer no feed; toggle permitir reações (oculto quando feed desligado)
- Ranking: toggle participar do ranking público
- Nota legal com link para política de privacidade (url_launcher)
- Camada domain: `PrivacySettings` entity, `GetPrivacySettings`/`SavePrivacySettings` use cases
- Camada data: `SupabasePrivacyDatasource` lê/grava em `user_profiles`; ao salvar display_name, propaga para `club_profiles.display_name` (try/catch — squad opcional)
- Feed agora usa `display_name ?? full_name` (`challenge_repository_impl` + datasource `profilesByIds` atualizado)
- **Migration necessária**: `supabase/migrations/20260805120000_add_privacy_columns.sql` — adiciona `display_name`, `photo_visibility`, `feed_visible`, `reactions_enabled`, `ranking_visible` em `user_profiles`
- Linha em settings_screen.dart ativada (sem disabled / badge)

### F14. Central de ajuda e Termos [S8]

**✅ Implementado (2026-08-05).** ⚠️ Bloqueador de loja resolvido.
Seção "Suporte" + seção "Sobre" em `settings_screen.dart`:

- Central de ajuda → `mailto:suporte@bldrapp.com.br` (fallback email; url_launcher)
- Termos de uso → `https://www.bldrapp.com.br/termos` (LaunchMode.externalApplication)
- Política de privacidade → `https://www.bldrapp.com.br/privacidade` (LaunchMode.externalApplication)
- Versão → lida dinamicamente via PackageInfo (`_appVersion`, já existia na tela)
- BLDR → linha estática com copyright
- URL corrigida em `privacy_screen.dart`: `bldrapp.com` → `www.bldrapp.com.br` (alinhado com sign_up_form e checkout_screen)

### F15. Progresso → Corpo completo [PC4–PC7]

**✅ Implementado (2026-08-05).**
- PC4: `lineTouchData` com tooltip (data + valor + unidade) em `measurements_chart_widget.dart`.
- PC6: `_showPhotoComparison()` refatorado — novo `_PhotoComparisonDialog` com seleção livre de foto em cada lado (bottom sheet com miniaturas e datas).
- PC7: `_buildRecentMeasurements()` reescrito com `Dismissible` (swipe-to-delete via `DeleteMeasurement` use case) e delta vs medição anterior (↑/↓ + valor).
- Domain: `deleteMeasurement(String id)` adicionado ao `ProgressRepository`, `ProgressRepositoryImpl`, `DeleteMeasurement` use case, registrado no DI, e implementado no `FakeProgressRepository` de teste.

### F16. Progresso → Nutrição completo [PN3–PN7]

**✅ Implementado (2026-08-05).**
- PN3: já estava pronto (gráfico de calorias com linha de meta tracejada).
- PN4: `_buildMacroBar()` agora exibe `Xg · Y% da meta` usando metas reais de proteína/carbs/gordura carregadas de `GetNutritionGoals`; `BldrProgressBar` normalizado por meta.
- PN5: já estava pronto (evolução do IQD em `LineChart`).
- PN6: `_buildRecentMeals()` reescrito — busca 7 dias em paralelo (`Future.wait`), mostra section headers com data + total kcal do dia, cada dia agrupa por tipo de refeição via `ExpansionTile` expansível, cada alimento lista nome e calorias.

### F17. IQD em tempo real no formulário manual [N22]

**✅ Implementado (2026-08-05).**
`firebase_add_food_modal_widget.dart`: `_loadCurrentDayIqd()` carrega totais de hoje via `GetDailySummary` no `initState`. `_updateHypotheticalIqd()` agora calcula IQD projetado somando totais do dia + campos do formulário. `_buildIqdImpactPreview()` exibe "atual X → projetado Y" com seta direcional (gold) quando carregado, ou fallback para score isolado enquanto carrega.

### F18. Histórico de sets e partidas no Match Tracker [CM4, CM5]

**✅ Implementado (2026-08-07).**
- Entidade `MatchSession` adicionada a `club_community.dart`.
- Datasource: `insertMatchSession` + `matchSessions` em `supabase_club_datasource.dart` (schema `bldr_club`, tabela `match_sessions`).
- Repositório: `saveMatchSession` + `matchSessions` em `ClubWorkoutRepository` (abstract) e `ClubWorkoutRepositoryImpl`.
- Use cases `SaveMatchSession` + `GetMatchHistory` em `club_usecases.dart`, registrados no DI.
- `match_tracker_screen.dart`: `onSave` chama `SaveMatchSession` via `unawaited` (SharedPreferences mantido como cache local); seção "HISTÓRICO" ao fim da tela com lista paginada (máx 20), chips de filtro por modalidade e empty state.

### F19. BLDR Run — stats inline [CE1]

**✅ Implementado (2026-08-07).**
- `run_card_widget.dart`: novo `_buildStatsRow()` exibe "Última: título · distância · data relativa" e "Pace médio: M:SS/km · N corridas este mês".
- Pace médio calculado cliente-side parseando `pace_text` ("M:SS" → segundos → média → formato).
- Count mensal: filtra `_lastActivities` por `year == now.year && month == now.month`.
- `club_repositories_impl.dart`: `saveRun` agora salva `pace_sec` = `duration_seconds / (distance_m / 1000)` para corridas futuras.

### F20. Esportes — resumo semanal [CE5]

**✅ Implementado (2026-08-07).**
- Widget `_WeeklySummaryCard` adicionado ao final de `esportes_screen.dart`, inserido entre RunCardWidget e protocolos.
- Carrega corridas da semana via `GetRunActivities` (Supabase) e sessões locais via `TrackerStorage.getHistory` (match, round).
- Exibe: tempo ativo total, chips de sessão por tipo (corrida/partida/round), recorde da semana (maior distância).
- Rodapé em `textMuted` 9pt: "Corridas sincronizadas · outros só neste dispositivo".
- Card é suprimido (`SizedBox.shrink`) quando não há nenhuma atividade na semana.

### F21. Operação da semana no hub do Club [C5]

**✅ Implementado (2026-08-07) — Opção A (global, definida por admin).**

**Schema:** `bldr_club.weekly_operations` (id, title, description, goal_type, goal_value, xp_reward, week_start, week_end) + `bldr_club.operation_progress` (user_id, operation_id, current_value, completed, completed_at) com RLS `user_id = auth.uid()` e unique `(user_id, operation_id)`.

**Domínio:**
- `WeeklyOperation` + `OperationProgress` em `club_community.dart`
- `ClubWorkoutRepository`: `getCurrentOperation`, `getOperationProgress`, `tryIncrementOperation`
- Use cases: `GetCurrentOperation`, `GetOperationProgress`, `TryIncrementOperation` — registrados no DI

**Card (`bldr_club_screen.dart`):**
- `_WeeklyOperationCard` stateful entre o grid e o squad row
- Oculto quando não há operação ativa (`SizedBox.shrink()`)
- Com operação ativa: `BldrGlassCard` com borda dourada, badge "OPERAÇÃO DA SEMANA", título, descrição, `BldrProgressBar`, "{current} de {goal} {unidade}", "+{xp} XP ao completar"
- Badge "CONCLUÍDA ✓" quando `completed=true`

**Progresso automático:**
- `workout_count` → `unawaited(TryIncrementOperation('workout_count', 1))` em `club_active_workout_screen._finishWorkout()`
- `run_distance` → `unawaited(TryIncrementOperation('run_distance', km))` em `run_tracker_screen` após `SaveRunActivity`
- `calorie_goal` → verificação async após `LogMeal`: se `GetDailySummary.total_calories >= GetNutritionGoals.calories`, chama `TryIncrementOperation('calorie_goal', 1)`
- `TryIncrementOperation` é idempotente: no-op se já concluída ou se goal_type não coincide

### F25. Tela de Feedback (chat BLDR → Supabase de gestão)

**✅ Implementado (2026-08-09).**

**Arquitetura:** App Flutter → Edge Function `send-feedback` → Supabase de Gestão (projeto separado). Credenciais de gestão ficam APENAS na edge function como secrets — nunca no código Dart.

- `lib/features/profile/domain/entities/feedback_entity.dart` — `FeedbackType` enum + `FeedbackResult`
- `lib/features/profile/domain/repositories/feedback_repository.dart` — contrato abstrato
- `lib/features/profile/domain/usecases/feedback_usecases.dart` — `SendFeedback` use case
- `lib/features/profile/data/repositories/feedback_repository_impl.dart` — chama `_client.functions.invoke('send-feedback')`; usa `PackageInfo` para versão, `Platform` para plataforma, `FunctionException` para erro da edge function
- `lib/features/profile/presentation/feedback_screen.dart` — UI de chat com `_Step` enum (selectType / message / screenshot / sending / done / error); bolhas BLDR (avatar "B" 24px dourado, border-radius topLeft:4) e usuário (right-aligned, chips dourados); screenshot via `ImagePicker` + `FlutterImageCompress` (≤800px, q70) + upload para `feedback-screenshots/{userId}/{timestamp}.jpg`; metadata footer `v{ver} · {plat} · {nome}`
- `supabase/functions/send-feedback/index.ts` — cria registro em `feedbacks` do Supabase de gestão via service role; retorna `{ protocolo }`
- 38 chaves de i18n adicionadas a `app_pt.arb`, `app_en.arb`, `app_it.arb`
- Navegação: Settings → SUPORTE → "Reportar bug" e "Enviar sugestão" (linhas separadas) com `tipoInicial` pré-selecionando chip e pulando step de seleção
- DI: `FeedbackRepository` + `SendFeedback` registrados em `injection.dart`
- Rota `AppRoutes.feedbackScreen` em `app_routes.dart`

**Secrets a configurar manualmente no Supabase BLDR** (Code não tem acesso):
- `GESTAO_SUPABASE_URL` — URL do projeto de gestão
- `GESTAO_SUPABASE_SERVICE_KEY` — service role key do projeto de gestão

**Schema** a executar no SQL Editor do projeto de gestão: `docs/gestao/feedback_schema.sql`

### F26. Infraestrutura de Push Notifications — Edge Function `send-push`

**✅ Implementado (2026-08-09).**

- `supabase/functions/send-push/index.ts` — FCM v1 API via OAuth2 JWT (RS256 com service account); segmentação `all | user | segment`; batch de 500; tokens inválidos (`UNREGISTERED/INVALID_ARGUMENT`) coletados e NULLados no banco; loga em `push_notifications_log`
- `supabase/config.toml` — entrada `send-push` com `verify_jwt = false`, `timeout_seconds = 120`
- `supabase/migrations/20260809000001_push_notifications_infrastructure.sql` — tabela `push_notifications_log` com RLS habilitado (sem policy pública — só service role); coluna `platform_type TEXT CHECK ('ios','android','web')` em `user_profiles`
- `docs/gestao/push_notifications_api.md` — documentação completa (endpoint, auth, payload examples, segmentação, tipos e navegação, resposta)

**Secrets a configurar manualmente no Supabase BLDR:**
- `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` — do JSON de service account do Firebase
- `GESTAO_WEBHOOK_SECRET` — `openssl rand -hex 32`, compartilhado com o painel de gestão (Lovable)

**Deploy:** `supabase functions deploy send-push`
**Migration:** aplicar `20260809000001_push_notifications_infrastructure.sql` no projeto BLDR

### F27. Auditoria de notificações — 6 correções

**✅ Implementado (2026-08-09).**

1. **Push exibido ao usuário** — `notification_service.dart`: removido `requestPermission` duplicado (Correção 5); novo método `showPushNotification()` via `FlutterLocalNotificationsPlugin`. `push_notification_service.dart` reescrito: `FirebaseMessaging.onMessage` → `showPushNotification()`; handler de background (`firebaseMessagingBackgroundHandler`) auto-inicializa Firebase + plugin sem usar getIt (isolate separado); `onMessageOpenedApp` + `getInitialMessage` → `NotificationRouter.navigate()`

2. **Rest timer notificação** — `active_workout_screen.dart` e `club_active_workout_screen.dart`: `_startRestTimer()` chama `scheduleRestNotification(seconds)`; skip/finish/resume chamam `cancelRestNotification()`

3. **Token sync centralizado** — `syncTokenToProfile({required bool enabled})` extrado para `PushNotificationService`; `settings_screen.dart`, `profile_screen.dart` e `notification_permission_modal.dart` delegam para `getIt<PushNotificationService>().syncTokenToProfile()`; `platform_type` (`ios`/`android`) gravado junto com o token

4. **Deep-link em notificações** — `notifications_screen.dart` usa `NotificationRouter.navigate(type, data, navigatorKey: appNavigatorKey)` (roteamento por `type` field: duel_invite→Comunidade, ranking→Ranking, streak→Dashboard, level_up→Perfil, outros→Central)

5. **`requestPermission` duplicado removido** — `notification_service.dart` não chama mais `FirebaseMessaging.instance.requestPermission()` (FCM já faz isso em `PushNotificationService.initialize()`)

6. **`getIt<PushNotificationService>()` consistente** — todas as telas usam DI, não singleton manual

### F29. Integração Apple Watch — ponte Flutter/iPhone + UI redesenhada

**✅ Implementado (2026-08-09). UI redesenhada (2026-08-09).**

**Contexto:** Watch App SwiftUI já existia e funcionava (`WatchApp.swift`, `WatchViewModel.swift`, `ContentView.swift`). Faltava somente a ponte do lado Flutter.

**Ponte Flutter/iPhone:**

- **`WatchService`** — `lib/features/integrations/data/watch_service.dart`: singleton que encapsula `WatchConnectivity`. Métodos: `initialize()`, `sendWorkoutState(...)`, `sendWorkoutFinished()`, `sendRunState(...)`, `watchActions` stream.
- Sincronização de corridas autônomas via `messageStream` (Watch envia `{ type: run_synced, key }`) + App Group lido via `MethodChannel("com.bldr.fitness/appgroup")`. `AppDelegate.swift` expõe `getAppGroupValue` e `removeAppGroupValue`.
- **DI** — registrado como `lazySingleton<WatchService>` em `injection.dart`.
- **`main.dart`** — `getIt<WatchService>().initialize()` chamado após `LiveActivityService.init()`.
- **`active_workout_screen.dart`** e **`club_active_workout_screen.dart`**: `_sendToWatch()` na carga e a cada série; `sendWorkoutFinished()` no fim; `_watchSub` escuta `watchActions`.

**UI Watch — redesign (2026-08-09):**

- **`ContentView.swift`** — `TabView` com `.tabViewStyle(.page)` + `.indexViewStyle(.page(backgroundDisplayMode: .automatic))`. Duas tabs: Treino e Corrida. `WorkoutIdleView` (sem treino) e `WorkoutActiveView` (com exercício + timer nativo `Text(.timer)` + botões com SF Symbols + háptico `WKInterfaceDevice.play()`).
- **`RunView.swift`** — `ConnectedRunView` (badge verde, distância 32pt, pace/FC, botões play/stop com SF Symbols) e `AutonomousRunView` (badge laranja, tela de início com `figure.run`, cronômetro nativo, métricas em colunas, botões SF Symbols). Sem `ScrollView` em views sem conteúdo longo.
- **`AutonomousRunManager.swift`** — `startDate` promovido de `private var` para `@Published var` para alimentar `Text(start, style: .timer)` sem Timer adicional na UI.
- **`WatchViewModel.swift`** — adicionados `workoutStartDate: Date?`, `exerciseName`, `seriesLabel`, `currentBpm` (`@Published`); populados em `processarDados`; limpos em `limparTela`.
- **`project.pbxproj`** — `INFOPLIST_KEY_NSHealthShareUsageDescription`, `INFOPLIST_KEY_NSHealthUpdateUsageDescription`, `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` adicionados nas 3 configurações (Debug/Release/Profile) do target Watch Watch App (target usa `GENERATE_INFOPLIST_FILE = YES`).

**Paleta Watch:** dourado `Color(red: 0.831, green: 0.686, blue: 0.216)` + preto `Color.black` + branco com opacidades. SF Symbols: `dumbbell.fill`, `figure.run`, `pause.fill`, `play.fill`, `stop.fill`, `checkmark`, `heart.fill`, `antenna.radiowaves.left.and.right`.

**Correção cronômetro pausado (2026-08-09):**
- **Problema:** `Text(startDate, style: .timer)` continua contando mesmo quando pausado.
- **Fix em `AutonomousRunManager.swift`:** ao pausar, salva `pauseBegin = Date()`; ao retomar, calcula `pauseDuration` e avança `startDate` por esse intervalo — o timer nativo exibe sempre tempo efetivo de corrida.
- **Fix em `RunView.swift`:** quando `isPaused`, exibe `Text(runManager.formattedElapsed())` estático (derivado de `elapsedSeconds` cujo Timer já parou); quando ativo, exibe `Text(startDate, style: .timer)` com `startDate` já compensado.

### F28. Correções visuais pós-redesign

**✅ Implementado (2026-08-09).**

- **EditProfileDialog → glassmorphism** — `edit_profile_dialog_widget.dart`: `Dialog(backgroundColor: Colors.transparent)` + inner Container com `BldrColors.sheetBg` + `Border.all(BldrColors.border)` + `BorderRadius.circular(16)`. Glass audit confirmou que outros containers sólidos encontrados (`programs_page`, `collective_challenge_detail_screen`) são fundos de tela, não superfícies — corretos.

- **Ícone de atividade só no Club** — `weekly_plan_screen.dart` `_buildDoneCard()`: modo livre exibe `check_circle_rounded` à esquerda; modo Club exibe `actType.icon`. Nenhuma lógica de dados alterada.

- **Nome propagado para `club_profiles.display_name`** — `user_service.dart` `updateUserProfile()`: após gravar `user_profiles`, propaga `full_name` → `club_profiles.display_name` apenas quando `display_name IS NULL` (preserva apelido personalizado definido em Privacidade). Try/catch — squad opcional.

- **Dia marcado após deletar treino** — diagnosticado como já funcionando: `_load()` é chamado após delete em `weekly_plan_screen`, e `_weekCardKey.currentState?.reload()` é chamado no retorno a `workouts_screen`. Nenhuma alteração necessária.

### F22. Internacionalização — pt-BR, en-US, it-IT

**Decisões tomadas:**

- 3 idiomas completos: Português (Brasil), English (US), Italiano
- Toggle em Configurações → bottom sheet com bandeiras
- Aplica imediatamente sem reiniciar o app
- HAVOK responde no idioma selecionado
- Lançamento somente com os 3 idiomas 100% traduzidos
- Italiano: tradução profissional (não automática)

**Fase 1 — Estrutura** ✅ Implementado (2026-08-07)

- `generate: true` em pubspec.yaml; `l10n.yaml` na raiz
- `lib/l10n/app_pt.arb`, `app_en.arb`, `app_it.arb` (só `@@locale`)
- `LocaleProvider` (ChangeNotifier + SharedPreferences) em `lib/core/providers/`
- Registrado em DI como `registerLazySingleton`; `load()` chamado no `main()`
- `MultiProvider` em `main()` inclui `ChangeNotifierProvider.value(value: localeProvider)`
- `MaterialApp` usa `localeProvider.locale`, `AppLocalizations.delegate`, 3 `supportedLocales`
- Linha "Idioma" em Configurações → `LanguageSelectorSheet` (3 cards 🇧🇷/🇺🇸/🇮🇹)
- `havok_sheet.dart` injeta `ctx['locale']` via `context.read<LocaleProvider>()`
- Edge functions `gerar-resposta-havok`, `gerar-treino-havok`, `gerar-plano-havok` usam `buildSystemPrompt(locale)` com `"Responda SEMPRE em ${lang}"`
- App continua em português — nenhuma string extraída ainda

**Fase 2 — Extração** ✅ Implementado (2026-08-09)

- 1.092 chaves extraídas em app_pt.arb, app_en.arb, app_it.arb
- Blocos cobertos: Dashboard, Treinos, Execução de treino, Nutrição,
  Hidratação, Progresso, Perfil, Configurações, BLDR Club, HAVOK,
  Paywall, Checkout, Splash
- `dart analyze lib` 0 erros; `flutter test` 85 testes passando

**Fase 3 — Toggle + Tradução** ✅ Implementado (2026-08-09)

- Toggle em Configurações já funciona (muda imediatamente, persiste via SharedPreferences)
- `app_en.arb`: 1.092 chaves traduzidas para inglês americano
- `app_it.arb`: 1.092 chaves com placeholder em inglês — **aguarda tradução profissional**
- HAVOK responde no idioma selecionado (locale injetado via `ctx['locale']`)
- Pontos para revisão manual: "IQD" vs "DQI" no en, abreviação "F" (Fat), "ALPHA" vs "ALFA"

**Pendente — Italiano profissional** 🔴
- `app_it.arb` está preenchido com inglês como placeholder temporário
- Contratar tradução profissional pt-BR → it-IT (1.092 strings)
- Prioridade: antes do lançamento no mercado italiano

### F32. Mini-player global de treino pausado

**✅ Implementado (2026-08-20).**

Pill persistente acima da navbar em todas as telas que usam `BldrScreen`.

- `WorkoutSessionProvider` (ChangeNotifier) registrado no `MultiProvider` do `main.dart`.
- `BldrMiniPlayer` (`Consumer<WorkoutSessionProvider>`) injetado no Stack de `BldrScreen` em `lib/design_system/bldr_components.dart` (`Positioned bottom: 140`).
- `active_workout_card_widget.dart` chama `sessionProvider.setPausedWorkout(firstPaused)` após carregar treinos pausados.
- `active_workout_screen.dart` e `club_active_workout_screen.dart` chamam `sessionProvider.setPausedWorkout(null)` ao finalizar o treino.
- Retomar: `provider.hide()` → push rota → `.then((_) => provider.show())`.
- Novos arquivos: `lib/shared/providers/workout_session_provider.dart`, `lib/shared/presentation/widgets/bldr_mini_player.dart`.

### F33. Sync do widget iOS ao alterar Meu Plano

**✅ Implementado (2026-08-20).**

`WidgetDataService.updateAll()` agora é chamado (via `unawaited`) em todos os pontos onde `UpdatePlanDay` é executado com sucesso:

- `lib/features/workouts/presentation/workouts_screen/weekly_plan_screen.dart` — `_applyTemplateToDay()`
- `lib/features/club/presentation/bldr_club/havok/workout_detail_screen.dart` — `_openAddToPlanSheet()`

### F34. Excluir protocolos de performance em EsportesScreen

**✅ Implementado (2026-08-20).**

- Ícone `delete_outline` (vermelho) no card de cada protocolo; substitui o `chevron_right`.
- `_confirmDelete()` — AlertDialog com nome do plano antes de excluir.
- `_deletePlan()` — remove otimisticamente do estado local; chama `updatePerformancePlans` + `TrackerStorage.clearProtocolState` em paralelo.
- `TrackerStorage.clearProtocolState(planId)` — novo método que remove todas as chaves de SharedPreferences que contêm o `planId`.

### F35. Seção de protocolos HAVOK temporariamente desabilitada

**⚠️ Desabilitado em EsportesScreen (2026-08-20) — bugs conhecidos documentados:**

1. Estado do checklist não persiste entre sessões (SharedPreferences sem data-awareness).
2. Checklist reseta ao trocar de dia ou reabrir — `_checked` é volátil, sem persistência.
3. Sem tabela de DB dedicada — protocolos ficam em `user_profiles.performance_plans` (JSONB).
4. `PlanoPerformanceDetailScreen` com lógica de "Dia concluído" não integrada ao plano semanal.

Quando resolver: descomentar `slivers.add(_buildProtocolosSectionSliver())` em `_buildContentSlivers`, restaurar import de `plano_performance_detail_screen.dart` e reativar `onTap` no `_buildPerformanceCard`.

### F23. ✅ IMPLEMENTADO — Widgets iOS

BLDRWidgets.swift completo: Small Streak, Small Calorias, Medium Resumo,
Large Dashboard, Lock Screen (inline, circular ×2, rectangular).
App Group: group.com.bldr.fitness. Pacote: home_widget.

### F24. ✅ IMPLEMENTADO — LiveActivity iOS

BLDRWorkoutActivity.swift com Dynamic Island compacta/expandida,
Lock Screen, AppIntents (+15s e Pular), integrado ao active_workout_screen.
**LiveActivity de corrida adicionado em F30 (2026-08-09).**

**Pendências verificadas no código (2026-08-09):**

- ~~Vídeo/GIF não aparece na tela Club~~ — `legacy_ui_maps.dart` foi removido. **Resolvido.**
- ~~LiveActivity não funciona na tela Club~~ — verificado: `club_active_workout_screen.dart` já tinha import, `init`, `_startLiveActivity()`, `_updateLiveActivity()` e `LiveActivityService.end()`. O bug havia sido corrigido em sessão anterior. Adicionado `LiveActivityService.end()` no `dispose()` como fallback (paridade com `active_workout_screen`). **Resolvido.**
- ~~Deep link `bldr://workout/confirm` ignorado no Club~~ — `main.dart:155` já usa Stream broadcast. **Resolvido.**

### F30. LiveActivity — Corrida (BLDR Run)

**✅ Implementado (2026-08-09).**

Reutiliza a infraestrutura do `live_activities` plugin (mesma `LiveActivitiesAppAttributes`) com discriminador `activityType: 'run'` em UserDefaults para rotear para os layouts de corrida.

- **`ios/BLDRWidgets/BLDRRunActivity.swift`** (novo) — `RunState` struct lê `startTimestamp`, `distanceM`, `paceSec`, `hr`, `isActive` do App Group UserDefaults; views: `BLDRRunLockScreenView`, `BLDRRunCompactLeading/Trailing`, `BLDRRunMinimal`, `BLDRRunExpandedBottom` (3 colunas: distância · timer/pausado · FC)
- **`ios/BLDRWidgets/BLDRWorkoutActivity.swift`** — `ActivityConfiguration` estendida: lê `activityType` para decidir entre layouts de treino e corrida; `return` explícito em `Group { }` e `DynamicIsland { }` (obrigatório quando `let isRun = ...` torna o closure multi-statement)
- **`lib/features/integrations/data/run_live_activity_service.dart`** (novo) — singleton; `start()` cria a activity com `activityType: 'run'` + `startTimestamp`; `update()` usa o UUID retornado pelo ActivityKit (não o alias); `pause()`/`resume()` reutilizam cache de última distância/pace/FC; `end()` encerra e limpa estado
- **DI** — `RunLiveActivityService` registrado como `lazySingleton` em `injection.dart`
- **`run_tracker_screen.dart`** — `start()`/`pause()`/`resume()`/`end()` integrados via `unawaited`; LiveActivity atualizado a cada ponto GPS (geolocator já filtra `distanceFilter: 5m`)

### F31. What's New — bottom sheet de novidades

**✅ Implementado (2026-08-09).**

Sheet de carrossel exibido uma vez por usuário por registro de novidade. Fonte de verdade no Supabase de Gestão; marcação via SharedPreferences (imediato) + Supabase BLDR (background).

**Arquitetura:**
- **Supabase Gestão** — tabela `whats_new` (id, title, subtitle, slides JSONB, active, trigger_mode, target_version). Executar manualmente: `docs/gestao/whats_new_schema.sql`
- **Supabase BLDR** — tabela `public.whats_new_seen` (user_id, whats_new_id, UNIQUE). Migration: `supabase/migrations/20260809160000_add_whats_new_seen.sql`. RLS: SELECT + INSERT apenas do próprio usuário.
- **Edge Function `get-whats-new`** — autentica via JWT manual (verify_jwt=false), busca itens ativos no Gestão, cruza com `whats_new_seen` do BLDR, retorna primeiro item não visto que satisfaz `trigger_mode` (flag / version / both)
- **`WhatsNewDatasource`** — chama edge function, double-check local via SharedPreferences (`whats_new_seen_{id}`), persiste visto no Supabase em background
- **`GetWhatsNew` / `MarkWhatsNewSeen`** — use cases simples, registrados no DI
- **`whats_new_sheet.dart`** — sheet com handle, badge "NOVIDADES", header (título + subtítulo), `PageView` com 3 slides/página, dots animados (pill dourado = ativo), botão "Entendido". Tokens do Design System: `#050505` bg, glass surfaces, dourado `#E0B830`.
- **`dashboard.dart`** — `_checkWhatsNew()` chamado via `addPostFrameCallback` no `initState`; exibe sheet e chama `MarkWhatsNewSeen` ao dispensar.

**Para deploy:** `supabase functions deploy get-whats-new` + secret `GESTAO_SUPABASE_SERVICE_KEY` no painel BLDR.

---

## Prioridade 4 — Decisões de produto

### P1. Mapa da corrida em tema escuro

Única tela branca do app. Alta prioridade visual, baixa complexidade.
Mapbox e Google Maps permitem estilo customizado.

### P2. Convenção de nomenclatura dos treinos

"LEGS A | QUADS, GLUTE, PANTURRILHA" força truncamento.
Sugestão: separar em nome (curto) e grupos_musculares (lista).

### P3. ✅ Modo padrão do formulário de squad

Mudado para "Hustle" (CQ5, 2026-08-05).

### P4. Identidade visual de parceiros

Card do parceiro com identidade própria quebra a paleta.
Definir se parceiro adapta ao tema ou tem espaço delimitado.

### P5. Mascote (pantera)

Aparecia cortado na borda do hub do Club.
Definir: marca d'água no fundo, elemento do card, ou remoção.

### P6. Recordes pessoais e zonas de esforço

PRs e tempo em zonas de FC. Depende de F12 (integrações).

### P7. Histórico de rotas

Corridas já têm GPS. Mapa com rotas usa dado existente.

### P8. Protocolo sugerido pelo HAVOK

"3 corridas essa semana — quer um protocolo de resistência?"

---

## HAVOK — status


| Item                                    | Status                              |
| --------------------------------------- | ----------------------------------- |
| L1 — Promessas falsas + BldrInsightCard | ✅                                   |
| L2 — Cadeia de execução (B5)            | ✅                                   |
| L3 — Hub de conversa (HavokSheet)       | ✅                                   |
| L4 — Onboarding com geração real        | ✅                                   |
| B6 — Artefato persistido                | ✅                                   |
| B7 — Streak no contexto                 | ✅ parcial                           |
| B8 — Plano semanal sem domínio real     | ✅ (migration pendente no Dashboard) |
| Tom do HAVOK                            | ✅ Implementado (2026-08-09) — system prompt em `gerar-plano-havok` com tom técnico/direto e limites de segurança. `gerar-resposta-havok` e `gerar-treino-havok` já tinham tom adequado. |
| Nome/gênero padronizado                 | ✅ Implementado (2026-08-09) — 8 correções em `app_pt.arb`: "a HAVOK"→"o HAVOK", "Havok"→"HAVOK". `flutter gen-l10n` re-gerado. |
| Rate limit por plano                    | ✅ Implementado (2026-08-09) — view `bldr_club.havok_daily_usage` (security_invoker), use case `GetHavokDailyCount`, integrado em `havok_sheet.dart` (10 msg/dia free, ilimitado Club). Deploy: `supabase db push` para migration `20260809170000_add_havok_rate_limit.sql`. |
| TDEE ignorado na geração do plano       | ✅ Corrigido (2026-08-09) — `gerar-plano-havok/index.ts` agora usa `target_calories`/`target_protein`/`calculated_tdee` do Flutter; safety net post-parse corrige divergências e loga `console.warn`. Deploy: `supabase functions deploy gerar-plano-havok`. |
| Paywall real (isPremiumUser hardcoded)  | ⏳ `panther_fab.dart:17` — FAB mostra HAVOK a todos. `havok_sheet.dart` já usa subscrição real (rate limit correto); só o ícone de cadeado do FAB está errado. |
| UserService.instance em havok_hub.dart  | ⏳ confirmado em `havok_hub.dart:44` (+ 8 outros lugares no codebase — dívida mais ampla) |

### send-push — status (2026-08-09)

| Item                                           | Status |
| ---------------------------------------------- | ------ |
| Edge function FCM v1 (OAuth2 JWT)              | ✅      |
| Bug: tokens.filter(Boolean) antes da checagem  | ✅ Corrigido |
| Bug: log salvo mesmo quando sent=0             | ✅ Corrigido — INSERT no branch early-return |
| Coluna `notes TEXT` em push_notifications_log  | ✅ Migration `20260809180000_add_notes_to_push_log.sql` |
| Campo `warning` na resposta JSON               | ✅ — `null` na rota normal, mensagem na rota 0-tokens |
| Deploy pendente                                | ⏳ `supabase functions deploy send-push` |
| Migration pendente                             | ⏳ aplicar `20260809180000_add_notes_to_push_log.sql` no projeto BLDR |


## Integração Whoop — status


| Item                                  | Status |
| ------------------------------------- | ------ |
| OAuth 2.0                             | ✅      |
| Tokens em Supabase (whoop_tokens)     | ✅      |
| Polling + whoop_daily_data            | ✅      |
| BldrWhoopCard no Dashboard            | ✅      |
| Contexto no HAVOK                     | ✅      |
| read:body_measurement                 | ✅      |
| Cores da Whoop mantidas nos anéis     | ✅      |
| Aprovação da Whoop (Request Approval) | ⏳      |
| Troca de endpoints (produção)         | ⏳      |


## Correções de infraestrutura (2026-08-21)

| Item | Status |
|---|---|
| B3 — `completed_at` salvo sem `.toUtc()` → timestamp 3h errado no banco (BRT) | ✅ corrigido em 8 arquivos |
| B3 migration — registros históricos com `completed_at < started_at` corrigidos via `+3h` | ✅ |
| Watch — WatchKit removido (deprecado watchOS 26), hápticos migrados para `.sensoryFeedback()` | ✅ |
| Watch — `WATCHOS_DEPLOYMENT_TARGET = 10.0`, `WCSessionDelegate @preconcurrency` | ✅ |
| Watch — `HKLiveWorkoutBuilder` removido (re-anotado watchOS 26+ no Xcode 26 SDK) | ✅ |
| iOS mínimo — `IPHONEOS_DEPLOYMENT_TARGET` atualizado para 17.0 (RunnerTests + Widget Extension) | ✅ |
| LaunchScreen — `flutter_native_splash` gera assets nativos; SplashScreen sem tagline, sem tela preta | ✅ |
| Navbar — logo BLDR_CLUB.png substituiu monograma "B" | ✅ |

## Bloqueadores de publicação nas lojas

| Item                                                         | Criticidade        |
| ------------------------------------------------------------ | ------------------ |
| F13 — Privacidade (controle de visibilidade no feed/ranking) | 🔴 Obrigatório     |
| F14 — Central de ajuda e Termos de uso                       | 🔴 Obrigatório     |
| B2 — Conquistas nunca desbloqueiam                           | ✅                  |
| Whoop: aprovação para produção                               | 🟡 Limita usuários |


