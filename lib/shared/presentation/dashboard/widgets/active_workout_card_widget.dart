import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/features/workouts/domain/usecases/week_plan_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/week_override.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/plan_day_type_resolver.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart'
    as uc;
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart'
    as clubUc;
import 'package:bldr_fitness/features/workouts/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/club_active_workout_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/active_workout_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/today_workout_state.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/weekly_plan_screen.dart';
import 'package:bldr_fitness/shared/providers/workout_session_provider.dart';

class ActiveWorkoutCardWidget extends StatefulWidget {
  final VoidCallback onStartPressed;

  const ActiveWorkoutCardWidget({
    Key? key,
    required this.onStartPressed,
  }) : super(key: key);

  @override
  State<ActiveWorkoutCardWidget> createState() =>
      _ActiveWorkoutCardWidgetState();
}

class _ActiveWorkoutCardWidgetState extends State<ActiveWorkoutCardWidget> {
  Map<String, dynamic>? activeWorkout;
  List<Map<String, dynamic>> pausedSummaries = [];
  bool isLoading = true;
  bool hasError = false;

  // L4 — treino de hoje vindo do plano gerado no onboarding, se houver
  // (OnboardingPlanStorage; ver ressalva de B8 sobre não ser fonte real
  // de plano semanal, só o resultado imediato do onboarding).
  Map<String, dynamic>? _todayTemplate;
  bool _startingToday = false;

  // Template de hoje com exercícios — grupos musculares, nº de exercícios e
  // duração estimada do card v2. Mesma busca da tela de Treinos
  // (GetTemplateWithExercises / GetClubTemplateWithExercises pelo id do plano).
  WorkoutTemplate? _todayDetails;

  // Home v2 — estados do card (Figma 57:386 / 57:385 / 57:380 / 57:379).
  /// Resumos de treinos não concluídos ANTES da deduplicação: incluem o
  /// treino ativo (a consulta de pausados devolve todo `is_completed=false`).
  List<PausedWorkoutSummary> _rawPaused = const [];

  /// `PlanDay.isRestDay` do dia de hoje.
  bool _todayIsRest = false;

  /// Detalhes (séries + exercícios) do treino em andamento — grupos
  /// musculares. Mesma busca usada pelo card concluído.
  WorkoutSession? _inProgressDetails;

  WorkoutSession? _completedToday; // não nulo → exibe card "concluído"

  @override
  void initState() {
    super.initState();
    _loadActiveWorkout();
  }

  Future<void> _loadActiveWorkout() async {
    // Captura o provider antes de qualquer await para evitar uso de context em async gap
    final sessionProvider =
        mounted ? context.read<WorkoutSessionProvider>() : null;
    try {
      if (!getIt<AuthRepository>().isAuthenticated) {
        if (mounted)
          setState(() {
            isLoading = false;
            hasError = false;
          });
        return;
      }

      final historyResult =
          await getIt<uc.GetWorkoutHistory>()(completedOnly: false, limit: 1);
      final completedHistoryResult =
          await getIt<clubUc.GetConsolidatedWorkoutHistory>()(
        completedOnly: true,
        limit: 10,
      );
      final pausedResult = await getIt<uc.GetPausedWorkouts>()(limit: 2);
      final pausedClubResult =
          await getIt<clubUc.GetPausedClubWorkouts>()(limit: 2);
      final rawPaused = <PausedWorkoutSummary>[
        ...pausedResult.valueOrNull ?? [],
        ...pausedClubResult.valueOrNull ?? [],
      ];
      // B8: lê o treino de hoje do Supabase (weekly_plan_days).
      // Filtra pelo dia da semana atual (1=seg … 7=dom).
      final planResult = await getIt<GetWeekPlan>()(WeekCalendar.weekStartFor(DateTime.now()));
      final planDays = planResult.valueOrNull ?? [];
      // Regra única do tipo do dia (mesma da WeeklyPlanScreen e do hub):
      // linha do plano decide; sem linha, rest_days; vazio, frequência.
      final config = (await getIt<uc.GetWeeklyPlanConfig>()()).valueOrNull;
      final todayIsRest = !PlanDayTypeResolver.trainingDays(
        plan: planDays,
        restDays: config?.restDays ?? const [],
        frequencyDays: config?.frequencyDays ?? 3,
      )[DateTime.now().weekday - 1];
      final todayWeekday = DateTime.now().weekday;
      final todayPlanDay =
          planDays.where((d) => d.diaSemana == todayWeekday).firstOrNull;
      // Descanso com template guardado não é treino do dia.
      final todayTemplate = (todayPlanDay?.treino?.id != null &&
              !todayPlanDay!.isRestDay)
          ? {
              'id': todayPlanDay.treino!.id!,
              'name': todayPlanDay.treino!.name,
              'source': todayPlanDay.treino!.source,
            }
          : null;

      final history = historyResult.valueOrNull;
      if (history == null) {
        throw Exception(historyResult.failureOrNull?.message);
      }
      final workouts = history.map(sessionToLegacyMap).toList();
      final paused = rawPaused.map(pausedToLegacyMap).toList();

      if (mounted) {
        final active =
            workouts.isNotEmpty && workouts.first['is_completed'] == false
                ? workouts.first
                : null;

        // Verifica se o treino mais recente foi concluído hoje.
        WorkoutSession? completedToday;
        final completedHistory = completedHistoryResult.valueOrNull ?? const [];
        if (active == null && completedHistory.isNotEmpty) {
          final completedForTodayTemplate = completedHistory.where((session) {
            final ct = session.completedAt?.toLocal();
            return ct != null &&
                ct.year == DateTime.now().year &&
                ct.month == DateTime.now().month &&
                ct.day == DateTime.now().day &&
                session.templateId == todayTemplate?['id'];
          }).firstOrNull;
          final ct = completedForTodayTemplate?.completedAt?.toLocal();
          final now = DateTime.now();
          if (ct != null &&
              ct.year == now.year &&
              ct.month == now.month &&
              ct.day == now.day) {
            completedToday = completedForTodayTemplate;
          }
        }

        // O histórico é intencionalmente leve. Para o card concluído, busca os
        // detalhes uma única vez para calcular séries e volume executados.
        if (completedToday?.id != null) {
          final detailsResult =
              await getIt<uc.GetWorkoutDetails>()(completedToday!.id!);
          completedToday = detailsResult.valueOrNull ?? completedToday;
        }

        if (!mounted) return;

        // Race condition: a session already picked up as activeWorkout may also
        // appear in pausedSummaries — remove the duplicate.
        final dedupedPaused = active == null
            ? paused
            : paused.where((p) => p['id'] != active['id']).toList();
        // Popula o mini-player global com o primeiro pausado (se houver)
        final firstPaused = rawPaused.isNotEmpty ? rawPaused.first : null;
        sessionProvider?.setPausedWorkout(firstPaused);

        setState(() {
          activeWorkout = active;
          pausedSummaries = dedupedPaused;
          _todayTemplate = todayTemplate;
          _rawPaused = rawPaused;
          _todayIsRest = todayIsRest;
          _completedToday = completedToday;
          isLoading = false;
          hasError = false;
        });
        _loadTodayDetails(todayTemplate);
        _loadInProgressDetails();
      }
    } catch (error) {
      debugPrint('Erro ao carregar treino ativo: $error');
      if (mounted)
        setState(() {
          isLoading = false;
          hasError = true;
        });
    }
  }

  /// Detalhes do treino de hoje para o card v2. Falha silenciosa: sem
  /// detalhes, as linhas de músculos/meta ficam vazias (altura preservada).
  Future<void> _loadTodayDetails(Map<String, dynamic>? today) async {
    final id = today?['id'] as String?;
    if (id == null) {
      if (mounted && _todayDetails != null) {
        setState(() => _todayDetails = null);
      }
      return;
    }
    final result = today!['source'] == 'club'
        ? await getIt<clubUc.GetClubTemplateWithExercises>()(id)
        : await getIt<uc.GetTemplateWithExercises>()(id);
    if (!mounted || _todayTemplate?['id'] != id) return;
    setState(() => _todayDetails = result.valueOrNull);
  }

  /// Treino não concluído mostrado no card v2: o ativo, senão o pausado
  /// mais recente (decisão aprovada: só um card na Home).
  ({String id, String name, String source, DateTime? startedAt})?
      get _unfinished {
    final active = activeWorkout;
    if (active != null) {
      final started = active['started_at'] as String?;
      return (
        id: active['id'] as String,
        name: active['name'] as String? ?? 'Treino',
        source: 'free',
        startedAt: started == null ? null : DateTime.parse(started),
      );
    }
    if (pausedSummaries.isEmpty) return null;
    final p = pausedSummaries.first;
    final started = p['started_at'];
    return (
      id: p['id'] as String,
      name: (p['name'] as String?) ?? 'Treino',
      source: (p['source'] as String?) ?? 'free',
      startedAt: started is DateTime
          ? started
          : (started is String ? DateTime.tryParse(started) : null),
    );
  }

  Future<void> _loadInProgressDetails() async {
    final u = _unfinished;
    if (u == null) return;
    final result = u.source == 'club'
        ? await getIt<clubUc.GetClubWorkoutDetails>()(u.id)
        : await getIt<uc.GetWorkoutDetails>()(u.id);
    if (!mounted || _unfinished?.id != u.id) return;
    setState(() => _inProgressDetails = result.valueOrNull);
  }

  Future<void> _openWeeklyPlan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WeeklyPlanScreen()),
    );
    if (mounted) _loadActiveWorkout();
  }

  Future<void> _startTodayTemplate() async {
    final template = _todayTemplate;
    if (template == null || _startingToday) return;
    setState(() => _startingToday = true);
    try {
      final name = template['name'] as String? ?? 'Treino';
      final templateId = template['id'] as String?;
      if (templateId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível iniciar o treino.'),
          backgroundColor: BldrColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      final isClub = template['source'] == 'club';
      final startResult = isClub
          ? await getIt<clubUc.StartClubWorkout>()(
              name: name,
              templateId: templateId,
            )
          : await getIt<uc.StartWorkout>()(
              name: name,
              templateId: templateId,
            );
      final session = startResult.valueOrNull;
      if (session?.id == null || !mounted) {
        final failure = startResult.failureOrNull;
        if (failure != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(failure.message),
            backgroundColor: BldrColors.danger,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => isClub
              ? ClubActiveWorkoutScreen(
                  workoutId: session!.id!,
                  workoutName: name,
                )
              : ActiveWorkoutScreen(
                  workoutId: session!.id!,
                  workoutName: name,
                ),
        ),
      );
      if (mounted) _loadActiveWorkout();
    } finally {
      if (mounted) setState(() => _startingToday = false);
    }
  }

  void _resumeWorkout(Map<String, dynamic> summary) {
    final id = summary['id'] as String;
    final name = (summary['name'] as String?) ?? 'Treino';
    final source = (summary['source'] as String?) ?? 'free';

    if (source == 'club') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubActiveWorkoutScreen(
            workoutId: id,
            workoutName: name,
          ),
        ),
      ).then((_) {
        if (mounted) _loadActiveWorkout();
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveWorkoutScreen(
            workoutId: id,
            workoutName: name,
          ),
        ),
      ).then((_) {
        if (mounted) _loadActiveWorkout();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCard();
    }

    if (hasError) {
      return _buildErrorCard();
    }

    if (!getIt<AuthRepository>().isAuthenticated) {
      return _buildUnauthenticatedCard();
    }

    final state = resolveTodayWorkoutState(
      hasUnfinishedWorkout: _unfinished != null,
      completedToday: _completedToday != null,
      hasTodayTemplate: _todayTemplate != null,
      todayIsRestDay: _todayIsRest,
    );
    return switch (state) {
      TodayWorkoutState.inProgress => _buildInProgressCardV2(),
      TodayWorkoutState.done => _buildDoneCardV2(_completedToday!),
      TodayWorkoutState.planned => _buildStartWorkoutCard(),
      TodayWorkoutState.rest => _buildRestCardV2(),
      TodayWorkoutState.noPlan => _buildNoPlanCardV2(),
    };
  }

  // ── Home v2 — casca comum dos estados ─────────────────────────────────

  Widget _v2Card({
    required String label,
    required String title,
    required String detail,
    String meta = '',
    Widget? cta,
    Widget? stats,
    Widget? corner,
  }) {
    final pageX = BldrSpacingV2.pageX(MediaQuery.sizeOf(context).width);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pageX),
      child: BldrTrainCardV2(
        label: label,
        title: title,
        detail: detail,
        meta: meta,
        cta: cta,
        stats: stats,
        corner: corner,
      ),
    );
  }

  /// Dia de descanso (57:386): CTA neutro "VER MEU PLANO ›".
  Widget _buildRestCardV2() {
    final l10n = AppLocalizations.of(context);
    return _v2Card(
      label: l10n.dashboard_v2_workout_today_label,
      title: l10n.dashboard_rest_title,
      detail: l10n.dashboard_rest_subtitle,
      meta: l10n.dashboard_rest_meta,
      cta: BldrOutlineCta(
        label: l10n.dashboard_rest_cta,
        variant: BldrCtaVariant.neutral,
        trailingChevron: true,
        onPressed: _openWeeklyPlan,
      ),
    );
  }

  /// Sem treino planejado (57:385): "CRIAR MEU PLANO ›" abre o editor do
  /// plano semanal (mesma tela de criar/editar).
  Widget _buildNoPlanCardV2() {
    final l10n = AppLocalizations.of(context);
    return _v2Card(
      label: l10n.dashboard_v2_workout_today_label,
      title: l10n.dashboard_noplan_title,
      detail: l10n.dashboard_noplan_subtitle,
      meta: l10n.dashboard_noplan_meta,
      cta: BldrOutlineCta(
        label: l10n.dashboard_noplan_cta,
        trailingChevron: true,
        onPressed: _openWeeklyPlan,
      ),
    );
  }

  /// Em andamento (57:380): exercícios feitos/total e tempo decorrido.
  /// "RETOMAR" usa a ação de retomar existente. Arrastar para a esquerda
  /// descarta, com a confirmação atual.
  Widget _buildInProgressCardV2() {
    final l10n = AppLocalizations.of(context);
    final u = _unfinished!;
    final summary = _rawPaused.where((p) => p.id == u.id).firstOrNull;
    final details = _inProgressDetails;
    final meta = [
      if (summary != null && summary.totalExercises > 0)
        l10n.dashboard_v2_exercises_progress(
            summary.completedExercises, summary.totalExercises),
      if (u.startedAt != null) HomeV2Format.elapsed(u.startedAt!, DateTime.now()),
    ].join('    ·    ');

    final card = _v2Card(
      label: l10n.dashboard_v2_in_progress_label,
      title: u.name,
      detail: details == null ? '' : HomeV2Format.muscleGroupsFromSession(details),
      meta: meta,
      cta: BldrOutlineCta(
        label: l10n.dashboard_v2_resume_cta,
        onPressed: () => _resumeWorkout({
          'id': u.id,
          'name': u.name,
          'source': u.source,
        }),
      ),
    );

    return Dismissible(
      key: ValueKey('in_progress_${u.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _confirmAndDelete(u.id, u.source);
        return false;
      },
      background: const SizedBox.shrink(),
      child: card,
    );
  }

  /// Concluído (57:379): sem CTA, check duplo verde e três métricas.
  Widget _buildDoneCardV2(WorkoutSession session) {
    final l10n = AppLocalizations.of(context);
    final via = session.completedViaWhoop;
    final muscles = HomeV2Format.muscleGroupsFromSession(session);
    final sets = session.completedSetCount;
    return _v2Card(
      label: l10n.dashboard_v2_done_label,
      title: session.templateName ?? session.name,
      detail: via && muscles.isEmpty ? l10n.dashboard_v2_done_via_whoop : muscles,
      corner: SvgPicture.asset('assets/images/v2/icons/done_checks.svg',
          width: 24, height: 24),
      stats: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BldrDoneStatV2(
            icon: 'assets/images/v2/icons/done_stopwatch.svg',
            value: HomeV2Format.doneDuration(session.totalDurationSeconds ?? 0),
            label: l10n.dashboard_v2_done_duration,
          ),
          const SizedBox(width: 17),
          BldrDoneStatV2(
            icon: 'assets/images/v2/icons/done_barbell.svg',
            value: via && sets == 0 ? '—' : '$sets',
            label: l10n.dashboard_v2_done_sets,
          ),
          const SizedBox(width: 17),
          BldrDoneStatV2(
            icon: 'assets/images/v2/icons/done_weight.svg',
            value: HomeV2Format.volume(session.completedVolumeKg),
            label: l10n.dashboard_v2_done_volume,
          ),
        ],
      ),
    );
  }

  /// D4 — placeholder do hero enquanto carrega. Mesma família visual do card
  /// final (BldrHeroCard), altura equivalente — nunca uma tela vazia.
  Widget _buildLoadingCard() {
    return Padding(
      padding: BldrSpacing.pageInsets,
      child: BldrHeroCard(
        cornerGlow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).dashboard_workout_today_title,
                style: BldrText.label),
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context).common_loading,
                style: BldrText.kpiMd),
            const SizedBox(height: BldrSpacing.padCard),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: BldrColors.goldBright, strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'warning',
                  color: AppTheme.warningAmber,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .dashboard_workout_load_error_title,
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)
                          .dashboard_workout_load_error_body,
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadActiveWorkout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentGold,
                side: BorderSide(color: AppTheme.accentGold, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: 3.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: AppTheme.accentGold,
                size: 4.w,
              ),
              label: Text(
                AppLocalizations.of(context).common_retry,
                style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'fitness_center',
                  color: AppTheme.accentGold,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).dashboard_welcome_title,
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).dashboard_welcome_subtitle,
                      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.loginScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: AppTheme.primaryBlack,
                padding: EdgeInsets.symmetric(vertical: 4.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: CustomIconWidget(
                iconName: 'login',
                color: AppTheme.primaryBlack,
                size: 5.w,
              ),
              label: Text(
                AppLocalizations.of(context).dashboard_login_btn,
                style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// D4 — card hero "Treino de hoje" com botão primário interno.
  ///
  /// Quando o onboarding gerou um plano e hoje tem treino nele (L4), mostra
  /// o nome real do treino em vez do texto genérico e inicia direto esse
  /// template.
  /// Treino de hoje — estado PLANEJADO no visual v2 (Figma 57:387, dentro
  /// do frame base 57:388). Card 386 × 189 só com borda, glow no canto
  /// superior direito e CTA com borda.
  Widget _buildStartWorkoutCard() {
    final l10n = AppLocalizations.of(context);
    final today = _todayTemplate;
    final details = _todayDetails;

    final String title;
    final String muscles;
    final String meta;
    if (today != null) {
      title = today['name'] as String? ?? 'Treino';
      muscles = details == null ? '' : HomeV2Format.muscleGroups(details);
      final count = details?.exercises.length ?? 0;
      final minutes = details?.estimatedDurationMinutes ?? 0;
      meta = [
        if (count > 0) l10n.dashboard_v2_exercises_count(count),
        if (minutes > 0) l10n.dashboard_v2_workout_duration(minutes),
      ].join('    ·    ');
    } else {
      // Sem plano (node 57:385, próxima etapa): textos atuais no layout v2.
      title = l10n.dashboard_workout_ready;
      muscles = l10n.dashboard_workout_next_session;
      meta = '';
    }

    return _v2Card(
      label: l10n.dashboard_v2_workout_today_label,
      title: title,
      detail: muscles,
      meta: meta,
      cta: BldrOutlineCta(
        label: l10n.dashboard_v2_start_workout_cta,
        onPressed: today != null
            ? (_startingToday ? null : _startTodayTemplate)
            : widget.onStartPressed,
      ),
    );
  }

  Future<void> _confirmAndDelete(String workoutId, String source) async {
    final dl = AppLocalizations.of(context);
    final confirmed = await BldrV2ConfirmDialog.show(
      context,
      title: dl.dashboard_delete_paused_title,
      message: dl.dashboard_delete_paused_body,
      cancelLabel: dl.common_cancel,
      confirmLabel: dl.dashboard_delete_btn,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => pausedSummaries.removeWhere((w) => w['id'] == workoutId));
    final result = await getIt<uc.DeletePausedWorkout>()(workoutId, source);
    if (result.isFailure && mounted) _loadActiveWorkout();
  }
}
