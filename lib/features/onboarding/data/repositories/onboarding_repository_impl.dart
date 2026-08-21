import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:bldr_fitness/core/providers/locale_provider.dart';
import 'package:get_it/get_it.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final supabase.SupabaseClient _client;
  final String? Function() _currentUserId;

  OnboardingRepositoryImpl(this._client, this._currentUserId);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on Failure catch (f) {
      return Result.failure(f);
    } on supabase.PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message, cause: e));
    } on supabase.FunctionException catch (e) {
      return Result.failure(
          ServerFailure('Erro na geração do plano (${e.status}).', cause: e));
    } on SocketException catch (e) {
      return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
    } on TimeoutException catch (e) {
      return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
    } catch (e) {
      return Result.failure(UnexpectedFailure('Ocorreu um erro inesperado.', e));
    }
  }

  String _requireUser() {
    final uid = _currentUserId();
    if (uid == null) throw const AuthFailure('Usuário não autenticado.');
    return uid;
  }

  /// Garante que nenhum campo obrigatório chegue como null na edge function.
  /// Campos opcionais que se tornaram opcionais no redesign do onboarding
  /// (body_fat_image, activity_details) recebem defaults seguros.
  static Map<String, dynamic> _sanitize(Map<String, dynamic> d) => {
        'gender': d['gender'] ?? '',
        'age': (d['age'] as num?)?.toInt() ?? 25,
        'height': (d['height'] as num?)?.toInt() ?? 170,
        'weight': (d['weight'] as num?)?.toDouble() ?? 70.0,
        'main_goal': d['main_goal'] ?? '',
        'goal_pace': d['goal_pace'] ?? 'Moderado',
        'activity_level': d['activity_level'] ?? '',
        'regular_activities': d['regular_activities'] ?? <String>[],
        'experience_level': d['experience_level'] ?? '',
        'workout_frequency_days': (d['workout_frequency_days'] as num?)?.toInt() ?? 3,
        'workout_duration_range': d['workout_duration_range'] ?? '',
        'workout_environment': d['workout_environment'] ?? '',
        'home_equipment': d['home_equipment'] ?? <String>[],
        'muscle_focus': d['muscle_focus'] ?? <String>[],
        'split_preference': d['split_preference'] ?? 'Deixa a HAVOK decidir',
        'injuries': d['injuries'] ?? <String>['Nenhuma lesão atual'],
        // opcionais — defaults neutros para compatibilidade com versão anterior
        'body_fat_image': d['body_fat_image'] ?? '',
        'activity_details': d['activity_details'] ?? <String, dynamic>{},
        // metas já calculadas pelo Flutter (passadas para contexto)
        'target_calories': d['target_calories'] ?? 0,
        'target_protein': d['target_protein'] ?? 0,
        'calculated_tdee': d['calculated_tdee'] ?? 0,
      };

  @override
  Future<Result<Map<String, dynamic>>> generatePlan(
          Map<String, dynamic> onboardingData) =>
      _guard(() async {
        final locale = GetIt.instance<LocaleProvider>().locale.languageCode;
        final response = await _client.functions.invoke(
          'gerar-plano-havok',
          body: {'onboardingData': _sanitize(onboardingData), 'locale': locale},
        );
        if (response.status != 200) {
          throw ServerFailure('Falha na função gerar-plano-havok (${response.status}).');
        }
        final data = response.data;
        return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      });

  @override
  Future<Result<Map<String, dynamic>>> getOnboardingData() =>
      _guard(() async {
        final uid = _requireUser();
        final row = await _client
            .from('user_profiles')
            .select('onboarding_data')
            .eq('id', uid)
            .maybeSingle();
        final data = row?['onboarding_data'];
        return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      });

  @override
  Future<Result<void>> saveNutritionGoals({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) =>
      _guard(() async {
        final uid = _requireUser();
        final row = await _client
            .from('user_profiles')
            .select('onboarding_data')
            .eq('id', uid)
            .maybeSingle();
        final current = row?['onboarding_data'];
        final merged = current is Map
            ? Map<String, dynamic>.from(current)
            : <String, dynamic>{};
        merged['target_calories'] = calories;
        merged['target_protein'] = protein;
        merged['target_carbs'] = carbs;
        merged['target_fat'] = fat;

        await _client
            .from('user_profiles')
            .update({'onboarding_data': merged}).eq('id', uid);
      });
}
