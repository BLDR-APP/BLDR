import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart' as uc;
import 'package:bldr_fitness/features/workouts/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/widgets/continue_workout_card.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_provider.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/club_active_workout_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/active_workout_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
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
  Map<String, String>? _todayTemplate;
  bool _startingToday = false;

  WorkoutSession? _completedToday; // não nulo → exibe card "concluído"

  @override
  void initState() {
    super.initState();
    _loadActiveWorkout();
  }

  Future<void> _loadActiveWorkout() async {
    // Captura o provider antes de qualquer await para evitar uso de context em async gap
    final sessionProvider = mounted ? context.read<WorkoutSessionProvider>() : null;
    try {
      if (!getIt<AuthRepository>().isAuthenticated) {
        if (mounted) setState(() { isLoading = false; hasError = false; });
        return;
      }

      final historyResult =
          await getIt<uc.GetWorkoutHistory>()(completedOnly: false, limit: 1);
      final pausedResult = await getIt<uc.GetPausedWorkouts>()(limit: 2);
      final rawPaused = pausedResult.valueOrNull ?? [];
      // B8: lê o treino de hoje do Supabase (weekly_plan_days).
      // Filtra pelo dia da semana atual (1=seg … 7=dom).
      final planResult = await getIt<uc.GetWeeklyPlan>()();
      final planDays = planResult.valueOrNull ?? [];
      final todayWeekday = DateTime.now().weekday;
      final todayPlanDay = planDays.where((d) => d.diaSemana == todayWeekday).firstOrNull;
      final todayTemplate = (todayPlanDay?.treino?.id != null)
          ? {'id': todayPlanDay!.treino!.id!, 'name': todayPlanDay.treino!.name}
          : null;

      final history = historyResult.valueOrNull;
      if (history == null) {
        throw Exception(historyResult.failureOrNull?.message);
      }
      final workouts = history.map(sessionToLegacyMap).toList();
      final paused = rawPaused.map(pausedToLegacyMap).toList();

      if (mounted) {
        final active = workouts.isNotEmpty &&
                workouts.first['is_completed'] == false
            ? workouts.first
            : null;

        // Verifica se o treino mais recente foi concluído hoje.
        WorkoutSession? completedToday;
        if (active == null && history.isNotEmpty && history.first.isCompleted) {
          final ct = history.first.completedAt?.toLocal();
          final now = DateTime.now();
          if (ct != null &&
              ct.year == now.year &&
              ct.month == now.month &&
              ct.day == now.day) {
            completedToday = history.first;
          }
        }

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
          _completedToday = completedToday;
          isLoading = false;
          hasError = false;
        });
      }
    } catch (error) {
      debugPrint('Erro ao carregar treino ativo: $error');
      if (mounted) setState(() { isLoading = false; hasError = true; });
    }
  }

  Future<void> _startTodayTemplate() async {
    final template = _todayTemplate;
    if (template == null || _startingToday) return;
    setState(() => _startingToday = true);
    try {
      final startResult = await getIt<uc.StartWorkout>()(
        name: template['name'] ?? 'Treino',
        templateId: template['id'],
      );
      final session = startResult.valueOrNull;
      if (session?.id == null || !mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveWorkoutScreen(
            workoutId: session!.id!,
            workoutName: template['name'] ?? 'Treino',
          ),
        ),
      );
      if (mounted) _loadActiveWorkout();
    } finally {
      if (mounted) setState(() => _startingToday = false);
    }
  }

  void _resumeWorkout(Map<String, dynamic> summary) {
    final id     = summary['id'] as String;
    final name   = (summary['name'] as String?) ?? 'Treino';
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
      ).then((_) { if (mounted) _loadActiveWorkout(); });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveWorkoutScreen(
            workoutId: id,
            workoutName: name,
          ),
        ),
      ).then((_) { if (mounted) _loadActiveWorkout(); });
    }
  }

  String _formatDuration(DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
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

    // If there are paused workouts, show "Continuar" cards
    if (pausedSummaries.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Text(
              AppLocalizations.of(context).dashboard_continue_workout_label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          ...pausedSummaries.map((s) {
                final workoutId = s['id'] as String;
                final source = (s['source'] as String?) ?? 'free';
                return Padding(
                  padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 1.2.h),
                  child: Dismissible(
                    key: ValueKey('paused_dash_$workoutId'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      await _confirmAndDelete(workoutId, source);
                      // _confirmAndDelete already handles setState; tell
                      // Dismissible not to animate removal itself.
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC84040),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 24),
                    ),
                    child: ContinueWorkoutCard(
                      summary: s,
                      onResume: () => _resumeWorkout(s),
                      onDiscard: () => _confirmAndDelete(workoutId, source),
                    ),
                  ),
                );
              }),
        ],
      );
    }

    if (_completedToday != null) return _buildDoneCard(_completedToday!);

    return activeWorkout != null
        ? _buildActiveWorkoutCard()
        : _buildStartWorkoutCard();
  }

  Widget _buildDoneCard(WorkoutSession session) {
    final durSeconds = session.totalDurationSeconds ?? 0;
    final durMin = durSeconds ~/ 60;
    final durH = durMin ~/ 60;
    final durLabel = durH > 0
        ? '${durH}h ${durMin % 60}min'
        : '${durMin}min';

    final completedSets = session.sets.where((s) => s.isCompleted).toList();
    final setsCount = completedSets.length;
    final volumeKg = completedSets.fold<double>(
      0,
      (acc, s) => acc + ((s.reps ?? 0) * (s.weightKg ?? 0)),
    );

    final completedAtLabel = () {
      final ct = session.completedAt?.toLocal();
      if (ct == null) return '';
      final h = ct.hour.toString().padLeft(2, '0');
      final m = ct.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }();

    return Padding(
      padding: BldrSpacing.pageInsets,
      child: BldrHeroCard(
        cornerGlow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppTheme.successGreen, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).dashboard_workout_today_title,
                  style: BldrText.label,
                ),
                if (completedAtLabel.isNotEmpty) ...[
                  const Spacer(),
                  Text(completedAtLabel, style: BldrText.meta),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              session.templateName ?? session.name,
              style: BldrText.kpiMd,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).dashboard_workout_done_label,
              style: BldrText.meta.copyWith(color: AppTheme.successGreen),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DoneStat(
                  icon: Icons.timer_outlined,
                  value: durLabel,
                  label: AppLocalizations.of(context).dashboard_done_duration_label,
                ),
                _DoneStat(
                  icon: Icons.fitness_center_rounded,
                  value: '$setsCount',
                  label: AppLocalizations.of(context).dashboard_done_sets_label,
                ),
                if (volumeKg > 0)
                  _DoneStat(
                    icon: Icons.scale_rounded,
                    value: volumeKg >= 1000
                        ? '${(volumeKg / 1000).toStringAsFixed(1)}t'
                        : '${volumeKg.toStringAsFixed(0)}kg',
                    label: AppLocalizations.of(context).dashboard_done_volume_label,
                  ),
              ],
            ),
          ],
        ),
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
            Text(AppLocalizations.of(context).dashboard_workout_today_title, style: BldrText.label),
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context).common_loading, style: BldrText.kpiMd),
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
                      AppLocalizations.of(context).dashboard_workout_load_error_title,
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).dashboard_workout_load_error_body,
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

  Widget _buildActiveWorkoutCard() {
    final workout = activeWorkout!;
    final startTime = DateTime.parse(workout['started_at']);
    final workoutName = workout['name'] as String? ?? 'Workout';
    final templateName = workout['workout_templates'] != null
        ? workout['workout_templates']['name'] as String?
        : null;

    return Padding(
      padding: BldrSpacing.pageInsets,
      child: BldrHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).dashboard_workout_in_progress, style: BldrText.label),
          const SizedBox(height: 6),
          // Dinâmico: nome real da sessão.
          Text(
            workoutName,
            style: BldrText.kpiMd,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // G10 — título curto + detalhe no subtítulo.
          if (templateName != null) ...[
            const SizedBox(height: 4),
            Text(
              templateName,
              style: BldrText.meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),

          // Duração corrente da sessão.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined,
                  color: BldrColors.goldBright, size: 15),
              const SizedBox(width: 6),
              Text(_formatDuration(startTime), style: BldrText.meta),
            ],
          ),
          const SizedBox(height: BldrSpacing.padCard),

          // Action Buttons
          Row(
            children: [
              // Expanded(
              //   child: OutlinedButton.icon(
              //     onPressed: () {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         SnackBar(
              //           content: Text('Resume workout feature coming soon'),
              //           backgroundColor: AppTheme.warningAmber,
              //           behavior: SnackBarBehavior.floating,
              //         ),
              //       );
              //     },
              //     style: OutlinedButton.styleFrom(
              //       foregroundColor: AppTheme.accentGold,
              //       side: BorderSide(color: AppTheme.accentGold, width: 1.5),
              //       padding: EdgeInsets.symmetric(vertical: 3.w),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //     ),
              //     icon: CustomIconWidget(
              //       iconName: 'play_arrow',
              //       color: AppTheme.accentGold,
              //       size: 4.w,
              //     ),
              //     label: Text(
              //       'Resumir',
              //       style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
              //         color: AppTheme.accentGold,
              //         fontWeight: FontWeight.w600,
              //       ),
              //     ),
              //   ),
              // ),
              // SizedBox(width: 3.w),
              // G4 — verde eliminado; ação principal em dourado.
              Expanded(
                child: BldrPrimaryButton(
                  label: AppLocalizations.of(context).dashboard_finish_workout_btn,
                  icon: Icons.check_rounded,
                  onPressed: _showCompleteWorkoutDialog,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  /// D4 — card hero "Treino de hoje" com botão primário interno.
  ///
  /// Quando o onboarding gerou um plano e hoje tem treino nele (L4), mostra
  /// o nome real do treino em vez do texto genérico e inicia direto esse
  /// template.
  Widget _buildStartWorkoutCard() {
    final today = _todayTemplate;
    return Padding(
      padding: BldrSpacing.pageInsets,
      child: BldrHeroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).dashboard_workout_today_title, style: BldrText.label),
            const SizedBox(height: 6),
            Text(today != null ? (today['name'] ?? 'Treino') : AppLocalizations.of(context).dashboard_workout_ready,
                style: BldrText.kpiMd),
            const SizedBox(height: 4),
            Text(today != null ? AppLocalizations.of(context).dashboard_workout_havok_generated : AppLocalizations.of(context).dashboard_workout_next_session,
                style: BldrText.meta),
            const SizedBox(height: BldrSpacing.padCard),
            BldrPrimaryButton(
              label: AppLocalizations.of(context).dashboard_workout_start_btn,
              icon: Icons.play_arrow_rounded,
              onPressed: today != null
                  ? (_startingToday ? null : _startTodayTemplate)
                  : widget.onStartPressed,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(String workoutId, String source) async {
    final dl = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1916),
          title: Text(l.dashboard_delete_paused_title,
              style: const TextStyle(color: Colors.white)),
          content: Text(l.dashboard_delete_paused_body,
              style: const TextStyle(color: Color(0xFF888070))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.common_cancel,
                  style: const TextStyle(color: Color(0xFF888070))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dl.dashboard_delete_btn,
                  style: const TextStyle(color: Color(0xFFC84040))),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() =>
        pausedSummaries.removeWhere((w) => w['id'] == workoutId));
    final result =
        await getIt<uc.DeletePausedWorkout>()(workoutId, source);
    if (result.isFailure && mounted) _loadActiveWorkout();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  void _showCompleteWorkoutDialog() {
    final stateContext = context;
    showDialog(
      context: stateContext,
      builder: (dialogContext) {
        final dl = AppLocalizations.of(dialogContext);
        return AlertDialog(
        backgroundColor: AppTheme.dialogDark,
        title: Text(
          dl.dashboard_finish_workout_dialog_title,
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          dl.dashboard_finish_workout_dialog_body,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
            Text(dl.common_cancel, style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                final result = await getIt<uc.CompleteWorkout>()(
                  workoutId: activeWorkout!['id'],
                );
                final failure = result.failureOrNull;
                if (failure != null) throw Exception(failure.message);

                // Verificar conquistas desbloqueadas pelo treino concluído
                if (mounted) {
                  await stateContext
                      .read<AchievementProvider>()
                      .checkAchievements('workout');
                }

                if (mounted) {
                  ScaffoldMessenger.of(stateContext).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(stateContext).dashboard_workout_completed_success),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }

                // Refresh the card
                _loadActiveWorkout();
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(stateContext).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(stateContext).dashboard_finish_workout_error(error.toString())),
                      backgroundColor: AppTheme.errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: AppTheme.textPrimary,
            ),
            child: Text(dl.dashboard_complete_workout_btn),
          ),
        ],
      );},
    );
  }
}
class _DoneStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _DoneStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: BldrColors.goldBright, size: 16),
        const SizedBox(height: 4),
        Text(value,
            style: BldrText.meta
                .copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label, style: BldrText.meta),
      ],
    );
  }
}
