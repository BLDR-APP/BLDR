import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/services/supabase_service.dart';

class AchievementService {
  static AchievementService? _instance;
  static AchievementService get instance => _instance ??= AchievementService._();
  AchievementService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<Map<String, dynamic>>> getCatalog() async {
    try {
      final response = await _client
          .from('achievements')
          .select()
          .order('category', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final response = await _client
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .order('achieved_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica e desbloqueia conquistas. Retorna lista das recém-desbloqueadas.
  Future<List<Map<String, dynamic>>> checkAndUnlock({
    required String triggerType,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return [];
    final userId = user.id;

    final results = await Future.wait([
      getCatalog(),
      getUserAchievements(userId),
    ]);

    final catalog  = List<Map<String, dynamic>>.from(results[0] as List);
    final unlocked = List<Map<String, dynamic>>.from(results[1] as List);
    debugPrint('[ACH] checkAndUnlock trigger=$triggerType catalog=${catalog.length} unlocked=${unlocked.length}');

    final unlockedNames = unlocked
        .map((a) => a['achievement_name'] as String)
        .toSet();

    final relevant = catalog.where((a) {
      if (unlockedNames.contains(a['name'])) return false;
      return _isRelevantForTrigger(
          a['criteria_type'] as String, triggerType);
    }).toList();
    debugPrint('[ACH] relevant=${relevant.length} → ${relevant.map((a) => a['name']).toList()}');

    if (relevant.isEmpty) return [];

    final context = await _fetchContext(userId, triggerType);
    debugPrint('[ACH] context=$context');

    final newlyUnlocked = <Map<String, dynamic>>[];
    for (final achievement in relevant) {
      final met = _evaluateCondition(achievement, context);
      debugPrint('[ACH] ${achievement['name']} criteria=${achievement['criteria_type']} value=${achievement['criteria_value']} met=$met');
      if (met) {
        try {
          await _unlock(userId, achievement);
          newlyUnlocked.add(achievement);
        } catch (e) {
          debugPrint('[ACH] ERRO _unlock ${achievement['name']}: $e');
        }
      }
    }
    debugPrint('[ACH] newlyUnlocked=${newlyUnlocked.length}');
    return newlyUnlocked;
  }

  // ---------------------------------------------------------------------------
  // Relevância por trigger
  // ---------------------------------------------------------------------------

  static const _workoutCriteria = {
    'workout_count', 'hiit_workout_count', 'consecutive_days',
    'max_weight_bench_press', 'weekend_warrior',
    'trained_before_hour', 'trained_on_date',
  };

  static const _bldrClubCriteria = {
    'bldr_workout_total', 'bldr_streak_days', 'duel_wins',
    'ranking_position', 'club_member', 'club_level', 'total_xp',
  };

  bool _isRelevantForTrigger(String criteriaType, String triggerType) {
    switch (triggerType) {
      case 'workout':    return _workoutCriteria.contains(criteriaType);
      case 'onboarding': return criteriaType == 'onboarding_complete';
      case 'profile':    return criteriaType == 'goal_created';
      case 'nutrition':  return criteriaType == 'meal_logged' ||
                                criteriaType == 'meal_logged_consecutive_days' ||
                                criteriaType == 'calorie_goal_reached' ||
                                criteriaType == 'calorie_goal_reached_consecutive_days' ||
                                criteriaType == 'macro_goal_reached';
      case 'photo':      return criteriaType == 'progress_photo_added';
      case 'bldr_club':  return _bldrClubCriteria.contains(criteriaType);
      default:           return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Busca de contexto
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _fetchContext(
      String userId, String triggerType) async {
    switch (triggerType) {
      case 'workout':    return _fetchWorkoutContext(userId);
      case 'onboarding':
      case 'profile':   return _fetchProfileContext(userId);
      case 'photo':      return _fetchPhotoContext(userId);
      case 'nutrition':  return _fetchNutritionContext(userId);
      case 'bldr_club':  return _fetchBldrClubContext(userId);
      default:           return {};
    }
  }

  /// Exposto publicamente para a galeria exibir barras de progresso.
  Future<Map<String, dynamic>> getWorkoutContext(String userId) =>
      _fetchWorkoutContext(userId);

  Future<Map<String, dynamic>> _fetchWorkoutContext(String userId) async {
    // Busca treinos grátis e BLDR CLUB em paralelo
    final results = await Future.wait([
      _client
          .from('user_workouts')
          .select('id, started_at, completed_at, workout_templates(workout_type)')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('completed_at', ascending: false),
      _client
          .from('club_user_workouts')
          .select('started_at, completed_at')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('completed_at', ascending: false),
    ]);

    final freeWorkouts = results[0] as List;
    final clubWorkouts = results[1] as List;
    final allWorkouts  = [...freeWorkouts, ...clubWorkouts];

    // workout_count = total grátis + BLDR CLUB
    final count = allWorkouts.length;

    // hiit_count — somente treinos grátis (têm template com workout_type)
    final hiitCount = freeWorkouts.where((w) {
      final t = w['workout_templates'] as Map?;
      return t?['workout_type']?.toString().toLowerCase() == 'hiit';
    }).length;

    // Dias únicos com treino (qualquer fonte)
    final workedDays = allWorkouts.map((w) {
      final s = (w as Map)['completed_at'] as String?;
      if (s == null) return null;
      final dt = DateTime.parse(s).toLocal();
      return DateTime(dt.year, dt.month, dt.day);
    }).whereType<DateTime>().toSet();

    int streak = 0;
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    while (workedDays.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    final trainedSat = workedDays.any((d) => d.weekday == DateTime.saturday);
    final trainedSun = workedDays.any((d) => d.weekday == DateTime.sunday);

    final trainedBeforeHour = allWorkouts.any((w) {
      final s = (w as Map)['started_at'] as String?;
      if (s == null) return false;
      return DateTime.parse(s).toLocal().hour < 7;
    });

    final now = DateTime.now();
    final todayMMDD = now.month * 100 + now.day;

    // Bench press: busca IDs dos templates com "bench press" no nome, depois max weight
    double maxBenchPress = 0;
    try {
      final benchTemplates = await _client
          .from('exercise_templates')
          .select('id')
          .ilike('name', '%bench press%');
      final templateIds = (benchTemplates as List).map((t) => t['id']).toList();
      if (templateIds.isNotEmpty) {
        final userWorkoutIds = freeWorkouts
            .map((w) => (w as Map)['id'])
            .whereType<Object>()
            .toList();
        if (userWorkoutIds.isNotEmpty) {
          final exercises = await _client
              .from('workout_exercises')
              .select('id')
              .inFilter('user_workout_id', userWorkoutIds)
              .inFilter('exercise_template_id', templateIds);
          final exerciseIds = (exercises as List)
              .map((e) => (e as Map)['id'])
              .whereType<Object>()
              .toList();
          if (exerciseIds.isNotEmpty) {
            final sets = await _client
                .from('workout_exercise_sets')
                .select('weight_kg')
                .inFilter('workout_exercise_id', exerciseIds)
                .order('weight_kg', ascending: false)
                .limit(1);
            if ((sets as List).isNotEmpty) {
              maxBenchPress =
                  ((sets.first as Map)['weight_kg'] as num?)?.toDouble() ?? 0;
            }
          }
        }
      }
    } catch (_) {}

    return {
      'workout_count':       count,
      'hiit_workout_count':  hiitCount,
      'consecutive_days':    streak,
      'weekend_warrior':     (trainedSat && trainedSun) ? 1 : 0,
      'trained_before_hour': trainedBeforeHour ? 1 : 0,
      'trained_on_date':     todayMMDD,
      'max_bench_press':     maxBenchPress,
    };
  }

  Future<Map<String, dynamic>> _fetchProfileContext(String userId) async {
    final results = await Future.wait([
      _client.from('user_profiles').select('onboarding_completed').eq('id', userId).single(),
      _client.from('user_goals').select('id').eq('user_id', userId).limit(1),
    ]);
    final profile = results[0] as Map;
    final goals   = results[1] as List;
    return {
      'onboarding_completed': profile['onboarding_completed'] == true,
      'goal_created':         goals.isNotEmpty,
    };
  }

  Future<Map<String, dynamic>> _fetchPhotoContext(String userId) async {
    final photos = await _client
        .from('progress_photos')
        .select('id')
        .eq('user_id', userId);
    return {'photo_count': (photos as List).length};
  }

  Future<Map<String, dynamic>> _fetchNutritionContext(String userId) async {
    // Refeições ficam no Firestore (user_meals); metas no Supabase (user_profiles)
    final cutoff = DateTime.now().subtract(const Duration(days: 365));
    final snapshotFuture = FirebaseFirestore.instance
        .collection('user_meals')
        .where('user_id', isEqualTo: userId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
        .get();
    final profileFuture = _client
        .from('user_profiles')
        .select('onboarding_data')
        .eq('id', userId)
        .maybeSingle();

    final snapshot = await snapshotFuture;
    final profile  = await profileFuture;
    final obd      = profile?['onboarding_data'] as Map?;

    final calorieGoal = (obd?['target_calories'] as num?)?.toDouble() ?? 2000.0;
    final proteinGoal = (obd?['target_protein']  as num?)?.toDouble() ?? 120.0;
    final carbsGoal   = (obd?['target_carbs']    as num?)?.toDouble() ?? 250.0;
    final fatGoal     = (obd?['target_fat']      as num?)?.toDouble() ?? 67.0;

    // Agrega totais por dia — cada doc é um item, com calories/protein/carbs/fat inline
    final dailyTotals = <DateTime, Map<String, double>>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final dateStr = data['date'] as String?;
      if (dateStr == null) continue;
      final dt  = DateTime.tryParse(dateStr);
      if (dt == null) continue;
      final day = DateTime(dt.year, dt.month, dt.day);
      dailyTotals[day] ??= {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
      dailyTotals[day]!['calories'] = dailyTotals[day]!['calories']! +
          ((data['calories'] as num?)?.toDouble() ?? 0);
      dailyTotals[day]!['protein']  = dailyTotals[day]!['protein']! +
          ((data['protein']  as num?)?.toDouble() ?? 0);
      dailyTotals[day]!['carbs']    = dailyTotals[day]!['carbs']! +
          ((data['carbs']    as num?)?.toDouble() ?? 0);
      dailyTotals[day]!['fat']      = dailyTotals[day]!['fat']! +
          ((data['fat']      as num?)?.toDouble() ?? 0);
    }

    final mealDays = dailyTotals.keys.toSet();

    int mealStreak = 0;
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    while (mealDays.contains(day)) {
      mealStreak++;
      day = day.subtract(const Duration(days: 1));
    }

    final calorieGoalDays = dailyTotals.entries
        .where((e) => e.value['calories']! >= calorieGoal)
        .map((e) => e.key)
        .toSet();

    int calorieGoalStreak = 0;
    day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    while (calorieGoalDays.contains(day)) {
      calorieGoalStreak++;
      day = day.subtract(const Duration(days: 1));
    }

    final now         = DateTime.now();
    final todayActual = DateTime(now.year, now.month, now.day);
    final todayTotals = dailyTotals[todayActual] ??
        {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
    final macroGoalMet = todayTotals['protein']! >= proteinGoal &&
        todayTotals['carbs']!   >= carbsGoal &&
        todayTotals['fat']!     >= fatGoal;

    return {
      'meal_count':                            mealDays.length,
      'meal_logged_consecutive_days':          mealStreak,
      'calorie_goal_reached':                  calorieGoalDays.contains(todayActual) ? 1 : 0,
      'calorie_goal_reached_consecutive_days': calorieGoalStreak,
      'macro_goal_reached':                    macroGoalMet ? 1 : 0,
    };
  }

  Future<Map<String, dynamic>> _fetchBldrClubContext(String userId) async {
    final results = await Future.wait([
      // Assinatura ativa
      _client
          .from('user_subscriptions')
          .select('status')
          .eq('user_id', userId)
          .or('status.eq.active,status.eq.trialing')
          .limit(1),
      // XP total e nível
      _client
          .schema('bldr_club')
          .from('club_ranking')
          .select('xp_total, current_level')
          .eq('user_id', userId)
          .maybeSingle(),
      // Treinos BLDR CLUB (tabela pública, não bldr_club.user_activities)
      _client
          .from('club_user_workouts')
          .select('id, completed_at')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('completed_at', ascending: false),
      // Duelos finalizados
      _client
          .schema('bldr_club')
          .from('user_challenges')
          .select('winner_id')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .eq('status', 'finished'),
      // Ranking global (para calcular posição)
      _client
          .schema('bldr_club')
          .from('club_ranking')
          .select('user_id, xp_total')
          .eq('ranking_visible', true)
          .order('xp_total', ascending: false)
          .limit(200),
    ]);

    final subs        = results[0] as List;
    final rankData    = results[1] as Map<String, dynamic>?;
    final activities  = results[2] as List;
    final challenges  = results[3] as List;
    final allRanking  = results[4] as List;

    int wins = 0;
    for (final c in challenges) {
      if (c['winner_id'] == userId) wins++;
    }

    int rankPos = 9999;
    for (int i = 0; i < allRanking.length; i++) {
      if (allRanking[i]['user_id'] == userId) {
        rankPos = i + 1;
        break;
      }
    }

    return {
      'club_member':       subs.isNotEmpty,
      'total_xp':          (rankData?['xp_total']      as num?)?.toInt() ?? 0,
      'club_level':        (rankData?['current_level']  as num?)?.toInt() ?? 1,
      'bldr_workout_total': activities.length,
      'duel_wins':         wins,
      'ranking_position':  rankPos,
      'bldr_streak_days':  _computeStreak(
          activities.map((a) => a['completed_at'] as String?).toList()),
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Calcula streak de dias consecutivos a partir de uma lista de timestamps ISO.
  int _computeStreak(List<String?> timestamps) {
    final days = timestamps
        .whereType<String>()
        .map((s) {
          final dt = DateTime.parse(s).toLocal();
          return DateTime(dt.year, dt.month, dt.day);
        })
        .toSet();
    int streak = 0;
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    while (days.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ---------------------------------------------------------------------------
  // Avaliação de condição
  // ---------------------------------------------------------------------------

  bool _evaluateCondition(
      Map<String, dynamic> achievement, Map<String, dynamic> context) {
    final type  = achievement['criteria_type'] as String;
    final value = (achievement['criteria_value'] as num?)?.toDouble() ?? 1.0;

    switch (type) {
      case 'workout_count':
        return (context['workout_count'] as int? ?? 0) >= value;
      case 'hiit_workout_count':
        return (context['hiit_workout_count'] as int? ?? 0) >= value;
      case 'consecutive_days':
        return (context['consecutive_days'] as int? ?? 0) >= value;
      case 'weekend_warrior':
        return (context['weekend_warrior'] as int? ?? 0) >= 1;
      case 'trained_before_hour':
        return (context['trained_before_hour'] as int? ?? 0) >= 1;
      case 'trained_on_date':
        return context['trained_on_date'] == value.toInt();
      case 'onboarding_complete':
        return context['onboarding_completed'] == true;
      case 'goal_created':
        return context['goal_created'] == true;
      case 'meal_logged':
        return (context['meal_count'] as int? ?? 0) >= value;
      case 'max_weight_bench_press':
        return (context['max_bench_press'] as double? ?? 0) >= value;
      case 'progress_photo_added':
        return (context['photo_count'] as int? ?? 0) >= value;
      case 'meal_logged_consecutive_days':
        return (context['meal_logged_consecutive_days'] as int? ?? 0) >= value;
      case 'club_member':
        return context['club_member'] == true;
      case 'total_xp':
        return (context['total_xp'] as int? ?? 0) >= value;
      case 'club_level':
        return (context['club_level'] as int? ?? 1) >= value;
      case 'bldr_workout_total':
        return (context['bldr_workout_total'] as int? ?? 0) >= value;
      case 'duel_wins':
        return (context['duel_wins'] as int? ?? 0) >= value;
      case 'ranking_position':
        // criteria_value = posição máxima (ex: 1 = top 1, 10 = top 10)
        final pos = context['ranking_position'] as int? ?? 9999;
        return pos > 0 && pos <= value;
      case 'bldr_streak_days':
        return (context['bldr_streak_days'] as int? ?? 0) >= value;
      case 'calorie_goal_reached':
        return (context['calorie_goal_reached'] as int? ?? 0) >= 1;
      case 'calorie_goal_reached_consecutive_days':
        return (context['calorie_goal_reached_consecutive_days'] as int? ?? 0) >= value;
      case 'macro_goal_reached':
        return (context['macro_goal_reached'] as int? ?? 0) >= 1;
      default:
        return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Unlock: user_achievements + XP
  // ---------------------------------------------------------------------------

  Future<void> _unlock(
      String userId, Map<String, dynamic> achievement) async {
    final name        = achievement['name'] as String;
    final description = achievement['description'] as String? ?? '';
    final category    = achievement['category'] as String? ?? 'general';
    final xpValue     = (achievement['xp_value'] as int?) ?? 50;

    await _client.from('user_achievements').insert({
      'user_id':                  userId,
      'achievement_type':         category,
      'achievement_name':         name,
      'achievement_description':  description,
      'achieved_at':              DateTime.now().toUtc().toIso8601String(),
    });

    await _client.schema('bldr_club').from('xp_events').insert({
      'user_id': userId,
      'delta':   xpValue,
      'reason':  name,
    });

    await _client.rpc('add_xp_to_user', params: {
      'p_user_id':   userId,
      'p_xp_amount': xpValue,
      'p_source':    achievement['criteria_type'] ?? 'achievement_unlocked',
    });
  }
}
