import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

/// Formatação/agrupamento de apresentação dos detalhes do treino (316:113).
abstract final class WorkoutDetailsFormat {
  /// "8–12" ou "10"; null sem reps.
  static String? repsRange(List<TemplateSetDetail> sets) {
    final reps = sets.map((s) => s.reps).whereType<int>().toList();
    if (reps.isEmpty) return null;
    final lo = reps.reduce((a, b) => a < b ? a : b);
    final hi = reps.reduce((a, b) => a > b ? a : b);
    return lo == hi ? '$lo' : '$lo–$hi';
  }

  static int totalSets(WorkoutTemplate t) =>
      t.exercises.fold(0, (sum, e) => sum + e.resolvedSets.length);

  /// Volume real de uma sessão: Σ carga × reps das séries concluídas e não
  /// puladas. null quando nenhuma série concluída tem carga e reps.
  static double? sessionVolume(WorkoutSession session) {
    var total = 0.0;
    var counted = false;
    for (final s in session.sets) {
      final done = s.isCompleted || s.completedAt != null;
      if (!done || s.isSkipped) continue;
      final w = s.weightKg, r = s.reps;
      if (w == null || r == null || w <= 0 || r <= 0) continue;
      total += w * r;
      counted = true;
    }
    return counted ? total : null;
  }

  /// Última sessão concluída deste template (lista em ordem decrescente).
  static WorkoutSession? lastCompletedFor(
      List<WorkoutSession> history, String templateId) {
    for (final s in history) {
      if (s.templateId == templateId &&
          (s.isCompleted || s.completedAt != null)) {
        return s;
      }
    }
    return null;
  }

  /// Nome exibido do exercício do template.
  static String exerciseName(TemplateExercise e, String fallback) =>
      e.exercise?.name ?? e.freeName ?? fallback;

  /// Grupos musculares do exercício: principal + secundários, sem repetir.
  static String muscleGroups(TemplateExercise e) {
    final out = <String>[];
    void add(dynamic v) {
      if (v is String && v.trim().isNotEmpty) out.add(v.trim());
      if (v is List) {
        for (final x in v) {
          add(x);
        }
      }
    }
    add(e.exercise?.primaryMuscleGroup);
    add(e.exercise?.secondaryMuscleGroups);
    return out.toSet().join(' · ');
  }

  /// URL do GIF: imagem do exercício, senão o GIF do ExerciseDB.
  static String? gifUrl(TemplateExercise e) {
    final url = e.exercise?.imageUrl;
    if (url != null && url.isNotEmpty) return url;
    final id = e.exerciseDbId ?? e.exercise?.exerciseDbId;
    return id == null || id.isEmpty
        ? null
        : 'https://static.exercisedb.dev/media/$id.gif';
  }

  /// Cópia de um template para "Duplicar treino": sem id, nome [name],
  /// do usuário (privado, origem "user"), com os exercícios na mesma ordem
  /// e as séries uma a uma (`setDetails`). [durationMinutes] vem do
  /// estimador (P1).
  static WorkoutTemplate duplicate(WorkoutTemplate t,
          {required String name, required int durationMinutes}) =>
      WorkoutTemplate(
        name: name,
        description: t.description,
        workoutType: t.workoutType,
        estimatedDurationMinutes: durationMinutes,
        difficultyLevel: t.difficultyLevel,
        isPublic: false,
        source: 'user',
        exercises: [
          for (final e in t.exercises)
            TemplateExercise(
              orderIndex: e.orderIndex,
              sets: e.sets,
              reps: e.reps,
              durationSeconds: e.durationSeconds,
              restSeconds: e.restSeconds,
              weightKg: e.weightKg,
              distanceMeters: e.distanceMeters,
              notes: e.notes,
              exerciseDbId: e.exerciseDbId,
              exercise: e.exercise,
              freeName: e.freeName,
              setDetails: e.resolvedSets,
            ),
        ],
      );
}
