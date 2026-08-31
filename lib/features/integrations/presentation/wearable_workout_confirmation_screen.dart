import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/achievements/domain/usecases/achievement_usecases.dart';
import 'package:bldr_fitness/features/integrations/data/widget_data_service.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/external_workout_activity.dart';
import 'package:bldr_fitness/features/integrations/domain/usecases/wearable_activity_usecases.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/routes/app_routes.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class WearableWorkoutConfirmationScreen extends StatefulWidget {
  final String activityId;

  const WearableWorkoutConfirmationScreen({
    super.key,
    required this.activityId,
  });

  @override
  State<WearableWorkoutConfirmationScreen> createState() =>
      _WearableWorkoutConfirmationScreenState();
}

class _WearableWorkoutConfirmationScreenState
    extends State<WearableWorkoutConfirmationScreen> {
  ExternalWorkoutActivity? _activity;
  PlanDay? _assignedDay;
  bool _loading = true;
  bool _confirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final activityResult =
        await getIt<GetWearableActivity>()(widget.activityId);
    final activity = activityResult.valueOrNull;
    if (activity == null ||
        !const {'pending', 'processing'}.contains(activity.status)) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = activity == null
            ? activityResult.failureOrNull?.message ??
                'Atividade não encontrada ou já indisponível.'
            : 'Essa atividade já foi processada.';
      });
      return;
    }

    final planResult = await getIt<GetWeeklyPlan>()();
    PlanDay? assigned;
    for (final day in planResult.valueOrNull ?? const <PlanDay>[]) {
      if (day.diaSemana == activity.startedAt.toLocal().weekday &&
          day.treino != null) {
        assigned = day;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _activity = activity;
      _assignedDay = assigned;
      _loading = false;
    });
  }

  Future<void> _confirm({required bool useAssignedWorkout}) async {
    final activity = _activity;
    if (activity == null || _confirming) return;
    setState(() {
      _confirming = true;
      _error = null;
    });

    final template = useAssignedWorkout ? _assignedDay?.treino : null;
    final requestedSource = template?.source == 'club' ? 'club' : 'free';
    final preparedResult = await getIt<PrepareWearableWorkout>()(
      activityId: activity.id,
      templateId: template?.id,
      source: requestedSource,
    );
    final prepared = preparedResult.valueOrNull;
    if (prepared == null) {
      return _showFailure(preparedResult.failureOrNull?.message);
    }

    final completionResult = await getIt<CompleteWorkoutWithAnalytics>()(
      workoutId: prepared.workoutId,
      source: prepared.source,
      setsCompleted: 0,
      exerciseCount: 0,
      notes: useAssignedWorkout
          ? 'Atividade ${activity.provider.toUpperCase()} vinculada ao treino planejado, sem execução detalhada de exercícios.'
          : 'Atividade externa registrada via ${activity.provider.toUpperCase()}.',
    );
    if (completionResult.isFailure) {
      return _showFailure(completionResult.failureOrNull?.message);
    }

    final confirmedResult = await getIt<ConfirmWearableActivity>()(activity.id);
    if (confirmedResult.isFailure) {
      return _showFailure(confirmedResult.failureOrNull?.message);
    }

    unawaited(getIt<CheckAndUnlockAchievements>()('workout'));
    unawaited(WidgetDataService.updateAll());
    if (!mounted) return;
    final xp = completionResult.valueOrNull?.xpEarned ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          xp > 0
              ? '${useAssignedWorkout ? 'Atividade vinculada' : 'Atividade registrada'}. Você ganhou $xp XP.'
              : useAssignedWorkout
                  ? 'Atividade vinculada e semana atualizada.'
                  : 'Atividade registrada e semana atualizada.',
        ),
      ),
    );
    Navigator.pushReplacementNamed(context, AppRoutes.workoutsScreen);
  }

  Future<void> _dismiss() async {
    final activity = _activity;
    if (activity == null || _confirming) return;
    setState(() => _confirming = true);
    final result = await getIt<DismissWearableActivity>()(activity.id);
    if (!mounted) return;
    if (result.isFailure) {
      return _showFailure(result.failureOrNull?.message);
    }
    Navigator.pop(context);
  }

  void _showFailure(String? message) {
    if (!mounted) return;
    setState(() {
      _confirming = false;
      _error = message ?? 'Não foi possível confirmar o treino.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Treino detectado', style: BldrText.screenTitle),
      ),
      body: BldrBackground(
        child: SafeArea(
          top: false,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: BldrColors.goldBright,
                  ),
                )
              : _activity == null
                  ? _buildLoadError()
                  : _buildConfirmation(),
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BldrSpacing.pageX),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(TablerIcons.alert_circle,
                size: 42, color: BldrColors.textSecondary),
            const SizedBox(height: 12),
            Text(_error ?? 'Atividade indisponível.',
                style: BldrText.body, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation() {
    final activity = _activity!;
    final duration = activity.durationSeconds == null
        ? '—'
        : '${activity.durationSeconds! ~/ 60} min';
    return ListView(
      padding: const EdgeInsets.all(BldrSpacing.pageX),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0x1F0093E7),
            border: Border.all(color: const Color(0x660093E7)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/whoop/whoop_puck_white.png',
                    width: 30,
                    height: 30,
                  ),
                  const Spacer(),
                  Text('IMPORTED FROM', style: BldrText.metaSm),
                ],
              ),
              const SizedBox(height: 18),
              Text(activity.activityType, style: BldrText.sectionTitle),
              const SizedBox(height: 16),
              Row(
                children: [
                  _metric('DURAÇÃO', duration),
                  _metric('STRAIN', activity.strain?.toStringAsFixed(1) ?? '—'),
                  _metric(
                    'FC MÉD.',
                    activity.averageHeartRate == null
                        ? '—'
                        : '${activity.averageHeartRate} bpm',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Image.asset(
                'assets/images/whoop/whoop_logo_white.png',
                width: 100,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_assignedDay?.treino != null) ...[
          Text('Treino planejado para esse dia', style: BldrText.sectionTitle),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BldrColors.surface,
              border: Border.all(color: BldrColors.goldBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(TablerIcons.barbell, color: BldrColors.goldBright),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_assignedDay!.treino!.name,
                      style: BldrText.cardTitle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BldrColors.surface,
              border: Border.all(color: BldrColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  TablerIcons.info_circle,
                  size: 18,
                  color: BldrColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A WHOOP não informa exercícios, séries ou cargas. Vincular marca o treino planejado como concluído, sem registrar execução detalhada, volume ou novos PRs.',
                    style: BldrText.description,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _primaryButton(
            'Vincular ao treino planejado',
            () => _confirm(useAssignedWorkout: true),
          ),
          const SizedBox(height: 10),
          _secondaryButton(
            'Registrar somente como atividade externa',
            () => _confirm(useAssignedWorkout: false),
          ),
        ] else ...[
          Text(
            'Não encontramos um treino planejado para esse dia. A atividade pode ser registrada como treino externo.',
            style: BldrText.description,
          ),
          const SizedBox(height: 16),
          _primaryButton(
            'Registrar atividade',
            () => _confirm(useAssignedWorkout: false),
          ),
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: _confirming ? null : _dismiss,
          child: const Text('Ignorar atividade'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: BldrText.description.copyWith(color: BldrColors.danger),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: BldrText.kpiSm),
          const SizedBox(height: 3),
          Text(label, style: BldrText.label),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _confirming ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: BldrColors.goldSolid,
          foregroundColor: BldrColors.bgBase,
          minimumSize: const Size.fromHeight(50),
        ),
        child: Text(_confirming ? 'Confirmando…' : label),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _confirming ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: BldrColors.textPrimary,
          side: const BorderSide(color: BldrColors.border),
          minimumSize: const Size.fromHeight(50),
        ),
        child: Text(label),
      ),
    );
  }
}
