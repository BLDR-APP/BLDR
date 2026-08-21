// lib/features/professional_portal/data/repositories/professional_repository.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class ProfessionalRepository {
  final _supabase = Supabase.instance.client;

  // ... (registerNewProfessional, isProfessionalUser, addClientByEmail ... permanecem iguais) ...
  Future<void> registerNewProfessional({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String professionalId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'register-professional',
        body: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': role,
          'professionalId': professionalId,
        },
      );
      if (response.status != 200) {
        final errorMessage =
            response.data['error'] ?? 'Ocorreu um erro desconhecido.';
        throw Exception(errorMessage);
      }
      return;
    } on FunctionException catch (e) {
      print('FunctionException: ${e.details}');
      throw Exception('Erro de comunicação com o servidor.');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isProfessionalUser({required String userId}) async {
    try {
      final response = await _supabase
          .schema('bldr_club')
          .from('professional_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Erro ao verificar perfil profissional: $e');
      return false;
    }
  }

  Future<String> addClientByEmail(String clientEmail) async {
    try {
      final response = await _supabase.functions.invoke(
        'link-professional-client', // Nome da nova Edge Function
        body: {'clientEmail': clientEmail},
      );

      if (response.status != 200) {
        throw Exception(response.data['error'] ?? 'Ocorreu um erro desconhecido.');
      }
      return response.data['message']; // Retorna a mensagem de sucesso
    } catch (e) {
      // Relança o erro para a UI poder tratá-lo
      rethrow;
    }
  }


  Future<List<String>> getMyClientsIds() async {
    try {
      if (_supabase.auth.currentUser == null) {
        throw Exception('Usuário não autenticado.');
      }

      final response = await _supabase
          .schema('bldr_club')
          .from('professional_clients')
          .select('client_user_id')
          .eq('professional_user_id', _supabase.auth.currentUser!.id);

      final clientList = (response as List).map((item) {
        return item['client_user_id'] as String;
      }).toList();

      return clientList;
    } catch (e) {
      print('Erro ao buscar IDs de clientes: $e');
      throw Exception('Não foi possível carregar seus clientes.');
    }
  }

  Future<Map<String, dynamic>> getClientProfileById(String clientId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url')
          .eq('id', clientId)
          .single();

      return response;
    } catch (e) {
      print('Erro ao buscar perfil do cliente $clientId: $e');
      throw Exception('Não foi possível carregar dados do cliente.');
    }
  }


  Future<Map<String, dynamic>> getMyProfessionalProfile() async {
    try {
      if (_supabase.auth.currentUser == null) {
        throw Exception('Usuário não autenticado.');
      }

      final response = await _supabase
          .schema('bldr_club')
          .from('professional_profiles')
          .select('role, subscription_status')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .single();

      final role = response['role'] as String?;
      final status = response['subscription_status'] as String?;

      if (role == null || (role != 'personal' && role != 'nutritionist')) {
        throw Exception('Tipo de profissional inválido ou não encontrado.');
      }

      if (status == null) {
        print('Aviso: subscription_status é nulo, tratando como inativo.');
        response['subscription_status'] = 'inactive';
      }

      return response;

    } catch (e) {
      print('Erro ao buscar o perfil profissional: $e');
      throw Exception('Não foi possível identificar seu perfil profissional.');
    }
  }

  // --- FUNÇÕES DE DIETA (V1.0 - PDF) ---
  Future<List<Map<String, dynamic>>> getDietPlans(String clientId) async {
    try {
      final response = await _supabase
          .schema('bldr_club')
          .from('diet_plans')
          .select('id, plan_title, file_path, created_at')
          .eq('client_user_id', clientId)
          .order('created_at', ascending: false);

      return (response as List).map((item) => item as Map<String, dynamic>).toList();

    } catch (e) {
      print('Erro ao buscar planos de dieta: $e');
      throw Exception('Não foi possível carregar as dietas do cliente.');
    }
  }
  Future<void> uploadDietPlan({
    required File file,
    required String planTitle,
    required String clientId,
  }) async {
    try {
      final professionalId = _supabase.auth.currentUser!.id;
      final fileExtension = p.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = '$professionalId/$clientId/$fileName';
      await _supabase.storage
          .from('diet_plans')
          .upload(filePath, file);
      final fileUrl = _supabase.storage
          .from('diet_plans')
          .getPublicUrl(filePath);
      await _supabase
          .schema('bldr_club')
          .from('diet_plans')
          .insert({
        'professional_user_id': professionalId,
        'client_user_id': clientId,
        'plan_title': planTitle,
        'file_path': fileUrl,
      });
    } catch (e) {
      print('Erro no upload da dieta: $e');
      throw Exception('Falha ao enviar o plano de dieta.');
    }
  }
  // --- FIM DAS FUNÇÕES DE DIETA (V1.0 - PDF) ---


  // --- FUNÇÕES DE TREINO (PERSONAL) ---
  Future<List<Map<String, dynamic>>> getWorkoutPlans(String clientId) async {
    try {
      final response = await _supabase
          .schema('bldr_club')
          .from('workout_plans')
          .select('id, plan_name, created_at')
          .eq('client_user_id', clientId)
          .order('created_at', ascending: false);

      return (response as List).map((item) => item as Map<String, dynamic>).toList();

    } catch (e) {
      print('Erro ao buscar planos de treino: $e');
      throw Exception('Não foi possível carregar os planos de treino.');
    }
  }
  Future<Map<String, dynamic>> createWorkoutPlan({
    required String planName,
    required String clientId,
  }) async {
    try {
      final professionalId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .schema('bldr_club')
          .from('workout_plans')
          .insert({
        'professional_user_id': professionalId,
        'client_user_id': clientId,
        'plan_name': planName,
      })
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao criar plano de treino: $e');
      throw Exception('Falha ao criar o plano de treino.');
    }
  }
  Future<List<Map<String, dynamic>>> getWorkoutPlanExercises(int planId) async {
    try {
      final response = await _supabase
          .schema('bldr_club')
          .from('workout_plan_exercises')
          .select('*')
          .eq('workout_plan_id', planId)
          .order('exercise_order', ascending: true);

      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      print('Erro ao buscar exercícios: $e');
      throw Exception('Não foi possível carregar os exercícios.');
    }
  }
  Future<void> addExerciseToPlan({
    required int planId,
    required String name,
    required String sets,
    required String reps,
    required String rest,
    required String notes,
    required int order,
  }) async {
    try {
      await _supabase
          .schema('bldr_club')
          .from('workout_plan_exercises')
          .insert({
        'workout_plan_id': planId,
        'exercise_name': name,
        'sets': sets,
        'reps': reps,
        'rest_period': rest,
        'notes': notes,
        'exercise_order': order,
      });
    } catch (e) {
      print('Erro ao adicionar exercício: $e');
      throw Exception('Falha ao adicionar o exercício.');
    }
  }
  // --- FIM DAS FUNÇÕES DE TREINO ---


  // --- INÍCIO DAS FUNÇÕES (V2.0 - CONSTRUTOR DE DIETAS) ---

  Future<List<Map<String, dynamic>>> getMealPlans(String clientId) async {
    try {
      final response = await _supabase
          .schema('bldr_club')
          .from('meal_plans')
          .select('id, plan_name, created_at, notes')
          .eq('client_user_id', clientId)
          .order('created_at', ascending: false);

      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      print('Erro ao buscar planos de refeição: $e');
      throw Exception('Não foi possível carregar os planos de refeição.');
    }
  }
  Future<Map<String, dynamic>> createMealPlan({
    required String clientId,
    required String planName,
    String? notes,
  }) async {
    try {
      final professionalId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .schema('bldr_club')
          .from('meal_plans')
          .insert({
        'professional_user_id': professionalId,
        'client_user_id': clientId,
        'plan_name': planName,
        'notes': notes,
      })
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao criar plano de refeição: $e');
      throw Exception('Falha ao criar o plano de refeição.');
    }
  }

  Future<Map<String, dynamic>> getMealPlanDetails(int planId) async {
    try {
      final response = await _supabase
          .schema('bldr_club')
          .from('meal_plans')
          .select('''
            id,
            plan_name,
            notes,
            meals (
              id,
              name,
              meal_order, 
              meal_items (
                id,
                food_db_id,
                food_name,
                quantity,
                unit,
                calories,
                protein,
                carbs,
                fat,
                item_order 
              )
            )
          ''')
          .eq('id', planId)
          .order('meal_order', referencedTable: 'meals', ascending: true) // <-- 1ª ALTERAÇÃO
          .order('item_order', referencedTable: 'meals.meal_items', ascending: true) // <-- 2ª ALTERAÇÃO
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao buscar detalhes do plano de refeição: $e');
      throw Exception('Não foi possível carregar os detalhes do plano.');
    }
  }

  Future<Map<String, dynamic>> createMeal({
    required int planId,
    required String mealName,
    required int order,
  }) async {
    try {
      final response = await _supabase
          .schema('bldr_club')
          .from('meals')
          .insert({
        'meal_plan_id': planId,
        'name': mealName,
        'meal_order': order, // <-- 3ª ALTERAÇÃO
      })
          .select()
          .single();
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao criar refeição: $e');
      throw Exception('Falha ao adicionar refeição.');
    }
  }

  Future<void> addFoodToMeal({
    required int mealId,
    required String foodDbId,
    required String foodName,
    required double quantity,
    required String unit,
    required int order,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    try {
      await _supabase
          .schema('bldr_club')
          .from('meal_items')
          .insert({
        'meal_id': mealId,
        'food_db_id': foodDbId,
        'food_name': foodName,
        'quantity': quantity,
        'unit': unit,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'item_order': order, // <-- 4ª ALTERAÇÃO
      });
    } catch (e) {
      print('Erro ao adicionar item de comida: $e');
      throw Exception('Falha ao adicionar alimento à refeição.');
    }
  }
  // --- FIM DAS FUNÇÕES (V2.0 - CONSTRUTOR DE DIETAS) ---


  // --- INÍCIO DAS NOVAS FUNÇÕES (PAYWALL) ---
  Future<String> createProfessionalCheckoutSession({required String priceId}) async {
    try {
      if (_supabase.auth.currentUser == null) {
        throw Exception('Usuário não autenticado.');
      }

      final response = await _supabase.functions.invoke(
        'checkout',
        body: {
          'price_id_stripe': priceId,
          'product_type': 'professional',
          'user_id': _supabase.auth.currentUser!.id
        },
      );

      if (response.status != 200) {
        final errorMessage = response.data?['error'] ?? 'Erro desconhecido.';
        throw Exception(errorMessage);
      }

      final checkoutUrl = response.data?['checkout_url'] as String?;

      if (checkoutUrl == null) {
        throw Exception('A resposta do servidor não continha uma URL de checkout.');
      }

      return checkoutUrl;

    } catch (e) {
      print('Erro ao criar sessão de checkout: $e');
      rethrow;
    }
  }
// --- FIM DAS NOVAS FUNÇÕES (PAYWALL) ---
}