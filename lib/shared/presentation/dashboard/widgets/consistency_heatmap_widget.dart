import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/workouts/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';

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

  // Tempo total da janela saiu da Home v2 (decisão 4); a soma continua em
  // `_totalSecondsLast7Days`.
  // ignore: unused_element
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

  /// Tile "7 dias" v2 (Figma): barras de 13 px (máx. 36), dourado nos dias
  /// com treino e #383838 nos demais; letra do dia e total de treinos.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Corrigido: antes somava MINUTOS e exibia como "N treinos".
    final workoutsInWindow =
        HomeV2Format.workoutsInLast7Days(_dayCount, DateTime.now());

    return BldrSolidCard(
      onTap: widget.onViewAllPressed,
      color: BldrColorsV2.tileBg,
      radius: BldrRadiusV2.tile,
      height: BldrSpacingV2.tileHeight,
      padding: const EdgeInsets.fromLTRB(BldrSpacingV2.tilePad, 11, 13, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashboard_seven_days, style: BldrTextV2.tileLabel),
          const SizedBox(height: 8.9),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: Column(
              children: [
                SizedBox(height: 36, child: _buildBars(_barValues)),
                const SizedBox(height: 4),
                _buildDayLabels(),
              ],
            ),
          ),
          Text(
            _isLoading ? '—' : l10n.dashboard_workouts_count(workoutsInWindow),
            style: BldrTextV2.tileLabel,
          ),
        ],
      ),
    );
  }

  static const double _barWidth = 13;
  static const double _barMax = 36;
  static const double _barIdle = 10;

  Widget _buildBars(List<double> values) {
    final max = values.fold<double>(0, (a, b) => b > a ? b : a);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        final hasValue = values[i] > 0;
        final ratio = max > 0 ? values[i] / max : 0.0;
        return Container(
          width: _barWidth,
          height: hasValue
              ? (_barMax * ratio).clamp(_barIdle, _barMax)
              : _barIdle,
          decoration: BoxDecoration(
            color: hasValue ? BldrColorsV2.goldBright : BldrColorsV2.weekBarIdle,
            borderRadius: BorderRadius.circular(BldrRadiusV2.weekBar),
          ),
        );
      }),
    );
  }

  static const _abbrevs = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  Widget _buildDayLabels() {
    final todayWeekday = DateTime.now().weekday - 1; // 0=Mon…6=Sun
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final dayOffset = 6 - i; // slot 0 = 6 dias atrás
        final normalizedWeekday = ((todayWeekday - dayOffset) % 7 + 7) % 7;
        final isToday = dayOffset == 0;
        return SizedBox(
          width: _barWidth,
          child: Text(
            _abbrevs[normalizedWeekday],
            textAlign: TextAlign.center,
            style: BldrTextV2.weekDay.copyWith(
              color: isToday ? BldrColorsV2.goldBright : null,
            ),
          ),
        );
      }),
    );
  }
}
