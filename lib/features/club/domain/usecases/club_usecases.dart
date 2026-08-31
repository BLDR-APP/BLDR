import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/club/domain/entities/club_community.dart';
import 'package:bldr_fitness/features/club/domain/entities/havok_thread.dart';
import 'package:bldr_fitness/features/club/domain/entities/havok_workout.dart';
import 'package:bldr_fitness/features/club/domain/repositories/challenge_repository.dart';
import 'package:bldr_fitness/features/club/domain/repositories/club_community_repository.dart';
import 'package:bldr_fitness/features/club/domain/repositories/club_workout_repository.dart';
import 'package:bldr_fitness/features/club/domain/repositories/havok_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/workout_session_repository.dart';

// --- Treinos Club ---

/// Histórico de treinos consolidado: pessoais (`user_workouts`) +
/// clube (`club_user_workouts`). Fonte única para qualquer tela que precise
/// de "todos os treinos do usuário" — nunca somar as duas tabelas na mão.
class GetConsolidatedWorkoutHistory {
  final WorkoutSessionRepository _personal;
  final ClubWorkoutRepository _club;
  const GetConsolidatedWorkoutHistory(this._personal, this._club);

  Future<Result<List<WorkoutSession>>> call({
    String? userId,
    bool completedOnly = false,
    int limit = 100,
  }) async {
    final personalResult = await _personal.history(
        userId: userId, completedOnly: completedOnly, limit: limit);
    if (personalResult.isFailure) return personalResult;

    final clubResult =
        await _club.userWorkouts(completedOnly: completedOnly, limit: limit);
    if (clubResult.isFailure) return clubResult;

    final combined = [
      ...personalResult.valueOrNull!,
      ...clubResult.valueOrNull!,
    ];
    combined.sort((a, b) {
      final dateA = a.completedAt ?? a.startedAt;
      final dateB = b.completedAt ?? b.startedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });
    return Result.success(combined);
  }
}

class GetMyClubTemplates {
  final ClubWorkoutRepository _repo;
  const GetMyClubTemplates(this._repo);

  Future<Result<List<WorkoutTemplate>>> call() => _repo.myTemplates();
}

class CreateClubTemplate {
  final ClubWorkoutRepository _repo;
  const CreateClubTemplate(this._repo);

  Future<Result<void>> call(WorkoutTemplate template) =>
      _repo.createTemplate(template);
}

class UpdateClubTemplate {
  final ClubWorkoutRepository _repo;
  const UpdateClubTemplate(this._repo);

  Future<Result<void>> call(WorkoutTemplate template) =>
      _repo.updateTemplate(template);
}

class StartClubWorkout {
  final ClubWorkoutRepository _repo;
  const StartClubWorkout(this._repo);

  Future<Result<WorkoutSession>> call({
    required String name,
    required String templateId,
  }) =>
      _repo.start(name: name, templateId: templateId);
}

class CompleteClubWorkout {
  final ClubWorkoutRepository _repo;
  const CompleteClubWorkout(this._repo);

  Future<Result<WorkoutSession>> call({
    required String workoutId,
    String? notes,
  }) =>
      _repo.complete(workoutId: workoutId, notes: notes);
}

class CompleteClubSet {
  final ClubWorkoutRepository _repo;
  const CompleteClubSet(this._repo);

  Future<Result<void>> call({
    required String setId,
    int? reps,
    double? weightKg,
  }) =>
      _repo.completeSet(setId: setId, reps: reps, weightKg: weightKg);
}

class UndoClubSet {
  final ClubWorkoutRepository _repo;
  const UndoClubSet(this._repo);

  Future<Result<void>> call(String setId) => _repo.undoSet(setId);
}

class WatchActiveClubWorkout {
  final ClubWorkoutRepository _repo;
  const WatchActiveClubWorkout(this._repo);

  Stream<WorkoutSession?> call() => _repo.activeWorkoutStream();
}

class GetClubWorkoutHistory {
  final ClubWorkoutRepository _repo;
  const GetClubWorkoutHistory(this._repo);

  Future<Result<List<WorkoutSession>>> call({
    bool completedOnly = false,
    int limit = 20,
  }) =>
      _repo.userWorkouts(completedOnly: completedOnly, limit: limit);
}

class LogClubCardio {
  final ClubWorkoutRepository _repo;
  const LogClubCardio(this._repo);

  Future<Result<void>> call({
    required String label,
    required String activityType,
    required int durationSeconds,
  }) =>
      _repo.logCardio(
        label: label,
        activityType: activityType,
        durationSeconds: durationSeconds,
      );
}

class IsUserInActiveChallenge {
  final ClubWorkoutRepository _repo;
  const IsUserInActiveChallenge(this._repo);

  Future<Result<bool>> call() => _repo.isUserInActiveChallenge();
}

class GetClubPublicTemplates {
  final ClubWorkoutRepository _repo;
  const GetClubPublicTemplates(this._repo);

  Future<Result<List<WorkoutTemplate>>> call({int limit = 50}) =>
      _repo.publicTemplates(limit: limit);
}

class GetClubTemplateExercises {
  final ClubWorkoutRepository _repo;
  const GetClubTemplateExercises(this._repo);

  Future<Result<List<TemplateExercise>>> call(String templateId) =>
      _repo.templateExercises(templateId);
}

class GetClubWorkoutsBetween {
  final ClubWorkoutRepository _repo;
  const GetClubWorkoutsBetween(this._repo);

  Future<Result<List<WorkoutSession>>> call(DateTime start, DateTime end) =>
      _repo.workoutsBetween(start, end);
}

class GetClubActivitiesBetween {
  final ClubWorkoutRepository _repo;
  const GetClubActivitiesBetween(this._repo);

  Future<Result<List<ClubActivity>>> call(DateTime start, DateTime end) =>
      _repo.activitiesBetween(start, end);
}

class GetClubXpBetween {
  final ClubWorkoutRepository _repo;
  const GetClubXpBetween(this._repo);

  Future<Result<int>> call(DateTime start, DateTime end) =>
      _repo.xpBetween(start, end);
}

class GetClubWorkoutDetails {
  final ClubWorkoutRepository _repo;
  const GetClubWorkoutDetails(this._repo);

  Future<Result<WorkoutSession?>> call(String workoutId) =>
      _repo.workoutDetails(workoutId);
}

class GetClubTemplateWithExercises {
  final ClubWorkoutRepository _repo;
  const GetClubTemplateWithExercises(this._repo);

  Future<Result<WorkoutTemplate?>> call(String templateId) =>
      _repo.templateWithExercises(templateId);
}

class DeleteClubTemplate {
  final ClubWorkoutRepository _repo;
  const DeleteClubTemplate(this._repo);

  Future<Result<void>> call(String templateId) =>
      _repo.deleteTemplate(templateId);
}

class GetPausedClubWorkouts {
  final ClubWorkoutRepository _repo;
  const GetPausedClubWorkouts(this._repo);

  Future<Result<List<PausedWorkoutSummary>>> call({int limit = 2}) =>
      _repo.pausedSummaries(limit: limit);
}

class DeletePausedClubWorkout {
  final ClubWorkoutRepository _repo;
  const DeletePausedClubWorkout(this._repo);

  Future<Result<void>> call(String workoutId) => _repo.deletePaused(workoutId);
}

class DeleteClubWorkoutRecord {
  final ClubWorkoutRepository _repo;
  const DeleteClubWorkoutRecord(this._repo);

  Future<Result<void>> call(String workoutId) =>
      _repo.deleteWorkoutRecord(workoutId);
}

class DeleteClubActivityRecord {
  final ClubWorkoutRepository _repo;
  const DeleteClubActivityRecord(this._repo);

  Future<Result<void>> call(String activityId) =>
      _repo.deleteActivityRecord(activityId);
}

// --- Comunidade (conteúdo editorial) ---

class GetClubAnnouncements {
  final ClubCommunityRepository _repo;
  const GetClubAnnouncements(this._repo);

  Future<Result<List<ClubAnnouncement>>> call({int limit = 20}) =>
      _repo.announcements(limit: limit);
}

class GetClubEvents {
  final ClubCommunityRepository _repo;
  const GetClubEvents(this._repo);

  Future<Result<List<ClubEvent>>> call({int limit = 20}) =>
      _repo.events(limit: limit);
}

// --- Comunidade competitiva (feed, ranking, duelos, desafios coletivos) ---

class GetXpFeed {
  final ChallengeRepository _repo;
  const GetXpFeed(this._repo);

  Future<Result<List<XpFeedItem>>> call({int limit = 50}) =>
      _repo.xpFeed(limit: limit);
}

class ReactToXpEvent {
  final ChallengeRepository _repo;
  const ReactToXpEvent(this._repo);

  Future<Result<void>> call(String eventId) => _repo.reactToXpEvent(eventId);
}

class RemoveReactionFromXpEvent {
  final ChallengeRepository _repo;
  const RemoveReactionFromXpEvent(this._repo);

  Future<Result<void>> call(String eventId) =>
      _repo.removeReactionFromXpEvent(eventId);
}

class GetMyReactions {
  final ChallengeRepository _repo;
  const GetMyReactions(this._repo);

  Future<Result<Set<String>>> call(List<String> eventIds) =>
      _repo.myReactions(eventIds);
}

class GetClubRanking {
  final ChallengeRepository _repo;
  const GetClubRanking(this._repo);

  Future<Result<List<ClubRankingEntry>>> call({int limit = 100}) =>
      _repo.ranking(limit: limit);
}

class GetMyDuels {
  final ChallengeRepository _repo;
  const GetMyDuels(this._repo);

  Future<Result<List<Duel>>> call({int limit = 20}) =>
      _repo.myDuels(limit: limit);
}

class RespondDuel {
  final ChallengeRepository _repo;
  const RespondDuel(this._repo);

  Future<Result<void>> call(String duelId, {required bool accept}) =>
      _repo.respondDuel(duelId, accept: accept);
}

class GetCollectiveChallenges {
  final ChallengeRepository _repo;
  const GetCollectiveChallenges(this._repo);

  Future<Result<List<CollectiveChallenge>>> call({int limit = 10}) =>
      _repo.collectiveChallenges(limit: limit);
}

class JoinCollectiveChallenge {
  final ChallengeRepository _repo;
  const JoinCollectiveChallenge(this._repo);

  Future<Result<void>> call(String challengeId) =>
      _repo.joinChallenge(challengeId);
}

class LeaveCollectiveChallenge {
  final ChallengeRepository _repo;
  const LeaveCollectiveChallenge(this._repo);

  Future<Result<void>> call(String challengeId) =>
      _repo.leaveChallenge(challengeId);
}

class CreateCollectiveChallenge {
  final ChallengeRepository _repo;
  const CreateCollectiveChallenge(this._repo);

  Future<Result<void>> call(NewCollectiveChallenge data) =>
      _repo.createCollectiveChallenge(data);
}

class GetChallengeDetail {
  final ChallengeRepository _repo;
  const GetChallengeDetail(this._repo);

  Future<Result<CollectiveChallenge?>> call(String challengeId) =>
      _repo.challengeDetail(challengeId);
}

class GetMyChallengeParticipation {
  final ChallengeRepository _repo;
  const GetMyChallengeParticipation(this._repo);

  Future<Result<ChallengeParticipation>> call(String challengeId) =>
      _repo.myParticipation(challengeId);
}

class GetChallengeTopContributors {
  final ChallengeRepository _repo;
  const GetChallengeTopContributors(this._repo);

  Future<Result<List<ChallengeContributor>>> call(String challengeId,
          {int limit = 10}) =>
      _repo.topContributors(challengeId, limit: limit);
}

class GetChallengeFeed {
  final ChallengeRepository _repo;
  const GetChallengeFeed(this._repo);

  Future<Result<List<ChallengeFeedItem>>> call(String challengeId,
          {DateTime? since}) =>
      _repo.challengeFeed(challengeId, since: since);
}

class GetChallengeMilestones {
  final ChallengeRepository _repo;
  const GetChallengeMilestones(this._repo);

  Future<Result<List<ChallengeMilestone>>> call(String challengeId) =>
      _repo.milestones(challengeId);
}

class GetChallengeComments {
  final ChallengeRepository _repo;
  const GetChallengeComments(this._repo);

  Future<Result<List<ChallengeComment>>> call(String challengeId,
          {int limit = 30}) =>
      _repo.comments(challengeId, limit: limit);
}

class AddChallengeComment {
  final ChallengeRepository _repo;
  const AddChallengeComment(this._repo);

  Future<Result<void>> call(String challengeId, String content) =>
      _repo.addComment(challengeId, content);
}

class ReportChallenge {
  final ChallengeRepository _repo;
  const ReportChallenge(this._repo);

  Future<Result<void>> call(String challengeId, String reason) =>
      _repo.reportChallenge(challengeId, reason);
}

class UpdateChallengeSettings {
  final ChallengeRepository _repo;
  const UpdateChallengeSettings(this._repo);

  Future<Result<void>> call(
    String challengeId, {
    required List<String>? allowedSources,
    num? targetValue,
  }) =>
      _repo.updateChallengeSettings(challengeId,
          allowedSources: allowedSources, targetValue: targetValue);
}

class GetPendingDuelInvite {
  final ChallengeRepository _repo;
  const GetPendingDuelInvite(this._repo);

  Future<Result<DuelInvite?>> call() => _repo.pendingDuelInvite();
}

class CheckActiveDuel {
  final ChallengeRepository _repo;
  const CheckActiveDuel(this._repo);

  Future<Result<ActiveDuelStatus?>> call() => _repo.checkActiveDuel();
}

class SendDuelInvite {
  final ChallengeRepository _repo;
  const SendDuelInvite(this._repo);

  Future<Result<void>> call({
    required String opponentId,
    required int targetXp,
    required DateTime expiresAt,
  }) =>
      _repo.sendDuelInvite(
          opponentId: opponentId, targetXp: targetXp, expiresAt: expiresAt);
}

class GetRunActivities {
  final ClubWorkoutRepository _repo;
  const GetRunActivities(this._repo);

  Future<Result<List<ClubActivityRun>>> call({int? limit}) =>
      _repo.runActivities(limit: limit);
}

typedef ClubActivityRun = RunActivity;

class SaveMatchSession {
  final ClubWorkoutRepository _repo;
  const SaveMatchSession(this._repo);

  Future<Result<void>> call({
    required String modality,
    required String result,
    required List<Map<String, dynamic>> sets,
    required int intensity,
    required int durationSec,
  }) =>
      _repo.saveMatchSession(
        modality: modality,
        result: result,
        sets: sets,
        intensity: intensity,
        durationSec: durationSec,
      );
}

class GetMatchHistory {
  final ClubWorkoutRepository _repo;
  const GetMatchHistory(this._repo);

  Future<Result<List<MatchSession>>> call({int limit = 50}) =>
      _repo.matchSessions(limit: limit);
}

// --- Operação da Semana (F21) ---

class GetCurrentOperation {
  final ClubWorkoutRepository _repo;
  const GetCurrentOperation(this._repo);

  Future<Result<WeeklyOperation?>> call() => _repo.getCurrentOperation();
}

class GetOperationProgress {
  final ClubWorkoutRepository _repo;
  const GetOperationProgress(this._repo);

  Future<Result<OperationProgress?>> call(String operationId) =>
      _repo.getOperationProgress(operationId);
}

class TryIncrementOperation {
  final ClubWorkoutRepository _repo;
  const TryIncrementOperation(this._repo);

  Future<Result<void>> call(String goalType, int delta) =>
      _repo.tryIncrementOperation(goalType, delta);
}

class SaveRunActivity {
  final ClubWorkoutRepository _repo;
  const SaveRunActivity(this._repo);

  Future<Result<void>> call({
    required double distanceMeters,
    required int durationSeconds,
    required String paceText,
    required List<Map<String, dynamic>> routeData,
    required int earnedXp,
  }) =>
      _repo.saveRun(
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        paceText: paceText,
        routeData: routeData,
        earnedXp: earnedXp,
      );
}

// --- HAVOK (IA) ---

class GenerateFreeWorkout {
  final HavokRepository _repo;
  const GenerateFreeWorkout(this._repo);

  Future<Result<Map<String, dynamic>>> call(String userPrompt) =>
      _repo.generateFreeWorkout(userPrompt);
}

class GenerateHavokWorkout {
  final HavokRepository _repo;
  const GenerateHavokWorkout(this._repo);

  Future<Result<SavedWorkout>> call() => _repo.generateHavokWorkout();
}

class GenerateHavokRecipe {
  final HavokRepository _repo;
  const GenerateHavokRecipe(this._repo);

  Future<Result<Map<String, dynamic>>> call(String userQuery) =>
      _repo.generateRecipe(userQuery);
}

class SaveHavokRecipe {
  final HavokRepository _repo;
  const SaveHavokRecipe(this._repo);

  Future<Result<void>> call(Map<String, dynamic> recipeData) =>
      _repo.saveRecipe(recipeData);
}

class GetHavokRecipes {
  final HavokRepository _repo;
  const GetHavokRecipes(this._repo);

  Future<Result<List<Map<String, dynamic>>>> call() => _repo.myRecipes();
}

class GetHavokWorkouts {
  final HavokRepository _repo;
  const GetHavokWorkouts(this._repo);

  Future<Result<List<Map<String, dynamic>>>> call() => _repo.myWorkouts();
}

// --- HAVOK (conversa) ---

class GetOrCreateTodayThread {
  final HavokRepository _repo;
  const GetOrCreateTodayThread(this._repo);

  Future<Result<HavokThread>> call(String originScreen) =>
      _repo.getOrCreateTodayThread(originScreen);
}

class GetThreadMessages {
  final HavokRepository _repo;
  const GetThreadMessages(this._repo);

  Future<Result<List<HavokMessage>>> call(String threadId) =>
      _repo.getThreadMessages(threadId);
}

class SendHavokMessage {
  final HavokRepository _repo;
  const SendHavokMessage(this._repo);

  Future<Result<HavokMessage>> call({
    required String threadId,
    required String userMessage,
    required String originScreen,
    required Map<String, dynamic> context,
  }) =>
      _repo.sendMessage(
        threadId: threadId,
        userMessage: userMessage,
        originScreen: originScreen,
        context: context,
      );
}

class DismissHavokInsight {
  final HavokRepository _repo;
  const DismissHavokInsight(this._repo);

  Future<Result<void>> call(DateTime date) => _repo.dismissInsight(date);
}

class GetHavokDailyCount {
  final HavokRepository _repo;
  const GetHavokDailyCount(this._repo);

  Future<Result<int>> call() => _repo.getDailyMessageCount();
}

class GetHavokMemories {
  final HavokRepository _repo;
  const GetHavokMemories(this._repo);
  Future<Result<List<HavokMemory>>> call() => _repo.getMemories();
}

class UpdateHavokMemory {
  final HavokRepository _repo;
  const UpdateHavokMemory(this._repo);
  Future<Result<void>> call(HavokMemory memory, dynamic value) =>
      _repo.updateMemory(memory, value);
}

class ForgetHavokMemory {
  final HavokRepository _repo;
  const ForgetHavokMemory(this._repo);
  Future<Result<void>> call(String id) => _repo.forgetMemory(id);
}

class ClearHavokMemories {
  final HavokRepository _repo;
  const ClearHavokMemories(this._repo);
  Future<Result<void>> call() => _repo.clearMemories();
}

class GetClubNotifications {
  final ChallengeRepository _repo;
  const GetClubNotifications(this._repo);

  Future<Result<List<ClubNotification>>> call({int limit = 50}) =>
      _repo.notifications(limit: limit);
}

class MarkAllNotificationsRead {
  final ChallengeRepository _repo;
  const MarkAllNotificationsRead(this._repo);

  Future<Result<void>> call() => _repo.markAllNotificationsRead();
}

class MarkNotificationRead {
  final ChallengeRepository _repo;
  const MarkNotificationRead(this._repo);

  Future<Result<void>> call(String id) => _repo.markNotificationRead(id);
}

class GetPublicClubProfile {
  final ChallengeRepository _repo;
  const GetPublicClubProfile(this._repo);

  Future<Result<PublicClubProfile>> call(String userId) =>
      _repo.publicProfile(userId);
}

class GetMyRankingEntry {
  final ChallengeRepository _repo;
  const GetMyRankingEntry(this._repo);

  Future<Result<ClubRankingEntry?>> call() => _repo.myRankingEntry();
}

class GetPastChallenges {
  final ChallengeRepository _repo;
  const GetPastChallenges(this._repo);

  Future<Result<List<PastChallengeEntry>>> call({int limit = 20}) =>
      _repo.pastChallenges(limit: limit);
}

class EnsureClubWorkoutSets {
  final ClubWorkoutRepository _repo;
  const EnsureClubWorkoutSets(this._repo);

  /// Cria os sets iniciais se `club_workout_exercise_sets` estiver vazio.
  /// Idempotente — seguro chamar mesmo que os sets já existam.
  Future<Result<void>> call(String sessionId, String templateId) =>
      _repo.ensureClubInitialSets(sessionId, templateId);
}
