import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/profile/domain/repositories/user_timezone_repository.dart';
import 'package:bldr_fitness/features/club/domain/repositories/club_workout_repository.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/activity_type.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/extra_activity.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_summary_data.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/weekly_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/extra_activity_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/weekly_plan_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/workout_session_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/workout_template_repository.dart';

// --- Templates ---

class GetWorkoutTemplates {
  final WorkoutTemplateRepository _repo;
  const GetWorkoutTemplates(this._repo);

  Future<Result<List<WorkoutTemplate>>> call({
    String? workoutType,
    int? difficultyLevel,
    bool publicOnly = false,
  }) =>
      _repo.templates(
        workoutType: workoutType,
        difficultyLevel: difficultyLevel,
        publicOnly: publicOnly,
      );
}

class GetTemplateWithExercises {
  final WorkoutTemplateRepository _repo;
  const GetTemplateWithExercises(this._repo);

  Future<Result<WorkoutTemplate?>> call(String templateId) =>
      _repo.templateWithExercises(templateId);
}

class CreateWorkoutTemplate {
  final WorkoutTemplateRepository _repo;
  const CreateWorkoutTemplate(this._repo);

  Future<Result<WorkoutTemplate>> call(WorkoutTemplate template) =>
      _repo.create(template);
}

class UpdateWorkoutTemplate {
  final WorkoutTemplateRepository _repo;
  const UpdateWorkoutTemplate(this._repo);

  Future<Result<WorkoutTemplate>> call(WorkoutTemplate template) =>
      _repo.update(template);
}

class DeleteWorkoutTemplate {
  final WorkoutTemplateRepository _repo;
  const DeleteWorkoutTemplate(this._repo);

  Future<Result<void>> call(String templateId) => _repo.delete(templateId);
}

// --- Sessões ---

class StartWorkout {
  final WorkoutSessionRepository _repo;
  const StartWorkout(this._repo);

  Future<Result<WorkoutSession>> call({
    required String name,
    String? templateId,
  }) =>
      _repo.start(name: name, templateId: templateId);
}

class CompleteWorkout {
  final WorkoutSessionRepository _repo;
  const CompleteWorkout(this._repo);

  Future<Result<WorkoutSession>> call({
    required String workoutId,
    String? notes,
  }) =>
      _repo.complete(workoutId: workoutId, notes: notes);
}

class CompleteWorkoutWithAnalytics {
  final WorkoutSessionRepository _repo;
  const CompleteWorkoutWithAnalytics(this._repo);

  Future<Result<WorkoutSummaryData>> call({
    required String workoutId,
    required String source,
    required int setsCompleted,
    int? exerciseCount,
    String? notes,
  }) =>
      _repo.completeWithAnalytics(
        workoutId: workoutId,
        source: source,
        setsCompleted: setsCompleted,
        exerciseCount: exerciseCount,
        notes: notes,
      );
}

class LogWorkoutSet {
  final WorkoutSessionRepository _repo;
  const LogWorkoutSet(this._repo);

  Future<Result<WorkoutSet>> call(WorkoutSet set) => _repo.logSet(set);
}

class CompleteWorkoutSet {
  final WorkoutSessionRepository _repo;
  const CompleteWorkoutSet(this._repo);

  Future<Result<void>> call({
    required String setId,
    int? reps,
    double? weightKg,
  }) =>
      _repo.completeSet(setId: setId, reps: reps, weightKg: weightKg);
}

class UndoWorkoutSet {
  final WorkoutSessionRepository _repo;
  const UndoWorkoutSet(this._repo);

  Future<Result<void>> call(String setId) => _repo.undoSet(setId);
}

class HasActiveWorkout {
  final WorkoutSessionRepository _repo;
  const HasActiveWorkout(this._repo);

  Future<Result<bool>> call() => _repo.hasActiveWorkout();
}

class GetActiveWorkoutDetails {
  final WorkoutSessionRepository _repo;
  const GetActiveWorkoutDetails(this._repo);

  Future<Result<WorkoutSession?>> call() => _repo.activeWorkoutDetails();
}

class WatchActiveWorkout {
  final WorkoutSessionRepository _repo;
  const WatchActiveWorkout(this._repo);

  Stream<WorkoutSession?> call() => _repo.activeWorkoutStream();
}

class GetWorkoutDetails {
  final WorkoutSessionRepository _repo;
  const GetWorkoutDetails(this._repo);

  Future<Result<WorkoutSession?>> call(String workoutId) =>
      _repo.workoutDetails(workoutId);
}

class GetWorkoutHistory {
  final WorkoutSessionRepository _repo;
  const GetWorkoutHistory(this._repo);

  Future<Result<List<WorkoutSession>>> call({
    String? userId,
    bool completedOnly = false,
    int limit = 20,
  }) =>
      _repo.history(userId: userId, completedOnly: completedOnly, limit: limit);
}

class GetPausedWorkouts {
  final WorkoutSessionRepository _repo;
  const GetPausedWorkouts(this._repo);

  Future<Result<List<PausedWorkoutSummary>>> call({int limit = 2}) =>
      _repo.pausedSummaries(limit: limit);
}

class EnsureWorkoutSets {
  final WorkoutSessionRepository _repo;
  const EnsureWorkoutSets(this._repo);

  /// Cria os sets iniciais se `workout_exercise_sets` estiver vazio.
  /// Idempotente — seguro chamar mesmo que os sets já existam.
  Future<Result<void>> call(String sessionId, String templateId) =>
      _repo.ensureInitialSets(sessionId, templateId);
}

class DeletePausedWorkout {
  final WorkoutSessionRepository _repo;
  const DeletePausedWorkout(this._repo);

  /// [source]: 'free' ou 'club'.
  Future<Result<void>> call(String workoutId, String source) =>
      _repo.deletePaused(workoutId, source);
}

class DeleteCompletedWorkout {
  final WorkoutSessionRepository _repo;
  const DeleteCompletedWorkout(this._repo);

  Future<Result<void>> call(String workoutId) =>
      _repo.deleteCompleted(workoutId);
}

// --- Plano semanal ---

class GetWeeklyPlanConfig {
  final WeeklyPlanRepository _repo;
  const GetWeeklyPlanConfig(this._repo);

  Future<Result<WeeklyPlanConfig>> call() => _repo.planConfig();
}

class SaveWeeklyPlanConfig {
  final WeeklyPlanRepository _repo;
  const SaveWeeklyPlanConfig(this._repo);

  Future<Result<void>> call({
    required String splitPreference,
    required List<int> restDays,
  }) =>
      _repo.savePlanConfig(
          splitPreference: splitPreference, restDays: restDays);
}

class SaveWeeklyPlan {
  final WeeklyPlanRepository _repo;
  const SaveWeeklyPlan(this._repo);

  Future<Result<void>> call(List<PlanDay> days) => _repo.saveWeeklyPlan(days);
}

class GetWeeklyPlan {
  final WeeklyPlanRepository _repo;
  const GetWeeklyPlan(this._repo);

  Future<Result<List<PlanDay>>> call() => _repo.getWeeklyPlan();
}

/// Atualiza (upsert) o template atribuído a um único dia da semana.
/// Passa [template] null para definir o dia como descanso.
class UpdatePlanDay {
  final WeeklyPlanRepository _repo;
  const UpdatePlanDay(this._repo);

  Future<Result<void>> call(int diaSemana, {WorkoutTemplate? template}) =>
      _repo.saveWeeklyPlan([
        PlanDay(
          diaSemana: diaSemana,
          tipo: template != null ? 'treino' : 'descanso',
          treino: template,
        ),
      ]);
}

class GetWeekCompletedWorkouts {
  final WeeklyPlanRepository _repo;
  const GetWeekCompletedWorkouts(this._repo);

  Future<Result<WeekCompletedWorkouts>> call(
          DateTime weekStart, DateTime weekEnd) =>
      _repo.completedBetween(weekStart, weekEnd);
}

class GetWorkoutMuscles {
  final WeeklyPlanRepository _repo;
  const GetWorkoutMuscles(this._repo);

  Future<Result<List<String>>> call(String workoutId) =>
      _repo.musclesForWorkout(workoutId);
}

class DeleteCompletedClubWorkout {
  final WeeklyPlanRepository _repo;
  const DeleteCompletedClubWorkout(this._repo);

  Future<Result<void>> call(String clubWorkoutId) =>
      _repo.deleteCompletedClub(clubWorkoutId);
}

/// Fonte única de streak (BACKLOG_FUNCIONAL.md B7 / ESTADO_POS_REDESIGN.md
/// §3) — dias consecutivos até hoje com pelo menos um treino concluído,
/// somando `user_workouts` (pessoal) e `club_user_workouts` (Club). Vários
/// treinos no mesmo dia contam como 1 dia só.
class GetCurrentStreak {
  final WorkoutSessionRepository _personal;
  final ClubWorkoutRepository _club;
  final UserTimezoneRepository? _timezoneRepository;
  final String? Function()? _userId;

  const GetCurrentStreak(
    this._personal,
    this._club, {
    UserTimezoneRepository? timezoneRepository,
    String? Function()? userId,
  })  : _timezoneRepository = timezoneRepository,
        _userId = userId;

  Future<Result<int>> call() async {
    final personalResult =
        await _personal.history(completedOnly: true, limit: 200);
    final personalFailure = personalResult.failureOrNull;
    if (personalFailure != null) return Result.failure(personalFailure);

    final clubResult =
        await _club.userWorkouts(completedOnly: true, limit: 200);
    final clubFailure = clubResult.failureOrNull;
    if (clubFailure != null) return Result.failure(clubFailure);

    final timezone = await _resolveTimezone();
    final workedDays = <DateTime>{};
    for (final w in [
      ...personalResult.valueOrNull!,
      ...clubResult.valueOrNull!
    ]) {
      final dt = _localInTimezone(w.completedAt, timezone);
      if (dt != null) workedDays.add(DateTime(dt.year, dt.month, dt.day));
    }

    int streak = 0;
    final now = _localInTimezone(DateTime.now().toUtc(), timezone)!;
    var day = DateTime(now.year, now.month, now.day);
    while (workedDays.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return Result.success(streak);
  }

  Future<String> _resolveTimezone() async {
    final userId = _userId?.call();
    if (_timezoneRepository == null || userId == null) return 'UTC';
    final result = await _timezoneRepository.getTimezone(userId);
    final value = result.valueOrNull?.trim();
    return value?.contains('/') == true ? value! : 'UTC';
  }

  DateTime? _localInTimezone(DateTime? timestamp, String timezone) {
    if (timestamp == null) return null;
    tz_data.initializeTimeZones();
    try {
      final local =
          tz.TZDateTime.from(timestamp.toUtc(), tz.getLocation(timezone));
      return DateTime(local.year, local.month, local.day);
    } catch (_) {
      final utc = timestamp.toUtc();
      return DateTime.utc(utc.year, utc.month, utc.day);
    }
  }
}

// --- Extra Activities ---

class LogExtraActivity {
  final ExtraActivityRepository _repo;
  const LogExtraActivity(this._repo);

  Future<Result<void>> call({
    required DateTime date,
    required ActivityType activityType,
    int? durationMin,
    String? notes,
  }) =>
      _repo.logExtraActivity(
        date: date,
        activityType: activityType,
        durationMin: durationMin,
        notes: notes,
      );
}

class GetExtraActivities {
  final ExtraActivityRepository _repo;
  const GetExtraActivities(this._repo);

  Future<Result<List<ExtraActivity>>> call(
          DateTime weekStart, DateTime weekEnd) =>
      _repo.getExtraActivities(weekStart, weekEnd);
}
