import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/features/achievements/domain/usecases/achievement_usecases.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// D3 — chips de consistência (v2): Streak · Treinos/mês · Tempo total.
///
/// Absorve dado que antes vivia em outros widgets do Dashboard, sem alterar
/// nenhuma consulta:
///   • treinos do mês e tempo total — consulta original deste arquivo, intacta;
///   • streak — veio do GreetingHeaderWidget (mesmo `GetWorkoutHistory`);
///   • conquistas — veio do AchievementsWidget (mesmos use cases).
/// Isso é o que o D8 quer dizer com "o dado migrou para os chips".
class TodayMetricsWidget extends StatefulWidget {
  const TodayMetricsWidget({super.key});

  @override
  State<TodayMetricsWidget> createState() => _TodayMetricsWidgetState();
}

class _TodayMetricsWidgetState extends State<TodayMetricsWidget> {
  int _workoutsThisMonth = 0;
  int _totalMinutes = 0;
  int _streak = 0;
  bool _streakAtRisk = false;
  // Conquistas saíram da Home v2 (decisão 4). A consulta continua no código
  // (`_loadAchievements`), mas não é disparada enquanto não houver slot.
  // ignore: unused_field
  int _unlockedAchievements = 0;
  // ignore: unused_field
  int _totalAchievements = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadStreak();
  }

  Future<void> _load() async {
    if (!AuthService.instance.isAuthenticated) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final userId = AuthService.instance.currentUser!.id;
      final client = Supabase.instance.client;

      final results = await Future.wait([
        client
            .from('user_workouts')
            .select('completed_at, total_duration_seconds')
            .eq('user_id', userId)
            .eq('is_completed', true),
        client
            .from('club_user_workouts')
            .select('completed_at, total_duration_seconds')
            .eq('user_id', userId)
            .eq('is_completed', true),
      ]);

      final allWorkouts = [
        ...(results[0] as List),
        ...(results[1] as List),
      ];

      final now = DateTime.now();
      int count = 0;
      int totalSeconds = 0;
      for (final w in allWorkouts) {
        final dateStr = w['completed_at'] as String?;
        if (dateStr == null) continue;
        final dt = DateTime.parse(dateStr).toLocal();
        if (dt.year == now.year && dt.month == now.month) {
          count++;
          totalSeconds += (w['total_duration_seconds'] as int?) ?? 0;
        }
      }

      if (mounted) {
        setState(() {
          _workoutsThisMonth = count;
          _totalMinutes = totalSeconds ~/ 60;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStreak() async {
    try {
      if (!getIt<AuthRepository>().isAuthenticated) return;
      final result = await getIt<GetCurrentStreak>()();
      final streak = result.valueOrNull ?? 0;

      bool atRisk = false;
      if (streak > 0) {
        final lastResult = await getIt<GetConsolidatedWorkoutHistory>()(
            completedOnly: true, limit: 1);
        final last = lastResult.valueOrNull?.firstOrNull;
        final lastDate = last?.completedAt?.toLocal();
        if (lastDate != null) {
          final today = DateTime.now();
          atRisk = !(lastDate.year == today.year &&
              lastDate.month == today.month &&
              lastDate.day == today.day);
        }
      }

      if (mounted) {
        setState(() {
          _streak = streak;
          _streakAtRisk = atRisk;
        });
      }
    } catch (e) {
      debugPrint('[TodayMetrics] erro streak: $e');
    }
  }

  /// Conquistas — mesmos use cases que o AchievementsWidget usa, mais o
  /// catálogo completo para exibir a fração "N/total". Sem chip na Home v2.
  // ignore: unused_element
  Future<void> _loadAchievements() async {
    final userId = getIt<AuthRepository>().currentUser?.id;
    if (userId == null) return;
    try {
      final unlockedResult = await getIt<GetUserAchievements>()(userId);
      final catalogResult = await getIt<GetAchievementCatalog>()();
      final unlocked = unlockedResult.valueOrNull ?? [];
      final catalog = catalogResult.valueOrNull ?? [];
      if (mounted) {
        setState(() {
          _unlockedAchievements = unlocked.length;
          _totalAchievements = catalog.length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // O zero é informativo no streak e nos contadores (REDESIGN_SPEC,
    // "Estados vazios") — por isso não são ocultados.
    final showRisk = _streakAtRisk && _streak > 0;

    // Chips v2 (Figma "03 — CONSISTÊNCIA"): 3 cards 81 × 78, gap 13,
    // centralizados. O chip de Conquistas saiu (decisão 4).
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BldrStatChip(
            iconAsset: 'assets/images/v2/icons/stat_flame.svg',
            value: l10n.dashboard_streak_value(_streak),
            label: l10n.dashboard_streak_label,
            valueColor: showRisk ? BldrColorsV2.goldBright : null,
            onTap: showRisk
                ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Treine hoje para manter seu streak de $_streak dias!'),
                      backgroundColor: const Color(0xFFFF6432),
                      behavior: SnackBarBehavior.floating,
                    ))
                : null,
          ),
          const SizedBox(width: BldrSpacingV2.chipGap),
          BldrStatChip(
            iconAsset: 'assets/images/v2/icons/stat_barbell.svg',
            value: _isLoading ? '—' : '$_workoutsThisMonth',
            label: l10n.dashboard_workouts_month_label,
          ),
          const SizedBox(width: BldrSpacingV2.chipGap),
          BldrStatChip(
            iconAsset: 'assets/images/v2/icons/stat_alarm.svg',
            value: _isLoading ? '—' : HomeV2Format.totalDuration(_totalMinutes),
            label: l10n.dashboard_total_time_label,
          ),
        ],
      ),
    );
  }
}
