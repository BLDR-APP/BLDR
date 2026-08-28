import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/integrations/domain/usecases/whoop_usecases.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/progress/domain/usecases/progress_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/services/supabase_service.dart';

class GenerateHavokInsight {
  SupabaseClient get _client => SupabaseService.instance.client;

  static String _cacheKey() {
    final now = DateTime.now();
    final d = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return 'havok_insight_$d';
  }

  Future<Result<String>> call({String locale = 'pt'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey());
      if (cached != null && cached.isNotEmpty) {
        return Result.success(cached);
      }

      final ctx = await _buildContext(locale: locale);

      final response = await _client.functions.invoke(
        'gerar-insight-havok',
        body: {'context': ctx},
      );

      if (response.status != 200 || response.data == null) {
        return Result.failure(
          ServerFailure('Falha ao gerar insight: status ${response.status}'),
        );
      }

      final insight = (response.data as Map<String, dynamic>)['insight'] as String?;
      if (insight == null || insight.isEmpty) {
        return Result.failure(ServerFailure('Insight vazio'));
      }

      await prefs.setString(_cacheKey(), insight);
      return Result.success(insight);
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao gerar insight: $e'));
    }
  }

  Future<Map<String, dynamic>> _buildContext({required String locale}) async {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final Map<String, dynamic> ctx = {
      'locale': locale,
      'today': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'weekday': _weekdayPt(now.weekday),
    };

    // workouts — fallback para 0 se falhar
    try {
      final weekResult =
          await getIt<GetWeekCompletedWorkouts>()(weekStart, weekEnd);
      final week = weekResult.valueOrNull;
      final completed =
          (week?.personal.length ?? 0) + (week?.club.length ?? 0);
      ctx['workouts'] = {'completedThisWeek': completed};
    } catch (e, st) {
      debugPrint('[HAVOK insight] erro ao carregar workouts: $e');
      debugPrint('[HAVOK insight] stacktrace: $st');
      ctx['workouts'] = {'completedThisWeek': 0};
    }

    // nutrition — omitido se falhar (sem dados = sem seção)
    try {
      final userId = getIt<GetCurrentUser>()()?.id;
      final summaryResult = await getIt<GetDailySummary>()(now);
      final summary = summaryResult.valueOrNull;
      final goalsResult =
          userId == null ? null : await getIt<GetNutritionGoals>()(userId);
      final goals = goalsResult?.valueOrNull;
      if (summary != null && goals != null && goals.protein > 0) {
        ctx['nutrition'] = {
          'proteinG': summary.totals.protein,
          'proteinGoalG': goals.protein,
          'proteinPercentOfGoal':
              ((summary.totals.protein / goals.protein) * 100).round(),
          'caloriesConsumed': summary.totals.calories,
        };
      }
    } catch (e, st) {
      debugPrint('[HAVOK insight] erro ao carregar nutrition: $e');
      debugPrint('[HAVOK insight] stacktrace: $st');
    }

    // weight — omitido se falhar
    try {
      final weightResult =
          await getIt<GetMeasurements>()(measurementType: 'weight', limit: 1);
      final weights = weightResult.valueOrNull ?? [];
      if (weights.isNotEmpty) {
        ctx['weight'] = {'latestKg': weights.first.value};
      }
    } catch (e, st) {
      debugPrint('[HAVOK insight] erro ao carregar weight: $e');
      debugPrint('[HAVOK insight] stacktrace: $st');
    }

    // streak — fallback para 0 se falhar
    try {
      final streakResult = await getIt<GetCurrentStreak>()();
      final streak = streakResult.valueOrNull;
      final atRisk = await _isStreakAtRisk();
      ctx['streak'] = {'days': streak ?? 0, 'at_risk': atRisk};
    } catch (e, st) {
      debugPrint('[HAVOK insight] erro ao carregar streak: $e');
      debugPrint('[HAVOK insight] stacktrace: $st');
      ctx['streak'] = {'days': 0, 'at_risk': false};
    }

    // whoop — omitido se falhar (não essencial)
    try {
      final whoopResult = await getIt<GetTodayWhoopData>()();
      final whoop = whoopResult.valueOrNull;
      if (whoop != null) {
        ctx['whoop'] = {
          'recovery': whoop.recoveryScore,
          'strain': whoop.strainScore,
          'sleep': whoop.sleepScore,
          'hrv': whoop.hrvRmssd,
        };
      }
    } catch (e, st) {
      debugPrint('[HAVOK insight] erro ao carregar whoop: $e');
      debugPrint('[HAVOK insight] stacktrace: $st');
    }

    debugPrint('[HAVOK insight] contexto montado: $ctx');
    return ctx;
  }

  Future<bool> _isStreakAtRisk() async {
    final lastResult = await getIt<GetConsolidatedWorkoutHistory>()(
        completedOnly: true, limit: 1);
    final last = lastResult.valueOrNull?.firstOrNull;
    final lastDate = last?.completedAt?.toLocal();
    if (lastDate == null) return true;
    final today = DateTime.now();
    return !(lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day);
  }

  static String _weekdayPt(int weekday) {
    const days = ['', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    return days[weekday];
  }
}
