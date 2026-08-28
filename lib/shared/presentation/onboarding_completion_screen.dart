import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:bldr_fitness/features/onboarding/presentation/onboarding_plan_storage.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

const List<String> _kWeekDayNames = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

enum _Phase { generating, result, fallback }

class OnboardingCompletionScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;

  const OnboardingCompletionScreen({super.key, this.onboardingData = const {}});

  @override
  State<OnboardingCompletionScreen> createState() =>
      _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState extends State<OnboardingCompletionScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.generating;
  int _stepIndex = 0;
  int _regenerateCount = 0;
  static const _maxRegenerate = 2;

  OnboardingPlan? _plan;
  WorkoutTemplate? _fallbackTemplate;

  late final AnimationController _spinCtrl;

  String get _objetivo => (widget.onboardingData['main_goal'] as String?) ?? 'Equilíbrio';
  int get _frequencia => (widget.onboardingData['workout_frequency_days'] as int?) ?? 3;
  String get _equipamentos =>
      (widget.onboardingData['workout_environment'] as String?) ?? 'Academia completa';
  String get _split =>
      (widget.onboardingData['split_preference'] as String?) ?? 'Full body';

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _runSteps();
    _generate();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSteps() async {
    if (!mounted) return;
    setState(() => _stepIndex = 1);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _stepIndex = 2);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _stepIndex = 3);
  }

  Future<void> _generate() async {
    Result<OnboardingPlan>? result;
    try {
      result = await getIt<GenerateOnboardingPlan>()(widget.onboardingData)
          .timeout(const Duration(seconds: 55));
    } on TimeoutException {
      if (mounted) await _loadFallback();
      return;
    } catch (_) {
      if (mounted) await _loadFallback();
      return;
    }

    final plan = result.valueOrNull;

    if (!mounted) return;

    if (plan == null) {
      await _loadFallback();
      return;
    }

    await _saveTodayTemplates(plan);
    setState(() {
      _plan = plan;
      _stepIndex = 4;
      _phase = _Phase.result;
    });
  }

  Future<void> _saveTodayTemplates(OnboardingPlan plan) async {
    final byWeekday = <int, Map<String, String>>{};
    for (final day in plan.plano) {
      final t = day.treino;
      debugPrint('[PLANO] dia ${day.diaSemana}: tipo=${day.tipo} templateId=${t?.id} templateName=${t?.name}');
      if (t?.id != null) {
        byWeekday[day.diaSemana] = {'id': t!.id!, 'name': t.name};
      }
    }
    await OnboardingPlanStorage.saveTemplatesByWeekday(byWeekday);
    debugPrint('[PLANO] salvando plano semanal (${plan.plano.length} dias)');
    final saveResult = await getIt<SaveWeeklyPlan>()(plan.plano);
    final failure = saveResult.failureOrNull;
    if (failure != null) {
      debugPrint('[PLANO] ERRO ao salvar plano semanal: ${failure.message}');
    } else {
      debugPrint('[PLANO] plano semanal salvo com sucesso');
    }
  }

  Future<void> _loadFallback() async {
    final result = await getIt<GetWorkoutTemplates>()(publicOnly: true);
    final templates = result.valueOrNull ?? const [];
    if (!mounted) return;
    setState(() {
      _fallbackTemplate = templates.isNotEmpty ? templates.first : null;
      _phase = _Phase.fallback;
    });
  }

  Future<void> _regenerate() async {
    if (_regenerateCount >= _maxRegenerate) return;
    _regenerateCount++;

    final previous = _plan;
    setState(() {
      _phase = _Phase.generating;
      _stepIndex = 4;
      _plan = null;
    });

    if (previous != null) {
      for (final day in previous.plano) {
        final id = day.treino?.id;
        if (id != null) {
          await getIt<DeleteWorkoutTemplate>()(id);
        }
      }
    }

    await _generate();
  }

  void _finish() {
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      body: BldrBackground(
        child: SafeArea(
          child: switch (_phase) {
            _Phase.generating => _buildGenerating(),
            _Phase.result => _buildResult(_plan!, isFallback: false),
            _Phase.fallback => _buildFallback(),
          },
        ),
      ),
    );
  }

  Widget _buildGenerating() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _spinCtrl,
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: const AlwaysStoppedAnimation(BldrColors.goldBright),
                      backgroundColor: BldrColors.border,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: ClipOval(child: _PantheraIcon()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('HAVOK',
              style: TextStyle(
                  color: BldrColors.goldBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6)),
          const SizedBox(height: 10),
          Text(l10n.onboarding_completion_generating_title,
              textAlign: TextAlign.center, style: BldrText.screenTitle),
          const SizedBox(height: 8),
          Text(
            l10n.onboarding_completion_generating_body,
            textAlign: TextAlign.center,
            style: BldrText.description,
          ),
          const SizedBox(height: 32),
          _buildStep(0, 'Objetivo: $_objetivo'),
          _buildStep(1, '$_frequencia dias por semana · $_equipamentos'),
          _buildStep(2, 'Distribuindo $_split'),
          _buildStep(3, 'Ajustando volume e metas'),
        ],
      ),
    );
  }

  Widget _buildStep(int index, String label) {
    final state = _stepIndex > index
        ? _StepState.done
        : _stepIndex == index
            ? _StepState.active
            : _StepState.pending;

    Widget icon;
    Color color;
    double opacity = 1;
    switch (state) {
      case _StepState.pending:
        icon = const Icon(TablerIcons.circle, size: 20, color: BldrColors.textMuted);
        color = BldrColors.textMuted;
        opacity = 0.3;
        break;
      case _StepState.active:
        color = BldrColors.goldBright;
        icon = index == 2
            ? RotationTransition(
                turns: _spinCtrl,
                child: const Icon(TablerIcons.loader_2, size: 20, color: BldrColors.goldBright),
              )
            : const Icon(TablerIcons.circle_check, size: 20, color: BldrColors.goldBright);
        break;
      case _StepState.done:
        icon = const Icon(TablerIcons.circle_check_filled,
            size: 20, color: BldrColors.goldBright);
        color = BldrColors.goldBright;
        break;
    }

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 20, height: 20, child: icon),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: BldrText.body.copyWith(color: color))),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(OnboardingPlan plan, {required bool isFallback}) {
    final l10n = AppLocalizations.of(context);
    final today = plan.today;
    final canRegenerate = _regenerateCount < _maxRegenerate;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboarding_completion_ready_title, style: BldrText.screenTitle),
          const SizedBox(height: 4),
          Text(plan.resumo.isNotEmpty ? plan.resumo : l10n.onboarding_completion_plan_fallback_desc,
              style: BldrText.description),
          const SizedBox(height: 20),

          BldrGlassCard(
            background: BldrColors.goldTintStrong,
            borderColor: BldrColors.goldBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.onboarding_completion_starts_today_label,
                    style: BldrText.label.copyWith(color: BldrColors.goldBright)),
                const SizedBox(height: 6),
                Text(
                  today == null
                      ? l10n.onboarding_rest_day
                      : (today.isRestDay ? l10n.onboarding_rest_day : (today.treino?.name ?? 'Treino')),
                  style: BldrText.cardTitleLg,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...plan.plano.map((d) => _WorkoutDayCard(day: d)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: BldrGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.onboarding_calorie_goal_label, style: BldrText.label),
                      const SizedBox(height: 4),
                      Text('${plan.metaCalorica} kcal', style: BldrText.kpiMd),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BldrGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.onboarding_protein_label, style: BldrText.label),
                      const SizedBox(height: 4),
                      Text('${plan.metaProteina}g', style: BldrText.kpiMd),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(l10n.onboarding_completion_adjust_hint, style: BldrText.meta),
          const SizedBox(height: 24),

          BldrPrimaryButton(label: l10n.common_start_btn, onPressed: _finish),
          if (canRegenerate && !isFallback) ...[
            const SizedBox(height: 10),
            BldrSecondaryButton(label: l10n.onboarding_completion_regenerate_btn, onPressed: _regenerate),
          ],
        ],
      ),
    );
  }

  Widget _buildFallback() {
    final l10n = AppLocalizations.of(context);
    final t = _fallbackTemplate;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(TablerIcons.mood_confuzed, color: BldrColors.goldBright, size: 40),
          const SizedBox(height: 16),
          Text(
            l10n.onboarding_completion_fallback_title,
            textAlign: TextAlign.center,
            style: BldrText.screenTitle,
          ),
          const SizedBox(height: 8),
          Text(
            t != null
                ? l10n.onboarding_completion_fallback_body_with_plan
                : l10n.onboarding_completion_fallback_body_no_plan,
            textAlign: TextAlign.center,
            style: BldrText.description,
          ),
          if (t != null) ...[
            const SizedBox(height: 20),
            BldrGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.onboarding_completion_today_workout_label, style: BldrText.label),
                  const SizedBox(height: 6),
                  Text(t.name, style: BldrText.cardTitleLg),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          BldrPrimaryButton(label: l10n.common_continue_btn, onPressed: _finish),
        ],
      ),
    );
  }
}

enum _StepState { pending, active, done }

/// Card por dia da semana com lista colapsável de exercícios.
class _WorkoutDayCard extends StatefulWidget {
  final PlanDay day;
  const _WorkoutDayCard({required this.day});

  @override
  State<_WorkoutDayCard> createState() => _WorkoutDayCardState();
}

class _WorkoutDayCardState extends State<_WorkoutDayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = widget.day;
    final dayName = _kWeekDayNames[(d.diaSemana - 1).clamp(0, 6)];
    final exercises = d.treino?.exercises ?? const [];
    final isRest = d.isRestDay || exercises.isEmpty && d.treino == null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        onTap: isRest ? null : () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: BldrColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isRest
                  ? BldrColors.border
                  : _expanded
                      ? BldrColors.goldBorder
                      : BldrColors.border,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 78,
                      child: Text(dayName, style: BldrText.meta),
                    ),
                    Expanded(
                      child: Text(
                        isRest
                            ? l10n.onboarding_rest_day
                            : (d.treino?.name ?? 'Treino'),
                        style: isRest
                            ? BldrText.meta
                            : BldrText.body.copyWith(color: BldrColors.goldBright),
                      ),
                    ),
                    if (!isRest)
                      Icon(
                        _expanded
                            ? TablerIcons.chevron_up
                            : TablerIcons.chevron_down,
                        size: 16,
                        color: BldrColors.textMuted,
                      ),
                    if (isRest)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: BldrColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Descanso',
                            style: BldrText.meta.copyWith(fontSize: 11)),
                      ),
                  ],
                ),
              ),
              if (_expanded && exercises.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Column(
                    children: exercises.map((ex) {
                      final name = ex.freeName ?? ex.exercise?.name ?? 'Exercício';
                      final sets = ex.sets;
                      final reps = ex.reps;
                      final repsLabel = reps != null ? '$sets×$reps' : '${sets}s';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const SizedBox(width: 4),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: BldrColors.goldBright,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(name,
                                  style: BldrText.meta
                                      .copyWith(color: BldrColors.textPrimary)),
                            ),
                            Text(repsLabel,
                                style: BldrText.meta
                                    .copyWith(color: BldrColors.goldBright)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PantheraIcon extends StatelessWidget {
  const _PantheraIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/havoknew.png', fit: BoxFit.cover);
  }
}
