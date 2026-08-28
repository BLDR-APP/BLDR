import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_provider.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/shared/presentation/onboarding_completion_screen.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

// ---------------------------------------------------------------------------
// OnboardingFlow — 9-step redesign
// ---------------------------------------------------------------------------
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;
  static const int _totalSteps = 9;
  bool _isCompleting = false;

  final TextEditingController _injuryOtherController = TextEditingController();

  final Map<String, dynamic> _responses = {
    'gender': '',
    'age': 25.0,
    'height': 175.0,
    'weight': 70.0,
    'activity_level': '',
    'regular_activities': <String>[],
    'activity_details': <String, Map<String, dynamic>>{},
    'body_fat_image': '',
    'main_goal': '',
    'goal_pace': '',
    'experience_level': '',
    'injuries': <String>['Nenhuma lesão atual'],
    'injury_other_text': '',
    'workout_frequency_days': 3,
    'workout_duration_range': '',
    'workout_environment': '',
    'home_equipment': <String>[],
    'muscle_focus': <String>[],
    'split_preference': 'Deixa a HAVOK decidir',
  };

  // ── data ──────────────────────────────────────────────────────────────────

  final List<Map<String, String>> _activityLevelOptions = [
    {'title': 'Sedentário', 'subtitle': 'Trabalho em escritório, pouco movimento'},
    {'title': 'Levemente Ativo', 'subtitle': 'Caminhadas leves, atividades casuais'},
    {'title': 'Ativo', 'subtitle': 'Movimento frequente ao longo do dia'},
    {'title': 'Muito Ativo', 'subtitle': 'Trabalho físico ou sempre em movimento'},
  ];

  final List<String> _mainGoalOptions = ['Perder Gordura', 'Manter o Peso', 'Ganhar Massa Muscular'];
  final Map<String, String> _mainGoalSubtitles = {
    'Perder Gordura': 'Reduzir % de gordura corporal',
    'Manter o Peso': 'Preservar o peso e a composição atual',
    'Ganhar Massa Muscular': 'Aumentar volume e força muscular',
  };

  final List<String> _paceOptions = ['Leve', 'Moderado', 'Agressivo'];
  final Map<String, String> _paceSubtitles = {
    'Leve': 'Progressão gradual, mais fácil de manter',
    'Moderado': 'Equilíbrio entre resultado e esforço',
    'Agressivo': 'Resultados mais rápidos, exige mais disciplina',
  };

  final List<String> _experienceLevels = [
    'Iniciante (0-6 meses)',
    'Intermediário (6 meses - 2 anos)',
    'Avançado (Mais de 2 anos)',
  ];
  final Map<String, String> _experienceSubtitles = {
    'Iniciante (0-6 meses)': 'Ainda aprendendo os movimentos básicos',
    'Intermediário (6 meses - 2 anos)': 'Execução consistente, buscando evolução',
    'Avançado (Mais de 2 anos)': 'Treino periodizado, alto nível de performance',
  };

  final List<String> _workoutDurationOptions = ['30-45 min', '45-60 min', '60-90 min', '90+ min'];

  final List<String> _workoutEnvironmentOptions = [
    'Academia Completa',
    'Casa com Equipamentos',
    'Apenas Peso Corporal',
  ];

  final List<String> _homeEquipmentOptions = [
    'Halteres', 'Kettlebell', 'Elásticos', 'Barra de Pull-up', 'Banco', 'Outro',
  ];

  final List<String> _regularActivitiesOptions = [
    'Musculação', 'Crossfit', 'Corrida', 'Ciclismo', 'Futebol', 'Natação', 'Outro',
  ];

  // Simplified muscle groups → IDs stored in muscle_focus
  static const List<Map<String, dynamic>> _muscleChipGroups = [
    {'label': 'Peito',       'ids': ['chest']},
    {'label': 'Costas',      'ids': ['lats', 'upper_back']},
    {'label': 'Ombros',      'ids': ['shoulder']},
    {'label': 'Bíceps',      'ids': ['biceps']},
    {'label': 'Tríceps',     'ids': ['triceps']},
    {'label': 'Abdômen',     'ids': ['abs', 'obliques']},
    {'label': 'Quadríceps',  'ids': ['quads']},
    {'label': 'Posteriores', 'ids': ['harmstrings']},
    {'label': 'Glúteos',     'ids': ['glutes']},
    {'label': 'Lombar',      'ids': ['lower_back']},
    {'label': 'Panturrilhas','ids': ['calves']},
    {'label': 'Antebraço',   'ids': ['forearm']},
  ];

  final List<String> _injuryOptions = [
    'Ombro / Rotador',
    'Joelho',
    'Lombar / Coluna',
    'Quadril',
    'Cotovelo / Pulso',
    'Tornozelo / Pé',
    'Outro',
    'Nenhuma lesão atual',
  ];

  final List<String> _splitPreferenceOptions = [
    'Deixa a HAVOK decidir',
    'Full Body',
    'Upper/Lower',
    'Push/Pull/Legs',
    'ABCDE',
  ];
  final Map<String, String> _splitSubtitles = {
    'Deixa a HAVOK decidir': 'Recomendado para melhores resultados',
    'Full Body': 'Todos os grupos em cada sessão',
    'Upper/Lower': 'Alterna entre superior e inferior',
    'Push/Pull/Legs': 'Divide por padrão de movimento',
    'ABCDE': 'Um grupo muscular por sessão',
  };

  final Map<String, String> _muscleTranslation = {
    'chest': 'Peito',
    'lats': 'Dorsais',
    'upper_back': 'Costas Sup.',
    'shoulder': 'Ombros',
    'biceps': 'Bíceps',
    'triceps': 'Tríceps',
    'forearm': 'Antebraço',
    'abs': 'Abdômen',
    'obliques': 'Oblíquos',
    'glutes': 'Glúteos',
    'quads': 'Quadríceps',
    'harmstrings': 'Posteriores',
    'calves': 'Panturrilhas',
    'lower_back': 'Lombar',
    'adductors': 'Adutores',
    'abductor': 'Abdutores',
    'trapezius': 'Trapézio',
  };

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _injuryOtherController.dispose();
    super.dispose();
  }

  // ── navigation ─────────────────────────────────────────────────────────────

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep = _currentStep + 1);
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep = _currentStep - 1);
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: return true;
      case 1:
        final goal = _responses['main_goal'] as String;
        if (goal.isEmpty) return false;
        if (goal == 'Manter o Peso') return true;
        return (_responses['goal_pace'] as String).isNotEmpty;
      case 2: return (_responses['gender'] as String).isNotEmpty;
      case 3: return (_responses['activity_level'] as String).isNotEmpty;
      case 4:
        return (_responses['experience_level'] as String).isNotEmpty &&
            (_responses['workout_duration_range'] as String).isNotEmpty;
      case 5:
        final env = _responses['workout_environment'] as String;
        if (env.isEmpty) return false;
        if (env == 'Casa com Equipamentos') {
          return (_responses['home_equipment'] as List<String>).isNotEmpty;
        }
        return true;
      case 6:
        return (_responses['regular_activities'] as List<String>).isNotEmpty &&
            (_responses['muscle_focus'] as List<String>).isNotEmpty;
      case 7: return true;
      case 8: return true;
      default: return true;
    }
  }

  // ── nutrition calc ─────────────────────────────────────────────────────────

  Map<String, String> _calculateNutritionPlan() {
    try {
      final double w = (_responses['weight'] as num).toDouble();
      final double h = (_responses['height'] as num).toDouble();
      final double a = (_responses['age'] as num).toDouble();
      final String g = _responses['gender'] as String;
      final String al = _responses['activity_level'] as String;
      final String mg = _responses['main_goal'] as String;
      final String gp = _responses['goal_pace'] as String;

      if (w <= 0 || h <= 0 || a <= 0 || g.isEmpty || al.isEmpty || mg.isEmpty) {
        return {'error': 'Dados insuficientes.'};
      }

      final double bmr = g == 'Masculino'
          ? 88.362 + (13.397 * w) + (4.799 * h) - (5.677 * a)
          : 447.593 + (9.247 * w) + (3.098 * h) - (4.330 * a);

      double neat = 1.2;
      if (al == 'Levemente Ativo') neat = 1.375;
      else if (al == 'Ativo') neat = 1.55;
      else if (al == 'Muito Ativo') neat = 1.725;

      double tdee = bmr * neat;
      double targetC = tdee;

      if (mg == 'Perder Gordura') {
        if (gp == 'Leve') targetC -= 250;
        else if (gp == 'Moderado') targetC -= 500;
        else if (gp == 'Agressivo') targetC -= 750;
      } else if (mg == 'Ganhar Massa Muscular') {
        if (gp == 'Leve') targetC += 200;
        else if (gp == 'Moderado') targetC += 350;
        else if (gp == 'Agressivo') targetC += 500;
      }

      final double pG = w * 2.0;
      final double pK = pG * 4;
      final double fG = w * 0.8;
      final double fK = fG * 9;
      final double cK = targetC - pK - fK;
      final double cG = (cK / 4).clamp(0, double.infinity);
      final double hL = (w * 40) / 1000;

      return {
        'tdee': tdee.round().toString(),
        'targetCalories': targetC.round().toString(),
        'hydration': hL.toStringAsFixed(1),
        'protein': pG.round().toString(),
        'carbs': cG.round().toString(),
        'fat': fG.round().toString(),
      };
    } catch (_) {
      return {'error': 'Erro ao calcular.'};
    }
  }

  // ── complete ───────────────────────────────────────────────────────────────

  void _completeOnboarding() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      final sb = Supabase.instance.client;
      final user = sb.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');
      if (user.email == null) throw Exception('Email do usuário não disponível.');

      final plan = _calculateNutritionPlan();
      if (plan.containsKey('error')) throw Exception('Erro ao calcular plano: ${plan['error']}');

      final Map<String, dynamic> finalResponses = Map<String, dynamic>.from(_responses);
      finalResponses['onboarding_version'] = kCurrentOnboardingVersion;
      finalResponses['target_calories'] = int.tryParse(plan['targetCalories'] ?? '0') ?? 0;
      finalResponses['target_protein'] = int.tryParse(plan['protein'] ?? '0') ?? 0;
      finalResponses['target_carbs'] = int.tryParse(plan['carbs'] ?? '0') ?? 0;
      finalResponses['target_fat'] = int.tryParse(plan['fat'] ?? '0') ?? 0;
      finalResponses['target_hydration_liters'] = double.tryParse(plan['hydration'] ?? '0.0') ?? 0.0;
      finalResponses['calculated_tdee'] = int.tryParse(plan['tdee'] ?? '0') ?? 0;

      await sb.from('user_profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'Usuário',
        'onboarding_data': finalResponses,
        'onboarding_completed': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');

      if (mounted) {
        context.read<AchievementProvider>().checkAchievements('onboarding');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                OnboardingCompletionScreen(onboardingData: finalResponses),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.onboarding_completion_error(error.toString())),
          backgroundColor: AppTheme.errorRed,
          action: SnackBarAction(
            label: l10n.common_retry,
            textColor: BldrColors.goldBright,
            onPressed: _completeOnboarding,
          ),
        ));
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentStep > 0) {
      _previousStep();
      return false;
    }
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            final dialogL10n = AppLocalizations.of(context);
            return AlertDialog(
              backgroundColor: AppTheme.dialogDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(dialogL10n.onboarding_exit_dialog_title,
                  style: TextStyle(color: BldrColors.textPrimary, fontFamily: BldrText.family, fontWeight: FontWeight.w500)),
              content: Text(dialogL10n.onboarding_exit_dialog_body,
                  style: TextStyle(color: BldrColors.textSecondary, fontFamily: BldrText.family)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(dialogL10n.common_continue_btn, style: TextStyle(color: BldrColors.goldBright)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(dialogL10n.onboarding_exit_dialog_exit_btn, style: TextStyle(color: BldrColors.danger)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: BldrBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildProgressBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                        child: child,
                      ),
                    ),
                    child: SingleChildScrollView(
                      key: ValueKey(_currentStep),
                      padding: const EdgeInsets.symmetric(
                          horizontal: BldrSpacing.pageX, vertical: BldrSpacing.gapSection),
                      child: _buildCurrentStep(),
                    ),
                  ),
                ),
                _buildNavRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / _totalSteps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 16, BldrSpacing.pageX, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).onboarding_step_indicator(_currentStep + 1, _totalSteps),
                style: BldrText.meta,
              ),
              Text(
                '${(progress * 100).round()}%',
                style: BldrText.meta.copyWith(color: BldrColors.goldBright),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(BldrRadius.bar),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: BldrColors.border,
              valueColor: const AlwaysStoppedAnimation(BldrColors.goldBright),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow() {
    final isLast = _currentStep == _totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 8, BldrSpacing.pageX, 20),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            _BackButton(onTap: _previousStep),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: BldrPrimaryButton(
              label: isLast ? AppLocalizations.of(context).common_finish_btn : AppLocalizations.of(context).common_continue_btn,
              onPressed: _canProceedToNextStep()
                  ? (isLast ? _completeOnboarding : _nextStep)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildWelcomeStep();
      case 1: return _buildGoalStep();
      case 2: return _buildProfileStep();
      case 3: return _buildActivityLevelStep();
      case 4: return _buildWorkoutConfigStep();
      case 5: return _buildEnvironmentStep();
      case 6: return _buildActivitiesAndMusclesStep();
      case 7: return _buildSplitAndInjuriesStep();
      case 8: return _buildSummaryStep();
      default: return const SizedBox.shrink();
    }
  }

  // ── Step 0 – Welcome ───────────────────────────────────────────────────────

  Widget _buildWelcomeStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: BldrColors.goldTint,
              borderRadius: BorderRadius.circular(BldrRadius.iconBox),
              border: Border.all(color: BldrColors.goldBorder),
            ),
            child: const Icon(Icons.bolt, size: 40, color: BldrColors.goldBright),
          ),
        ),
        const SizedBox(height: 28),
        Text(l10n.onboarding_welcome_title, style: BldrText.screenTitle),
        const SizedBox(height: 8),
        Text(l10n.onboarding_welcome_body, style: BldrText.description),
        const SizedBox(height: 32),
        BldrGlassCard(
          padding: const EdgeInsets.all(BldrSpacing.padCard),
          child: Column(
            children: [
              _BulletItem(icon: Icons.local_fire_department_outlined,
                  text: l10n.onboarding_welcome_bullet_nutrition),
              const SizedBox(height: 14),
              _BulletItem(icon: Icons.fitness_center,
                  text: l10n.onboarding_welcome_bullet_workout),
              const SizedBox(height: 14),
              _BulletItem(icon: Icons.trending_up,
                  text: l10n.onboarding_welcome_bullet_adjustments),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.onboarding_welcome_duration_hint,
          style: BldrText.meta,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Step 1 – Goal + Pace ───────────────────────────────────────────────────

  Widget _buildGoalStep() {
    final l10n = AppLocalizations.of(context);
    final goal = _responses['main_goal'] as String;
    final showPace = goal.isNotEmpty && goal != 'Manter o Peso';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboarding_goal_title, style: BldrText.screenTitle),
        const SizedBox(height: 6),
        Text(l10n.onboarding_goal_body, style: BldrText.description),
        const SizedBox(height: 24),
        ..._mainGoalOptions.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: BldrSpacing.gapCard),
              child: _OptionCard(
                label: opt,
                subtitle: _mainGoalSubtitles[opt],
                isSelected: goal == opt,
                onTap: () => setState(() {
                  _responses['main_goal'] = opt;
                  _responses['goal_pace'] = '';
                }),
              ),
            )),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: showPace
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(l10n.onboarding_pace_title, style: BldrText.sectionTitle),
                    const SizedBox(height: 6),
                    Text(l10n.onboarding_pace_body, style: BldrText.description),
                    const SizedBox(height: 16),
                    ..._paceOptions.map((opt) => Padding(
                          padding: const EdgeInsets.only(bottom: BldrSpacing.gapCard),
                          child: _OptionCard(
                            label: opt,
                            subtitle: _paceSubtitles[opt],
                            isSelected: _responses['goal_pace'] == opt,
                            onTap: () => setState(() => _responses['goal_pace'] = opt),
                          ),
                        )),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Step 2 – Profile ───────────────────────────────────────────────────────

  Widget _buildProfileStep() {
    final l10n = AppLocalizations.of(context);
    final age = (_responses['age'] as num).toDouble();
    final height = (_responses['height'] as num).toDouble();
    final weight = (_responses['weight'] as num).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboarding_profile_title, style: BldrText.screenTitle),
        const SizedBox(height: 6),
        Text(l10n.onboarding_profile_body, style: BldrText.description),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _GenderCard(
                label: 'Masculino',
                icon: Icons.male_rounded,
                isSelected: _responses['gender'] == 'Masculino',
                onTap: () => setState(() => _responses['gender'] = 'Masculino'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderCard(
                label: 'Feminino',
                icon: Icons.female_rounded,
                isSelected: _responses['gender'] == 'Feminino',
                onTap: () => setState(() => _responses['gender'] = 'Feminino'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        BldrGlassCard(
          padding: const EdgeInsets.all(BldrSpacing.padCard),
          child: Column(
            children: [
              _SliderRow(
                label: l10n.onboarding_profile_age,
                value: age,
                min: 10,
                max: 80,
                divisions: 70,
                display: '${age.round()} anos',
                onChanged: (v) => setState(() => _responses['age'] = v),
              ),
              const _Divider(),
              _SliderRow(
                label: l10n.onboarding_profile_height,
                value: height,
                min: 140,
                max: 220,
                divisions: 80,
                display: '${height.round()} cm',
                onChanged: (v) => setState(() => _responses['height'] = v),
              ),
              const _Divider(),
              _SliderRow(
                label: l10n.onboarding_profile_weight,
                value: weight,
                min: 30,
                max: 200,
                divisions: 340,
                display: '${weight.toStringAsFixed(1)} kg',
                onChanged: (v) => setState(
                    () => _responses['weight'] = (v * 2).round() / 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 3 – Activity Level ────────────────────────────────────────────────

  Widget _buildActivityLevelStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboarding_activity_title, style: BldrText.screenTitle),
        const SizedBox(height: 6),
        Text(l10n.onboarding_activity_body, style: BldrText.description),
        const SizedBox(height: 24),
        ..._activityLevelOptions.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: BldrSpacing.gapCard),
              child: _OptionCard(
                label: o['title']!,
                subtitle: o['subtitle']!,
                isSelected: _responses['activity_level'] == o['title'],
                onTap: () => setState(() => _responses['activity_level'] = o['title']!),
              ),
            )),
      ],
    );
  }

  // ── Step 4 – Workout Config ────────────────────────────────────────────────

  Widget _buildWorkoutConfigStep() {
    final l10n = AppLocalizations.of(context);
    final freqDays = (_responses['workout_frequency_days'] as int);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboarding_workout_config_title, style: BldrText.screenTitle),
        const SizedBox(height: 6),
        Text(l10n.onboarding_workout_config_body, style: BldrText.description),
        const SizedBox(height: 24),
        Text(l10n.onboarding_experience_section_title, style: BldrText.sectionTitle),
        const SizedBox(height: 12),
        ..._experienceLevels.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: BldrSpacing.gapCard),
              child: _OptionCard(
                label: opt,
                subtitle: _experienceSubtitles[opt],
                isSelected: _responses['experience_level'] == opt,
                onTap: () => setState(() => _responses['experience_level'] = opt),
              ),
            )),
        const SizedBox(height: 20),
        BldrGlassCard(
          padding: const EdgeInsets.all(BldrSpacing.padCard),
          child: _SliderRow(
            label: l10n.onboarding_freq_days_label,
            value: freqDays.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            display: '$freqDays dias',
            onChanged: (v) => setState(() => _responses['workout_frequency_days'] = v.round()),
          ),
        ),
        const SizedBox(height: 20),
        Text(l10n.onboarding_duration_section_title, style: BldrText.sectionTitle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _workoutDurationOptions.map((opt) => BldrChip(
                label: opt,
                active: _responses['workout_duration_range'] == opt,
                onTap: () => setState(() => _responses['workout_duration_range'] = opt),
              )).toList(),
        ),
      ],
    );
  }

  // ── Step 5 – Environment + Equipment ──────────────────────────────────────

  Widget _buildEnvironmentStep() {
    final l10n = AppLocalizations.of(context);
    final env = _responses['workout_environment'] as String;
    final showEquipment = env == 'Casa com Equipamentos';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboarding_environment_title, style: BldrText.screenTitle),
        const SizedBox(height: 6),
        Text(l10n.onboarding_environment_body, style: BldrText.description),
        const SizedBox(height: 24),
        ..._workoutEnvironmentOptions.map((opt) {
          final icons = <String, IconData>{
            'Academia Completa': Icons.fitness_center,
            'Casa com Equipamentos': Icons.home_outlined,
            'Apenas Peso Corporal': Icons.accessibility_new_outlined,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: BldrSpacing.gapCard),
            child: _OptionCard(
              label: opt,
              icon: icons[opt],
              isSelected: env == opt,
              onTap: () => setState(() {
                _responses['workout_environment'] = opt;
                _responses['home_equipment'] = <String>[];
              }),
            ),
          );
        }),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: showEquipment
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(l10n.onboarding_equipment_title, style: BldrText.sectionTitle),
                    const SizedBox(height: 6),
                    Text(l10n.onboarding_equipment_body, style: BldrText.description),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _homeEquipmentOptions.map((opt) {
                        final equipment = _responses['home_equipment'] as List<String>;
                        return BldrChip(
                          label: opt,
                          active: equipment.contains(opt),
                          onTap: () => setState(() {
                            if (equipment.contains(opt)) {
                              equipment.remove(opt);
                            } else {
                              equipment.add(opt);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Step 6 – Activities + Muscles ─────────────────────────────────────────

  Widget _buildActivitiesAndMusclesStep() {
    final l10n = AppLocalizations.of(context);
    final acts = _responses['regular_activities'] as List<String>;
    final muscleFocus = _responses['muscle_focus'] as List<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboarding_activities_title, style: BldrText.screenTitle),
        const SizedBox(height: 6),
        Text(l10n.onboarding_activities_body, style: BldrText.description),
        const SizedBox(height: 24),
        Text(l10n.onboarding_activities_section_title, style: BldrText.sectionTitle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _regularActivitiesOptions.map((opt) => BldrChip(
                label: opt,
                active: acts.contains(opt),
                onTap: () => setState(() {
                  if (acts.contains(opt)) acts.remove(opt);
                  else acts.add(opt);
                }),
              )).toList(),
        ),
        const SizedBox(height: 24),
        Text(l10n.onboarding_muscles_section_title, style: BldrText.sectionTitle),
        const SizedBox(height: 6),
        Text(l10n.onboarding_muscles_body, style: BldrText.description),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _muscleChipGroups.map((group) {
            final ids = (group['ids'] as List).cast<String>();
            final isActive = ids.any((id) => muscleFocus.contains(id));
            return BldrChip(
              label: group['label'] as String,
              active: isActive,
              onTap: () => setState(() {
                if (isActive) {
                  for (final id in ids) muscleFocus.remove(id);
                } else {
                  for (final id in ids) {
                    if (!muscleFocus.contains(id)) muscleFocus.add(id);
                  }
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 7 – Split + Injuries ──────────────────────────────────────────────

  Widget _buildSplitAndInjuriesStep() {
    final l10n = AppLocalizations.of(context);
    final injuries = _responses['injuries'] as List<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboarding_split_injuries_title, style: BldrText.screenTitle),
        const SizedBox(height: 6),
        Text(l10n.onboarding_split_injuries_body, style: BldrText.description),
        const SizedBox(height: 24),
        Text(l10n.onboarding_split_section_title, style: BldrText.sectionTitle),
        const SizedBox(height: 6),
        Text(l10n.onboarding_split_body, style: BldrText.description),
        const SizedBox(height: 12),
        ..._splitPreferenceOptions.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: BldrSpacing.gapCard),
              child: _OptionCard(
                label: opt,
                subtitle: _splitSubtitles[opt],
                isSelected: _responses['split_preference'] == opt,
                onTap: () => setState(() => _responses['split_preference'] = opt),
              ),
            )),
        const SizedBox(height: 24),
        Text(l10n.onboarding_injuries_section_title, style: BldrText.sectionTitle),
        const SizedBox(height: 6),
        Text(l10n.onboarding_injuries_body, style: BldrText.description),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _injuryOptions.map((opt) {
            final isNenhuma = opt == 'Nenhuma lesão atual';
            final isSelected = injuries.contains(opt);
            return BldrChip(
              label: opt,
              active: isSelected,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isNenhuma) {
                    injuries.clear();
                    injuries.add('Nenhuma lesão atual');
                  } else {
                    injuries.remove('Nenhuma lesão atual');
                    if (isSelected) {
                      injuries.remove(opt);
                      if (injuries.isEmpty) injuries.add('Nenhuma lesão atual');
                    } else {
                      injuries.add(opt);
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
        if (injuries.contains('Outro')) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _injuryOtherController,
            style: BldrText.body,
            decoration: InputDecoration(
              hintText: l10n.onboarding_injury_other_hint,
              hintStyle: BldrText.description,
              filled: true,
              fillColor: BldrColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BldrRadius.input),
                borderSide: const BorderSide(color: BldrColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BldrRadius.input),
                borderSide: const BorderSide(color: BldrColors.goldBright, width: 1.5),
              ),
            ),
            onChanged: (v) => _responses['injury_other_text'] = v,
          ),
        ],
      ],
    );
  }

  // ── Step 8 – Summary ───────────────────────────────────────────────────────

  Widget _buildSummaryStep() {
    final l10n = AppLocalizations.of(context);
    final plan = _calculateNutritionPlan();
    final hasError = plan.containsKey('error');

    final muscleIds = (_responses['muscle_focus'] as List).cast<String>();
    final seenBases = <String>{};
    final uniqueMuscles = <String>[];
    for (final id in muscleIds) {
      if (seenBases.contains(id)) continue;
      seenBases.add(id);
      uniqueMuscles.add(_muscleTranslation[id] ?? id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboarding_summary_title, style: BldrText.screenTitle),
        const SizedBox(height: 6),
        Text(l10n.onboarding_summary_body, style: BldrText.description),
        const SizedBox(height: 24),
        if (!hasError) ...[
          BldrGlassCard(
            padding: const EdgeInsets.all(BldrSpacing.padCard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_outlined,
                        color: BldrColors.goldBright, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.onboarding_summary_nutrition_section, style: BldrText.sectionTitle),
                    const Spacer(),
                    GestureDetector(
                      onTap: _showTDEEInfo,
                      child: const Icon(Icons.info_outline,
                          color: BldrColors.goldBright, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.onboarding_summary_tdee(plan['tdee']!), style: BldrText.meta),
                const SizedBox(height: 16),
                _SummaryStatRow(label: l10n.onboarding_calorie_goal_label,
                    value: '${plan['targetCalories']} kcal'),
                _SummaryStatRow(label: l10n.onboarding_protein_label, value: '${plan['protein']}g'),
                _SummaryStatRow(label: l10n.onboarding_summary_carbs_label, value: '${plan['carbs']}g'),
                _SummaryStatRow(label: l10n.onboarding_summary_fat_label, value: '${plan['fat']}g'),
                _SummaryStatRow(label: l10n.onboarding_summary_hydration_label, value: '${plan['hydration']}L'),
              ],
            ),
          ),
        ] else ...[
          BldrGlassCard(
            padding: const EdgeInsets.all(BldrSpacing.padCard),
            child: Text(plan['error']!, style: BldrText.description),
          ),
        ],
        const SizedBox(height: BldrSpacing.gapCard),
        BldrGlassCard(
          padding: const EdgeInsets.all(BldrSpacing.padCard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.fitness_center, color: BldrColors.goldBright, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.onboarding_summary_workout_section, style: BldrText.sectionTitle),
                ],
              ),
              const SizedBox(height: 16),
              _SummaryStatRow(label: l10n.onboarding_summary_goal_label, value: _responses['main_goal'] as String),
              _SummaryStatRow(label: l10n.onboarding_summary_level_label,
                  value: (_responses['experience_level'] as String).split(' ').first),
              _SummaryStatRow(label: l10n.onboarding_summary_frequency_label,
                  value: '${_responses['workout_frequency_days']}x/semana'),
              _SummaryStatRow(label: l10n.onboarding_summary_duration_label, value: _responses['workout_duration_range'] as String),
              _SummaryStatRow(label: l10n.onboarding_summary_environment_label, value: _responses['workout_environment'] as String),
              _SummaryStatRow(label: l10n.onboarding_summary_split_label, value: _responses['split_preference'] as String),
              if (uniqueMuscles.isNotEmpty)
                _SummaryStatRow(label: l10n.onboarding_summary_focus_label, value: uniqueMuscles.take(4).join(', ')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboarding_summary_confirm_hint,
          style: BldrText.meta,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showTDEEInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final sheetL10n = AppLocalizations.of(context);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.info_outline, color: BldrColors.goldBright),
                const SizedBox(width: 8),
                Text(sheetL10n.onboarding_tdee_info_title, style: BldrText.sectionTitle),
              ]),
              const SizedBox(height: 12),
              Text(
                sheetL10n.onboarding_tdee_info_body,
                style: BldrText.description,
              ),
              const SizedBox(height: 24),
              BldrPrimaryButton(
                label: sheetL10n.common_got_it_btn,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared local widgets ───────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: BldrColors.surface,
          borderRadius: BorderRadius.circular(BldrRadius.button),
          border: Border.all(color: BldrColors.border),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: BldrColors.textSecondary),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    this.subtitle,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: BldrSpacing.padCard, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? BldrColors.goldTintChip : BldrColors.surface,
          borderRadius: BorderRadius.circular(BldrRadius.card),
          border: Border.all(
            color: isSelected ? BldrColors.goldBorderChip : BldrColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: isSelected ? BldrColors.goldBright : BldrColors.textSecondary, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: BldrText.cardTitle.copyWith(
                      color: isSelected ? BldrColors.goldBright : BldrColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: BldrText.description),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? BldrColors.goldBright : Colors.transparent,
                border: Border.all(
                  color: isSelected ? BldrColors.goldBright : BldrColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 13, color: Color(0xFF0A0A0A))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? BldrColors.goldTintChip : BldrColors.surface,
          borderRadius: BorderRadius.circular(BldrRadius.card),
          border: Border.all(
            color: isSelected ? BldrColors.goldBorderChip : BldrColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36,
                color: isSelected ? BldrColors.goldBright : BldrColors.textSecondary),
            const SizedBox(height: 8),
            Text(label,
                style: BldrText.cardTitle.copyWith(
                    color: isSelected ? BldrColors.goldBright : BldrColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: BldrText.body),
            Text(display,
                style: BldrText.kpiSm.copyWith(color: BldrColors.goldBright)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: BldrColors.goldBright,
            inactiveTrackColor: BldrColors.border,
            thumbColor: BldrColors.goldBright,
            overlayColor: BldrColors.goldTint,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: BldrColors.border, height: 1),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BulletItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: BldrColors.goldTint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: BldrColors.goldBright),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: BldrText.body)),
      ],
    );
  }
}

class _SummaryStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: BldrText.description),
          Flexible(
            child: Text(value,
                style: BldrText.body.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
