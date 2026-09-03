import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/features/community/presentation/create_post_screen.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_share_data.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_summary_data.dart';
import 'package:bldr_fitness/features/workouts/presentation/share/workout_share_preview.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_map.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutSummaryData data;
  const WorkoutSummaryScreen({super.key, required this.data});
  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  late WorkoutShareData _shareData;
  bool _isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _shareData = WorkoutShareData.fromSummary(widget.data);
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) BldrMuscleMap.precache(context);
    });
  }

  Future<void> _loadProfile() async {
    WorkoutShareData? loadedShareData;
    try {
      final profile = await UserService.instance.getCurrentUserProfile();
      if (profile != null) {
        debugPrint(
            '[ShareCard] username="${profile.username}" avatarUrl="${profile.avatarUrl}" fullName="${profile.fullName}"');
        loadedShareData = WorkoutShareData.fromSummary(
          widget.data,
          username: profile.username,
          fullName: profile.fullName,
          avatarUrl: profile.avatarUrl,
        );
      } else {
        debugPrint('[ShareCard] profile is null — handle não será exibido');
      }
    } catch (error) {
      debugPrint('[WorkoutShare] Perfil indisponível: $error');
    } finally {
      if (mounted) {
        setState(() {
          if (loadedShareData != null) _shareData = loadedShareData;
          _isProfileLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: SafeArea(
          child: CustomScrollView(slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: BldrColors.bgBase,
              title: const Text('Treino concluído'),
              actions: [
                IconButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              sliver: SliverList.list(children: [
                _SummaryHeader(data: _shareData),
                const SizedBox(height: 18),
                _PerformanceCard(data: _shareData),
                if (_shareData.muscleMapData != null) ...[
                  const SizedBox(height: 12),
                  _MuscleCard(data: _shareData),
                ],
                if (_shareData.prs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PrCard(prs: _shareData.prs),
                ],
                if (_shareData.xpEarned case final xp?) ...[
                  const SizedBox(height: 12),
                  _XpCard(xp: xp),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isProfileLoading
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkoutSharePreview(data: _shareData),
                            ),
                          ),
                  style: FilledButton.styleFrom(
                    backgroundColor: BldrColors.goldSolid,
                    foregroundColor: BldrColors.bgBase,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Compartilhar treino'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePostScreen(
                        preselectedWorkoutId: widget.data.workoutId,
                        preselectedSource: widget.data.source,
                        preselectedPrs: widget.data.newPRs,
                      ),
                    ),
                  ),
                  icon: const Icon(TablerIcons.users, size: 18),
                  label: const Text('Compartilhar na comunidade'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BldrColors.goldBright,
                    side: const BorderSide(color: BldrColors.goldBorder),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text('Ir para o início'),
                ),
              ]),
            ),
          ]),
        ),
      );
}

class _SummaryHeader extends StatelessWidget {
  final WorkoutShareData data;
  const _SummaryHeader({required this.data});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: BldrColors.goldTint,
              border: Border.all(color: BldrColors.goldBorder),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text('✓ CONCLUÍDO',
                style: BldrText.label.copyWith(color: BldrColors.goldBright)),
          ),
          const SizedBox(height: 14),
          Text(data.workoutName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BldrText.screenTitle.copyWith(fontSize: 28)),
          const SizedBox(height: 5),
          Text(data.summary.completedAtLabel.toUpperCase(),
              style: BldrText.meta),
        ],
      );
}

class _PerformanceCard extends StatelessWidget {
  final WorkoutShareData data;
  const _PerformanceCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final metrics = <(String, String)>[
      if (data.durationSeconds != null) (data.summary.durationLabel, 'Duração'),
      if (data.totalVolume != null) (data.summary.volumeLabel, 'Volume'),
      if (data.totalSets case final value?) ('$value', 'Séries'),
    ];
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PERFORMANCE', style: BldrText.label),
        if (metrics.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: metrics
                .map((m) => Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.$1,
                                style: BldrText.kpiSm
                                    .copyWith(color: BldrColors.goldBright)),
                            const SizedBox(height: 3),
                            Text(m.$2, style: BldrText.metaSm),
                          ]),
                    ))
                .toList(),
          ),
        ],
        if (data.exerciseCount case final count?) ...[
          const SizedBox(height: 16),
          Text('$count exercícios', style: BldrText.description),
        ],
      ]),
    );
  }
}

class _MuscleCard extends StatelessWidget {
  final WorkoutShareData data;
  const _MuscleCard({required this.data});
  @override
  Widget build(BuildContext context) => _Card(
        child: Column(children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Text('MÚSCULOS TRABALHADOS', style: BldrText.label)),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MuscleMapSlot(
                  muscles: data.muscleMapData!.muscles,
                  view: BldrMuscleMapView.front,
                ),
                const SizedBox(width: 10),
                _MuscleMapSlot(
                  muscles: data.muscleMapData!.muscles,
                  view: BldrMuscleMapView.back,
                ),
              ],
            ),
          ),
          if (data.primaryMuscleLabels.isNotEmpty)
            Text(data.primaryMuscleLabels.join(' • '),
                style: BldrText.description),
        ]),
      );
}

class _MuscleMapSlot extends StatelessWidget {
  final Object muscles;
  final BldrMuscleMapView view;

  const _MuscleMapSlot({required this.muscles, required this.view});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 110,
        height: 220,
        child: FittedBox(
          fit: BoxFit.contain,
          child: BldrMuscleMap(
            muscles: muscles,
            view: view,
            size: BldrMuscleMapSize.summary,
          ),
        ),
      );
}

class _PrCard extends StatelessWidget {
  final List<PersonalRecordData> prs;
  const _PrCard({required this.prs});
  @override
  Widget build(BuildContext context) => _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              '🏆 ${prs.length} NOVO${prs.length == 1 ? '' : 'S'} PR${prs.length == 1 ? '' : 'S'}',
              style: BldrText.label.copyWith(color: BldrColors.goldBright)),
          const SizedBox(height: 10),
          ...prs.map((pr) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Expanded(child: Text(pr.exerciseName, style: BldrText.body)),
                  if (pr.newWeightKg > 0)
                    Text('${pr.newWeightKg.toStringAsFixed(1)} kg',
                        style: BldrText.body
                            .copyWith(color: BldrColors.goldBright)),
                ]),
              )),
        ]),
      );
}

class _XpCard extends StatelessWidget {
  final int xp;
  const _XpCard({required this.xp});
  @override
  Widget build(BuildContext context) => _Card(
        child: Row(children: [
          const Icon(Icons.bolt_rounded, color: BldrColors.goldBright),
          const SizedBox(width: 10),
          Text('+$xp XP',
              style: BldrText.kpiSm.copyWith(color: BldrColors.goldBright)),
        ]),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BldrColors.surface,
          border: Border.all(color: BldrColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      );
}
