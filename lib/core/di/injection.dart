import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import 'package:bldr_fitness/core/providers/locale_provider.dart';
import 'package:bldr_fitness/core/time/device_timezone_service.dart';
import 'package:bldr_fitness/features/community/data/repositories/community_feed_repository_impl.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/profile/data/repositories/feedback_repository_impl.dart';
import 'package:bldr_fitness/features/profile/domain/repositories/feedback_repository.dart';
import 'package:bldr_fitness/features/profile/domain/usecases/feedback_usecases.dart';

import 'package:bldr_fitness/features/app_version/domain/app_version_repository.dart';
import 'package:bldr_fitness/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:bldr_fitness/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/achievements/data/repositories/achievements_repository_impl.dart';
import 'package:bldr_fitness/features/achievements/domain/repositories/achievements_repository.dart';
import 'package:bldr_fitness/features/achievements/domain/usecases/achievement_usecases.dart';
import 'package:bldr_fitness/features/club/data/datasources/supabase_challenges_datasource.dart';
import 'package:bldr_fitness/features/club/data/datasources/supabase_club_datasource.dart';
import 'package:bldr_fitness/features/club/data/repositories/arena_repository_impl.dart';
import 'package:bldr_fitness/features/club/data/repositories/challenge_repository_impl.dart';
import 'package:bldr_fitness/features/club/data/repositories/club_repositories_impl.dart';
import 'package:bldr_fitness/features/club/data/repositories/havok_repository_impl.dart';
import 'package:bldr_fitness/features/club/domain/usecases/generate_havok_insight.dart';
import 'package:bldr_fitness/features/integrations/data/datasources/whoop_datasource.dart';
import 'package:bldr_fitness/features/integrations/data/datasources/supabase_wearable_activity_datasource.dart';
import 'package:bldr_fitness/features/integrations/data/health_kit_service.dart';
import 'package:bldr_fitness/features/integrations/data/run_live_activity_service.dart';
import 'package:bldr_fitness/features/integrations/data/watch_service.dart';
import 'package:bldr_fitness/features/integrations/data/repositories/whoop_repository_impl.dart';
import 'package:bldr_fitness/features/integrations/data/repositories/wearable_activity_repository_impl.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/whoop_repository.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/wearable_activity_repository.dart';
import 'package:bldr_fitness/features/integrations/domain/usecases/whoop_usecases.dart';
import 'package:bldr_fitness/features/integrations/domain/usecases/wearable_activity_usecases.dart';
import 'package:bldr_fitness/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:bldr_fitness/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:bldr_fitness/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/club/domain/repositories/challenge_repository.dart';
import 'package:bldr_fitness/features/club/domain/repositories/club_community_repository.dart';
import 'package:bldr_fitness/features/club/domain/repositories/club_workout_repository.dart';
import 'package:bldr_fitness/features/club/domain/repositories/havok_repository.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/nutrition/data/datasources/firestore_nutrition_datasource.dart';
import 'package:bldr_fitness/features/nutrition/data/datasources/supabase_nutrition_goals_datasource.dart';
import 'package:bldr_fitness/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:bldr_fitness/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:bldr_fitness/features/subscription/data/datasources/revenue_cat_sdk_gateway.dart';
import 'package:bldr_fitness/features/subscription/data/datasources/apple_revenuecat_migration_datasource.dart';
import 'package:bldr_fitness/features/subscription/data/repositories/apple_revenuecat_migration_repository_impl.dart';
import 'package:bldr_fitness/features/subscription/data/repositories/revenue_cat_service_impl.dart';
import 'package:bldr_fitness/features/subscription/data/revenue_cat_config.dart';
import 'package:bldr_fitness/features/subscription/data/revenue_cat_lifecycle.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/revenue_cat_service.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/apple_revenuecat_migration_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/run_apple_revenuecat_migration.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart';
import 'package:bldr_fitness/features/progress/domain/repositories/progress_repository.dart';
import 'package:bldr_fitness/features/progress/domain/usecases/progress_usecases.dart';
import 'package:bldr_fitness/features/nutrition/data/datasources/supabase_xp_datasource.dart';
import 'package:bldr_fitness/features/nutrition/data/repositories/nutrition_repositories_impl.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/food_catalog_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/nutrition_diary_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/nutrition_goals_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/nutrition_xp_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/workouts/data/datasources/supabase_weekly_plan_datasource.dart';
import 'package:bldr_fitness/features/workouts/data/repositories/extra_activity_repository_impl.dart';
import 'package:bldr_fitness/features/workouts/data/repositories/weekly_plan_repository_impl.dart';
import 'package:bldr_fitness/features/workouts/data/repositories/workout_repositories_impl.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/extra_activity_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/weekly_plan_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/workout_session_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/workout_template_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/features/profile/data/datasources/supabase_privacy_datasource.dart';
import 'package:bldr_fitness/features/profile/data/repositories/privacy_repository_impl.dart';
import 'package:bldr_fitness/features/profile/data/repositories/user_timezone_repository_impl.dart';
import 'package:bldr_fitness/features/profile/data/user_timezone_sync_lifecycle.dart';
import 'package:bldr_fitness/features/profile/domain/repositories/privacy_repository.dart';
import 'package:bldr_fitness/features/profile/domain/repositories/user_timezone_repository.dart';
import 'package:bldr_fitness/features/profile/domain/usecases/privacy_usecases.dart';
import 'package:bldr_fitness/features/profile/domain/usecases/user_timezone_usecases.dart';
import 'package:bldr_fitness/services/achievement_service.dart';
import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/services/club_workouts_service.dart';
import 'package:bldr_fitness/services/community_service.dart';
import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';
import 'package:bldr_fitness/services/exercise_service.dart';
import 'package:bldr_fitness/services/export_service.dart';
import 'package:bldr_fitness/services/fatsecret_service.dart';
import 'package:bldr_fitness/services/firebase_auth_service.dart';
import 'package:bldr_fitness/services/notification_service.dart';
import 'package:bldr_fitness/services/nutrition_service.dart';
import 'package:bldr_fitness/services/oura_api_service.dart';
import 'package:bldr_fitness/services/payment_service.dart';
import 'package:bldr_fitness/features/whats_new/data/whats_new_datasource.dart';
import 'package:bldr_fitness/features/whats_new/domain/usecases/whats_new_usecases.dart';
import 'package:bldr_fitness/services/progress_service.dart';
import 'package:bldr_fitness/services/push_notification_service.dart';
import 'package:bldr_fitness/services/supabase_service.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/services/workout_service.dart';

/// Localizador de serviços global (Clean Architecture — Fase 1).
///
/// Durante a migração, os serviços legados ficam registrados aqui apontando
/// para seus singletons atuais. Código novo deve resolver dependências via
/// `getIt<T>()` (ou recebê-las por construtor) em vez de chamar
/// `XService.instance` diretamente.
///
/// Conforme cada feature migra (Fase 2+), seus repositories e use cases são
/// registrados aqui e o service legado correspondente é removido.
final GetIt getIt = GetIt.instance;

/// Registra as dependências do app. Chamar uma única vez no `main()`,
/// depois de `SupabaseService.initialize()`.
void setupInjection({Map<String, dynamic> config = const {}}) {
  // --- Feature: Auth (Fase 2 — migrada) ---
  getIt.registerLazySingleton<SupabaseAuthDatasource>(
      () => SupabaseAuthDatasource(SupabaseService.instance.client));
  getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<SupabaseAuthDatasource>()));
  getIt.registerFactory(() => GetCurrentUser(getIt<AuthRepository>()));
  getIt.registerFactory(() => SignIn(getIt<AuthRepository>()));
  getIt.registerFactory(() => SignUp(getIt<AuthRepository>()));
  getIt.registerFactory(() => SignOut(getIt<AuthRepository>()));
  getIt.registerFactory(() => SignInWithApple(getIt<AuthRepository>()));
  getIt.registerFactory(() => SignInWithGoogle(getIt<AuthRepository>()));
  getIt.registerFactory(() => ResendConfirmationEmail(getIt<AuthRepository>()));
  getIt.registerFactory(() => SendPasswordResetOtp(getIt<AuthRepository>()));
  getIt.registerFactory(() => VerifyPasswordResetOtp(getIt<AuthRepository>()));
  getIt.registerFactory(() => UpdatePassword(getIt<AuthRepository>()));
  getIt.registerFactory(() => DeleteAccount(getIt<AuthRepository>()));

  // --- Feature: Nutrition (Fase 3 — migrada) ---
  getIt.registerLazySingleton<FirestoreNutritionDatasource>(
      () => FirestoreNutritionDatasource(FirebaseFirestore.instance));
  getIt.registerLazySingleton<SupabaseXpDatasource>(
      () => SupabaseXpDatasource(SupabaseService.instance.client));
  getIt.registerLazySingleton<FoodCatalogRepository>(
      () => FoodCatalogRepositoryImpl(getIt<FirestoreNutritionDatasource>()));
  getIt.registerLazySingleton<NutritionDiaryRepository>(
      () => NutritionDiaryRepositoryImpl(
            getIt<FirestoreNutritionDatasource>(),
            () => getIt<AuthRepository>().currentUser?.id,
          ));
  getIt.registerLazySingleton<NutritionXpRepository>(
      () => NutritionXpRepositoryImpl(
            getIt<SupabaseXpDatasource>(),
            getIt<FirestoreNutritionDatasource>(),
          ));
  getIt.registerFactory(() => SearchFoods(getIt<FoodCatalogRepository>()));
  getIt.registerFactory(() => GetCategoryFoods(getIt<FoodCatalogRepository>()));
  getIt.registerFactory(() => GetFavoriteFoods(getIt<FoodCatalogRepository>()));
  getIt.registerFactory(() => SaveFavoriteFood(getIt<FoodCatalogRepository>()));
  getIt.registerFactory(() => GetRecentFoods(getIt<FoodCatalogRepository>()));
  getIt.registerFactory(
      () => GetMealsForDate(getIt<NutritionDiaryRepository>()));
  getIt.registerFactory(
      () => GetDailySummary(getIt<NutritionDiaryRepository>()));
  getIt.registerFactory(
      () => DeleteMealEntry(getIt<NutritionDiaryRepository>()));
  getIt.registerFactory(
      () => UpdateMealQuantity(getIt<NutritionDiaryRepository>()));
  getIt.registerFactory(() => LogMeal(
      getIt<NutritionDiaryRepository>(), getIt<NutritionXpRepository>()));
  getIt.registerLazySingleton<SupabaseNutritionGoalsDatasource>(
      () => SupabaseNutritionGoalsDatasource(SupabaseService.instance.client));
  getIt.registerLazySingleton<NutritionGoalsRepository>(() =>
      NutritionGoalsRepositoryImpl(getIt<SupabaseNutritionGoalsDatasource>()));
  getIt.registerFactory(
      () => GetNutritionGoals(getIt<NutritionGoalsRepository>()));
  getIt.registerFactory(() => GetUserGoals(getIt<NutritionGoalsRepository>()));
  getIt.registerFactory(() => SaveUserGoals(getIt<NutritionGoalsRepository>()));

  getIt.registerLazySingleton<SupabasePrivacyDatasource>(
      () => SupabasePrivacyDatasource(SupabaseService.instance.client));
  getIt.registerLazySingleton<PrivacyRepository>(
      () => PrivacyRepositoryImpl(getIt<SupabasePrivacyDatasource>()));
  getIt.registerFactory(() => GetPrivacySettings(getIt<PrivacyRepository>()));
  getIt.registerFactory(() => SavePrivacySettings(getIt<PrivacyRepository>()));
  getIt.registerLazySingleton<DeviceTimezoneService>(DeviceTimezoneService.new);
  getIt.registerLazySingleton<UserTimezoneRepository>(
      () => UserTimezoneRepositoryImpl(getIt<SupabasePrivacyDatasource>()));
  getIt.registerFactory(() => SyncDeviceTimezone(
      getIt<UserTimezoneRepository>(), getIt<DeviceTimezoneService>()));
  getIt.registerLazySingleton<UserTimezoneSyncLifecycle>(() =>
      UserTimezoneSyncLifecycle(
          getIt<AuthRepository>(), getIt<SyncDeviceTimezone>()));

  // --- Feature: Workouts (Fase 4a — domain/data; telas na 4b) ---
  getIt.registerLazySingleton<WorkoutTemplateRepository>(
      () => WorkoutTemplateRepositoryImpl(WorkoutService.instance));
  getIt.registerLazySingleton<WorkoutSessionRepository>(
      () => WorkoutSessionRepositoryImpl(WorkoutService.instance));
  getIt.registerFactory(
      () => GetWorkoutTemplates(getIt<WorkoutTemplateRepository>()));
  getIt.registerFactory(
      () => GetTemplateWithExercises(getIt<WorkoutTemplateRepository>()));
  getIt.registerFactory(
      () => CreateWorkoutTemplate(getIt<WorkoutTemplateRepository>()));
  getIt.registerFactory(
      () => UpdateWorkoutTemplate(getIt<WorkoutTemplateRepository>()));
  getIt.registerFactory(
      () => DeleteWorkoutTemplate(getIt<WorkoutTemplateRepository>()));
  getIt.registerFactory(() => StartWorkout(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => CompleteWorkout(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => CompleteWorkoutWithAnalytics(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(() => LogWorkoutSet(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => CompleteWorkoutSet(getIt<WorkoutSessionRepository>()));
  getIt
      .registerFactory(() => UndoWorkoutSet(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => HasActiveWorkout(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => GetActiveWorkoutDetails(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => WatchActiveWorkout(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => GetWorkoutDetails(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => GetWorkoutHistory(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => GetPausedWorkouts(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => EnsureWorkoutSets(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => DeletePausedWorkout(getIt<WorkoutSessionRepository>()));
  getIt.registerFactory(
      () => DeleteCompletedWorkout(getIt<WorkoutSessionRepository>()));

  getIt.registerLazySingleton<SupabaseWeeklyPlanDatasource>(
      () => SupabaseWeeklyPlanDatasource(SupabaseService.instance.client));
  getIt.registerLazySingleton<WeeklyPlanRepository>(
      () => WeeklyPlanRepositoryImpl(
            getIt<SupabaseWeeklyPlanDatasource>(),
            ExerciseDbRapidService.instance,
            () => getIt<AuthRepository>().currentUser?.id,
          ));
  getIt.registerFactory(
      () => GetWeeklyPlanConfig(getIt<WeeklyPlanRepository>()));
  getIt.registerFactory(
      () => SaveWeeklyPlanConfig(getIt<WeeklyPlanRepository>()));
  getIt.registerFactory(() => SaveWeeklyPlan(getIt<WeeklyPlanRepository>()));
  getIt.registerFactory(() => GetWeeklyPlan(getIt<WeeklyPlanRepository>()));
  getIt.registerFactory(() => UpdatePlanDay(getIt<WeeklyPlanRepository>()));
  getIt.registerFactory(
      () => GetWeekCompletedWorkouts(getIt<WeeklyPlanRepository>()));
  getIt.registerFactory(() => GetWorkoutMuscles(getIt<WeeklyPlanRepository>()));
  getIt.registerFactory(
      () => DeleteCompletedClubWorkout(getIt<WeeklyPlanRepository>()));
  getIt.registerFactory(() => GetCurrentStreak(
      getIt<WorkoutSessionRepository>(), getIt<ClubWorkoutRepository>(),
      timezoneRepository: getIt<UserTimezoneRepository>(),
      userId: () => getIt<AuthRepository>().currentUser?.id));

  getIt.registerLazySingleton<ExtraActivityRepository>(
      () => ExtraActivityRepositoryImpl(
            SupabaseService.instance.client,
            () => getIt<AuthRepository>().currentUser?.id,
          ));
  getIt.registerFactory(
      () => LogExtraActivity(getIt<ExtraActivityRepository>()));
  getIt.registerFactory(
      () => GetExtraActivities(getIt<ExtraActivityRepository>()));

  // --- Feature: Integrations (Whoop) ---
  getIt.registerLazySingleton<WhoopDatasource>(() => WhoopDatasource(
        SupabaseService.instance.client,
        () => getIt<AuthRepository>().currentUser?.id,
      ));
  getIt.registerLazySingleton<WhoopRepository>(
      () => WhoopRepositoryImpl(getIt<WhoopDatasource>()));
  getIt.registerFactory(() => ConnectWhoop(getIt<WhoopRepository>()));
  getIt.registerFactory(() => DisconnectWhoop(getIt<WhoopRepository>()));
  getIt.registerFactory(() => GetWhoopConnection(getIt<WhoopRepository>()));
  getIt.registerFactory(() => SyncWhoopData(getIt<WhoopRepository>()));
  getIt.registerFactory(() => GetTodayWhoopData(getIt<WhoopRepository>()));

  getIt.registerLazySingleton<SupabaseWearableActivityDatasource>(
      () => SupabaseWearableActivityDatasource(
            SupabaseService.instance.client,
          ));
  getIt.registerLazySingleton<WearableActivityRepository>(
      () => WearableActivityRepositoryImpl(
            getIt<SupabaseWearableActivityDatasource>(),
          ));
  getIt.registerFactory(
      () => GetWearableActivity(getIt<WearableActivityRepository>()));
  getIt.registerFactory(
      () => PrepareWearableWorkout(getIt<WearableActivityRepository>()));
  getIt.registerFactory(
      () => ConfirmWearableActivity(getIt<WearableActivityRepository>()));
  getIt.registerFactory(
      () => DismissWearableActivity(getIt<WearableActivityRepository>()));

  // --- Onboarding (L4) ---
  getIt.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(
            SupabaseService.instance.client,
            () => getIt<AuthRepository>().currentUser?.id,
          ));
  getIt.registerFactory(() => GenerateOnboardingPlan(
      getIt<OnboardingRepository>(), getIt<CreateWorkoutTemplate>()));
  getIt.registerFactory(
      () => GetOnboardingContext(getIt<OnboardingRepository>()));

  // --- Features: Progress + Achievements (Fase 5 — strangler) ---
  getIt.registerLazySingleton<ProgressRepository>(
      () => ProgressRepositoryImpl(ProgressService.instance));
  getIt.registerLazySingleton<AchievementsRepository>(
      () => AchievementsRepositoryImpl(AchievementService.instance));
  getIt.registerFactory(() => RecordMeasurement(getIt<ProgressRepository>()));
  getIt.registerFactory(() => GetMeasurements(getIt<ProgressRepository>()));
  getIt.registerFactory(
      () => GetMeasurementProgress(getIt<ProgressRepository>()));
  getIt.registerFactory(() => LogWater(getIt<ProgressRepository>()));
  getIt.registerFactory(() => RemoveWater(getIt<ProgressRepository>()));
  getIt.registerFactory(() => GetDailyWaterIntake(getIt<ProgressRepository>()));
  getIt.registerFactory(() => DeleteMeasurement(getIt<ProgressRepository>()));
  getIt.registerFactory(
      () => GetAchievementCatalog(getIt<AchievementsRepository>()));
  getIt.registerFactory(
      () => GetUserAchievements(getIt<AchievementsRepository>()));
  getIt.registerFactory(
      () => CheckAndUnlockAchievements(getIt<AchievementsRepository>()));
  getIt.registerFactory(
      () => GetWorkoutAchievementContext(getIt<AchievementsRepository>()));

  // --- Feature: BLDR Club (Fase 6a — strangler; telas na 6b) ---
  getIt.registerLazySingleton<SupabaseClubDatasource>(
      () => SupabaseClubDatasource(SupabaseService.instance.client));
  getIt.registerLazySingleton<ClubWorkoutRepository>(
      () => ClubWorkoutRepositoryImpl(
            ClubWorkoutsService.instance,
            getIt<SupabaseClubDatasource>(),
            () => getIt<AuthRepository>().currentUser?.id,
          ));
  getIt.registerLazySingleton<ClubCommunityRepository>(
      () => ClubCommunityRepositoryImpl(CommunityService.instance));
  getIt.registerFactory(
      () => GetMyClubTemplates(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => CreateClubTemplate(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => UpdateClubTemplate(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(() => StartClubWorkout(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => CompleteClubWorkout(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(() => CompleteClubSet(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(() => UndoClubSet(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => WatchActiveClubWorkout(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => GetClubWorkoutHistory(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(() => LogClubCardio(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => IsUserInActiveChallenge(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => GetClubPublicTemplates(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => GetClubTemplateExercises(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => GetClubWorkoutsBetween(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => GetClubActivitiesBetween(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(() => GetClubXpBetween(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => GetClubWorkoutDetails(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => GetClubTemplateWithExercises(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => DeleteClubTemplate(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => GetPausedClubWorkouts(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => DeletePausedClubWorkout(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => DeleteClubWorkoutRecord(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => EnsureClubWorkoutSets(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => DeleteClubActivityRecord(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(() => GetConsolidatedWorkoutHistory(
      getIt<WorkoutSessionRepository>(), getIt<ClubWorkoutRepository>()));
  getIt.registerLazySingleton<SupabaseChallengesDatasource>(
      () => SupabaseChallengesDatasource(SupabaseService.instance.client));
  getIt
      .registerLazySingleton<ChallengeRepository>(() => ChallengeRepositoryImpl(
            getIt<SupabaseChallengesDatasource>(),
            () => getIt<AuthRepository>().currentUser?.id,
          ));
  getIt.registerFactory(() => GetXpFeed(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => ReactToXpEvent(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => RemoveReactionFromXpEvent(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => GetMyReactions(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => GetClubRanking(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => GetMyDuels(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => RespondDuel(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => GetCollectiveChallenges(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => JoinCollectiveChallenge(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => LeaveCollectiveChallenge(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => CreateCollectiveChallenge(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => GetChallengeDetail(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => GetMyChallengeParticipation(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => GetChallengeTopContributors(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => GetChallengeFeed(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => GetChallengeMilestones(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => GetChallengeComments(getIt<ChallengeRepository>()));
  getIt
      .registerFactory(() => AddChallengeComment(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => ReportChallenge(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => UpdateChallengeSettings(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => GetPendingDuelInvite(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => CheckActiveDuel(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => SendDuelInvite(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => GetClubNotifications(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => MarkAllNotificationsRead(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => MarkNotificationRead(getIt<ChallengeRepository>()));
  getIt.registerFactory(
      () => GetPublicClubProfile(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => GetMyRankingEntry(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => GetPastChallenges(getIt<ChallengeRepository>()));
  getIt.registerFactory(() => GetRunActivities(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(() => SaveRunActivity(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(() => SaveMatchSession(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(() => GetMatchHistory(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => GetCurrentOperation(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => GetOperationProgress(getIt<ClubWorkoutRepository>()));
  getIt.registerFactory(
      () => TryIncrementOperation(getIt<ClubWorkoutRepository>()));
  getIt.registerLazySingleton<ArenaRepository>(() => ArenaRepositoryImpl(
        SupabaseService.instance.client,
        () => getIt<AuthRepository>().currentUser?.id,
      ));
  getIt.registerLazySingleton<HavokRepository>(() => HavokRepositoryImpl(
        SupabaseService.instance.client,
        () => getIt<AuthRepository>().currentUser?.id,
      ));
  getIt.registerFactory(() => GenerateFreeWorkout(getIt<HavokRepository>()));
  getIt.registerFactory(() => GenerateHavokWorkout(getIt<HavokRepository>()));
  getIt.registerFactory(() => GenerateHavokRecipe(getIt<HavokRepository>()));
  getIt.registerFactory(() => SaveHavokRecipe(getIt<HavokRepository>()));
  getIt.registerFactory(() => GetHavokRecipes(getIt<HavokRepository>()));
  getIt.registerFactory(() => GetHavokWorkouts(getIt<HavokRepository>()));
  getIt.registerFactory(() => GetOrCreateTodayThread(getIt<HavokRepository>()));
  getIt.registerFactory(() => GetThreadMessages(getIt<HavokRepository>()));
  getIt.registerFactory(() => SendHavokMessage(getIt<HavokRepository>()));
  getIt.registerFactory(() => DismissHavokInsight(getIt<HavokRepository>()));
  getIt.registerFactory(() => GetHavokDailyCount(getIt<HavokRepository>()));
  getIt.registerFactory(() => GetHavokMemories(getIt<HavokRepository>()));
  getIt.registerFactory(() => UpdateHavokMemory(getIt<HavokRepository>()));
  getIt.registerFactory(() => ForgetHavokMemory(getIt<HavokRepository>()));
  getIt.registerFactory(() => ClearHavokMemories(getIt<HavokRepository>()));
  getIt.registerFactory(() => GenerateHavokInsight());
  getIt.registerFactory(
      () => GetClubAnnouncements(getIt<ClubCommunityRepository>()));
  getIt.registerFactory(() => GetClubEvents(getIt<ClubCommunityRepository>()));

  // --- Features: Subscription + AppVersion (Fase 7 — strangler) ---
  getIt.registerLazySingleton<SubscriptionRepository>(
      () => SubscriptionRepositoryImpl(PaymentService.instance));
  getIt.registerLazySingleton<RevenueCatSdkGateway>(
      PurchasesRevenueCatSdkGateway.new);
  getIt.registerLazySingleton<RevenueCatService>(() => RevenueCatServiceImpl(
        getIt<RevenueCatSdkGateway>(),
        RevenueCatConfig.fromMap(config),
      ));
  getIt.registerLazySingleton<RevenueCatLifecycle>(() => RevenueCatLifecycle(
        getIt<AuthRepository>(),
        getIt<RevenueCatService>(),
        getIt<RunAppleRevenueCatMigration>(),
      ));
  getIt.registerLazySingleton<AppleRevenueCatMigrationDatasource>(() =>
      SupabaseAppleRevenueCatMigrationDatasource(
          SupabaseService.instance.client));
  getIt.registerLazySingleton<AppleRevenueCatMigrationRepository>(() =>
      AppleRevenueCatMigrationRepositoryImpl(
          getIt<AppleRevenueCatMigrationDatasource>()));
  getIt.registerFactory(() => RunAppleRevenueCatMigration(
        getIt<AuthRepository>(),
        getIt<AppleRevenueCatMigrationRepository>(),
        getIt<RevenueCatService>(),
      ));
  getIt.registerFactory(() => ResolveClubAccess(
        getIt<AuthRepository>(),
        getIt<SubscriptionRepository>(),
        getIt<RevenueCatService>(),
        getIt<AppleRevenueCatMigrationRepository>(),
      ));
  getIt.registerLazySingleton<AppVersionRepository>(
      () => const AppVersionRepositoryImpl());
  getIt.registerFactory(
      () => GetSubscriptionPlans(getIt<SubscriptionRepository>()));
  getIt.registerFactory(
      () => GetCurrentSubscription(getIt<SubscriptionRepository>()));
  getIt.registerFactory(
      () => CreateStripeSubscription(getIt<SubscriptionRepository>()));
  getIt.registerFactory(
      () => ProcessStripePayment(getIt<SubscriptionRepository>()));
  getIt.registerFactory(
      () => ProcessApplePurchase(getIt<SubscriptionRepository>()));
  getIt.registerFactory(
      () => CancelSubscription(getIt<SubscriptionRepository>()));
  getIt.registerFactory(
      () => WatchPurchaseSuccess(getIt<SubscriptionRepository>()));
  getIt.registerFactory(
      () => WatchPurchaseError(getIt<SubscriptionRepository>()));
  getIt.registerFactory(() => ShouldForceUpdate(getIt<AppVersionRepository>()));

  // --- Serviços legados (singletons existentes) ---
  getIt.registerLazySingleton<SupabaseService>(() => SupabaseService.instance);
  getIt.registerLazySingleton<AuthService>(() => AuthService.instance);
  getIt.registerLazySingleton<UserService>(() => UserService.instance);
  getIt.registerLazySingleton<WorkoutService>(() => WorkoutService.instance);
  getIt.registerLazySingleton<ExerciseService>(() => ExerciseService.instance);
  getIt.registerLazySingleton<ExerciseDbRapidService>(
      () => ExerciseDbRapidService.instance);
  getIt
      .registerLazySingleton<NutritionService>(() => NutritionService.instance);
  getIt
      .registerLazySingleton<FatSecretService>(() => FatSecretService.instance);
  getIt.registerLazySingleton<ProgressService>(() => ProgressService.instance);
  getIt.registerLazySingleton<AchievementService>(
      () => AchievementService.instance);
  getIt.registerLazySingleton<ClubWorkoutsService>(
      () => ClubWorkoutsService.instance);
  getIt
      .registerLazySingleton<CommunityService>(() => CommunityService.instance);
  getIt.registerLazySingleton<PaymentService>(() => PaymentService.instance);
  getIt.registerLazySingleton<OuraApiService>(() => OuraApiService.instance);
  getIt.registerLazySingleton<ExportService>(() => ExportService.instance);
  getIt.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<PushNotificationService>(
      () => PushNotificationService());

  // --- Features: Feedback ---
  getIt.registerLazySingleton<FeedbackRepository>(
      () => FeedbackRepositoryImpl(SupabaseService.instance.client));
  getIt.registerFactory(() => SendFeedback(getIt<FeedbackRepository>()));

  // --- Internacionalização (F22 — Fase 1) ---
  getIt.registerLazySingleton<LocaleProvider>(() => LocaleProvider());

  // --- What's New ---
  getIt.registerLazySingleton<WhatsNewDatasource>(() => WhatsNewDatasource());
  getIt.registerFactory(() => GetWhatsNew(getIt<WhatsNewDatasource>()));
  getIt.registerFactory(() => MarkWhatsNewSeen(getIt<WhatsNewDatasource>()));

  // --- Apple Watch & HealthKit ---
  getIt.registerLazySingleton<WatchService>(() => WatchService());
  getIt.registerLazySingleton<HealthKitService>(() => HealthKitService());
  getIt.registerLazySingleton<RunLiveActivityService>(
      () => RunLiveActivityService());

  // --- Community ---
  getIt.registerLazySingleton<CommunityFeedRepository>(
    () => CommunityFeedRepositoryImpl(
      SupabaseService.instance.client,
      getIt<HealthKitService>(),
    ),
  );
}
