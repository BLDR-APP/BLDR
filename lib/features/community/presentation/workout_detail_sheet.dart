import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/community/domain/entities/workout_exercise.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class WorkoutDetailSheet extends StatefulWidget {
  final String workoutId;
  final String source; // 'free' | 'club'
  final String workoutName;

  const WorkoutDetailSheet({
    super.key,
    required this.workoutId,
    required this.source,
    required this.workoutName,
  });

  @override
  State<WorkoutDetailSheet> createState() => _WorkoutDetailSheetState();
}

class _WorkoutDetailSheetState extends State<WorkoutDetailSheet> {
  final _repo = getIt<CommunityFeedRepository>();

  bool _loading = true;
  bool _copying = false;
  List<WorkoutExercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final result = await _repo.fetchWorkoutExercises(
      workoutId: widget.workoutId,
      source: widget.source,
    );
    if (!mounted) return;
    result.fold(
      onSuccess: (exercises) => setState(() {
        _exercises = exercises;
        _loading = false;
      }),
      onFailure: (_) => setState(() => _loading = false),
    );
  }

  Future<void> _copyWorkout() async {
    setState(() => _copying = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final key = 'workout_copies_${now.year}_${now.month}';
      final count = prefs.getInt(key) ?? 0;

      if (widget.source == 'free' && count >= 3) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Você atingiu o limite de 3 cópias este mês. Faça upgrade para Club'),
          ),
        );
        setState(() => _copying = false);
        return;
      }

      await _repo.copyWorkout(
          workoutId: widget.workoutId, source: widget.source);

      if (widget.source == 'free') {
        await prefs.setInt(key, count + 1);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treino copiado para Meus Treinos ✓'),
          backgroundColor: Color(0xFF2D7D46),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao copiar treino: $e')),
      );
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: BldrColors.sheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: BldrColors.border),
              left: BorderSide(color: BldrColors.border),
              right: BorderSide(color: BldrColors.border),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BldrColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: BldrColors.goldBright,
                          strokeWidth: 2,
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        children: [
                          Text(widget.workoutName,
                              style: BldrText.screenTitle),
                          const SizedBox(height: 20),
                          if (_exercises.isNotEmpty) ...[
                            Text('Exercícios',
                                style: BldrText.sectionTitle),
                            const SizedBox(height: 12),
                            ..._exercises.map(_buildExerciseCard),
                          ] else
                            Text('Nenhum exercício encontrado.',
                                style: BldrText.body),
                          const SizedBox(height: 24),
                          _buildCopyBtn(),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseCard(WorkoutExercise ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BldrColors.surface,
        border: Border.all(color: BldrColors.border),
        borderRadius: BorderRadius.circular(BldrRadius.cardSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(TablerIcons.barbell, size: 14,
                  color: BldrColors.goldBright),
              const SizedBox(width: 8),
              Expanded(child: Text(ex.name, style: BldrText.cardTitle)),
            ],
          ),
          if (ex.sets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: ex.sets.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final label = [
                  if (s.weightKg != null)
                    '${s.weightKg!.toStringAsFixed(1)}kg',
                  if (s.reps != null) '${s.reps} reps',
                ].join(' × ');
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x08FFFFFF),
                    border: Border.all(color: const Color(0x0DFFFFFF)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label.isNotEmpty ? 'S${i + 1}: $label' : 'S${i + 1}',
                    style: BldrText.meta,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCopyBtn() {
    return BldrPrimaryButton(
      label: _copying ? 'Copiando…' : 'Copiar treino',
      onPressed: _copying ? null : _copyWorkout,
    );
  }
}

