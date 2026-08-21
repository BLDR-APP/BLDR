import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/models/user_profile.dart';
import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/services/supabase_service.dart';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();

  UserService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return null;

    return getUserProfile(currentUser.id);
  }

  /// Update user profile
  Future<UserProfile> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      // Propaga full_name → club_profiles.display_name para manter ranking
      // e comunidade sincronizados (quando display_name personalizado é nulo).
      final newName = updates['full_name'];
      if (newName != null) {
        try {
          await _client
              .from('club_profiles')
              .update({'display_name': newName})
              .eq('user_id', userId)
              .isFilter('display_name', null);
        } catch (_) {
          // club_profiles pode não existir — não é erro fatal.
        }
      }

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update user profile: $error');
    }
  }

  /// Update current user profile
  Future<UserProfile?> updateCurrentUserProfile({
    required Map<String, dynamic> updates,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return null;

    return updateUserProfile(userId: currentUser.id, updates: updates);
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      // Contagem de treinos — histórico consolidado (pessoal + clube).
      // Antes só contava `user_workouts`, subcontando quem treina pelo Club.
      final historyResult = await getIt<GetConsolidatedWorkoutHistory>()(
          userId: userId, limit: 1000);
      final allWorkouts = historyResult.valueOrNull ?? [];
      final completedWorkouts =
          allWorkouts.where((w) => w.isCompleted).toList();

      final totalWorkoutsCount = allWorkouts.length;
      final completedWorkoutsCount = completedWorkouts.length;

      // Get achievements count
      final achievementData = await _client
          .from('user_achievements')
          .select('id')
          .eq('user_id', userId)
          .count();

      // Get latest weight measurement
      final weightResponse = await _client
          .from('user_measurements')
          .select('value, measured_at')
          .eq('user_id', userId)
          .eq('measurement_type', 'weight')
          .order('measured_at', ascending: false)
          .limit(1);

      double? currentWeight;
      if (weightResponse.isNotEmpty) {
        currentWeight = (weightResponse.first['value'] as num?)?.toDouble();
      }

      return {
        'total_workouts': totalWorkoutsCount,
        'completed_workouts': completedWorkoutsCount,
        'achievements': achievementData.count ?? 0,
        'current_weight': currentWeight,
        'completion_rate': totalWorkoutsCount > 0
            ? (completedWorkoutsCount / totalWorkoutsCount * 100).round()
            : 0,
      };
    } catch (error) {
      throw Exception('Failed to get user statistics: $error');
    }
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      return response == null;
    } catch (error) {
      throw Exception('Failed to check username availability: $error');
    }
  }

  /// Search users by username or full name
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .eq('is_active', true)
          .limit(20);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to search users: $error');
    }
  }

  /// Get user achievements
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final response = await _client
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .order('achieved_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get user achievements: $error');
    }
  }

  /// Add user achievement
  Future<Map<String, dynamic>> addUserAchievement({
    required String userId,
    required String achievementType,
    required String achievementName,
    String? achievementDescription,
    double? value,
    String? unit,
  }) async {
    try {
      final response = await _client
          .from('user_achievements')
          .insert({
        'user_id': userId,
        'achievement_type': achievementType,
        'achievement_name': achievementName,
        'achievement_description': achievementDescription,
        'value': value,
        'unit': unit,
      })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to add user achievement: $error');
    }
  }

  /// Mark user onboarding as completed
  Future<UserProfile?> markOnboardingCompleted() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .update({'onboarding_completed': true})
          .eq('id', currentUser.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to mark onboarding complete: $error');
    }
  }

  /// Dados do perfil usados pela tela de esportes (onboarding + planos).
  Future<Map<String, dynamic>?> getSportsProfileData() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return null;

    final response = await _client
        .from('user_profiles')
        .select('onboarding_data, performance_plans')
        .eq('id', currentUser.id)
        .single();
    return Map<String, dynamic>.from(response);
  }

  /// Gera um plano de performance via edge function (tela de esportes).
  Future<Map<String, dynamic>> generatePerformancePlan(String sport) async {
    final response = await _client.functions.invoke(
      'gerar-plano-performance',
      body: {'sport': sport},
    );
    if (response.status != 200 || response.data == null) {
      throw Exception('Falha API: ${response.data?['error']}');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Persiste os planos de performance (tela de esportes).
  Future<void> updatePerformancePlans(List<Map<String, dynamic>> plans) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return;

    await _client
        .from('user_profiles')
        .update({'performance_plans': plans}).eq('id', currentUser.id);
  }

  /// Versão do onboarding salva no perfil, ou `null` se não houver
  /// (ou em caso de erro — o chamador trata `null` como "refazer").
  Future<String?> getOnboardingVersion() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select('onboarding_data')
          .eq('id', currentUser.id)
          .maybeSingle();

      final onboardingData = response?['onboarding_data'];
      if (onboardingData is Map) {
        return onboardingData['onboarding_version']?.toString();
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return false;

    try {
      final response = await _client
          .from('user_profiles')
          .select('onboarding_completed')
          .eq('id', currentUser.id)
          .single();

      return response['onboarding_completed'] as bool? ?? false;
    } catch (error) {
      // If user profile doesn't exist yet, onboarding not completed
      return false;
    }
  }

  /// Save onboarding data to user profile
  Future<UserProfile?> saveOnboardingData({
    required Map<String, dynamic> onboardingData,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return null;

    try {
      // Convert onboarding responses to profile fields
      final profileUpdates = <String, dynamic>{
        'onboarding_completed': true,
      };

      // Map onboarding responses to profile fields
      if (onboardingData['fitness_goals'] != null) {
        final goal = onboardingData['fitness_goals'] as String;
        switch (goal.toLowerCase()) {
          case 'lose weight':
            profileUpdates['fitness_goal'] = 'weight_loss';
            break;
          case 'build muscle':
            profileUpdates['fitness_goal'] = 'muscle_gain';
            break;
          case 'improve endurance':
            profileUpdates['fitness_goal'] = 'endurance';
            break;
          case 'general fitness':
            profileUpdates['fitness_goal'] = 'general_fitness';
            break;
          case 'athletic performance':
          case 'rehabilitation':
            profileUpdates['fitness_goal'] = 'strength';
            break;
        }
      }

      if (onboardingData['experience_level'] != null) {
        final experience = onboardingData['experience_level'] as String;
        if (experience.contains('Beginner')) {
          profileUpdates['activity_level'] = 'lightly_active';
        } else if (experience.contains('Intermediate')) {
          profileUpdates['activity_level'] = 'moderately_active';
        } else if (experience.contains('Advanced')) {
          profileUpdates['activity_level'] = 'very_active';
        } else if (experience.contains('Expert')) {
          profileUpdates['activity_level'] = 'extremely_active';
        }
      }

      // Update user profile with onboarding data
      final response = await _client
          .from('user_profiles')
          .update(profileUpdates)
          .eq('id', currentUser.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to save onboarding data: $error');
    }
  }
}

