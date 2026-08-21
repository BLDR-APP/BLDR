import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/club/domain/entities/club_community.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

/// Treinos do BLDR Club — espelha o domínio de Workouts (mesmas entidades),
/// mas sobre as tabelas `club_*` e com extras exclusivos (cardio, desafios).
abstract class ClubWorkoutRepository {
  Future<Result<List<WorkoutTemplate>>> myTemplates();

  Future<Result<void>> createTemplate(WorkoutTemplate template);

  Future<Result<void>> updateTemplate(WorkoutTemplate template);

  Future<Result<WorkoutSession>> start({
    required String name,
    required String templateId,
  });

  Future<Result<WorkoutSession>> complete({
    required String workoutId,
    String? notes,
  });

  Future<Result<void>> completeSet({
    required String setId,
    int? reps,
    double? weightKg,
  });

  Future<Result<void>> undoSet(String setId);

  Stream<WorkoutSession?> activeWorkoutStream();

  Future<Result<List<WorkoutSession>>> userWorkouts({
    bool completedOnly = false,
    int limit = 20,
  });

  /// Registra atividade de cardio avulsa (corrida, bike, etc.).
  Future<Result<void>> logCardio({
    required String label,
    required String activityType,
    required int durationSeconds,
  });

  /// Se o usuário participa de algum desafio coletivo ativo.
  Future<Result<bool>> isUserInActiveChallenge();

  /// Biblioteca pública de templates do Club.
  Future<Result<List<WorkoutTemplate>>> publicTemplates({int limit = 50});

  /// Exercícios de um template, com nomes resolvidos.
  Future<Result<List<TemplateExercise>>> templateExercises(String templateId);

  /// Treinos do Club no intervalo (inclui não concluídos).
  Future<Result<List<WorkoutSession>>> workoutsBetween(
      DateTime start, DateTime end);

  /// Atividades avulsas no intervalo [start, end).
  Future<Result<List<ClubActivity>>> activitiesBetween(
      DateTime start, DateTime end);

  /// Soma de XP ganho no intervalo [start, end).
  Future<Result<int>> xpBetween(DateTime start, DateTime end);

  Future<Result<WorkoutSession?>> workoutDetails(String workoutId);

  Future<Result<WorkoutTemplate?>> templateWithExercises(String templateId);

  Future<Result<void>> deleteTemplate(String templateId);

  Future<Result<List<PausedWorkoutSummary>>> pausedSummaries({int limit = 2});

  Future<Result<void>> deletePaused(String workoutId);

  /// Exclui um registro de treino concluído do Club (sets + registro).
  Future<Result<void>> deleteWorkoutRecord(String workoutId);

  /// Exclui uma atividade avulsa (corrida GPS, esporte).
  Future<Result<void>> deleteActivityRecord(String activityId);

  /// Garante que os sets iniciais existam para uma sessão do Club.
  /// Idempotente — não duplica sets se já existirem.
  Future<Result<void>> ensureClubInitialSets(String sessionId, String templateId);

  /// Corridas GPS do usuário (mais recentes primeiro).
  Future<Result<List<RunActivity>>> runActivities({int? limit});

  /// Salva uma corrida concluída: registro + evento de XP + crédito de XP.
  Future<Result<void>> saveRun({
    required double distanceMeters,
    required int durationSeconds,
    required String paceText,
    required List<Map<String, dynamic>> routeData,
    required int earnedXp,
  });

  /// Persiste sessão de partida em bldr_club.match_sessions.
  Future<Result<void>> saveMatchSession({
    required String modality,
    required String result,
    required List<Map<String, dynamic>> sets,
    required int intensity,
    required int durationSec,
  });

  /// Lista partidas anteriores do usuário.
  Future<Result<List<MatchSession>>> matchSessions({int limit = 50});

  /// Operação semanal global ativa (week_start <= hoje <= week_end).
  Future<Result<WeeklyOperation?>> getCurrentOperation();

  /// Progresso do usuário na operação [operationId].
  Future<Result<OperationProgress?>> getOperationProgress(String operationId);

  /// Incrementa [delta] no progresso da operação do tipo [goalType],
  /// se houver uma operação ativa com esse goal_type. No-op se já concluída.
  Future<Result<void>> tryIncrementOperation(String goalType, int delta);
}
