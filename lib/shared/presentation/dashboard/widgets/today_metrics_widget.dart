import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/achievements/domain/usecases/achievement_usecases.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// D3 — fileira de chips roláveis: Streak · Treinos/mês · Tempo total ·
/// Conquistas.
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
  int _unlockedAchievements = 0;
  int _totalAchievements = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadStreak();
    _loadAchievements();
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
      if (mounted) setState(() => _streak = result.valueOrNull ?? 0);
    } catch (e) {
      debugPrint('[TodayMetrics] erro streak: $e');
    }
  }

  /// Conquistas — mesmos use cases que o AchievementsWidget usa, mais o
  /// catálogo completo para exibir a fração "N/total" (mockup).
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

  String _formatDuration() {
    if (_totalMinutes == 0) return '—';
    final h = _totalMinutes ~/ 60;
    final m = _totalMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // O zero é informativo no streak e nos contadores de progresso
    // (REDESIGN_SPEC, "Estados vazios") — por isso não são ocultados.
    // Hierarquia (mockup): ícone → valor COM unidade → label da categoria.
    final cards = <Widget>[
      _StatCard(
        icon: Icons.local_fire_department_outlined,
        value: l10n.dashboard_streak_value(_streak),
        label: l10n.dashboard_streak_label,
      ),
      _StatCard(
        icon: Icons.calendar_today_outlined,
        value: _isLoading ? '—' : '$_workoutsThisMonth',
        label: l10n.dashboard_workouts_month_label,
      ),
      _StatCard(
        icon: Icons.timer_outlined,
        value: _isLoading ? '—' : _formatDuration(),
        label: l10n.dashboard_total_time_label,
      ),
      _StatCard(
        icon: Icons.emoji_events_outlined,
        value: '$_unlockedAchievements/$_totalAchievements',
        label: l10n.dashboard_achievements_label,
      ),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Padding no ListView (não margin nos filhos) — evita o primeiro
        // chip cortado à esquerda.
        padding: BldrSpacing.pageInsets,
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: BldrSpacing.gapCard),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }
}

/// D3 — card vertical de estatística: ícone (15px, dourado) → valor grande
/// (com unidade) → label da categoria. Largura mínima ~106px (mockup).
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 106,
      child: BldrGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: BldrColors.goldSolid),
            const SizedBox(height: 6),
            Text(value, style: BldrText.kpiSm),
            const SizedBox(height: 1),
            Text(label, style: BldrText.meta),
          ],
        ),
      ),
    );
  }
}
