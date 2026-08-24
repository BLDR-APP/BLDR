import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/club/domain/entities/club_community.dart';
import 'package:bldr_fitness/features/club/domain/repositories/club_workout_repository.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_summary_data.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/workout_session_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';

class FakePersonalRepository implements WorkoutSessionRepository {
  final List<WorkoutSession> sessions;
  FakePersonalRepository(this.sessions);

  @override
  Future<Result<List<WorkoutSession>>> history({
    String? userId,
    bool completedOnly = false,
    int limit = 20,
  }) async {
    final filtered =
        completedOnly ? sessions.where((s) => s.isCompleted).toList() : sessions;
    return Result.success(filtered);
  }

  @override
  Future<Result<WorkoutSession>> start({required String name, String? templateId}) =>
      throw UnimplementedError();
  @override
  Future<Result<WorkoutSession>> complete({required String workoutId, String? notes}) =>
      throw UnimplementedError();
  @override
  Future<Result<WorkoutSet>> logSet(WorkoutSet set) => throw UnimplementedError();
  @override
  Future<Result<void>> completeSet({required String setId, int? reps, double? weightKg}) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> undoSet(String setId) => throw UnimplementedError();
  @override
  Future<Result<bool>> hasActiveWorkout() => throw UnimplementedError();
  @override
  Future<Result<WorkoutSession?>> activeWorkoutDetails() => throw UnimplementedError();
  @override
  Stream<WorkoutSession?> activeWorkoutStream() => throw UnimplementedError();
  @override
  Future<Result<WorkoutSession?>> workoutDetails(String workoutId) =>
      throw UnimplementedError();
  @override
  Future<Result<List<PausedWorkoutSummary>>> pausedSummaries({int limit = 2}) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> deletePaused(String workoutId, String source) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> deleteCompleted(String workoutId) => throw UnimplementedError();
  @override
  Future<Result<void>> ensureInitialSets(String sessionId, String templateId) async => const Result.success(null);
  @override
  Future<Result<WorkoutSummaryData>> completeWithAnalytics({
    required String workoutId,
    required String source,
    required int setsCompleted,
    String? notes,
  }) => throw UnimplementedError();
}

class FakeClubRepository implements ClubWorkoutRepository {
  final List<WorkoutSession> sessions;
  FakeClubRepository(this.sessions);

  @override
  Future<Result<List<WorkoutSession>>> userWorkouts({
    bool completedOnly = false,
    int limit = 20,
  }) async {
    final filtered =
        completedOnly ? sessions.where((s) => s.isCompleted).toList() : sessions;
    return Result.success(filtered);
  }

  @override
  Future<Result<List<WorkoutTemplate>>> myTemplates() => throw UnimplementedError();
  @override
  Future<Result<void>> createTemplate(WorkoutTemplate template) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> updateTemplate(WorkoutTemplate template) =>
      throw UnimplementedError();
  @override
  Future<Result<WorkoutSession>> start({required String name, required String templateId}) =>
      throw UnimplementedError();
  @override
  Future<Result<WorkoutSession>> complete({required String workoutId, String? notes}) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> completeSet({required String setId, int? reps, double? weightKg}) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> undoSet(String setId) => throw UnimplementedError();
  @override
  Stream<WorkoutSession?> activeWorkoutStream() => throw UnimplementedError();
  @override
  Future<Result<void>> logCardio({
    required String label,
    required String activityType,
    required int durationSeconds,
  }) =>
      throw UnimplementedError();
  @override
  Future<Result<bool>> isUserInActiveChallenge() => throw UnimplementedError();
  @override
  Future<Result<List<WorkoutTemplate>>> publicTemplates({int limit = 50}) =>
      throw UnimplementedError();
  @override
  Future<Result<List<TemplateExercise>>> templateExercises(String templateId) =>
      throw UnimplementedError();
  @override
  Future<Result<List<WorkoutSession>>> workoutsBetween(DateTime start, DateTime end) =>
      throw UnimplementedError();
  @override
  Future<Result<List<ClubActivity>>> activitiesBetween(DateTime start, DateTime end) =>
      throw UnimplementedError();
  @override
  Future<Result<int>> xpBetween(DateTime start, DateTime end) => throw UnimplementedError();
  @override
  Future<Result<WorkoutSession?>> workoutDetails(String workoutId) =>
      throw UnimplementedError();
  @override
  Future<Result<WorkoutTemplate?>> templateWithExercises(String templateId) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> deleteTemplate(String templateId) => throw UnimplementedError();
  @override
  Future<Result<List<PausedWorkoutSummary>>> pausedSummaries({int limit = 2}) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> deletePaused(String workoutId) => throw UnimplementedError();
  @override
  Future<Result<void>> deleteWorkoutRecord(String workoutId) => throw UnimplementedError();
  @override
  Future<Result<void>> deleteActivityRecord(String activityId) => throw UnimplementedError();
  @override
  Future<Result<void>> ensureClubInitialSets(String sessionId, String templateId) async => const Result.success(null);
  @override
  Future<Result<List<RunActivity>>> runActivities({int? limit}) => throw UnimplementedError();
  @override
  Future<Result<void>> saveRun({
    required double distanceMeters,
    required int durationSeconds,
    required String paceText,
    required List<Map<String, dynamic>> routeData,
    required int earnedXp,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> saveMatchSession({
    required String modality,
    required String result,
    required List<Map<String, dynamic>> sets,
    required int intensity,
    required int durationSec,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<List<MatchSession>>> matchSessions({int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<Result<WeeklyOperation?>> getCurrentOperation() async =>
      const Result.success(null);

  @override
  Future<Result<OperationProgress?>> getOperationProgress(
          String operationId) async =>
      const Result.success(null);

  @override
  Future<Result<void>> tryIncrementOperation(
          String goalType, int delta) async =>
      const Result.success(null);
}

WorkoutSession sessionAt(String id, DateTime completedAt, {bool isCompleted = true}) =>
    WorkoutSession(
      id: id,
      name: 'Treino $id',
      completedAt: completedAt,
      isCompleted: isCompleted,
    );

void main() {
  group('GetConsolidatedWorkoutHistory (bug de divergência — mesmo padrão do B4)', () {
    test('inclui treinos pessoais e do clube, não só user_workouts', () async {
      // Reproduz o cenário do bug: um caminho que só olha `user_workouts`
      // (personal) subconta um usuário que treina pelo Club.
      final personal = FakePersonalRepository([sessionAt('p1', DateTime(2026, 8, 1))]);
      final club = FakeClubRepository([sessionAt('c1', DateTime(2026, 8, 2))]);

      final result = await GetConsolidatedWorkoutHistory(personal, club)();

      final sessions = result.valueOrNull;
      expect(sessions, isNotNull);
      expect(sessions!.length, 2);
      expect(sessions.map((s) => s.id), containsAll(['p1', 'c1']));
    });

    test('ordena por data mais recente primeiro, misturando as duas fontes', () async {
      final personal = FakePersonalRepository([sessionAt('p1', DateTime(2026, 8, 1))]);
      final club = FakeClubRepository([sessionAt('c1', DateTime(2026, 8, 3))]);

      final result = await GetConsolidatedWorkoutHistory(personal, club)();

      final sessions = result.valueOrNull!;
      expect(sessions.first.id, 'c1');
      expect(sessions.last.id, 'p1');
    });

    test('completedOnly filtra as duas fontes', () async {
      final personal = FakePersonalRepository([
        sessionAt('p1', DateTime(2026, 8, 1)),
        sessionAt('p2', DateTime(2026, 8, 1), isCompleted: false),
      ]);
      final club = FakeClubRepository([
        sessionAt('c1', DateTime(2026, 8, 2), isCompleted: false),
      ]);

      final result =
          await GetConsolidatedWorkoutHistory(personal, club)(completedOnly: true);

      final sessions = result.valueOrNull!;
      expect(sessions.length, 1);
      expect(sessions.single.id, 'p1');
    });

    test('só `user_workouts` (comportamento antigo) subestima o total — prova do bug',
        () async {
      final personal = FakePersonalRepository(
          [sessionAt('p1', DateTime(2026, 8, 1)), sessionAt('p2', DateTime(2026, 8, 2))]);
      final club = FakeClubRepository(
          [sessionAt('c1', DateTime(2026, 8, 3)), sessionAt('c2', DateTime(2026, 8, 4))]);

      final onlyPersonal = (await personal.history()).valueOrNull!;
      final consolidated =
          (await GetConsolidatedWorkoutHistory(personal, club)()).valueOrNull!;

      // Este teste falharia se a fonte "consolidada" voltasse a ser, por
      // engano, só o histórico pessoal — exatamente o bug descoberto em
      // current_week_card_widget.dart, today_metrics_widget.dart,
      // progress_overview_widget.dart, consistency_heatmap_widget.dart e
      // UserService.getUserStatistics.
      expect(onlyPersonal.length, lessThan(consolidated.length));
      expect(consolidated.length, 4);
    });
  });

  group('GetCurrentStreak (BACKLOG_FUNCIONAL.md B7)', () {
    DateTime daysAgo(int n) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return today.subtract(Duration(days: n));
    }

    test('streak zerado quando não há treino nenhum', () async {
      final result =
          await GetCurrentStreak(FakePersonalRepository([]), FakeClubRepository([]))();
      expect(result.valueOrNull, 0);
    });

    test('streak com gap: treinou hoje e há 2 dias, não ontem — streak = 1', () async {
      final personal = FakePersonalRepository([
        sessionAt('p1', daysAgo(0)),
        sessionAt('p2', daysAgo(2)),
      ]);
      final result = await GetCurrentStreak(personal, FakeClubRepository([]))();
      expect(result.valueOrNull, 1);
    });

    test(
        'streak contínuo com múltiplos treinos no mesmo dia conta como 1 dia',
        () async {
      final personal = FakePersonalRepository([
        sessionAt('p1', daysAgo(0)),
        sessionAt('p2', daysAgo(0).add(const Duration(hours: 3))),
        sessionAt('p3', daysAgo(1)),
        sessionAt('p4', daysAgo(2)),
      ]);
      final result = await GetCurrentStreak(personal, FakeClubRepository([]))();
      expect(result.valueOrNull, 3);
    });

    test('streak inclui treinos do Club (ambas as tabelas)', () async {
      final personal = FakePersonalRepository([sessionAt('p1', daysAgo(0))]);
      final club = FakeClubRepository([
        sessionAt('c1', daysAgo(1)),
        sessionAt('c2', daysAgo(2)),
      ]);
      final result = await GetCurrentStreak(personal, club)();
      expect(result.valueOrNull, 3);
    });
  });
}
