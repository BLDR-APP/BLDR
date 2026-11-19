import 'dart:async' show unawaited;
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bldr_fitness/core/toast/bldr_toaster.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/week_plan_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/week_override.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_workout_hub_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_workout_v2_components.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/esportes_screen.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_duration_estimator.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/features/workouts/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/routes/app_routes.dart';
import 'package:bldr_fitness/services/workout_photo_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/widgets/custom_error_widget.dart';
import 'package:bldr_fitness/features/club/programs_page.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/club_active_workout_screen.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/muscle_normalizer.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/today_workout_resolver.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/widgets/current_week_card_widget.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/active_workout_screen.dart';
import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/create_workout_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/weekly_plan_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workout_details_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workout_photo_review_screen.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_map.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  // ── state ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _myWorkouts = [];
  List<Map<String, dynamic>> _bldrWorkouts = [];
  Map<String, BldrMuscleMapData> _muscleDataByTemplateId = {};
  Map<String, dynamic>? _todayWorkout;
  BldrMuscleMapData? _todayMuscleData;
  WorkoutSession? _completedTodayWorkout;
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasActiveWorkout = false;
  bool _isPro = false;
  bool _analyzingPhoto = false;

  // T1 — busca local sobre as listas já carregadas (sem nova consulta).
  bool _searchOpen = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // T9 — "Ver tudo" expande o carrossel da Biblioteca BLDR para grade cheia,
  // usando o mesmo dado já carregado.
  bool _bldrExpanded = false;

  // ── Hub v2 (Figma 249:18901 / 179:2) ──────────────────────────────────────
  /// 0 = Treino, 1 = Esportes.
  int _hubTab = 0;

  /// Templates carregados, por id — duração estimada e grupos musculares.
  Map<String, WorkoutTemplate> _templatesById = {};
  WorkoutTemplate? _todayTemplateEntity;

  // ── Hub revisado (305:1656 / 310:195) ──────────────────────────────────────
  /// Menu flutuante da Workout Library aberto (o botão some enquanto isso).
  bool _libraryMenuOpen = false;

  /// Dica de primeiro uso do botão (uma vez por usuário).
  bool _showLibraryTip = false;

  /// Key that lets us call reload() on the card after editing the plan.
  final _weekCardKey = GlobalKey<CurrentWeekCardWidgetState>();

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkLibraryTip();
    // Prefetch ExerciseDB catalog in the background so ActiveWorkoutScreen
    // gets instant cache hits instead of N individual network calls.
    unawaited(
      ExerciseDbRapidService.instance.listAllExercises().catchError((_) {}),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── data ──────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final hasRenderableData = _myWorkouts.isNotEmpty ||
          _bldrWorkouts.isNotEmpty ||
          _todayWorkout != null;
      if (!_isLoading && !hasRenderableData) {
        setState(() => _isLoading = true);
      }

      final templatesResult = await getIt<GetWorkoutTemplates>()();
      final weeklyPlanResult = await getIt<GetWeekPlan>()(WeekCalendar.weekStartFor(DateTime.now()));
      final activeResult = await getIt<HasActiveWorkout>()();
      final completedResult = await getIt<GetConsolidatedWorkoutHistory>()(
        completedOnly: true,
        limit: 20,
      );

      if (!mounted) return;

      final templates = templatesResult.valueOrNull;
      if (templates == null) {
        throw Exception(templatesResult.failureOrNull?.message);
      }
      final plan = weeklyPlanResult.valueOrNull ?? const [];
      final completedSessions = completedResult.valueOrNull ?? const [];
      final now = DateTime.now();
      final completedOnDate = TodayWorkoutResolver.completedOnDate(
        sessions: completedSessions,
        date: now,
      );
      var todayTemplate = TodayWorkoutResolver.resolve(
        plan: plan,
        templates: templates,
        weekday: DateTime.now().weekday,
      );
      final todayRow = plan
          .where((day) => day.diaSemana == DateTime.now().weekday)
          .firstOrNull;
      // Descanso com template guardado não é treino do dia.
      final assignedToday =
          (todayRow?.isRestDay ?? false) ? null : todayRow?.treino;
      if (todayTemplate == null && assignedToday?.id != null) {
        final assignedResult = assignedToday!.source == 'club'
            ? await getIt<GetClubTemplateWithExercises>()(assignedToday.id!)
            : await getIt<GetTemplateWithExercises>()(assignedToday.id!);
        todayTemplate = assignedResult.valueOrNull;
      }
      // Um treino confirmado hoje (inclusive via wearable) continua sendo o
      // treino do dia mesmo se o plano legado não tiver template_id preenchido.
      if (todayTemplate == null && completedOnDate?.templateId != null) {
        todayTemplate = (await getIt<GetTemplateWithExercises>()(
          completedOnDate!.templateId!,
        ))
            .valueOrNull;
      }
      if (!mounted) return;

      final all = templates.map(templateToLegacyMap).toList();
      final muscleData = <String, BldrMuscleMapData>{};
      for (final template in templates) {
        final data = MuscleNormalizer.mapDataForTemplate(template);
        if (template.id != null) muscleData[template.id!] = data;
        _debugMusclePipeline(template, data.muscles);
      }
      final todayData = todayTemplate == null
          ? null
          : MuscleNormalizer.mapDataForTemplate(todayTemplate);
      if (todayTemplate?.id != null && todayData != null) {
        muscleData[todayTemplate!.id!] = todayData;
      }
      if (kDebugMode && todayTemplate != null && todayData != null) {
        final scores = MuscleNormalizer.viewScores(todayData.muscles);
        debugPrint('[MuscleMapView] workout=${todayTemplate.name}');
        debugPrint('[MuscleMapView] structuralFrontScore=${scores.front}');
        debugPrint('[MuscleMapView] structuralBackScore=${scores.back}');
        debugPrint('[MuscleMapView] dominantView='
            '${MuscleNormalizer.dominantView(todayData.muscles).name}');
        debugPrint('[MuscleMapView] data.view=${todayData.view.name}');
      }
      final isActive = activeResult.valueOrNull ?? false;
      final completedToday = completedSessions.where((session) {
        final completedAt = session.completedAt?.toLocal();
        return completedAt != null &&
            completedAt.year == now.year &&
            completedAt.month == now.month &&
            completedAt.day == now.day &&
            session.templateId == todayTemplate?.id;
      }).firstOrNull;

      // Load subscription in parallel (non-blocking for main list)
      _loadSubscription();

      setState(() {
        _bldrWorkouts = all.where((w) => w['is_public'] == true).toList();
        _myWorkouts = all.where((w) => w['is_public'] != true).toList();
        _muscleDataByTemplateId = muscleData;
        _todayWorkout = todayTemplate == null
            ? null
            : {
                ...templateToLegacyMap(todayTemplate),
                'source': assignedToday?.source ?? todayTemplate.source,
              };
        _todayMuscleData = todayData;
        _templatesById = {
          for (final t in templates)
            if (t.id != null) t.id!: t,
        };
        _todayTemplateEntity = todayTemplate;
        _completedTodayWorkout = completedToday;
        _hasActiveWorkout = isActive;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _debugMusclePipeline(
    WorkoutTemplate template,
    Map<BldrMuscle, double> aggregated,
  ) {
    if (!kDebugMode) return;
    debugPrint('[MuscleMap] Workout: ${template.name} id=${template.id}');
    debugPrint('[MuscleMap] exercises=${template.exercises.length}');
    for (var i = 0; i < template.exercises.length; i++) {
      final row = template.exercises[i];
      final exercise = row.exercise;
      final rawPrimary = exercise?.primaryMuscleGroup;
      final rawSecondary = exercise?.secondaryMuscleGroups ?? const <String>[];
      debugPrint('[MuscleMap] Exercise ${i + 1}:');
      debugPrint('[MuscleMap]   name: ${exercise?.name ?? row.freeName}');
      debugPrint('[MuscleMap]   exerciseDbId: '
          '${row.exerciseDbId ?? exercise?.exerciseDbId}');
      debugPrint('[MuscleMap]   raw primaryMuscleGroup: '
          '$rawPrimary (${rawPrimary.runtimeType})');
      debugPrint('[MuscleMap]   raw secondaryMuscleGroups: '
          '$rawSecondary (${rawSecondary.runtimeType})');
      debugPrint('[MuscleMap]   normalized primary: '
          '${MuscleNormalizer.fromDynamic(rawPrimary).map((e) => e.name).toList()}');
      debugPrint('[MuscleMap]   normalized secondary: '
          '${MuscleNormalizer.fromList(rawSecondary).map((e) => e.name).toList()}');
    }
    debugPrint('[MuscleMap] Aggregated map: '
        '${aggregated.map((key, value) => MapEntry(key.name, value))}');
    final scores = MuscleNormalizer.viewScores(aggregated);
    debugPrint('[MuscleMap] structuralFrontScore=${scores.front}, '
        'structuralBackScore=${scores.back}, '
        'dominantView=${MuscleNormalizer.dominantView(aggregated).name}');
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> source) {
    if (_searchQuery.trim().isEmpty) return source;
    final q = _searchQuery.trim().toLowerCase();
    return source
        .where((w) => (w['name'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  // ── navigation ─────────────────────────────────────────────────────────────

  void _startWorkout(Map<String, dynamic> template) async {
    try {
      final name = template['name'] as String? ?? 'Treino';
      final templateId = template['id'] as String?;
      if (templateId == null) {
        context.toast.error('Não foi possível iniciar o treino.');
        return;
      }
      final isClub = template['source'] == 'club';
      final startResult = isClub
          ? await getIt<StartClubWorkout>()(
              name: name,
              templateId: templateId,
            )
          : await getIt<StartWorkout>()(
              name: name,
              templateId: templateId,
            );
      final session = startResult.valueOrNull;
      if (session == null) {
        final failure = startResult.failureOrNull;
        if (failure != null && mounted) {
          context.toast.error(failure.message);
        }
        return;
      }

      if (!mounted) return;
      setState(() => _hasActiveWorkout = true);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => isClub
              ? ClubActiveWorkoutScreen(
                  workoutId: session.id!,
                  workoutName: name,
                )
              : ActiveWorkoutScreen(
                  workoutId: session.id!,
                  workoutName: name,
                ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() => _hasActiveWorkout = false);
          _loadData();
        }
      });
    } catch (_) {
      if (!mounted) return;
      context.toast.error(AppLocalizations.of(context).workouts_start_error);
    }
  }

  /// Detalhes do treino v2 (316:113). Treinos do usuário ganham o menu
  /// (editar / excluir); "Iniciar" volta para cá e usa o fluxo atual.
  Future<void> _viewWorkoutDetails(Map<String, dynamic> template) async {
    final id = template['id'] as String?;
    if (id == null) return;
    final l10n = AppLocalizations.of(context);
    final name = template['name'] as String? ?? '';
    final result = await Navigator.push<WorkoutDetailsResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDetailsScreen(
          templateId: id,
          fallbackName: name,
          isOwned: template['is_public'] != true,
        ),
      ),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case WorkoutDetailsResult.start:
        _startWorkout(template);
      case WorkoutDetailsResult.changed:
        _loadData();
      case WorkoutDetailsResult.duplicated:
        _loadData();
        context.toast.success(l10n.wd_duplicated);
      case WorkoutDetailsResult.deleted:
        _loadData();
        context.toast.success(l10n.workouts_deleted_snackbar(name));
    }
  }

  /// Carrega o template completo (com exercícios) e abre a edição.
  Future<void> _editTemplate(Map<String, dynamic> template) async {
    final fullResult = await getIt<GetTemplateWithExercises>()(template['id']);
    final full = fullResult.valueOrNull;
    if (!mounted || full == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateWorkoutScreen(editTemplate: full),
      ),
    );
    if (updated == true && mounted) _loadData();
  }

  /// Confirmation dialog before permanently deleting a template.
  /// [closeSheet]: também fecha o sheet de detalhe que abriu o diálogo.
  void _confirmDelete(BuildContext sheetCtx, Map<String, dynamic> template,
      {bool closeSheet = true}) async {
    final l10n = AppLocalizations.of(context);
    final ok = await BldrV2ConfirmDialog.show(
      sheetCtx,
      title: l10n.workouts_delete_title,
      message: l10n.workouts_delete_body(template['name']),
      cancelLabel: l10n.common_cancel,
      confirmLabel: l10n.common_delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    if (closeSheet && sheetCtx.mounted) Navigator.pop(sheetCtx);
    try {
      final result =
          await getIt<DeleteWorkoutTemplate>()(template['id'] as String);
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);
      if (mounted) {
        _loadData();
        context.toast.success(l10n.workouts_deleted_snackbar(template['name']));
      }
    } catch (e) {
      if (mounted) {
        context.toast.error(l10n.workouts_delete_error(e.toString()));
      }
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: Center(
            child: CircularProgressIndicator(color: BldrColors.goldBright)),
      );
    }

    if (_hasError) {
      return const Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: Center(child: CustomErrorWidget()),
      );
    }

    // Aba Esportes: a EsportesScreen atual dentro do hub (só com acesso ao
    // Club; sem acesso, o paywall abre e a aba Treino continua ativa).
    if (_hubTab == 1) {
      return Stack(
        children: [
          const EsportesScreen(),
          Positioned(
            top: MediaQuery.viewPaddingOf(context).top + 8,
            right: _hubPx,
            child: BldrHubTabs(
              labels: [
                AppLocalizations.of(context).hub_tab_workout,
                AppLocalizations.of(context).hub_tab_sports,
              ],
              selected: 1,
              onChanged: _onHubTab,
            ),
          ),
        ],
      );
    }

    return PopScope(
      // Android: o voltar do sistema fecha o menu em vez de sair da tela.
      canPop: !_libraryMenuOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _libraryMenuOpen) _closeLibraryMenu();
      },
      child: Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: Stack(
          children: [
            Positioned.fill(child: _buildHubScroll()),
            ..._buildLibraryOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHubScroll() {
    return BldrBackground(
      v2: true,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: BldrColors.goldBright,
          backgroundColor: BldrColors.surface,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // ── Cabeçalho v2: abas Treino / Esportes + busca ─────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(_hubPx, 20, _hubPx, 0),
                sliver: SliverToBoxAdapter(child: _buildHeader()),
              ),

              // ── Treino de hoje ──────────────────────────────────────
              if (_todayWorkout != null)
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(_hubPx - 2, 18, _hubPx - 2, 0),
                  sliver: SliverToBoxAdapter(child: _buildTodayHero()),
                ),

              // ── Minha semana ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(_hubPx, 16, _hubPx, 0),
                sliver: SliverToBoxAdapter(
                  child: CurrentWeekCardWidget(
                    key: _weekCardKey,
                    onViewPlan: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WeeklyPlanScreen()),
                      );
                      await _loadData();
                      _weekCardKey.currentState?.reload();
                    },
                  ),
                ),
              ),

              const SliverPadding(
                padding: EdgeInsets.only(top: 24),
                sliver: SliverToBoxAdapter(child: BldrGoldDivider()),
              ),

              // ── Meus treinos ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(_hubPx, 10, _hubPx, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildMyWorkoutsSection(),
                ),
              ),

              const SliverPadding(
                padding: EdgeInsets.only(top: 14),
                sliver: SliverToBoxAdapter(child: BldrGoldDivider()),
              ),

              if (_bldrExpanded)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: _buildBldrSection(),
                  ),
                ),

              // Folga para o botão da Workout Library nunca cobrir o
              // último conteúdo.
              const SliverToBoxAdapter(
                  child: SizedBox(
                      height: BldrSpacing.navClearance +
                          BldrWorkoutLibraryFab.size +
                          _fabGap * 2)),
            ],
          ),
        ),
      ),
    );
  }

  // ── T1: header ────────────────────────────────────────────────────────────

  static const double _hubPx = 27;

  void _onHubTab(int i) {
    if (i == _hubTab) return;
    if (i == 1 && !_isPro) {
      // Regra de acesso de hoje: Esportes é do BLDR Club.
      ClubPaywallSheet.show(
        context,
        onSubscribed: () async {
          await _loadSubscription();
          if (mounted && _isPro) setState(() => _hubTab = 1);
        },
      );
      return;
    }
    setState(() => _hubTab = i);
  }

  /// Cabeçalho v2: abas + busca (o campo abre no lugar das abas; "×" fecha).
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 49,
      child: Row(
        children: [
          Expanded(
            child: _searchOpen
                ? TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: BldrWorkoutTextV2.hubTabActive
                        .copyWith(color: BldrWorkoutColorsV2.text),
                    cursorColor: BldrColors.goldBright,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: l10n.workouts_search_hint,
                      hintStyle: BldrWorkoutTextV2.hubTab,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  )
                : Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: BldrHubTabs(
                        labels: [l10n.hub_tab_workout, l10n.hub_tab_sports],
                        selected: _hubTab,
                        onChanged: _onHubTab,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          BldrGoldCircleButton(
            icon: _searchOpen ? TablerIcons.x : TablerIcons.search,
            semanticLabel: l10n.hub_search,
            onTap: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
    );
  }

  // ── T3: hero do treino de hoje ──────────────────────────────────────────

  /// Card "Treino de hoje" v2. Muscle map atual (só o container é do
  /// mockup); duração pelo estimador (P1).
  Widget _buildTodayHero() {
    final l10n = AppLocalizations.of(context);
    final todayWorkout = _todayWorkout!;
    final mapData = _todayMuscleData ??
        const BldrMuscleMapData(
          muscles: <BldrMuscle, double>{},
          view: BldrMuscleMapView.front,
        );
    final entity = _todayTemplateEntity;
    final exerciseCount = entity?.exercises.length ??
        ((todayWorkout['workout_template_exercises'] as List?) ?? const [])
            .length;
    final minutes = entity == null
        ? (todayWorkout['estimated_duration_minutes'] as int? ?? 0)
        : WorkoutDurationEstimator.estimateTemplate(entity.exercises);
    final completedToday = _completedTodayWorkout;
    final completedViaWhoop = completedToday?.completedViaWhoop ?? false;

    return BldrTodayWorkoutCard(
      label: l10n.hub_today_label,
      name: todayWorkout['name'] as String? ?? 'Treino',
      hint: completedToday == null
          ? l10n.hub_today_hint
          : completedViaWhoop
              ? l10n.dashboard_v2_done_via_whoop
              : l10n.hub_done_sub,
      meta: l10n.hub_meta(exerciseCount, minutes),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WeeklyPlanScreen()),
        );
        await _loadData();
        _weekCardKey.currentState?.reload();
      },
      action: completedToday == null
          ? BldrSmallGoldPill(
              width: 136,
              icon: TablerIcons.caret_right,
              label: l10n.hub_start,
              onTap: () => _startWorkout(todayWorkout),
            )
          : BldrSmallGoldPill(
              width: 136,
              icon: TablerIcons.check,
              label: l10n.hub_done,
            ),
      muscleMap: FittedBox(
        fit: BoxFit.contain,
        child: BldrMuscleMap(
          muscles: mapData.muscles,
          size: BldrMuscleMapSize.hero,
          view: mapData.view,
        ),
      ),
    );
  }

  // ── active workout banner ─────────────────────────────────────────────────

  Widget _buildActiveWorkoutBanner() {
    return BldrGlassCard(
      background: BldrColors.goldTintChip,
      borderColor: BldrColors.goldBorderChip,
      onTap: () async {
        final activeResult = await getIt<GetActiveWorkoutDetails>()();
        final active = activeResult.valueOrNull;
        if (active == null || active.id == null || !mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveWorkoutScreen(
              workoutId: active.id!,
              workoutName: active.name.isNotEmpty ? active.name : 'Treino',
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() => _hasActiveWorkout = false);
            _loadData();
          }
        });
      },
      child: Row(
        children: [
          const Icon(Icons.circle, color: BldrColors.goldBright, size: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                AppLocalizations.of(context).workouts_active_banner_text,
                style: BldrText.body.copyWith(
                    color: BldrColors.goldBright, fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.chevron_right,
              color: BldrColors.goldBright, size: 18),
        ],
      ),
    );
  }

  // ── T6: meus treinos section ──────────────────────────────────────────────

  /// "Meus treinos" (309:493): cabeçalho com contagem e carrossel 2×2
  /// paginado; vazio → área tracejada com "Criar treino".
  Widget _buildMyWorkoutsSection() {
    final l10n = AppLocalizations.of(context);
    final list = _filtered(_myWorkouts);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.hub_my_workouts,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrWorkoutTextV2.myHeader),
            ),
            const SizedBox(width: 8),
            Text(l10n.hub_count(list.length).toUpperCase(),
                maxLines: 1, style: BldrWorkoutTextV2.myCount),
          ],
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          BldrDashedEmptyBox(
            height: 150,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(TablerIcons.barbell,
                      size: 20, color: BldrWorkoutColorsV2.text),
                  const SizedBox(height: 8),
                  Text(l10n.hub_empty_title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWorkoutTextV2.emptyTitle),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 180,
                    child: BldrOutlineCta(
                      label: l10n.hub_empty_cta,
                      icon: TablerIcons.plus,
                      onPressed: _openCreateWorkout,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          BldrMyWorkoutsCarousel(
            itemCount: list.length,
            itemBuilder: (_, i, mapW) => _buildMyWorkoutCard(list[i], mapW),
          ),
      ],
    );
  }

  void _openCreateWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateWorkoutScreen()),
    ).then((created) {
      if (created == true && mounted) _loadData();
    });
  }

  Widget _buildMyWorkoutCard(Map<String, dynamic> workout, double mapW) {
    final l10n = AppLocalizations.of(context);
    final mapData = _muscleDataForLegacy(workout, consumer: 'MiniCard');
    final entity = _templatesById[workout['id']];
    final exerciseCount = entity?.exercises.length ??
        ((workout['workout_template_exercises'] as List?) ?? const []).length;
    final minutes = entity == null
        ? (workout['estimated_duration_minutes'] as int? ?? 0)
        : WorkoutDurationEstimator.estimateTemplate(entity.exercises);
    return BldrMyWorkoutCard(
      name: workout['name'] as String? ?? 'Treino',
      groups: entity == null ? '' : HomeV2Format.muscleGroups(entity),
      exercises: l10n.hub_card_exercises(exerciseCount),
      minutes: l10n.hub_card_minutes(minutes),
      mapWidth: mapW,
      onTap: () => _viewWorkoutDetails(workout),
      editLabel: l10n.hub_card_edit,
      deleteLabel: l10n.common_delete,
      optionsLabel: l10n.hub_card_options,
      onAction: (action) => switch (action) {
        BldrMyWorkoutAction.edit => _editTemplate(workout),
        BldrMyWorkoutAction.delete =>
          _confirmDelete(context, workout, closeSheet: false),
      },
      muscleMap: FittedBox(
        fit: BoxFit.contain,
        child: BldrMuscleMap(
          muscles: mapData.muscles,
          size: BldrMuscleMapSize.card,
          view: mapData.view,
        ),
      ),
    );
  }

  // ── T8: criar treino / a partir de foto ──────────────────────────────────

  Future<void> _onCreateFromPhoto() async {
    // Free user → upsell
    if (!_isPro) {
      Navigator.pushNamed(context, AppRoutes.checkoutScreen);
      return;
    }

    // PRO user → choose source
    final l10n = AppLocalizations.of(context);
    final source = await BldrV2Sheet.show<ImageSource>(
      context,
      title: l10n.hub_menu_photo_title,
      child: Builder(
        builder: (ctx) => Column(children: [
          BldrV2SheetOption(
            icon: TablerIcons.camera,
            label: l10n.workouts_photo_camera,
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          BldrV2SheetOption(
            icon: TablerIcons.photo,
            label: l10n.workouts_photo_gallery,
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    setState(() => _analyzingPhoto = true);
    try {
      final matches =
          await WorkoutPhotoService.instance.analyzeImage(File(picked.path));

      if (!mounted) return;
      if (matches.isEmpty) {
        context.toast.warning(AppLocalizations.of(context).workouts_photo_no_exercises);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutPhotoReviewScreen(matches: matches),
        ),
      );
      if (mounted) _loadData();
    } catch (e) {
      if (mounted) {
        context.toast.error(AppLocalizations.of(context).workouts_photo_error(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _analyzingPhoto = false);
    }
  }

  // ── Explorar ─────────────────────────────────────────────────────────────

  Future<void> _loadSubscription() async {
    final access = (await getIt<ResolveClubAccess>()()).valueOrNull ?? false;
    if (!mounted) return;
    setState(() {
      _isPro = access;
    });
  }

  void _openClubDestination(WidgetBuilder builder) {
    if (_isPro) {
      Navigator.push(context, MaterialPageRoute(builder: builder));
      return;
    }

    ClubPaywallSheet.show(
      context,
      onSubscribed: () async {
        await _loadSubscription();
        if (mounted && _isPro) {
          Navigator.push(context, MaterialPageRoute(builder: builder));
        }
      },
    );
  }

  // ── Workout Library: botão + menu flutuante ──────────────────────────────

  static const double _fabGap = 8;
  static const _menuAnim = Duration(milliseconds: 220);

  void _toggleLibraryMenu() {
    setState(() {
      _libraryMenuOpen = !_libraryMenuOpen;
      _showLibraryTip = false;
    });
    _markLibraryTipSeen();
  }

  void _closeLibraryMenu() => setState(() => _libraryMenuOpen = false);

  /// Fecha o menu e então executa o destino.
  void _selectLibraryItem(VoidCallback action) {
    _closeLibraryMenu();
    action();
  }

  String get _libraryTipKey {
    final uid = getIt<GetCurrentUser>()()?.id ?? 'anon';
    return 'hub_library_tip_seen_$uid';
  }

  Future<void> _checkLibraryTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_libraryTipKey) ?? false) return;
      if (mounted) setState(() => _showLibraryTip = true);
    } catch (_) {}
  }

  Future<void> _markLibraryTipSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_libraryTipKey, true);
    } catch (_) {}
  }

  void _dismissLibraryTip() {
    if (!_showLibraryTip) return;
    setState(() => _showLibraryTip = false);
    _markLibraryTipSeen();
  }

  List<Widget> _buildLibraryOverlay() {
    final l10n = AppLocalizations.of(context);
    // Com extendBody no dashboard, o padding inferior já inclui a navbar.
    final bottom = MediaQuery.paddingOf(context).bottom + _fabGap;
    final screenW = MediaQuery.sizeOf(context).width;
    final menuW = (screenW * 256 / 440).clamp(220.0, screenW - _hubPx * 2);
    final items = [
      BldrLibraryMenuItem(
        icon: SvgPicture.asset('assets/images/v2/icons/hub_book_clone.svg'),
        title: l10n.hub_menu_library_title,
        description: l10n.hub_menu_library_sub,
        highlight: l10n.hub_menu_library_highlight,
        onTap: () => _selectLibraryItem(_openBldrLibrary),
      ),
      BldrLibraryMenuItem(
        icon: const Icon(TablerIcons.tic_tac,
            size: 24, color: BldrWorkoutColorsV2.goldBrand),
        title: l10n.hub_menu_programs_title,
        description: l10n.hub_menu_programs_sub,
        locked: !_isPro,
        onTap: () => _selectLibraryItem(
            () => _openClubDestination((_) => const ClubProgramsPage())),
      ),
      BldrLibraryMenuItem(
        icon: const Icon(TablerIcons.barbell,
            size: 24, color: BldrWorkoutColorsV2.goldBrand),
        title: l10n.hub_menu_create_title,
        description: l10n.hub_menu_create_sub,
        onTap: () => _selectLibraryItem(_openCreateWorkout),
      ),
      BldrLibraryMenuItem(
        icon: _analyzingPhoto
            ? const Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: BldrWorkoutColorsV2.goldBrand))
            : const Icon(TablerIcons.camera,
                size: 24, color: BldrWorkoutColorsV2.goldBrand),
        title: l10n.hub_menu_photo_title,
        description: l10n.hub_menu_photo_sub,
        onTap: () => _selectLibraryItem(_onCreateFromPhoto),
      ),
    ];
    return [
      // Toque fora fecha o menu sem executar nada.
      if (_libraryMenuOpen)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeLibraryMenu,
          ),
        ),
      // Dica de primeiro uso: some no primeiro toque em qualquer lugar.
      if (_showLibraryTip && !_libraryMenuOpen)
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _dismissLibraryTip(),
          ),
        ),
      if (_showLibraryTip && !_libraryMenuOpen)
        Positioned(
          right: _hubPx,
          bottom: bottom + BldrWorkoutLibraryFab.size + 10,
          child:
              IgnorePointer(child: BldrLibraryTip(text: l10n.hub_library_tip)),
        ),
      Positioned(
        right: _hubPx,
        bottom: bottom,
        child: IgnorePointer(
          ignoring: _libraryMenuOpen,
          child: AnimatedOpacity(
            opacity: _libraryMenuOpen ? 0 : 1,
            duration: _menuAnim,
            child: BldrWorkoutLibraryFab(
              semanticLabel: l10n.hub_library_button,
              onTap: _toggleLibraryMenu,
            ),
          ),
        ),
      ),
      Positioned(
        right: _hubPx,
        bottom: bottom,
        child: IgnorePointer(
          ignoring: !_libraryMenuOpen,
          child: AnimatedSlide(
            offset: _libraryMenuOpen ? Offset.zero : const Offset(0, 0.08),
            duration: _menuAnim,
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _libraryMenuOpen ? 1 : 0,
              duration: _menuAnim,
              child: BldrWorkoutLibraryMenu(items: items, width: menuW),
            ),
          ),
        ),
      ),
    ];
  }

  void _openBldrLibrary() {
    final workouts = _filtered(_bldrWorkouts);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (libraryContext) => Scaffold(
          backgroundColor: BldrColors.bgBase,
          body: BldrBackground(
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        BldrSpacing.pageX, 14, BldrSpacing.pageX, 18),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          BldrCircleButton(
                            icon: Icons.arrow_back_rounded,
                            size: 38,
                            filled: false,
                            onPressed: () => Navigator.pop(libraryContext),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Biblioteca BLDR',
                                style: BldrText.screenTitle),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (workouts.isEmpty)
                    SliverPadding(
                      padding: BldrSpacing.pageInsets,
                      sliver: SliverToBoxAdapter(
                        child: BldrEmptyState(
                          icon: Icons.auto_awesome_outlined,
                          title:
                              AppLocalizations.of(context).workouts_bldr_empty,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: BldrSpacing.pageInsets,
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final workout = workouts[i];
                            final mapData = _muscleDataForLegacy(workout,
                                consumer: 'Biblioteca');
                            return BldrWorkoutCard(
                              title: workout['name'] as String? ?? 'Treino',
                              subtitle: workout['description'] as String?,
                              metaLeft:
                                  '${workout['estimated_duration_minutes'] ?? 30} min',
                              metaRight:
                                  'Nível ${workout['difficulty_level'] ?? 1}',
                              muscles: mapData.muscles,
                              view: mapData.view,
                              onTap: () => _viewWorkoutDetails(workout),
                              onStart: () => _startWorkout(workout),
                            );
                          },
                          childCount: workouts.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: BldrSpacing.gapCard,
                          crossAxisSpacing: BldrSpacing.gapCard,
                          childAspectRatio: .60,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BldrMuscleMapData _muscleDataForLegacy(
    Map<String, dynamic> workout, {
    required String consumer,
  }) {
    final id = workout['id']?.toString();
    final data = id == null ? null : _muscleDataByTemplateId[id];
    final effective = data ??
        const BldrMuscleMapData(
          muscles: <BldrMuscle, double>{},
          view: BldrMuscleMapView.front,
        );
    if (kDebugMode) {
      debugPrint('[MuscleMap] Value actually passed to $consumer '
          '(${workout['name']}): '
          '${effective.muscles.map((key, value) => MapEntry(key.name, value))}; '
          'view=${effective.view.name}');
      if (effective.muscles.isEmpty) {
        final rows =
            (workout['workout_template_exercises'] as List?) ?? const [];
        final resolved = rows.where((row) {
          return row is Map && row['exercises'] is Map;
        }).length;
        final unresolvedExerciseDbIds = rows
            .whereType<Map>()
            .where((row) => row['exercises'] == null)
            .map((row) => row['exercise_db_id'])
            .whereType<String>()
            .toList();
        debugPrint('[MuscleMap] AVISO: mapa vazio para ${workout['name']}; '
            'rows=${rows.length}, resolved=$resolved, '
            'unresolvedExerciseDbIds=$unresolvedExerciseDbIds.');
      }
    }
    return effective;
  }

  // ── T4/T9: biblioteca bldr ──────────────────────────────────────────────

  Widget _buildBldrSection() {
    final list = _filtered(_bldrWorkouts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BldrSectionHeader(
          title: AppLocalizations.of(context).workouts_bldr_library,
          trailingLabel: list.isEmpty
              ? null
              : (_bldrExpanded
                  ? AppLocalizations.of(context).workouts_see_less
                  : AppLocalizations.of(context).workouts_see_all),
          onTrailingTap: () => setState(() => _bldrExpanded = !_bldrExpanded),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: BldrSpacing.pageInsets,
            child: BldrEmptyState(
              icon: Icons.auto_awesome_outlined,
              title: AppLocalizations.of(context).workouts_bldr_empty,
            ),
          )
        else if (_bldrExpanded)
          Padding(
            padding: BldrSpacing.pageInsets,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: BldrSpacing.gapCard,
                crossAxisSpacing: BldrSpacing.gapCard,
                childAspectRatio: 0.60,
              ),
              itemBuilder: (_, i) {
                final w = list[i];
                final mapData =
                    _muscleDataForLegacy(w, consumer: 'BibliotecaGrid');
                return BldrWorkoutCard(
                  title: w['name'] as String? ?? 'Treino',
                  subtitle: w['description'] as String?,
                  metaLeft: '${w['estimated_duration_minutes'] ?? 30} min',
                  metaRight: 'Nível ${w['difficulty_level'] ?? 1}',
                  muscles: mapData.muscles,
                  view: mapData.view,
                  onTap: () => _viewWorkoutDetails(w),
                  onStart: () => _startWorkout(w),
                );
              },
            ),
          )
        else
          BldrCarousel(
            itemWidth: 154,
            height: 258,
            children: list.map((w) {
              final mapData =
                  _muscleDataForLegacy(w, consumer: 'BibliotecaCarousel');
              return BldrWorkoutCard(
                title: w['name'] as String? ?? 'Treino',
                subtitle: w['description'] as String?,
                metaLeft: '${w['estimated_duration_minutes'] ?? 30} min',
                metaRight: AppLocalizations.of(context)
                    .workouts_difficulty_label(
                        ((w['difficulty_level'] as int?) ?? 1)),
                muscles: mapData.muscles,
                view: mapData.view,
                onTap: () => _viewWorkoutDetails(w),
                onStart: () => _startWorkout(w),
              );
            }).toList(),
          ),
      ],
    );
  }
}
