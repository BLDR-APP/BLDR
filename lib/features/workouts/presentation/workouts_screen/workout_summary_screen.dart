import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bldr_fitness/features/workouts/domain/entities/workout_summary_data.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_atlas.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutSummaryData data;

  const WorkoutSummaryScreen({super.key, required this.data});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  final _shareKey = GlobalKey();
  bool _sharing = false;

  WorkoutSummaryData get data => widget.data;

  Future<void> _shareCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bldr_workout.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Treino concluído no BLDR 💪',
        ),
      );
    } catch (e) {
      debugPrint('[Summary] erro ao compartilhar: $e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 0),
              child: Row(
                children: [
                  Text('Resumo do treino', style: BldrText.cardTitleLg),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: BldrColors.textMuted),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Share Card ──────────────────────────────────────────
                    RepaintBoundary(
                      key: _shareKey,
                      child: _ShareCard(data: data),
                    ),
                    const SizedBox(height: 14),

                    // ── PRs ─────────────────────────────────────────────────
                    if (data.newPRs.isNotEmpty) ...[
                      _PRSection(prs: data.newPRs),
                      const SizedBox(height: 12),
                    ],

                    // ── XP ──────────────────────────────────────────────────
                    _XPBanner(xp: data.xpEarned),
                    const SizedBox(height: 12),

                    // ── Comparação ──────────────────────────────────────────
                    if (data.volumeDeltaPercent != null) ...[
                      _ComparisonCard(
                        delta: data.volumeDeltaPercent!,
                        currentKg: data.volumeKg,
                        previousKg: data.previousVolumeKg!,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Botões ──────────────────────────────────────────────
                    _ActionButtons(
                      sharing: _sharing,
                      onShare: _shareCard,
                      onDashboard: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Share Card ────────────────────────────────────────────────────────────────

class _ShareCard extends StatelessWidget {
  final WorkoutSummaryData data;

  const _ShareCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111111), Color(0xFF050505)],
        ),
        border: Border.all(color: BldrColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Text('BLDR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: BldrColors.goldBright,
                      fontFamily: BldrText.family,
                    )),
                const SizedBox(width: 6),
                Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BldrColors.goldBright.withValues(alpha: 0.4),
                    )),
                const SizedBox(width: 6),
                Text('PERFORMANCE',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 1,
                      fontFamily: BldrText.family,
                      color: BldrColors.goldBright.withValues(alpha: 0.4),
                    )),
              ]),
              _DoneBadge(),
            ],
          ),
          const SizedBox(height: 14),

          // Nome + data
          Text(data.workoutName, style: BldrText.cardTitleLg),
          const SizedBox(height: 3),
          Text(data.completedAtLabel, style: BldrText.meta),
          const SizedBox(height: 14),

          // Stats
          _StatsRow(data: data),

          // Muscle map
          if (data.muscleGroups.isNotEmpty) ...[
            const SizedBox(height: 14),
            Center(child: BLDRMuscleAtlas(muscleGroups: data.muscleGroups)),
          ],
          const SizedBox(height: 14),

          // Rodapé
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BLDR · PERFORMANCE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: BldrText.family,
                    color: BldrColors.goldBright.withValues(alpha: 0.3),
                  )),
              Text('bldr.app',
                  style: TextStyle(
                    fontSize: 8,
                    fontFamily: BldrText.family,
                    color: Colors.white.withValues(alpha: 0.15),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
        border:
            Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_rounded, size: 10, color: Color(0xFF4CAF50)),
        SizedBox(width: 4),
        Text('CONCLUÍDO',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF4CAF50),
              fontFamily: BldrText.family,
            )),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final WorkoutSummaryData data;

  const _StatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(value: data.durationLabel, label: 'Duração'),
        _divider(),
        _StatItem(value: data.volumeLabel, label: 'Volume'),
        _divider(),
        _StatItem(value: '${data.setsCompleted}', label: 'Séries'),
      ],
    );
  }

  Widget _divider() => Container(
      width: 1, height: 32, color: BldrColors.border, margin: const EdgeInsets.symmetric(horizontal: 12));
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: BldrText.kpiSm.copyWith(color: BldrColors.goldBright)),
      const SizedBox(height: 2),
      Text(label, style: BldrText.metaSm),
    ]);
  }
}

// ── PRs ───────────────────────────────────────────────────────────────────────

class _PRSection extends StatelessWidget {
  final List<PersonalRecordData> prs;

  const _PRSection({required this.prs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BldrColors.goldBright.withValues(alpha: 0.06),
        border: Border.all(color: BldrColors.goldBright.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.emoji_events_rounded,
                size: 14, color: BldrColors.goldBright),
            const SizedBox(width: 6),
            Text('NOVOS RECORDS PESSOAIS',
                style: BldrText.label
                    .copyWith(color: BldrColors.goldBright, fontSize: 10)),
          ]),
          const SizedBox(height: 10),
          ...prs.map((pr) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Expanded(
                      child: Text(pr.exerciseName,
                          style: BldrText.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Text('${pr.newWeightKg.toStringAsFixed(1)} kg',
                      style: BldrText.body.copyWith(
                          color: BldrColors.goldBright,
                          fontWeight: FontWeight.w700)),
                  if (pr.newE1rm != null) ...[
                    const SizedBox(width: 6),
                    Text('1RM ~${pr.newE1rm!.toStringAsFixed(0)}kg',
                        style: BldrText.metaSm),
                  ],
                ]),
              )),
        ],
      ),
    );
  }
}

// ── XP Banner ─────────────────────────────────────────────────────────────────

class _XPBanner extends StatelessWidget {
  final int xp;

  const _XPBanner({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BldrColors.surface,
        border: Border.all(color: BldrColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        const Icon(Icons.bolt_rounded, color: BldrColors.goldBright, size: 20),
        const SizedBox(width: 10),
        Text('+$xp XP ganhos',
            style: BldrText.body.copyWith(color: BldrColors.goldBright)),
        const Spacer(),
        Text('Treino concluído', style: BldrText.meta),
      ]),
    );
  }
}

// ── Comparação ────────────────────────────────────────────────────────────────

class _ComparisonCard extends StatelessWidget {
  final double delta;
  final double currentKg;
  final double previousKg;

  const _ComparisonCard({
    required this.delta,
    required this.currentKg,
    required this.previousKg,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = delta >= 0;
    final color = isUp ? const Color(0xFF4CAF50) : BldrColors.danger;
    final icon =
        isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final sign = isUp ? '+' : '';

    return Container(
      decoration: BoxDecoration(
        color: BldrColors.surface,
        border: Border.all(color: BldrColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Comparação com sessão anterior', style: BldrText.meta),
            const SizedBox(height: 2),
            Text(
              '${currentKg.toStringAsFixed(0)}kg vs ${previousKg.toStringAsFixed(0)}kg',
              style: BldrText.body,
            ),
          ]),
        ),
        Text('$sign${delta.toStringAsFixed(0)}%',
            style: BldrText.body
                .copyWith(color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ── Botões ────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool sharing;
  final VoidCallback onShare;
  final VoidCallback onDashboard;

  const _ActionButtons({
    required this.sharing,
    required this.onShare,
    required this.onDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: sharing ? null : onShare,
          style: OutlinedButton.styleFrom(
            foregroundColor: BldrColors.goldBright,
            side: const BorderSide(color: BldrColors.goldBright),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: sharing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: BldrColors.goldBright))
              : const Icon(Icons.share_rounded, size: 18),
          label: Text(sharing ? 'Preparando...' : 'Compartilhar card',
              style: BldrText.buttonSecondary
                  .copyWith(color: BldrColors.goldBright)),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onDashboard,
          style: ElevatedButton.styleFrom(
            backgroundColor: BldrColors.goldBright,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Ir para o Dashboard',
              style: BldrText.buttonPrimary.copyWith(color: Colors.black)),
        ),
      ),
    ]);
  }
}
