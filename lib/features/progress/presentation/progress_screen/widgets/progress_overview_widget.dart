import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/services/progress_service.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class ProgressOverviewWidget extends StatefulWidget {
  final int selectedPeriod;

  const ProgressOverviewWidget({Key? key, required this.selectedPeriod})
    : super(key: key);

  @override
  State<ProgressOverviewWidget> createState() => _ProgressOverviewWidgetState();
}

class _ProgressOverviewWidgetState extends State<ProgressOverviewWidget> {
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _workoutProgress;
  Map<String, dynamic>? _streakData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  @override
  void didUpdateWidget(ProgressOverviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _loadOverviewData();
    }
  }

  Future<void> _loadOverviewData() async {
    setState(() => _isLoading = true);

    try {
      final userProfile = await UserService.instance.getCurrentUserProfile();
      if (userProfile != null) {
        final userStatsData = await UserService.instance.getUserStatistics(
          userProfile.id,
        );
        final workoutProgressData = await ProgressService.instance
            .getWorkoutProgress(daysPeriod: widget.selectedPeriod);

        final streakResult = await getIt<GetCurrentStreak>()();
        final streakData = {
          'current_streak': streakResult.valueOrNull ?? 0,
        };

        if (mounted) {
          setState(() {
            _userStats = userStatsData;
            _workoutProgress = workoutProgressData;
            _streakData = streakData;
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator(color: BldrColors.goldBright)),
      );
    }

    final totalWorkouts = _userStats?['total_workouts'] ?? 0;
    final achievements = _userStats?['achievements'] ?? 0;
    final workoutTime = _workoutProgress?['total_workout_time_hours'] ?? '0.0';
    final currentStreak = _streakData?['current_streak'] ?? 0;

    final l10n = AppLocalizations.of(context)!;
    // PG1 — achatado: sem card externo, título simples + grid 2×2 de
    // BldrGlassCard direto. PG2 — sem o badge de conclusão.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.progress_overview_title, style: BldrText.sectionTitle),
        const SizedBox(height: 2),
        Text(l10n.progress_overview_period(widget.selectedPeriod), style: BldrText.meta),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(l10n.progress_stat_workouts, totalWorkouts.toString(), l10n.progress_stat_total,
                  Icons.fitness_center),
            ),
            const SizedBox(width: BldrSpacing.gapCard),
            Expanded(
              child: _buildStatCard(
                  l10n.progress_stat_time, workoutTime, l10n.progress_stat_time_unit, Icons.schedule_outlined),
            ),
          ],
        ),
        const SizedBox(height: BldrSpacing.gapCard),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(l10n.progress_stat_badges, achievements.toString(),
                  l10n.progress_stat_badges_unit, Icons.emoji_events_outlined),
            ),
            const SizedBox(width: BldrSpacing.gapCard),
            Expanded(
              child: _buildStatCard(l10n.progress_stat_streak, currentStreak.toString(), l10n.progress_stat_streak_unit,
                  Icons.local_fire_department_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon) {
    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: BldrColors.goldBright, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: BldrText.meta, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: value,
              style: BldrText.kpiSm,
              children: [TextSpan(text: ' $unit', style: BldrText.unit)],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
