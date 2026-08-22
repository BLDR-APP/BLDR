import 'package:supabase_flutter/supabase_flutter.dart';

/// Queries do plano semanal (antes espalhadas na weekly_plan_screen).
/// Não trata erros — exceções sobem para o repository.
class SupabaseWeeklyPlanDatasource {
  final SupabaseClient _client;

  SupabaseWeeklyPlanDatasource(this._client);

  Future<Map<String, dynamic>?> onboardingData(String userId) async {
    final profile = await _client
        .from('user_profiles')
        .select('onboarding_data')
        .eq('id', userId)
        .maybeSingle();
    return profile?['onboarding_data'] as Map<String, dynamic>?;
  }

  Future<void> updateOnboardingData(
      String userId, Map<String, dynamic> onboardingData) =>
      _client
          .from('user_profiles')
          .update({'onboarding_data': onboardingData}).eq('id', userId);

  Future<List<Map<String, dynamic>>> personalWorkoutsBetween(
      String userId, DateTime start, DateTime end) async {
    final rows = await _client
        .from('user_workouts')
        .select(
            'id, name, completed_at, started_at, total_duration_seconds, workout_templates(name, workout_type)')
        .eq('user_id', userId)
        .not('completed_at', 'is', null)
        .gte('started_at', start.toIso8601String())
        .lt('started_at', end.toIso8601String())
        .order('started_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> clubCompletedBetween(
      String userId, DateTime start, DateTime end) async {
    final rows = await _client
        .from('club_user_workouts')
        .select('id, completed_at, started_at, notes')
        .eq('user_id', userId)
        .not('completed_at', 'is', null) // fonte de verdade: completed_at
        .gte('started_at', start.toIso8601String())
        .lt('started_at', end.toIso8601String());
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<String>> exerciseDbIdsForWorkout(String workoutId) async {
    final rows = await _client
        .from('workout_exercise_sets')
        .select('exercise_db_id')
        .eq('user_workout_id', workoutId);
    return rows
        .map((r) => r['exercise_db_id'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Grupos musculares da biblioteca interna, tentando a FK nomeada e caindo
  /// para o join genérico (mesma estratégia do código original).
  Future<List<String>> internalMusclesForWorkout(String workoutId) async {
    Future<List<String>> extract(String select) async {
      final rows = await _client
          .from('workout_exercise_sets')
          .select(select)
          .eq('user_workout_id', workoutId);
      return rows
          .map((row) =>
              (row['exercises'] as Map?)?['primary_muscle_group'] as String?)
          .whereType<String>()
          .where((m) => m.isNotEmpty)
          .toList();
    }

    try {
      return await extract(
          'exercises!workout_exercise_sets_exercise_id_fkey(primary_muscle_group)');
    } catch (_) {
      try {
        return await extract('exercises(primary_muscle_group)');
      } catch (_) {
        return [];
      }
    }
  }

  /// Upsert de todos os dias do plano (ON CONFLICT user_id, dia_semana DO UPDATE).
  Future<void> upsertWeeklyPlan(
      String userId, List<Map<String, dynamic>> rows) async {
    await _client.from('weekly_plan_days').upsert(
      rows,
      onConflict: 'user_id,dia_semana',
    );
  }

  /// Retorna os dias do plano ordenados por dia_semana.
  Future<List<Map<String, dynamic>>> getWeeklyPlan(String userId) async {
    final rows = await _client
        .from('weekly_plan_days')
        .select('dia_semana, template_id, club_template_id, template_name, tipo, source')
        .eq('user_id', userId)
        .order('dia_semana');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> deleteClubWorkout(String clubWorkoutId) async {
    await _client
        .from('club_workout_exercise_sets')
        .delete()
        .eq('user_workout_id', clubWorkoutId);
    await _client.from('club_user_workouts').delete().eq('id', clubWorkoutId);
  }
}
