import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/workouts/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class ConsistencyHeatmapWidget extends StatefulWidget {
  final VoidCallback onViewAllPressed;

  const ConsistencyHeatmapWidget({
    Key? key,
    required this.onViewAllPressed,
  }) : super(key: key);

  @override
  State<ConsistencyHeatmapWidget> createState() => _ConsistencyHeatmapWidgetState();
}

class _ConsistencyHeatmapWidgetState extends State<ConsistencyHeatmapWidget> {
  Map<DateTime, int> _dayCount = {};
  Map<DateTime, int> _dayDurationMinutes = {}; // F4: duração por dia
  int _totalSecondsLast7Days = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AuthService.instance.isAuthenticated) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      // Histórico consolidado (pessoal + clube) — antes só via GetWorkoutHistory,
      // o heatmap ficava incompleto para quem treina pelo Club.
      final workoutsResult = await getIt<GetConsolidatedWorkoutHistory>()(
        completedOnly: true,
        limit: 60,
      );
      final workouts =
          (workoutsResult.valueOrNull ?? []).map(sessionToLegacyMap).toList();
      final Map<DateTime, int> counts = {};
      final Map<DateTime, int> durMinutes = {};

      final today = DateTime.now();
      final windowStart = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 6));
      int totalSeconds = 0;

      for (final w in workouts) {
        final dateStr = w['completed_at'] as String?;
        if (dateStr == null) continue;
        final dt = DateTime.parse(dateStr).toLocal();
        final day = DateTime(dt.year, dt.month, dt.day);
        counts[day] = (counts[day] ?? 0) + 1;
        final sec = (w['total_duration_seconds'] as int?) ?? 0;
        if (!day.isBefore(windowStart)) {
          totalSeconds += sec;
          durMinutes[day] = (durMinutes[day] ?? 0) + (sec ~/ 60);
        }
      }
      if (mounted) {
        setState(() {
          _dayCount = counts;
          _dayDurationMinutes = durMinutes;
          _totalSecondsLast7Days = totalSeconds;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTotalTime() {
    final totalMinutes = _totalSecondsLast7Days ~/ 60;
    if (totalMinutes == 0) return '—';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  // F4: barras proporcionais à duração em minutos por dia (últimos 7 dias).
  List<double> get _barValues {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return List.generate(7, (i) {
      final day = base.subtract(Duration(days: 6 - i));
      return (_dayDurationMinutes[day] ?? 0).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bars = _barValues;
    final workoutsInWindow =
        bars.fold<int>(0, (sum, v) => sum + v.round());

    return BldrGlassCard(
      onTap: widget.onViewAllPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.dashboard_seven_days, style: BldrText.meta),
              if (!_isLoading && _totalSecondsLast7Days > 0)
                Text(_formatTotalTime(), style: BldrText.metaSm),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: _isLoading
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text('—', style: BldrText.kpiLg),
                  )
                : _buildBars(bars),
          ),
          const SizedBox(height: 4),
          _buildDayLabels(),
          const SizedBox(height: 4),
          Text(
            l10n.dashboard_workouts_count(workoutsInWindow),
            style: BldrText.metaSm,
          ),
        ],
      ),
    );
  }

  Widget _buildBars(List<double> values) {
    final max = values.fold<double>(0, (a, b) => b > a ? b : a);
    final today = DateTime.now();
    final todayIdx = 6; // último slot = hoje
    final todayWeekday = today.weekday; // 1=Mon…7=Sun
    // slot i corresponde ao dia weekday: base=(Mon da semana passada)+i*dias
    // Na janela de 7 dias: slot 0 = 6 dias atrás, slot 6 = hoje
    final baseWeekday = ((todayWeekday - 1 - 6) % 7 + 7) % 7; // weekday do slot 0 (0=Mon)

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        final hasValue = values[i] > 0;
        final isToday = i == todayIdx;
        final ratio = max > 0 ? values[i] / max : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: hasValue
                  ? (44 * ratio).clamp(6.0, 44.0)
                  : 4.0,
              decoration: BoxDecoration(
                color: hasValue
                    ? (isToday ? BldrColors.goldBright : BldrColors.goldBright.withOpacity(0.7))
                    : BldrColors.border.withOpacity(0.5),
                borderRadius: BorderRadius.circular(BldrRadius.bar),
              ),
            ),
          ),
        );
      }),
    );
  }

  static const _abbrevs = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  Widget _buildDayLabels() {
    final today = DateTime.now();
    final todayWeekday = today.weekday - 1; // 0=Mon…6=Sun
    return Row(
      children: List.generate(7, (i) {
        final dayOffset = 6 - i; // slot 0 = 6 dias atrás
        final weekday = (todayWeekday - dayOffset) % 7;
        final normalizedWeekday = (weekday + 7) % 7;
        final isToday = dayOffset == 0;
        return Expanded(
          child: Text(
            _abbrevs[normalizedWeekday],
            textAlign: TextAlign.center,
            style: BldrText.metaSm.copyWith(
              fontSize: 8,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
              color: isToday ? BldrColors.goldBright : BldrColors.textMuted,
            ),
          ),
        );
      }),
    );
  }
}
