import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/club/domain/entities/club_community.dart';
import 'package:bldr_fitness/features/club/domain/entities/havok_thread.dart';
import 'package:bldr_fitness/features/club/domain/entities/havok_workout.dart';
import 'package:bldr_fitness/features/club/domain/repositories/club_workout_repository.dart';
import 'package:bldr_fitness/features/club/domain/repositories/havok_repository.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

class FakeClubWorkoutRepository implements ClubWorkoutRepository {
  String? lastCall;
  Map<String, Object?> lastArgs = {};
  bool inChallenge = false;

  @override
  Future<Result<List<WorkoutTemplate>>> myTemplates() async {
    lastCall = 'myTemplates';
    return const Result.success([]);
  }

  @override
  Future<Result<void>> createTemplate(WorkoutTemplate template) async {
    lastCall = 'createTemplate';
    lastArgs = {'name': template.name, 'type': template.workoutType};
    return const Result.success(null);
  }

  @override
  Future<Result<void>> updateTemplate(WorkoutTemplate template) async {
    lastCall = 'updateTemplate';
    return const Result.success(null);
  }

  @override
  Future<Result<WorkoutSession>> start(
      {required String name, required String templateId}) async {
    lastCall = 'start';
    lastArgs = {'name': name, 'templateId': templateId};
    return Result.success(WorkoutSession(id: 'w1', name: name));
  }

  @override
  Future<Result<WorkoutSession>> complete(
      {required String workoutId, String? notes}) async {
    lastCall = 'complete';
    return Result.success(WorkoutSession(id: workoutId, name: 'Treino'));
  }

  @override
  Future<Result<void>> completeSet(
      {required String setId, int? reps, double? weightKg}) async {
    lastCall = 'completeSet';
    lastArgs = {'setId': setId, 'reps': reps, 'weightKg': weightKg};
    return const Result.success(null);
  }

  @override
  Future<Result<void>> undoSet(String setId) async {
    lastCall = 'undoSet';
    return const Result.success(null);
  }

  @override
  Stream<WorkoutSession?> activeWorkoutStream() => Stream.value(null);

  @override
  Future<Result<List<WorkoutSession>>> userWorkouts(
          {bool completedOnly = false, int limit = 20}) async =>
      const Result.success([]);

  @override
  Future<Result<void>> logCardio(
      {required String label,
      required String activityType,
      required int durationSeconds}) async {
    lastCall = 'logCardio';
    lastArgs = {'label': label, 'seconds': durationSeconds};
    return const Result.success(null);
  }

  @override
  Future<Result<bool>> isUserInActiveChallenge() async =>
      Result.success(inChallenge);

  @override
  Future<Result<List<WorkoutTemplate>>> publicTemplates({int limit = 50}) async =>
      const Result.success([]);

  @override
  Future<Result<List<TemplateExercise>>> templateExercises(
          String templateId) async =>
      const Result.success([]);

  @override
  Future<Result<List<WorkoutSession>>> workoutsBetween(
          DateTime start, DateTime end) async =>
      const Result.success([]);

  @override
  Future<Result<List<ClubActivity>>> activitiesBetween(
          DateTime start, DateTime end) async =>
      const Result.success([]);

  @override
  Future<Result<int>> xpBetween(DateTime start, DateTime end) async =>
      const Result.success(0);

  @override
  Future<Result<WorkoutSession?>> workoutDetails(String workoutId) async =>
      const Result.success(null);

  @override
  Future<Result<List<RunActivity>>> runActivities({int? limit}) async =>
      const Result.success([]);

  @override
  Future<Result<void>> saveRun({
    required double distanceMeters,
    required int durationSeconds,
    required String paceText,
    required List<Map<String, dynamic>> routeData,
    required int earnedXp,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<WorkoutTemplate?>> templateWithExercises(
          String templateId) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deleteTemplate(String templateId) async =>
      const Result.success(null);

  @override
  Future<Result<List<PausedWorkoutSummary>>> pausedSummaries(
          {int limit = 2}) async =>
      const Result.success([]);

  @override
  Future<Result<void>> deletePaused(String workoutId) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deleteWorkoutRecord(String workoutId) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deleteActivityRecord(String activityId) async =>
      const Result.success(null);

  @override
  Future<Result<void>> ensureClubInitialSets(String sessionId, String templateId) async =>
      const Result.success(null);

  @override
  Future<Result<void>> saveMatchSession({
    required String modality,
    required String result,
    required List<Map<String, dynamic>> sets,
    required int intensity,
    required int durationSec,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<List<MatchSession>>> matchSessions({int limit = 50}) async =>
      const Result.success([]);

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

class FakeHavokRepository implements HavokRepository {
  Result<SavedWorkout>? generateHavokWorkoutResult;

  HavokThread? existingTodayThread;
  String? lastOriginScreen;
  List<HavokMessage> threadMessages = [];
  Result<HavokMessage>? sendMessageResult;
  Map<String, dynamic>? lastContext;
  DateTime? lastDismissedDate;

  @override
  Future<Result<Map<String, dynamic>>> generateFreeWorkout(
          String userPrompt) async =>
      const Result.success({});

  @override
  Future<Result<SavedWorkout>> generateHavokWorkout() async =>
      generateHavokWorkoutResult ??
      Result.success(SavedWorkout(
        id: 'w0',
        name: 'Treino',
        createdAt: DateTime(2026, 1, 1),
        workoutData: const {},
      ));

  @override
  Future<Result<Map<String, dynamic>>> generateRecipe(String userQuery) async =>
      const Result.success({});

  @override
  Future<Result<void>> saveRecipe(Map<String, dynamic> recipeData) async =>
      const Result.success(null);

  @override
  Future<Result<List<Map<String, dynamic>>>> myRecipes() async =>
      const Result.success([]);

  @override
  Future<Result<List<Map<String, dynamic>>>> myWorkouts() async =>
      const Result.success([]);

  @override
  Future<Result<HavokThread>> getOrCreateTodayThread(String originScreen) async {
    lastOriginScreen = originScreen;
    return Result.success(existingTodayThread ??
        HavokThread(
          id: 't1',
          userId: 'u1',
          createdAt: DateTime.now(),
          lastMessageAt: DateTime.now(),
          originScreen: originScreen,
        ));
  }

  @override
  Future<Result<List<HavokMessage>>> getThreadMessages(String threadId) async =>
      Result.success(threadMessages);

  @override
  Future<Result<HavokMessage>> sendMessage({
    required String threadId,
    required String userMessage,
    required String originScreen,
    required Map<String, dynamic> context,
  }) async {
    lastContext = context;
    return sendMessageResult ??
        Result.success(HavokMessage(
          id: 'm1',
          threadId: threadId,
          role: 'assistant',
          content: 'Resposta padrão',
          createdAt: DateTime.now(),
        ));
  }

  @override
  Future<Result<void>> dismissInsight(DateTime date) async {
    lastDismissedDate = date;
    return const Result.success(null);
  }

  @override
  Future<Result<int>> getDailyMessageCount() async => const Result.success(0);
}

void main() {
  late FakeClubWorkoutRepository repo;

  setUp(() => repo = FakeClubWorkoutRepository());

  test('StartClubWorkout repassa nome e template', () async {
    final result = await StartClubWorkout(repo)(
        name: 'HIIT Pesado', templateId: 't9');
    expect(result.valueOrNull?.id, 'w1');
    expect(repo.lastArgs['templateId'], 't9');
  });

  test('CompleteClubSet repassa peso e reps', () async {
    await CompleteClubSet(repo)(setId: 's1', reps: 12, weightKg: 40);
    expect(repo.lastCall, 'completeSet');
    expect(repo.lastArgs['weightKg'], 40.0);
  });

  test('LogClubCardio repassa duração', () async {
    await LogClubCardio(repo)(
        label: 'Corrida', activityType: 'run', durationSeconds: 1800);
    expect(repo.lastArgs['seconds'], 1800);
  });

  test('IsUserInActiveChallenge reflete o repositório', () async {
    expect((await IsUserInActiveChallenge(repo)()).valueOrNull, false);
    repo.inChallenge = true;
    expect((await IsUserInActiveChallenge(repo)()).valueOrNull, true);
  });

  test('ClubAnnouncement entidade guarda os campos do banner', () {
    const a = ClubAnnouncement(
        title: 'Novo desafio', imageUrl: 'x.png', linkUrl: 'https://b.com');
    expect(a.title, 'Novo desafio');
    expect(a.imageUrlMain, isNull);
  });

  group('GenerateHavokWorkout (HAVOK_SPEC.md §10 — round-trip)', () {
    late FakeHavokRepository havokRepo;

    setUp(() => havokRepo = FakeHavokRepository());

    test('retorna o SavedWorkout já devolvido pela edge function, '
        'sem precisar de um SELECT adicional', () async {
      final workout = SavedWorkout(
        id: 'hw1',
        name: 'Protocolo Hipertrofia',
        createdAt: DateTime(2026, 8, 1),
        workoutData: const {
          'nome': 'Protocolo Hipertrofia',
          'exercicios': [
            {'nome': 'Supino reto', 'series': 4, 'repeticoes': '8-12'},
          ],
        },
      );
      havokRepo.generateHavokWorkoutResult = Result.success(workout);

      final result = await GenerateHavokWorkout(havokRepo)();

      expect(result.valueOrNull?.id, 'hw1');
      expect(result.valueOrNull?.workoutData['nome'], 'Protocolo Hipertrofia');
    });

    test('propaga a falha sem alterá-la', () async {
      const failure = ServerFailure('Falha na função gerar-treino-havok.');
      havokRepo.generateHavokWorkoutResult = const Result.failure(failure);

      final result = await GenerateHavokWorkout(havokRepo)();

      expect(result.failureOrNull, failure);
    });
  });

  group('SavedWorkout.fromMap (linha de bldr_club.havok_workouts)', () {
    test('parseia id, nome, data e workout_data', () {
      final workout = SavedWorkout.fromMap({
        'id': 'hw2',
        'workout_name': 'Treino de Pernas',
        'created_at': '2026-08-01T12:00:00.000Z',
        'workout_data': {
          'nome': 'Treino de Pernas',
          'exercicios': [
            {'nome': 'Agachamento', 'series': 4, 'repeticoes': '10'},
          ],
        },
      });

      expect(workout.id, 'hw2');
      expect(workout.name, 'Treino de Pernas');
      expect(workout.createdAt, DateTime.parse('2026-08-01T12:00:00.000Z'));
      expect(workout.workoutData['exercicios'], hasLength(1));
    });
  });

  group('HavokMessage.fromMap (B6 — artifact_data persistido)', () {
    test('parseia artifact_type e artifact_data quando presentes', () {
      final message = HavokMessage.fromMap({
        'id': 'm1',
        'thread_id': 't1',
        'role': 'assistant',
        'content': 'Montei um treino pra você.',
        'created_at': '2026-08-03T12:00:00.000Z',
        'artifact_type': 'workout',
        'artifact_data': {
          'nome': 'Treino de Pernas',
          'exercicios': [
            {'nome': 'Agachamento', 'series': 4, 'repeticoes': '10'},
          ],
        },
      });

      expect(message.artifactType, 'workout');
      expect(message.artifactData?['nome'], 'Treino de Pernas');
      expect((message.artifactData?['exercicios'] as List), hasLength(1));
    });

    test('artifactData é null quando a mensagem não tem artefato', () {
      final message = HavokMessage.fromMap({
        'id': 'm2',
        'thread_id': 't1',
        'role': 'user',
        'content': 'Como está minha semana?',
        'created_at': '2026-08-03T12:00:00.000Z',
      });

      expect(message.artifactData, isNull);
      expect(message.artifactType, isNull);
    });
  });

  group('Conversa do HAVOK (L3 — HAVOK_SPEC.md §4)', () {
    late FakeHavokRepository havokRepo;

    setUp(() => havokRepo = FakeHavokRepository());

    test('GetOrCreateTodayThread repassa originScreen', () async {
      final result = await GetOrCreateTodayThread(havokRepo)('dashboard');
      expect(result.valueOrNull?.originScreen, 'dashboard');
      expect(havokRepo.lastOriginScreen, 'dashboard');
    });

    test('GetThreadMessages devolve as mensagens da thread', () async {
      havokRepo.threadMessages = [
        HavokMessage(
          id: 'm1',
          threadId: 't1',
          role: 'user',
          content: 'Oi',
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
      final result = await GetThreadMessages(havokRepo)('t1');
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull?.first.isUser, true);
    });

    test('SendHavokMessage repassa o contexto do usuário para o repositório', () async {
      await SendHavokMessage(havokRepo)(
        threadId: 't1',
        userMessage: 'Como está minha semana?',
        originScreen: 'dashboard',
        context: {'workouts': {'completedThisWeek': 2}},
      );
      expect(havokRepo.lastContext?['workouts']['completedThisWeek'], 2);
    });

    test('SendHavokMessage retorna a mensagem do assistente', () async {
      havokRepo.sendMessageResult = Result.success(HavokMessage(
        id: 'm2',
        threadId: 't1',
        role: 'assistant',
        content: 'Você fez 2 de 4 treinos essa semana.',
        createdAt: DateTime(2026, 1, 1),
      ));
      final result = await SendHavokMessage(havokRepo)(
        threadId: 't1',
        userMessage: 'Como está minha semana?',
        originScreen: 'dashboard',
        context: const {},
      );
      expect(result.valueOrNull?.role, 'assistant');
      expect(result.valueOrNull?.content, contains('2 de 4'));
    });

    test('DismissHavokInsight persiste a data informada', () async {
      final date = DateTime(2026, 8, 3);
      await DismissHavokInsight(havokRepo)(date);
      expect(havokRepo.lastDismissedDate, date);
    });
  });
}
