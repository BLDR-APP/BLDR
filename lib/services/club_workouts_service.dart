import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';
import 'package:bldr_fitness/services/supabase_service.dart';

class ClubWorkoutsService {
  static ClubWorkoutsService? _instance;
  static ClubWorkoutsService get instance => _instance ??= ClubWorkoutsService._();

  ClubWorkoutsService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // ==========================================================
  // BUSCAS DE TEMPLATES
  // ==========================================================

  /// Lista templates de treino do CLUB
  Future<List<Map<String, dynamic>>> getClubWorkoutTemplates({
    String? workoutType,
    int? difficultyLevel,
    bool publicOnly = false,
  }) async {
    // ... (Esta função permanece INALTERADA) ...
    try {
      var query = _client.from('club_workout_templates').select('''
        id, name, description, workout_type, estimated_duration_minutes,
        difficulty_level, is_public, created_at
      ''');

      if (publicOnly) query = query.eq('is_public', true);
      if (workoutType != null) query = query.eq('workout_type', workoutType);
      if (difficultyLevel != null) query = query.eq('difficulty_level', difficultyLevel);

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get club workout templates: $error');
    }
  }

  /// Detalha um template com exercícios (2 queries — sem embed FK para exercises)
  Future<Map<String, dynamic>?> getClubWorkoutTemplateWithExercises(String templateId) async {
    try {
      // 1) Cabeçalho do template
      final template = await _client.from('club_workout_templates').select('''
        id, name, description, workout_type, estimated_duration_minutes,
        difficulty_level, is_public, created_at
      ''').eq('id', templateId).single();

      // 2) Exercícios do template (sem embed)
      final rawExercises = await _client
          .from('club_workout_template_exercises')
          .select('id, exercise_id, order_index, sets, reps, duration_seconds, rest_seconds, weight_kg, distance_meters, notes')
          .eq('workout_template_id', templateId)
          .order('order_index', ascending: true);

      final exerciseRows = List<Map<String, dynamic>>.from(rawExercises);

      // 3) Busca nomes/detalhes dos exercícios em public.exercises
      final ids = exerciseRows
          .map((m) => (m['exercise_id'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> exById = {};
      if (ids.isNotEmpty) {
        final orCond = ids.map((id) => 'id.eq.$id').join(',');
        final exRows = await _client
            .from('exercises')
            .select('id, name, description, exercise_type, primary_muscle_group, secondary_muscle_groups, instructions, image_url, equipment_needed, exercise_db_id')
            .or(orCond);
        for (final e in (exRows as List)) {
          final id = (e['id'] ?? '').toString();
          exById[id] = Map<String, dynamic>.from(e as Map);
        }
      }

      // 4) Mescla exercícios com detalhes
      final enriched = exerciseRows.map((row) {
        final exId = (row['exercise_id'] ?? '').toString();
        final ex = exById[exId] ?? {
          'id': exId,
          'name': 'Exercício',
          'primary_muscle_group': null,
          'exercise_db_id': null,
        };
        return {...row, 'exercises': ex};
      }).toList();

      return {
        ...Map<String, dynamic>.from(template),
        // Chave sem prefixo 'club_' — é o que WorkoutModels.templateFromMap
        // espera (parser compartilhado com o modo grátis) e o que
        // templateToLegacyMap grava de volta. Antes divergia daqui, então a
        // lista de exercícios nunca chegava à UI (RELATORIO_TREINOS_CLUB.md, bug 1).
        'workout_template_exercises': enriched,
      };
    } catch (error) {
      throw Exception('Failed to get club workout template: $error');
    }
  }

  // ==========================================================
  // INÍCIO E FIM DO TREINO
  // ==========================================================

  /// Inicia um treino do CLUB
  Future<Map<String, dynamic>> startClubWorkout({
    required String name,
    required String clubWorkoutTemplateId,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) throw Exception('User must be authenticated');

      // 1) cria o club_user_workouts (UTC evita deslocamento de fuso)
      final baseInsert = {
        'user_id': currentUser.id,
        'workout_template_id': clubWorkoutTemplateId, // CORRETO
        'name': name,
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'is_completed': false,
      };

      Map<String, dynamic> workout;
      try {
        workout = await _client.from('club_user_workouts').insert(baseInsert).select().single();
      } on PostgrestException catch (e) {
        // Fallback se 'is_completed' não existir
        if ((e.message ?? '').toLowerCase().contains('is_completed')) {
          final withoutFlag = Map<String, dynamic>.from(baseInsert)..remove('is_completed');
          workout = await _client.from('club_user_workouts').insert(withoutFlag).select().single();
        } else {
          rethrow;
        }
      }

      // 2) clona sets do template
      final tpl = await _client
          .from('club_workout_template_exercises')
          .select('''
            order_index, sets, reps, duration_seconds, rest_seconds,
            weight_kg, distance_meters, notes, exercise_id
          ''')
          .eq('workout_template_id', clubWorkoutTemplateId) // CORRETO
          .order('order_index', ascending: true);

      final setsToInsert = <Map<String, dynamic>>[];
      for (final row in tpl) {
        final totalSets = (row['sets'] as int?) ?? 1;
        for (int s = 1; s <= totalSets; s++) {
          setsToInsert.add({
            'user_workout_id': workout['id'],
            'exercise_id': row['exercise_id'],
            'set_number': s,

            // =============================================
            // === ⬇️ MODIFICADO (BUG ii - Passo 2) ⬇️ ===
            // Copia a ordem do template para o set ativo
            'order_index': row['order_index'],
            // =============================================

            'reps': row['reps'],
            'weight_kg': row['weight_kg'],
            'duration_seconds': row['duration_seconds'],
            'distance_meters': row['distance_meters'],
            'rest_seconds': row['rest_seconds'],
            'notes': row['notes'],
            'completed_at': null,
            'is_completed': false, // pode não existir; tratamos abaixo
          });
        }
      }

      // 3) Insere sets
      if (setsToInsert.isNotEmpty) {
        try {
          // MODIFICADO: Tenta inserir na tabela 'club_workout_exercise_sets'
          await _client.from('club_workout_exercise_sets').insert(setsToInsert);
        } on PostgrestException catch (e) {
          // Fallback se 'is_completed' não existir
          if ((e.message ?? '').toLowerCase().contains('is_completed')) {
            final fallback = setsToInsert
                .map((m) => Map<String, dynamic>.from(m)..remove('is_completed'))
                .toList();
            // MODIFICADO: Tenta inserir na tabela 'club_workout_exercise_sets'
            await _client.from('club_workout_exercise_sets').insert(fallback);
          } else {
            rethrow;
          }
        }
      }

      return Map<String, dynamic>.from(workout);
    } catch (error) {
      throw Exception('Failed to start club workout: $error');
    }
  }

  /// Garante que os sets iniciais existam para uma sessão do Club.
  /// Idempotente — seguro chamar mesmo que os sets já existam.
  Future<void> ensureClubInitialSets(String sessionId, String templateId) async {
    try {
      final existing = await _client
          .from('club_workout_exercise_sets')
          .select('id')
          .eq('user_workout_id', sessionId)
          .limit(1);
      if ((existing as List).isNotEmpty) return;

      final tpl = await _client
          .from('club_workout_template_exercises')
          .select('order_index, sets, reps, duration_seconds, rest_seconds, weight_kg, distance_meters, notes, exercise_id')
          .eq('workout_template_id', templateId)
          .order('order_index', ascending: true);

      if ((tpl as List).isEmpty) return;

      final setsToInsert = <Map<String, dynamic>>[];
      for (final row in tpl) {
        final totalSets = (row['sets'] as int?) ?? 1;
        for (int s = 1; s <= totalSets; s++) {
          setsToInsert.add({
            'user_workout_id': sessionId,
            'exercise_id': row['exercise_id'],
            'set_number': s,
            'order_index': row['order_index'],
            'reps': row['reps'],
            'weight_kg': row['weight_kg'],
            'duration_seconds': row['duration_seconds'],
            'distance_meters': row['distance_meters'],
            'rest_seconds': row['rest_seconds'],
            'notes': row['notes'],
            'completed_at': null,
          });
        }
      }

      if (setsToInsert.isNotEmpty) {
        await _client.from('club_workout_exercise_sets').insert(setsToInsert);
      }
    } catch (_) {
      // Falha silenciosa: a tela renderiza vazia mas não crasha.
    }
  }

  /// Conclui um treino do CLUB
  Future<Map<String, dynamic>> completeClubWorkout({
    required String workoutId,
    String? notes,
  }) async {
    // ... (Esta função permanece INALTERADA) ...
    try {
      final now = DateTime.now();

      final workoutResponse = await _client
          .from('club_user_workouts')
          .select('started_at')
          .eq('id', workoutId)
          .single();

      final startedAt = DateTime.parse(workoutResponse['started_at'].toString());
      final rawDuration = now.difference(startedAt).inSeconds;
      final duration = rawDuration < 60 ? 60 : rawDuration;

      final response = await _client
          .from('club_user_workouts')
          .update({
        'completed_at': now.toUtc().toIso8601String(),
        'total_duration_seconds': duration,
        'notes': notes,
        'is_completed': true,
      })
          .eq('id', workoutId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to complete club workout: $error');
    }
  }

  // ==========================================================
  // LISTAGENS/ACÕES AUXILIARES
  // ==========================================================

  /// Lista treinos do usuário
  Future<List<Map<String, dynamic>>> getClubUserWorkouts({
    String? userId,
    bool completedOnly = false,
    int limit = 20,
  }) async {
    // ... (Esta função permanece INALTERADA) ...
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;

      var query = _client
          .from('club_user_workouts')
          .select('''
            id, name, started_at, completed_at, total_duration_seconds,
            notes, is_completed,
            club_workout_templates(name, workout_type, estimated_duration_minutes)
          ''')
          .eq('user_id', targetUserId);

      if (completedOnly) {
        query = query.eq('is_completed', true);
      }

      final response = await query.order('started_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get user club workouts: $error');
    }
  }

  /// Insere um set pontual (não usado no clone)
  Future<Map<String, dynamic>> logClubExerciseSet({
    required String userWorkoutId,
    required String exerciseId,
    required int setNumber,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
    int? restSeconds,
    String? notes,
  }) async {
    // ... (Esta função permanece INALTERADA) ...
    try {
      final response = await _client
          .from('club_workout_exercise_sets')
          .insert({
        'user_workout_id': userWorkoutId,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'reps': reps,
        'weight_kg': weightKg,
        'duration_seconds': durationSeconds,
        'distance_meters': distanceMeters,
        'rest_seconds': restSeconds,
        'notes': notes,
      })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to log club exercise set: $error');
    }
  }

  // =============================================
  // === ⬇️ MODIFICADO (Bug 'is_completed') ⬇️ ===
  // =============================================
  /// Marca série como concluída
  Future<void> completeClubSet({
    required String setId,
    double? weight, // <--- Novo parâmetro
    int? reps,      // <--- Novo parâmetro
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      };

      // Mapeia para as colunas do banco (weight_kg)
      if (weight != null) {
        updates['weight_kg'] = weight;
      }
      if (reps != null) {
        updates['reps'] = reps;
      }

      await _client
          .from('club_workout_exercise_sets') // Confirme se a tabela é essa mesmo
          .update(updates)
          .eq('id', setId);
    } catch (e) {
      throw Exception('Failed to complete club set: $e');
    }
  }

  // =============================================
  // === ⬇️ MODIFICADO (Bug 'is_completed') ⬇️ ===
  // =============================================
  /// Desfaz conclusão da série
  Future<void> undoClubSet({required String setId}) async {
    try {
      await _client
          .from('club_workout_exercise_sets')
          .update({
        'completed_at': null,
        // 'is_completed': false, // REMOVIDO
      })
          .eq('id', setId);
    } catch (e) {
      throw Exception('Failed to undo club set: $e');
    }
  }

  // ==========================================================
  // BUSCA DETALHADA (SEM EMBED) E STREAM DO BANNER
  // ==========================================================

  /// Detalhes do treino (head + sets + nomes dos exercícios via 2ª query).
  Future<Map<String, dynamic>?> getClubWorkoutDetails(String workoutId) async {
    try {
      // 1) Head + template (embed do template pode existir)
      Map<String, dynamic> head;
      try {
        head = await _client
            .from('club_user_workouts')
            .select('''
              id, name, started_at, completed_at, total_duration_seconds,
              notes, is_completed, workout_template_id,
              club_workout_templates(
                id, name, workout_type, difficulty_level, estimated_duration_minutes
              )
            ''')
            .eq('id', workoutId)
            .single();
      } on PostgrestException catch (_) {
        head = await _client
            .from('club_user_workouts')
            .select('id, name, started_at, completed_at, total_duration_seconds, notes, is_completed, workout_template_id')
            .eq('id', workoutId)
            .single();
        head['club_workout_templates'] = null;
      }

      // 2) Sets (sem embed de exercises)
      final rawSets = await _client
          .from('club_workout_exercise_sets')
          .select('''
            id, user_workout_id, exercise_id, set_number, reps, weight_kg,
            duration_seconds, distance_meters, rest_seconds, completed_at, notes,
            order_index
          ''')
      // ^^^ MODIFICADO: Adicionada a coluna 'order_index' ao select
          .eq('user_workout_id', workoutId)
      // =============================================
      // === ⬇️ MODIFICADO (BUG ii - Passo 3) ⬇️ ===
      // Ordena primeiro pela ORDEM, depois pelo NÚMERO DA SÉRIE
          .order('order_index', ascending: true)
          .order('set_number', ascending: true);
      // =============================================

      final sets = List<Map<String, dynamic>>.from(rawSets);

      // 3) Enriquecer sets com nomes dos exercícios via 2ª query (sem .in_)
      final exerciseIds = sets
          .map((m) => (m['exercise_id'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> exById = {};
      if (exerciseIds.isNotEmpty) {
        // Fallback universal: OR com múltiplos id.eq.
        final orCond = exerciseIds.map((id) => 'id.eq.$id').join(',');
        final exRows = await _client
            .from('exercises')
        // =============================================
        // === ⬇️ MODIFICADO (Bug 'exercise_db_id') ⬇️ ===
        // =============================================
            .select('id, name, primary_muscle_group, exercise_db_id')
            .or(orCond);

        for (final e in (exRows as List)) {
          final id = (e['id'] ?? '').toString();
          exById[id] = {
            'id': id,
            'name': (e['name'] ?? 'Exercício').toString(),
            'primary_muscle_group': e['primary_muscle_group'],
            'exercise_db_id': e['exercise_db_id'], // <-- ADICIONADO
          };
        }
      }

      // 4) Anexar um campo "exercises" em cada set (formato que o banner espera)
      final setsWithNames = sets.map((s) {
        final exId = (s['exercise_id'] ?? '').toString();
        final ex = exById[exId] ??
            {
              'id': exId,
              'name': 'Exercício',
              'primary_muscle_group': null,
              'exercise_db_id': null, // <-- ADICIONADO
            };
        return {...s, 'exercises': ex};
      }).toList();

      final workout = {
        ...head,
        'club_workout_exercise_sets': setsWithNames,
      };

      return _decorateClubSetsWithIsCompleted(workout);
    } catch (error) {
      throw Exception('Failed to get club workout details: $error');
    }
  }

  /// Retorna o head do treino ativo (NULL ou FALSE)
  Future<Map<String, dynamic>?> _getActiveClubWorkoutHead() async {
    // ... (Esta função permanece INALTERADA) ...
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) throw Exception('User must be authenticated');

    final rows = await _client
        .from('club_user_workouts')
        .select('id, is_completed, started_at')
        .eq('user_id', currentUser.id)
        .or('is_completed.is.null,is_completed.eq.false')
        .order('started_at', ascending: false)
        .limit(1);

    if (rows.isNotEmpty) {
      return Map<String, dynamic>.from(rows.first as Map);
    }
    return null;
  }

  /// Injeta `is_completed` em cada set com base em `completed_at`, caso não exista
  Map<String, dynamic>? _decorateClubSetsWithIsCompleted(Map<String, dynamic>? workout) {
    // ... (Esta função permanece INALTERADA) ...
    if (workout == null) return null;
    final sets = workout['club_workout_exercise_sets'];
    if (sets is List) {
      final newSets = sets.map<Map<String, dynamic>>((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        if (!m.containsKey('is_completed')) {
          m['is_completed'] = m['completed_at'] != null;
        }
        return m;
      }).toList();
      workout = {...workout, 'club_workout_exercise_sets': newSets};
    }
    return workout;
  }

  // ==========================================================
  // CRIAÇÃO DE TEMPLATE PERSONALIZADO (BLDR CLUB)
  // ==========================================================

  /// Garante que o exercício existe em public.exercises e retorna o UUID.
  Future<String?> _upsertExerciseToDb(ExDbExercise ex, String userId) async {
    // 1) busca por exercise_db_id
    try {
      final row = await _client
          .from('exercises')
          .select('id')
          .eq('exercise_db_id', ex.exerciseId)
          .maybeSingle();
      if (row != null) return row['id'] as String?;
    } catch (_) {}

    // 2) busca por nome
    try {
      final row = await _client
          .from('exercises')
          .select('id')
          .eq('name', ex.name)
          .maybeSingle();
      if (row != null) return row['id'] as String?;
    } catch (_) {}

    // 3) insere com exercise_db_id
    try {
      final row = await _client.from('exercises').insert({
        'name': ex.name,
        'exercise_type': ex.supabaseExerciseType,
        'primary_muscle_group': ex.supabasePrimaryMuscle,
        'secondary_muscle_groups': ex.supabaseSecondaryMuscles,
        'instructions': ex.instructions,
        'image_url': ex.displayUrl,
        'equipment_needed': ex.equipments,
        'is_system_exercise': false,
        'created_by': userId,
        'exercise_db_id': ex.exerciseId,
      }).select('id').single();
      return row['id'] as String?;
    } catch (_) {}

    // 4) fallback sem exercise_db_id (coluna pode não existir)
    try {
      final row = await _client.from('exercises').insert({
        'name': ex.name,
        'exercise_type': ex.supabaseExerciseType,
        'primary_muscle_group': ex.supabasePrimaryMuscle,
        'secondary_muscle_groups': ex.supabaseSecondaryMuscles,
        'instructions': ex.instructions,
        'image_url': ex.displayUrl,
        'equipment_needed': ex.equipments,
        'is_system_exercise': false,
        'created_by': userId,
      }).select('id').single();
      return row['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Cria um template personalizado em club_workout_templates.
  /// [exercises] = lista de {exercise_db_id, sets, reps, rest_seconds, weight_kg?}
  Future<void> createClubWorkoutTemplate({
    required String name,
    required String workoutType, // 'força' ou 'hiit'
    required int estimatedDurationMinutes,
    required int difficultyLevel,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) throw Exception('User must be authenticated');

    // 1) cria o template
    final template = await _client.from('club_workout_templates').insert({
      'name': name,
      'workout_type': workoutType,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'difficulty_level': difficultyLevel,
      'is_public': false,
      'created_by': currentUser.id,
    }).select().single();

    if (exercises.isEmpty) return;

    // 2) upserta cada exercício em public.exercises e cria os template_exercises
    final templateExercises = <Map<String, dynamic>>[];

    for (int i = 0; i < exercises.length; i++) {
      final ex = exercises[i];
      final exDbId = ex['exercise_db_id'] as String? ?? '';

      // Resolve ExDbExercise pelo cache/API
      final exDbExercise = exDbId.isNotEmpty
          ? await ExerciseDbRapidService.instance.getById(exDbId)
          : null;

      if (exDbExercise == null) continue;

      final exerciseId =
          await _upsertExerciseToDb(exDbExercise, currentUser.id);
      if (exerciseId == null) continue;

      final row = <String, dynamic>{
        'workout_template_id': template['id'],
        'exercise_id': exerciseId,
        'order_index': i + 1,
        'sets': ex['sets'],
        'reps': ex['reps'],
        'rest_seconds': ex['rest_seconds'],
      };
      if (ex['weight_kg'] != null) row['weight_kg'] = ex['weight_kg'];
      templateExercises.add(row);
    }

    if (templateExercises.isNotEmpty) {
      await _client
          .from('club_workout_template_exercises')
          .insert(templateExercises);
    }
  }

  /// Exclui um template pessoal do usuário logado.
  Future<void> deleteClubWorkoutTemplate(String templateId) async {
    try {
      await _client
          .from('club_workout_template_exercises')
          .delete()
          .eq('workout_template_id', templateId);
      await _client
          .from('club_workout_templates')
          .delete()
          .eq('id', templateId);
    } catch (e) {
      throw Exception('Failed to delete club workout template: $e');
    }
  }

  /// Atualiza um template pessoal existente (cabeçalho + exercícios).
  Future<void> updateClubWorkoutTemplate({
    required String templateId,
    required String name,
    required String workoutType,
    required int estimatedDurationMinutes,
    required int difficultyLevel,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) throw Exception('User must be authenticated');

    // 1) Atualiza cabeçalho
    await _client.from('club_workout_templates').update({
      'name': name,
      'workout_type': workoutType,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'difficulty_level': difficultyLevel,
    }).eq('id', templateId);

    if (exercises.isEmpty) return;

    // 2) Remove exercícios antigos
    await _client
        .from('club_workout_template_exercises')
        .delete()
        .eq('workout_template_id', templateId);

    // 3) Re-insere exercícios (mesma lógica do createClubWorkoutTemplate)
    final templateExercises = <Map<String, dynamic>>[];
    for (int i = 0; i < exercises.length; i++) {
      final ex = exercises[i];
      final exDbId = ex['exercise_db_id'] as String? ?? '';
      final exDbExercise = exDbId.isNotEmpty
          ? await ExerciseDbRapidService.instance.getById(exDbId)
          : null;
      if (exDbExercise == null) continue;
      final exerciseId = await _upsertExerciseToDb(exDbExercise, currentUser.id);
      if (exerciseId == null) continue;
      final row = <String, dynamic>{
        'workout_template_id': templateId,
        'exercise_id': exerciseId,
        'order_index': i + 1,
        'sets': ex['sets'],
        'reps': ex['reps'],
        'rest_seconds': ex['rest_seconds'],
      };
      if (ex['weight_kg'] != null) row['weight_kg'] = ex['weight_kg'];
      templateExercises.add(row);
    }
    if (templateExercises.isNotEmpty) {
      await _client
          .from('club_workout_template_exercises')
          .insert(templateExercises);
    }
  }

  /// Registra uma sessão de cardio em club_user_workouts.
  /// Reutiliza a tabela existente — sem necessidade de tabela extra.
  Future<void> logCardioActivity({
    required String label,
    required String activityType,
    required int durationSeconds,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) throw Exception('User must be authenticated');

    final now = DateTime.now().toUtc();
    final startedAt = now.subtract(Duration(seconds: durationSeconds));

    try {
      await _client.from('club_user_workouts').insert({
        'user_id': currentUser.id,
        'name': label,
        'notes': activityType, // tipo guardado em notes (corrida/hiit/yoga/pilates…)
        'started_at': startedAt.toIso8601String(),
        'completed_at': now.toIso8601String(),
        'total_duration_seconds': durationSeconds,
        'is_completed': true,
      });
    } catch (e) {
      throw Exception('Failed to log cardio activity: $e');
    }
  }

  /// Retorna os templates pessoais do usuário logado.
  Future<List<Map<String, dynamic>>> getMyClubWorkoutTemplates() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return [];

    try {
      final data = await _client
          .from('club_workout_templates')
          .select(
              'id, name, workout_type, estimated_duration_minutes, difficulty_level, is_public')
          .eq('created_by', currentUser.id)
          .eq('is_public', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Retorna até [limit] treinos pausados (is_completed=false) do BLDR Club,
  /// enriquecidos com nome do exercício atual e progresso de exercícios.
  /// Shape compatível com ContinueWorkoutCard (source: 'club').
  Future<List<Map<String, dynamic>>> getPausedClubWorkoutSummaries({
    int limit = 2,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return [];

    try {
      final rows = await _client
          .from('club_user_workouts')
          .select('id, name, started_at')
          .eq('user_id', currentUser.id)
          .eq('is_completed', false)
          .order('started_at', ascending: false)
          .limit(limit);

      final candidates = (rows as List)
          .map((r) => {...(r as Map<String, dynamic>), 'source': 'club'})
          .toList();

      if (candidates.isEmpty) return [];

      final enriched = await Future.wait(
          candidates.map(_enrichPausedClubWorkout));
      return enriched;
    } catch (e) {
      debugPrint('[ClubWorkoutsService] getPausedClubWorkoutSummaries: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _enrichPausedClubWorkout(
      Map<String, dynamic> head) async {
    final id = head['id'] as String;
    try {
      final rawSets = await _client
          .from('club_workout_exercise_sets')
          .select('order_index, completed_at, exercises(name)')
          .eq('user_workout_id', id)
          .order('order_index', ascending: true)
          .order('set_number', ascending: true);

      final sets = List<Map<String, dynamic>>.from(rawSets);

      // Group by order_index
      final byOrder = <int, List<Map<String, dynamic>>>{};
      for (final s in sets) {
        final idx = (s['order_index'] as int?) ?? 0;
        byOrder.putIfAbsent(idx, () => []).add(s);
      }

      final totalExercises = byOrder.length;
      int completedExercises = 0;
      String currentExerciseName = '';

      for (final exSets in byOrder.values) {
        final allDone = exSets.every((s) => s['completed_at'] != null);
        if (allDone) {
          completedExercises++;
        } else if (currentExerciseName.isEmpty) {
          final ex = exSets.first['exercises'] as Map?;
          currentExerciseName = (ex?['name'] as String?) ?? '';
        }
      }

      return {
        ...head,
        'total_exercises': totalExercises,
        'completed_exercises': completedExercises,
        'current_exercise_name': currentExerciseName,
      };
    } catch (_) {
      return {
        ...head,
        'total_exercises': 0,
        'completed_exercises': 0,
        'current_exercise_name': '',
      };
    }
  }

  /// Exclui um treino pausado do BLDR Club (sets + registro principal).
  /// Usado pelo swipe-to-delete no card "Continuar Treino".
  Future<void> deletePausedClubWorkout(String workoutId) async {
    try {
      await _client
          .from('club_workout_exercise_sets')
          .delete()
          .eq('user_workout_id', workoutId);
      await _client
          .from('club_user_workouts')
          .delete()
          .eq('id', workoutId);
    } catch (e) {
      throw Exception('Failed to delete paused club workout: $e');
    }
  }

  /// Exclui uma atividade GPS (corrida) registrada em bldr_club.user_activities.
  /// Usado pelo seletor de exclusão no day sheet da semana atual.
  Future<void> deleteActivityRecord(String activityId) async {
    try {
      await _client
          .schema('bldr_club')
          .from('user_activities')
          .delete()
          .eq('id', activityId);
    } catch (e) {
      throw Exception('Failed to delete activity record: $e');
    }
  }

  /// Exclui um registro de treino concluído do BLDR Club (sets + registro principal).
  /// Usado pelo botão "Excluir registro" no day sheet da semana atual.
  Future<void> deleteClubWorkoutRecord(String workoutId) async {
    try {
      await _client
          .from('club_workout_exercise_sets')
          .delete()
          .eq('user_workout_id', workoutId);
      await _client
          .from('club_user_workouts')
          .delete()
          .eq('id', workoutId);
    } catch (e) {
      throw Exception('Failed to delete club workout record: $e');
    }
  }

  /// Retorna true se o usuário logado participa de pelo menos um desafio
  /// coletivo ativo (status = 'active'). Usado para validar tempo mínimo.
  Future<bool> isUserInActiveChallenge() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return false;

    try {
      // Busca desafios ativos nos quais o usuário é participante
      final participants = await _client
          .schema('bldr_club')
          .from('collective_challenge_participants')
          .select('challenge_id')
          .eq('user_id', currentUser.id) as List<dynamic>;

      if (participants.isEmpty) return false;

      final challengeIds = participants
          .map((p) => p['challenge_id'].toString())
          .toList();

      final orCond =
          challengeIds.map((id) => 'id.eq.$id').join(',');

      final active = await _client
          .schema('bldr_club')
          .from('collective_challenges')
          .select('id')
          .or(orCond)
          .eq('status', 'active') as List<dynamic>;

      return active.isNotEmpty;
    } catch (_) {
      return false; // em caso de erro, não bloqueia o usuário
    }
  }

  /// Stream do treino ativo com detalhes; fecha quando o treino é concluído
  Stream<Map<String, dynamic>?> activeClubWorkoutStream() {
    // ... (Esta função permanece INALTERADA, pois ela usa a 'getClubWorkoutDetails' que já corrigimos) ...
    final controller = StreamController<Map<String, dynamic>?>.broadcast();

    RealtimeChannel? setsChannel;
    RealtimeChannel? workoutsChannel;
    String? currentWorkoutId;

    Future<void> _emitById(String workoutId) async {
      final details = await getClubWorkoutDetails(workoutId);
      final decorated = _decorateClubSetsWithIsCompleted(details);
      controller.add(decorated);
    }

    Future<void> _wireForActiveWorkout() async {
      final head = await _getActiveClubWorkoutHead();
      if (head == null) {
        currentWorkoutId = null;
        controller.add(null);
        setsChannel?.unsubscribe();
        setsChannel = null;
        return;
      }

      final workoutId = head['id'] as String;
      currentWorkoutId = workoutId;

      // Emite agora
      await _emitById(workoutId);

      // (re)assina canal de sets
      if (setsChannel != null) {
        setsChannel!.unsubscribe();
        setsChannel = null;
      }
      setsChannel = _client
          .channel('club_sets_${workoutId}_${DateTime.now().millisecondsSinceEpoch}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_workout_exercise_sets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_workout_id',
            value: workoutId,
          ),
          callback: (payload) async {
            await _emitById(workoutId);
          },
        )
        ..subscribe();
    }

    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      Future.microtask(() => controller.addError('User must be authenticated'));
      return controller.stream;
    }

    // Observa mudanças nos treinos do usuário
    workoutsChannel = _client
        .channel('club_uw_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'club_user_workouts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUser.id,
        ),
        callback: (payload) async {
          final newRec = payload.newRecord;

          // Se a mudança refere-se ao treino atual e ele foi concluído, zera imediatamente
          if (currentWorkoutId != null &&
              (newRec['id']?.toString() == currentWorkoutId) &&
              (newRec['is_completed'] == true)) {
            currentWorkoutId = null;
            controller.add(null); // banner deve sumir imediatamente
            setsChannel?.unsubscribe();
            setsChannel = null;
            return;
          }

          // Senão, recalcule qual é o ativo e (re)assine os sets
          await _wireForActiveWorkout();
        },
      )
      ..subscribe();

    // Emissão inicial
    _wireForActiveWorkout();

    controller.onCancel = () {
      setsChannel?.unsubscribe();
      workoutsChannel?.unsubscribe();
    };

    return controller.stream;
  }
}