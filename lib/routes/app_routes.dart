// lib/routes/app_routes.dart
import 'package:flutter/material.dart';

import 'package:bldr_fitness/features/subscription/presentation/checkout_screen/checkout_screen.dart';
import 'package:bldr_fitness/features/auth/presentation/create_new_password_screen.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/dashboard.dart';
import 'package:bldr_fitness/features/auth/presentation/email_confirmation_screen/email_confirmation_screen.dart';
import 'package:bldr_fitness/features/auth/presentation/login_screen/login_screen.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/nutrition_screen.dart';
import 'package:bldr_fitness/shared/presentation/onboarding_flow/onboarding_flow.dart';
import 'package:bldr_fitness/features/progress/presentation/progress_screen/progress_screen.dart';
import 'package:bldr_fitness/features/auth/presentation/sign_up_screen/sign_up_screen.dart';
import 'package:bldr_fitness/shared/presentation/splash_screen/splash_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workouts_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/active_workout_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/create_workout_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/weekly_plan_screen.dart';
import 'package:bldr_fitness/features/auth/presentation/wait_for_confirmation_screen.dart';
import 'package:bldr_fitness/features/auth/presentation/login_screen/widgets/verify_otp_screen.dart';
import 'package:bldr_fitness/shared/presentation/onboarding_completion_screen.dart';
import 'package:bldr_fitness/features/profile/presentation/profile_drawer/profile_screen.dart';
import 'package:bldr_fitness/features/profile/presentation/settings/settings_screen.dart';
import 'package:bldr_fitness/features/integrations/presentation/wearable_workout_confirmation_screen.dart';

// BLDR CLUB
import 'package:bldr_fitness/features/club/presentation/bldr_club/bldr_club_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/ranking_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/club_workout_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/esportes_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/comunidade_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/notifications_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/public_profile_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/collective_challenge_detail_screen.dart';

// TEMPORÁRIO — vitrine do design system. Remover junto com
// lib/design_system/bldr_showcase_screen.dart quando o redesign valer nas telas.
import 'package:bldr_fitness/design_system/bldr_showcase_screen.dart';
import 'package:bldr_fitness/features/profile/presentation/feedback_screen.dart';

class AppRoutes {
  // Route constants
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String signUpScreen = '/sign-up-screen';
  static const String emailConfirmationScreen = '/email-confirmation-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String dashboard = '/dashboard';
  static const String workoutsScreen = '/workouts-screen';
  static const String nutritionScreen = '/nutrition-screen';
  static const String progressScreen = '/progress-screen';
  static const String checkoutScreen = '/checkout-screen';
  static const String waitForConfirmationScreen = '/wait-for-confirmation';
  static const String createNewPasswordScreen = '/create-new-password';
  static const String verifyOtpScreen = '/verify-otp';
  static const String activeWorkoutScreen = '/active-workout';
  static const String createWorkoutScreen = '/create-workout';
  static const String weeklyPlanScreen = '/weekly-plan';
  static const String onboardingCompletion = '/onboarding-completion';
  static const String wearableWorkoutConfirmation =
      '/wearable-workout-confirmation';

  static const String profileScreen = '/profile';
  static const String settingsScreen = '/settings';

  // BLDR CLUB
  static const String bldrClubScreen = '/bldr-club';
  static const String rankingScreen = '/bldr-club/ranking';
  static const String treinosScreen = '/bldr-club/treinos';
  static const String esportesScreen = '/bldr-club/esportes';
  static const String comunidadeScreen = '/bldr-club/comunidade';
  static const String notificacoesScreen = '/bldr-club/notificacoes';
  static const String publicProfileScreen = '/bldr-club/perfil-publico';
  static const String collectiveChallengeDetail = '/bldr-club/desafio-coletivo';

  // TEMPORÁRIO — vitrine do design system, só para conferência visual.
  static const String bldrShowcase = '/__bldr-showcase';
  static const String feedbackScreen = '/feedback';

  // Route map
  static Map<String, WidgetBuilder> get routes {
    return {
      splashScreen: (context) => const SplashScreen(),
      loginScreen: (context) => const LoginScreen(),
      signUpScreen: (context) => const SignUpScreen(),
      emailConfirmationScreen: (context) => const EmailConfirmationScreen(),
      onboardingFlow: (context) => const OnboardingFlow(),
      onboardingCompletion: (context) => const OnboardingCompletionScreen(),
      wearableWorkoutConfirmation: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final activityId = args is Map ? args['activity_id'] as String? : null;
        if (activityId == null || activityId.isEmpty) {
          return const WorkoutsScreen();
        }
        return WearableWorkoutConfirmationScreen(activityId: activityId);
      },
      dashboard: (context) => const Dashboard(),
      profileScreen: (context) => const ProfileScreen(),
      settingsScreen: (context) => const SettingsScreen(),
      workoutsScreen: (context) => const WorkoutsScreen(),
      nutritionScreen: (context) => const NutritionScreen(),
      progressScreen: (context) => const ProgressScreen(),
      checkoutScreen: (context) => const CheckoutScreen(),
      waitForConfirmationScreen: (context) => const WaitForConfirmationScreen(),
      createNewPasswordScreen: (context) => const CreateNewPasswordScreen(),

      // TEMPORÁRIO — vitrine do design system
      bldrShowcase: (context) => const BldrShowcaseScreen(),

      // BLDR CLUB
      bldrClubScreen: (context) => const BldrClubScreen(),

      // ✅ usa loaders novos (select + stream). Se "club_ranking" for VIEW, o stream retornará null sem quebrar.
      rankingScreen: (context) => const RankingScreen(),

      treinosScreen: (context) => const ClubWorkoutsScreen(),
      esportesScreen: (context) => const EsportesScreen(),
      comunidadeScreen: (context) => const ComunidadeScreen(),
      notificacoesScreen: (context) => const NotificationsScreen(),
      publicProfileScreen: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return PublicProfileScreen(
          userId: args['userId'] as String,
          displayName: args['displayName'] as String?,
        );
      },
      collectiveChallengeDetail: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return CollectiveChallengeDetailScreen(
          challengeId: args['challengeId'] as String,
        );
      },

      createWorkoutScreen: (context) => const CreateWorkoutScreen(),
      weeklyPlanScreen: (context) => const WeeklyPlanScreen(),
      activeWorkoutScreen: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return ActiveWorkoutScreen(
          workoutId: args['workoutId'] as String,
          workoutName: args['workoutName'] as String,
        );
      },
      verifyOtpScreen: (context) {
        // Pega o e-mail passado como argumento
        final email = ModalRoute.of(context)!.settings.arguments as String;
        return VerifyOtpScreen(email: email);
      },
      feedbackScreen: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final tipoInicial = args is Map ? args['tipoInicial'] as String? : null;
        return FeedbackScreen(tipoInicial: tipoInicial);
      },
    };
  }
}
