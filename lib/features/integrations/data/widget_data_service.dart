import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/weekly_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';

const _kGroupId = 'group.com.bldr.fitness';

class WidgetDataService {
  WidgetDataService._();

  static Future<void> init() async {
    if (!Platform.isIOS) return;
    await HomeWidget.setAppGroupId(_kGroupId);
  }

  /// Coleta todos os dados e atualiza os widgets iOS.
  /// Silencioso — nunca lança exceção para a tela chamadora.
  static Future<void> updateAll({
    String? workoutName,
    String? workoutTemplateId,
    int? workoutExercises,
    int? workoutDuration,
    int? xpToday,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _doUpdate(
        workoutName: workoutName,
        workoutTemplateId: workoutTemplateId,
        workoutExercises: workoutExercises,
        workoutDuration: workoutDuration,
        xpToday: xpToday,
      );
    } catch (e) {
      debugPrint('WidgetDataService.updateAll error: $e');
    }
  }

  static Future<void> _doUpdate({
    String? workoutName,
    String? workoutTemplateId,
    int? workoutExercises,
    int? workoutDuration,
    int? xpToday,
  }) async {
    final userId = getIt<AuthRepository>().currentUser?.id;
    if (userId == null) return;

    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd   = weekStart.add(const Duration(days: 6));

    // Carrega dados tipados separadamente para evitar cast de Object
    final streakResult = await getIt<GetCurrentStreak>()();
    final weekResult   = await getIt<GetWeekCompletedWorkouts>()(weekStart, weekEnd);
    final summaryResult = await getIt<GetDailySummary>()(today, userId: userId);
    final goalsResult   = await getIt<GetNutritionGoals>()(userId);

    final streak  = streakResult.valueOrNull ?? 0;
    final weekComp = weekResult.valueOrNull;
    final summary  = summaryResult.valueOrNull;
    final goals    = goalsResult.valueOrNull;

    // Monta array de 7 bools (Seg=0 … Dom=6)
    final weekDays = List.filled(7, false);
    if (weekComp is WeekCompletedWorkouts) {
      final allSessions = [...weekComp.personal, ...weekComp.club];
      for (final s in allSessions) {
        final d = s.completedAt ?? s.startedAt;
        if (d != null &&
            d.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            d.isBefore(weekEnd.add(const Duration(days: 1)))) {
          final idx = d.weekday - 1;
          if (idx >= 0 && idx < 7) weekDays[idx] = true;
        }
      }
    }

    // B8: se workoutName não foi passado (chamada genérica), busca do plano real.
    String effectiveWorkoutName = workoutName ?? '';
    String effectiveWorkoutTemplateId = workoutTemplateId ?? '';
    if (workoutName == null) {
      final planResult = await getIt<GetWeeklyPlan>()();
      final planDays = planResult.valueOrNull ?? [];
      final todayWeekday = today.weekday;
      final todayDay = planDays.where((d) => d.diaSemana == todayWeekday).firstOrNull;
      if (todayDay?.treino != null) {
        effectiveWorkoutName = todayDay!.treino!.name;
        effectiveWorkoutTemplateId = todayDay.treino!.id ?? '';
      }
    }

    await Future.wait([
      HomeWidget.saveWidgetData<int>('bldr_streak_days', streak),
      HomeWidget.saveWidgetData<String>('bldr_streak_week', jsonEncode(weekDays)),
      HomeWidget.saveWidgetData<int>(
          'bldr_calories_consumed', summary?.totals.calories.round() ?? 0),
      HomeWidget.saveWidgetData<int>(
          'bldr_calories_goal', goals?.calories ?? 2000),
      HomeWidget.saveWidgetData<int>(
          'bldr_macro_protein', summary?.totals.protein.round() ?? 0),
      HomeWidget.saveWidgetData<int>(
          'bldr_macro_protein_goal', goals?.protein ?? 120),
      HomeWidget.saveWidgetData<int>(
          'bldr_macro_carbs', summary?.totals.carbs.round() ?? 0),
      HomeWidget.saveWidgetData<int>(
          'bldr_macro_carbs_goal', goals?.carbs ?? 250),
      HomeWidget.saveWidgetData<int>(
          'bldr_macro_fat', summary?.totals.fat.round() ?? 0),
      HomeWidget.saveWidgetData<int>(
          'bldr_macro_fat_goal', goals?.fat ?? 67),
      HomeWidget.saveWidgetData<String>('bldr_workout_name', effectiveWorkoutName),
      HomeWidget.saveWidgetData<String>('bldr_workout_template_id', effectiveWorkoutTemplateId),
      HomeWidget.saveWidgetData<int>(
          'bldr_workout_exercises', workoutExercises ?? 0),
      HomeWidget.saveWidgetData<int>(
          'bldr_workout_duration', workoutDuration ?? 0),
      HomeWidget.saveWidgetData<int>('bldr_xp_today', xpToday ?? 0),
    ]);

    await _reloadAllWidgets();
  }

  // home_widget 0.7.x não suporta reloadAllTimelines() — é preciso chamar
  // updateWidget para cada kind registrado no BLDRWidgets extension.
  static Future<void> _reloadAllWidgets() async {
    const kinds = [
      'BLDRStreakWidget',
      'BLDRCaloriasWidget',
      'BLDRResumoWidget',
      'BLDRDashboardWidget',
      'BLDRRectangularWidget',
    ];
    await Future.wait(
      kinds.map((k) => HomeWidget.updateWidget(iOSName: k)),
    );
  }

  /// Armazena o treino do dia sem refazer todos os use cases.
  static Future<void> setTodayWorkout({
    required String name,
    required String templateId,
    required int exercises,
    required int durationMinutes,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>('bldr_workout_name', name),
        HomeWidget.saveWidgetData<String>('bldr_workout_template_id', templateId),
        HomeWidget.saveWidgetData<int>('bldr_workout_exercises', exercises),
        HomeWidget.saveWidgetData<int>('bldr_workout_duration', durationMinutes),
      ]);
      await _reloadAllWidgets();
    } catch (e) {
      debugPrint('WidgetDataService.setTodayWorkout error: $e');
    }
  }
}
