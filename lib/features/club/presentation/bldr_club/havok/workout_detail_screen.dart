import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/integrations/data/widget_data_service.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_hub.dart'; // Importa para usar as cores consistentes
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/exercise.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/active_workout_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

/// Extrai o primeiro número de uma faixa de repetições em texto livre do
/// Gemini (ex: "8-12" -> 8, "10" -> 10). Null se não achar nada.
int? _parseReps(dynamic raw) {
  final text = raw?.toString() ?? '';
  final match = RegExp(r'\d+').firstMatch(text);
  return match == null ? null : int.tryParse(match.group(0)!);
}

/// Converte o artifact do HAVOK em [TemplateExercise]. Artifacts V2 trazem
/// uma identidade canônica resolvida pelo backend e nunca são persistidos como
/// `freeName`; o fallback permanece apenas para artifacts V1 já existentes.
List<TemplateExercise> _exercisesFromWorkoutData(Map<String, dynamic> data) {
  final raw = (data['exercicios'] ?? data['exercises'] ?? const []) as List;
  return raw.asMap().entries.map((entry) {
    final e = Map<String, dynamic>.from(entry.value as Map);
    final name = ((e['nome'] ?? e['name']) as String?)?.trim();
    final canonicalId = e['exercise_id'] as String?;
    final exerciseDbId = e['exercise_db_id'] as String?;
    return TemplateExercise(
      orderIndex: entry.key + 1,
      sets: ((e['series'] ?? e['sets']) as num?)?.toInt() ?? 3,
      reps: _parseReps(e['repeticoes'] ?? e['reps']),
      restSeconds:
          ((e['descanso_segundos'] ?? e['rest_seconds']) as num?)?.toInt(),
      notes: (e['instrucao'] ?? e['notes'] ?? e['observacoes']) as String?,
      exercise: canonicalId == null
          ? null
          : Exercise(
              id: canonicalId,
              exerciseDbId: exerciseDbId,
              name: name?.isNotEmpty == true ? name! : 'Exercício',
            ),
      exerciseDbId: canonicalId == null ? exerciseDbId : null,
      // V1 compatibility only. V2 artifacts are rejected by the server unless
      // every exercise has a canonical identity.
      freeName: canonicalId == null && exerciseDbId == null
          ? (name?.isNotEmpty == true ? name : 'Exercício')
          : null,
    );
  }).toList();
}

const List<String> _kWeekDayLabels = [
  'Seg',
  'Ter',
  'Qua',
  'Qui',
  'Sex',
  'Sáb',
  'Dom'
];

class WorkoutDetailScreen extends StatefulWidget {
  final Map<String, dynamic> workoutData;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutData,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool _startingNow = false;
  bool _saving = false;
  bool _saved = false;

  String get _workoutName =>
      (widget.workoutData['nome'] ?? widget.workoutData['name'] as String?)
                  ?.trim()
                  .isNotEmpty ==
              true
          ? (widget.workoutData['nome'] ?? widget.workoutData['name']) as String
          : 'Treino HAVOK';

  Future<WorkoutTemplate?> _createTemplate() async {
    final template = WorkoutTemplate(
      name: _workoutName,
      workoutType: 'força',
      source: 'havok',
      exercises: _exercisesFromWorkoutData(widget.workoutData),
    );
    final result = await getIt<CreateWorkoutTemplate>()(template);
    final failure = result.failureOrNull;
    if (failure != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.redAccent),
        );
      }
      return null;
    }
    return result.valueOrNull;
  }

  Future<void> _startNow() async {
    if (_startingNow) return;
    setState(() => _startingNow = true);
    try {
      final template = await _createTemplate();
      if (template?.id == null) return;

      debugPrint('[HAVOK] starting workout with templateId: ${template!.id}');
      final startResult = await getIt<StartWorkout>()(
        name: template.name,
        templateId: template.id,
      );
      final session = startResult.valueOrNull;
      if (session?.id == null) {
        final failure = startResult.failureOrNull;
        if (mounted && failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveWorkoutScreen(
              workoutId: session!.id!,
              workoutName: template.name,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _startingNow = false);
    }
  }

  Future<void> _saveToLibrary() async {
    if (_saving || _saved) return;
    setState(() => _saving = true);
    try {
      final template = await _createTemplate();
      if (template != null && mounted) {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Treino salvo na sua biblioteca.'),
            backgroundColor: goldColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAddToPlanSheet() async {
    final selectedDay = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddToPlanSheet(),
    );
    if (selectedDay == null || !mounted) return;

    // Cria o template no banco (source='havok') e associa ao dia selecionado.
    setState(() => _saving = true);
    try {
      final template = await _createTemplate();
      if (template == null || !mounted) return;

      // _AddToPlanSheet retorna 0-indexed (0=Seg); UpdatePlanDay espera 1-indexed (1=Seg).
      final result =
          await getIt<UpdatePlanDay>()(selectedDay + 1, template: template);
      if (!mounted) return;

      final failure = result.failureOrNull;
      if (failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.redAccent),
        );
      } else {
        unawaited(WidgetDataService.updateAll());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${template.name} adicionado ao plano de ${_kWeekDayLabels[selectedDay]}.'),
            backgroundColor: goldColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String workoutName = _workoutName;
    final List exercises = widget.workoutData['exercicios'] ?? [];

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: Text(workoutName.toUpperCase(),
            style: const TextStyle(color: goldColor, fontSize: 18)),
        backgroundColor: cardBackgroundColor,
        iconTheme: const IconThemeData(color: goldColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final String exerciseName =
                    exercise['nome'] ?? 'Exercício Desconhecido';
                final int series = exercise['series'] ?? 0;
                final String reps = exercise['repeticoes'] ?? '0';

                return Card(
                  color: cardBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: goldColor.withOpacity(0.3)),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            exerciseName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${series}x $reps',
                          style: const TextStyle(
                            color: goldColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openAddToPlanSheet,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: goldColor.withOpacity(0.12),
                      border: Border.all(color: goldColor.withOpacity(0.4)),
                    ),
                    child: const Icon(TablerIcons.calendar_plus,
                        color: goldColor, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saved || _saving ? null : _saveToLibrary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: goldColor,
                      side: BorderSide(color: goldColor.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: goldColor))
                        : Text(_saved
                            ? AppLocalizations.of(context).workout_detail_saved
                            : AppLocalizations.of(context).workout_detail_save),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startingNow ? null : _startNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _startingNow
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : Text(
                            AppLocalizations.of(context)
                                .workout_detail_start_now,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToPlanSheet extends StatelessWidget {
  const _AddToPlanSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).workout_detail_add_plan,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).workout_detail_which_day,
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_kWeekDayLabels.length, (i) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, i),
                  child: Container(
                    width: 62,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: goldColor.withOpacity(0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(_kWeekDayLabels[i],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
