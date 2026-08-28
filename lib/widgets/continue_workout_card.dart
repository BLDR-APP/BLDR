// lib/widgets/continue_workout_card.dart
//
// Card exibido no Dashboard para retomar treinos pausados.
// Recebe um summary map vindo de WorkoutService.getPausedWorkoutSummaries().

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ContinueWorkoutCard extends StatelessWidget {
  static const _gold       = Color(0xFFD4AF37);
  static const _goldBg     = Color(0x1FD4AF37);
  static const _borderGold = Color(0x40D4AF37);
  static const _card       = Color(0xFF1E1C18);
  static const _muted      = Color(0xFF888070);

  final Map<String, dynamic> summary;
  final VoidCallback onResume;
  final VoidCallback? onDiscard;

  const ContinueWorkoutCard({
    Key? key,
    required this.summary,
    required this.onResume,
    this.onDiscard,
  }) : super(key: key);

  // ── helpers ──────────────────────────────────────────────────────────────

  String get _workoutName => (summary['name'] as String?) ?? 'Treino';

  bool get _isClub => (summary['source'] as String?) == 'club';

  String get _pausedAgo {
    final raw = summary['started_at'] as String?;
    if (raw == null) return '';
    final started = DateTime.tryParse(raw);
    if (started == null) return '';
    final diff = DateTime.now().difference(started);
    if (diff.inDays >= 1) return 'há ${diff.inDays}d';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return h > 0 ? 'há ${h}h ${m}m' : 'há ${m}m';
  }

  String get _exercisesLabel {
    final total = (summary['total_exercises'] as int?) ?? 0;
    return total > 0 ? '$total exercícios' : '';
  }

  String get _subtitle {
    final parts = <String>[
      if (_pausedAgo.isNotEmpty) 'Parado $_pausedAgo',
      if (_exercisesLabel.isNotEmpty) _exercisesLabel,
    ];
    return parts.join(' · ');
  }

  double get _progress {
    final done  = (summary['completed_exercises'] as int?) ?? 0;
    final total = (summary['total_exercises']     as int?) ?? 0;
    return total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderGold),
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.5.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header row ───────────────────────────────────────────────────
          Row(
            children: [
              Text(
                'TREINO PAUSADO',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              if (_isClub) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: _goldBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _borderGold),
                  ),
                  child: const Text(
                    'CLUB',
                    style: TextStyle(
                        color: _gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
              const Spacer(),
              const Icon(Icons.pause_circle_outline_rounded,
                  color: _muted, size: 15),
            ],
          ),
          const SizedBox(height: 7),

          // ── workout name ──────────────────────────────────────────────────
          Text(
            _workoutName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // ── subtitle ─────────────────────────────────────────────────────
          if (_subtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(_subtitle,
                style: const TextStyle(color: _muted, fontSize: 12)),
          ],

          // ── progress bar ─────────────────────────────────────────────────
          if (_progress > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: _goldBg,
                color: _gold,
                minHeight: 3,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── action buttons ────────────────────────────────────────────────
          Row(
            children: [
              if (onDiscard != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDiscard,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _muted,
                      side: const BorderSide(color: Color(0xFF3A3830)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Descartar',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onResume,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: const Color(0xFF0D0C0A),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Continuar',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
