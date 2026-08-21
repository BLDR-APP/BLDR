import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';

/// Sessões de treino: iniciar, executar (séries), pausar, concluir e histórico.
abstract class WorkoutSessionRepository {
  /// Cria a sessão; se `templateId` for dado, clona as séries do template.
  Future<Result<WorkoutSession>> start({
    required String name,
    String? templateId,
  });

  Future<Result<WorkoutSession>> complete({
    required String workoutId,
    String? notes,
  });

  Future<Result<WorkoutSet>> logSet(WorkoutSet set);

  Future<Result<void>> completeSet({
    required String setId,
    int? reps,
    double? weightKg,
  });

  Future<Result<void>> undoSet(String setId);

  Future<Result<bool>> hasActiveWorkout();

  /// Sessão ativa com séries e exercícios, ou `null`.
  Future<Result<WorkoutSession?>> activeWorkoutDetails();

  /// Emite a sessão ativa a cada mudança (realtime), `null` quando não há.
  Stream<WorkoutSession?> activeWorkoutStream();

  Future<Result<WorkoutSession?>> workoutDetails(String workoutId);

  Future<Result<List<WorkoutSession>>> history({
    String? userId,
    bool completedOnly = false,
    int limit = 20,
  });

  Future<Result<List<PausedWorkoutSummary>>> pausedSummaries({int limit = 2});

  Future<Result<void>> deletePaused(String workoutId, String source);

  Future<Result<void>> deleteCompleted(String workoutId);

  /// Garante que os sets iniciais existam (cria se `workout_exercise_sets`
  /// estiver vazio para esta sessão). Idempotente: não duplica sets.
  Future<Result<void>> ensureInitialSets(String sessionId, String templateId);
}
