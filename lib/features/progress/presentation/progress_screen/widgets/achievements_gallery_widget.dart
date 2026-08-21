import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/widgets/achievement_badge.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/achievements/domain/usecases/achievement_usecases.dart';
import 'package:bldr_fitness/features/achievements/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// PG5 — [F] Alguns contadores (ex.: "Guerreiro Consistente — 26/10")
/// aparecem pendentes mesmo com critério cumprido. Causa raiz documentada em
/// BACKLOG_FUNCIONAL.md item B2 (trigger em código morto + backfill que roda
/// uma vez por instalação) — não é bug de apresentação, fora de escopo aqui.
class AchievementsGalleryWidget extends StatefulWidget {
  const AchievementsGalleryWidget({Key? key}) : super(key: key);

  @override
  State<AchievementsGalleryWidget> createState() =>
      _AchievementsGalleryWidgetState();
}

class _AchievementsGalleryWidgetState extends State<AchievementsGalleryWidget> {
  List<Map<String, dynamic>> _catalog        = [];
  Set<String>                _unlockedNames  = {};
  Map<String, dynamic>       _workoutContext = {};
  bool                       _isLoading      = true;

  List<(String, String)> _localizedCategories(AppLocalizations l10n) => [
    ('primeiros_passos', l10n.achievements_category_first_steps),
    ('workout',          l10n.achievements_category_workouts),
    ('strength',         l10n.achievements_category_strength),
    ('milestone',        l10n.achievements_category_milestones),
    ('nutrition',        l10n.achievements_category_nutrition),
    ('bldr_club',        'BLDR CLUB'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = getIt<AuthRepository>().currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final catalogResult  = await getIt<GetAchievementCatalog>()();
      final unlockedResult = await getIt<GetUserAchievements>()(userId);
      final contextResult  =
          await getIt<GetWorkoutAchievementContext>()(userId);

      final catalog = (catalogResult.valueOrNull ?? [])
          .map(achievementToLegacyMap)
          .toList();
      final unlocked = unlockedResult.valueOrNull ?? [];
      final workoutContext = contextResult.valueOrNull ?? <String, dynamic>{};
      if (mounted) {
        setState(() {
          _catalog        = catalog;
          _unlockedNames  = unlocked.map((a) => a.achievementName).toSet();
          _workoutContext = workoutContext;
          _isLoading      = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isUnlocked(Map<String, dynamic> a) =>
      _unlockedNames.contains(a['name'] as String);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: BldrColors.goldBright),
      );
    }

    final total    = _catalog.length;
    final unlocked = _unlockedNames.length;
    final progress = total > 0 ? unlocked / total : 0.0;

    final l10n = AppLocalizations.of(context)!;
    final categories = _localizedCategories(l10n);
    // Retorna Column (sem scroll próprio) para funcionar dentro do ListView
    // da tela de Progresso. O refresh é feito pelo pai.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(l10n, unlocked, total, progress),
        const SizedBox(height: 22),
        ...categories.map((cat) {
          final items = _catalog
              .where((a) => a['category'] == cat.$1)
              .toList();
          if (items.isEmpty) return const SizedBox.shrink();
          return _buildSection(cat.$2, items);
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header com progresso geral
  // ---------------------------------------------------------------------------

  Widget _buildHeader(AppLocalizations l10n, int unlocked, int total, double progress) {
    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BldrIconBox(icon: Icons.emoji_events_outlined),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.achievements_title, style: BldrText.cardTitleLg),
                  Text(l10n.achievements_unlocked_of_total(unlocked, total), style: BldrText.meta),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).round()}%',
                  style: BldrText.meta.copyWith(
                      color: BldrColors.goldBright, fontWeight: FontWeight.w600)),
              Text('$unlocked / $total', style: BldrText.meta),
            ],
          ),
          const SizedBox(height: 8),
          BldrProgressBar(value: progress),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Seção por categoria
  // ---------------------------------------------------------------------------

  Widget _buildSection(String label, List<Map<String, dynamic>> items) {
    // Ordena: desbloqueadas primeiro, depois bloqueadas
    final sorted = [...items]..sort((a, b) {
        final au = _isUnlocked(a) ? 0 : 1;
        final bu = _isUnlocked(b) ? 0 : 1;
        return au.compareTo(bu);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(label, style: BldrText.label),
        ),
        ...sorted.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCard(a),
            )),
        const SizedBox(height: 14),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Card individual
  // ---------------------------------------------------------------------------

  Widget _buildCard(Map<String, dynamic> achievement) {
    final unlocked    = _isUnlocked(achievement);
    final name        = achievement['name']        as String? ?? '';
    final description = achievement['description'] as String? ?? '';
    final iconName    = achievement['icon_name']   as String? ?? 'emoji_events';
    final xpValue     = (achievement['xp_value']   as int?)  ?? 50;
    final critType    = achievement['criteria_type'] as String? ?? '';
    final critValue   = (achievement['criteria_value'] as num?)?.toInt() ?? 0;

    final showProgress = !unlocked && _hasMeasurableProgress(critType);

    // PG3 — obtidas: fundo dourado sutil, sem badge de texto "Obtido"
    // repetido (o ícone de check já comunica o estado).
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? BldrColors.goldTint : BldrColors.surface,
        borderRadius: BldrRadius.all(BldrRadius.cardSm),
        border: Border.all(
          color: unlocked ? BldrColors.goldBorder : BldrColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AchievementBadge(iconName: iconName, unlocked: unlocked, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: BldrText.cardTitle.copyWith(
                        color: unlocked
                            ? BldrColors.textPrimary
                            : BldrColors.textSecondary)),
                const SizedBox(height: 3),
                Text(description,
                    style: BldrText.meta, maxLines: 2, overflow: TextOverflow.ellipsis),
                // PG4 — bloqueadas: barra de progresso + XP da recompensa
                // juntos.
                if (showProgress) ...[
                  const SizedBox(height: 8),
                  _buildProgressBar(critType, critValue, xpValue),
                ],
              ],
            ),
          ),
          if (unlocked) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded,
                color: BldrColors.goldBright, size: 20),
          ] else if (!showProgress) ...[
            const SizedBox(width: 8),
            Text('+$xpValue XP', style: BldrText.metaSm),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Barra de progresso para conquistas mensuráveis
  // ---------------------------------------------------------------------------

  static const _measurable = {
    'workout_count', 'hiit_workout_count', 'consecutive_days',
  };

  bool _hasMeasurableProgress(String critType) =>
      _measurable.contains(critType);

  int _currentValue(String critType) {
    switch (critType) {
      case 'workout_count':
        return (_workoutContext['workout_count'] as int?) ?? 0;
      case 'hiit_workout_count':
        return (_workoutContext['hiit_workout_count'] as int?) ?? 0;
      case 'consecutive_days':
        return (_workoutContext['consecutive_days'] as int?) ?? 0;
      default:
        return 0;
    }
  }

  Widget _buildProgressBar(String critType, int goal, int xpValue) {
    final current  = _currentValue(critType);
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BldrProgressBar(value: progress, height: 5),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$current / $goal', style: BldrText.metaSm),
            Text('+$xpValue XP',
                style: BldrText.metaSm.copyWith(
                    color: BldrColors.goldBright, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
