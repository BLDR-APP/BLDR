import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';
import 'package:bldr_fitness/services/supabase_service.dart';

class WorkoutService {
  static WorkoutService? _instance;
  static WorkoutService get instance => _instance ??= WorkoutService._();

  WorkoutService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Get workout templates
  Future<List<Map<String, dynamic>>> getWorkoutTemplates({
    String? workoutType,
    int? difficultyLevel,
    bool publicOnly = false,
  }) async {
    try {
      var query = _client.from('workout_templates').select('''
        id, name, description, workout_type, estimated_duration_minutes,
        difficulty_level, is_public, created_at,
        user_profiles!created_by(full_name)
      ''');

      if (publicOnly) query = query.eq('is_public', true);
      if (workoutType != null) query = query.eq('workout_type', workoutType);
      if (difficultyLevel != null) query = query.eq('difficulty_level', difficultyLevel);

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get workout templates: $error');
    }
  }

  /// Get workout template with exercises
  Future<Map<String, dynamic>?> getWorkoutTemplateWithExercises(String templateId) async {
    try {
      final response = await _client.from('workout_templates').select('''
        id, name, description, workout_type, estimated_duration_minutes,
        difficulty_level, is_public, created_at,
        workout_template_exercises(
          id, order_index, sets, reps, duration_seconds, rest_seconds,
          weight_kg, distance_meters, notes,
          exercise_db_id,
          exercises(
            id, name, description, exercise_type, primary_muscle_group,
            secondary_muscle_groups, instructions, tips, image_url,
            equipment_needed,
            exercise_db_id
          )
        )
      ''').eq('id', templateId).single();

      // Enrich ExerciseDB exercises: resolve name from cache when the
      // `exercises` join is null (i.e. the exercise came from ExerciseDB,
      // not the BLDR internal library).
      final rawExercises =
          (response['workout_template_exercises'] as List?)?.cast<Map>() ?? [];

      if (rawExercises.isNotEmpty) {
        final enriched = await Future.wait(rawExercises.map((row) async {
          final mutable = Map<String, dynamic>.from(row);
          if (mutable['exercises'] == null &&
              mutable['exercise_db_id'] != null) {
            final dbId = mutable['exercise_db_id'] as String;
            final dbEx =
                await ExerciseDbRapidService.instance.getById(dbId);
            if (dbEx != null) {
              mutable['exercises'] = {
                'id': null,
                'name': dbEx.name,
                'exercise_type': dbEx.bodyParts,
                'primary_muscle_group': dbEx.targetMuscles,
                'exercise_db_id': dbId,
              };
            }
          }
          return mutable;
        }));

        return {
          ...response,
          'workout_template_exercises': enriched,
        };
      }

      return response;
    } catch (error) {
      throw Exception('Failed to get workout template: $error');
    }
  }

  /// Create workout template
  Future<Map<String, dynamic>> createWorkoutTemplate({
    required String name,
    String? description,
    required String workoutType,
    int? estimatedDurationMinutes,
    int? difficultyLevel,
    bool isPublic = false,
    String source = 'user',
    List<Map<String, dynamic>>? exercises,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('workout_templates')
          .insert({
        'name': name,
        'description': description,
        'workout_type': workoutType,
        'estimated_duration_minutes': estimatedDurationMinutes,
        'difficulty_level': difficultyLevel,
        'is_public': isPublic,
        'source': source,
        'created_by': currentUser.id,
      })
          .select()
          .single();

      if (exercises != null && exercises.isNotEmpty) {
        final templateExercises = exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          final row = <String, dynamic>{
            'workout_template_id': response['id'],
            'order_index': index + 1,
            'sets': exercise['sets'],
            'reps': exercise['reps'],
            'duration_seconds': exercise['duration_seconds'],
            'rest_seconds': exercise['rest_seconds'],
            'weight_kg': exercise['weight_kg'],
            'distance_meters': exercise['distance_meters'],
            'notes': exercise['notes'],
          };
          // ExerciseDB exercises use exercise_db_id; BLDR library exercises use exercise_id
          if (exercise['exercise_db_id'] != null) {
            row['exercise_db_id'] = exercise['exercise_db_id'];
          } else if (exercise['exercise_id'] != null) {
            row['exercise_id'] = exercise['exercise_id'];
          } else if (exercise['free_name'] != null) {
            // Exercício gerado pelo HAVOK, sem match na biblioteca (B5).
            row['free_name'] = exercise['free_name'];
          }
          return row;
        }).toList();

        await _client.from('workout_template_exercises').insert(templateExercises);
      }

      return response;
    } catch (error) {
      throw Exception('Failed to create workout template: $error');
    }
  }

  /// Update an existing workout template (replaces exercises entirely).
  Future<Map<String, dynamic>> updateWorkoutTemplate({
    required String id,
    required String name,
    String? description,
    required String workoutType,
    int? estimatedDurationMinutes,
    int? difficultyLevel,
    List<Map<String, dynamic>>? exercises,
  }) async {
    try {
      final response = await _client
          .from('workout_templates')
          .update({
            'name': name,
            'description': description,
            'workout_type': workoutType,
            'estimated_duration_minutes': estimatedDurationMinutes,
            'difficulty_level': difficultyLevel,
          })
          .eq('id', id)
          .select()
          .single();

      // Replace exercises: delete old, insert new
      await _client
          .from('workout_template_exercises')
          .delete()
          .eq('workout_template_id', id);

      if (exercises != null && exercises.isNotEmpty) {
        final templateExercises = exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          final row = <String, dynamic>{
            'workout_template_id': id,
            'order_index': index + 1,
            'sets': exercise['sets'],
            'reps': exercise['reps'],
            'duration_seconds': exercise['duration_seconds'],
            'rest_seconds': exercise['rest_seconds'],
            'weight_kg': exercise['weight_kg'],
            'distance_meters': exercise['distance_meters'],
            'notes': exercise['notes'],
          };
          if (exercise['exercise_db_id'] != null) {
            row['exercise_db_id'] = exercise['exercise_db_id'];
          } else if (exercise['exercise_id'] != null) {
            row['exercise_id'] = exercise['exercise_id'];
          } else if (exercise['free_name'] != null) {
            row['free_name'] = exercise['free_name'];
          }
          return row;
        }).toList();

        await _client
            .from('workout_template_exercises')
            .insert(templateExercises);
      }

      return response;
    } catch (error) {
      throw Exception('Failed to update workout template: $error');
    }
  }

  /// Delete a workout template and all its exercises.
  Future<void> deleteWorkoutTemplate(String id) async {
    try {
      await _client
          .from('workout_template_exercises')
          .delete()
          .eq('workout_template_id', id);
      await _client
          .from('workout_templates')
          .delete()
          .eq('id', id);
    } catch (error) {
      throw Exception('Failed to delete workout template: $error');
    }
  }

  /// Delete a paused (not completed) workout and all its sets.
  /// [source] must be 'free' or 'club'.
  Future<void> deletePausedWorkout(String id, String source) async {
    try {
      if (source == 'free') {
        await _client
            .from('workout_exercise_sets')
            .delete()
            .eq('user_workout_id', id);
        await _client.from('user_workouts').delete().eq('id', id);
      } else {
        await _client
            .from('club_workout_exercise_sets')
            .delete()
            .eq('user_workout_id', id);
        await _client.from('club_user_workouts').delete().eq('id', id);
      }
    } catch (error) {
      throw Exception('Failed to delete paused workout: $error');
    }
  }

  /// Delete a completed workout record and all its sets (free mode only).
  Future<void> deleteCompletedWorkout(String id) async {
    try {
      await _client
          .from('workout_exercise_sets')
          .delete()
          .eq('user_workout_id', id);
      final deleted = await _client
          .from('user_workouts')
          .delete()
          .eq('id', id)
          .select('id');
      if (deleted.isEmpty) {
        throw Exception(
            'Registro não encontrado ou sem permissão para excluir.');
      }
    } catch (error) {
      throw Exception('Failed to delete completed workout: $error');
    }
  }

  /// Start a workout (robusto a schemas sem is_completed)
  Future<Map<String, dynamic>> startWorkout({
    required String name,
    String? workoutTemplateId,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) throw Exception('User must be authenticated');

      debugPrint('[HAVOK] startWorkout → workoutTemplateId: $workoutTemplateId');
      // 1) cria o workout (UTC evita deslocamento de fuso)
      final baseInsert = {
        'user_id': currentUser.id,
        'workout_template_id': workoutTemplateId,
        'name': name,
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'is_completed': false, // pode não existir; tratamos abaixo
      };

      Map<String, dynamic> workout;
      try {
        workout = await _client.from('user_workouts').insert(baseInsert).select().single();
      } on PostgrestException catch (e) {
        if ((e.message ?? '').toLowerCase().contains('is_completed')) {
          final withoutFlag = Map<String, dynamic>.from(baseInsert)..remove('is_completed');
          workout = await _client.from('user_workouts').insert(withoutFlag).select().single();
        } else {
          rethrow;
        }
      }

      // 2) clona sets do template
      if (workoutTemplateId != null) {
        final tpl = await _client
            .from('workout_template_exercises')
            .select('''
              order_index, sets, reps, duration_seconds, rest_seconds,
              weight_kg, distance_meters, notes, exercise_id, exercise_db_id,
              free_name
            ''')
            .eq('workout_template_id', workoutTemplateId)
            .order('order_index', ascending: true);

        final setsToInsert = <Map<String, dynamic>>[];
        for (final row in tpl) {
          final totalSets = (row['sets'] as int?) ?? 1;
          for (int s = 1; s <= totalSets; s++) {
            final setRow = <String, dynamic>{
              'user_workout_id': workout['id'],
              'set_number': s,
              'order_index': row['order_index'],
              'reps': row['reps'],
              'weight_kg': row['weight_kg'],
              'duration_seconds': row['duration_seconds'],
              'distance_meters': row['distance_meters'],
              'rest_seconds': row['rest_seconds'],
              'notes': row['notes'],
              'completed_at': null,
              'is_completed': false,
            };
            if (row['exercise_id'] != null) {
              setRow['exercise_id'] = row['exercise_id'];
            }
            if (row['exercise_db_id'] != null) {
              setRow['exercise_db_id'] = row['exercise_db_id'];
            }
            if (row['exercise_id'] == null &&
                row['exercise_db_id'] == null &&
                row['free_name'] != null) {
              setRow['free_name'] = row['free_name'];
            }
            setsToInsert.add(setRow);
          }
        }

        if (setsToInsert.isNotEmpty) {
          try {
            await _client.from('workout_exercise_sets').insert(setsToInsert);
          } on PostgrestException catch (e) {
            if ((e.message ?? '').toLowerCase().contains('is_completed')) {
              final fallback = setsToInsert
                  .map((m) => Map<String, dynamic>.from(m)..remove('is_completed'))
                  .toList();
              await _client.from('workout_exercise_sets').insert(fallback);
            } else {
              rethrow;
            }
          }
        }
      }

      return Map<String, dynamic>.from(workout);
    } catch (error) {
      throw Exception('Failed to start workout: $error');
    }
  }

  /// Garante que os sets iniciais existam para uma sessão já criada.
  ///
  /// Chamado como segurança após [startWorkout] — caso o INSERT dos sets tenha
  /// falhado silenciosamente (ex: RLS retorna 204 sem lançar exceção), este
  /// método detecta a ausência e tenta criar os sets novamente.
  /// Não duplica sets: verifica antes de inserir.
  Future<void> ensureInitialSets(String sessionId, String templateId) async {
    try {
      // 1. Verificar se já existem sets para esta sessão
      final existing = await _client
          .from('workout_exercise_sets')
          .select('id')
          .eq('user_workout_id', sessionId)
          .limit(1);
      if ((existing as List).isNotEmpty) return;

      // 2. Buscar exercícios do template
      final tpl = await _client
          .from('workout_template_exercises')
          .select('''
            order_index, sets, reps, duration_seconds, rest_seconds,
            weight_kg, distance_meters, notes, exercise_id, exercise_db_id,
            free_name
          ''')
          .eq('workout_template_id', templateId)
          .order('order_index', ascending: true);

      if ((tpl as List).isEmpty) return;

      // 3. Montar e inserir sets (mesma lógica do startWorkout)
      final setsToInsert = <Map<String, dynamic>>[];
      for (final row in tpl) {
        final totalSets = (row['sets'] as int?) ?? 1;
        for (int s = 1; s <= totalSets; s++) {
          final setRow = <String, dynamic>{
            'user_workout_id': sessionId,
            'set_number': s,
            'order_index': row['order_index'],
            'reps': row['reps'],
            'weight_kg': row['weight_kg'],
            'duration_seconds': row['duration_seconds'],
            'distance_meters': row['distance_meters'],
            'rest_seconds': row['rest_seconds'],
            'notes': row['notes'],
            'completed_at': null,
          };
          if (row['exercise_id'] != null) setRow['exercise_id'] = row['exercise_id'];
          if (row['exercise_db_id'] != null) setRow['exercise_db_id'] = row['exercise_db_id'];
          if (row['exercise_id'] == null &&
              row['exercise_db_id'] == null &&
              row['free_name'] != null) {
            setRow['free_name'] = row['free_name'];
          }
          setsToInsert.add(setRow);
        }
      }

      if (setsToInsert.isNotEmpty) {
        debugPrint('[HAVOK] ensureInitialSets → inserting ${setsToInsert.length} sets for session $sessionId, template $templateId');
        await _client.from('workout_exercise_sets').insert(setsToInsert);
        debugPrint('[HAVOK] ensureInitialSets → insert done (sem erro lançado)');
      }
    } catch (e) {
      debugPrint('[HAVOK] ensureInitialSets → EXCEPTION: $e');
    }
  }

  /// Complete a workout
  Future<Map<String, dynamic>> completeWorkoutWithAnalytics({
    required String workoutId,
    required String source,
    String? notes,
  }) async {
    try {
      final result = await _client.rpc(
        'complete_workout_with_analytics',
        params: {
          'p_workout_id': workoutId,
          'p_source': source,
          if (notes != null) 'p_notes': notes,
        },
      );
      return (result as Map<String, dynamic>?) ?? {};
    } catch (error) {
      throw Exception('Failed to complete workout with analytics: $error');
    }
  }

  Future<Map<String, dynamic>> completeWorkout({
    required String workoutId,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();

      final workoutResponse = await _client
          .from('user_workouts')
          .select('started_at')
          .eq('id', workoutId)
          .single();

      final startedAt = DateTime.parse(workoutResponse['started_at'].toString());
      final rawDuration = now.difference(startedAt).inSeconds;
      final duration = rawDuration < 60 ? 60 : rawDuration;

      final response = await _client
          .from('user_workouts')
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
      throw Exception('Failed to complete workout: $error');
    }
  }

  /// Log exercise set
  Future<Map<String, dynamic>> logExerciseSet({
    required String userWorkoutId,
    String? exerciseId,
    required int setNumber,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
    int? restSeconds,
    String? notes,
  }) async {
    try {
      final response = await _client
          .from('workout_exercise_sets')
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
      throw Exception('Failed to log exercise set: $error');
    }
  }

  /// Get user workouts
  Future<List<Map<String, dynamic>>> getUserWorkouts({
    String? userId,
    bool completedOnly = false,
    int limit = 20,
  }) async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated');
      }

      final targetUserId = userId ?? currentUser.id;

      var query = _client.from('user_workouts').select('''
        id, name, started_at, completed_at, total_duration_seconds,
        notes, is_completed,
        workout_templates(name, workout_type, estimated_duration_minutes)
      ''').eq('user_id', targetUserId);

      if (completedOnly) query = query.eq('is_completed', true);

      final response = await query.order('started_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get user workouts: $error');
    }
  }

  /// Get workout details with exercise sets (ordenado, join robusto)
  Future<Map<String, dynamic>?> getWorkoutDetails(String workoutId) async {
    try {
      // Tenta com FK nomeada
      final response = await _client
          .from('user_workouts')
          .select('''
            id, name, started_at, completed_at, total_duration_seconds,
            notes, is_completed,
            workout_templates(name, workout_type, estimated_duration_minutes),
            workout_exercise_sets(
              id, set_number, reps, weight_kg, duration_seconds,
              distance_meters, rest_seconds, completed_at, notes,
              order_index, exercise_db_id, free_name,
              exercises!workout_exercise_sets_exercise_id_fkey (
                id, name, primary_muscle_group,
                exercise_db_id, instructions
              )
            )
          ''')
          .eq('id', workoutId)
          .order('order_index', referencedTable: 'workout_exercise_sets', ascending: true)
          .order('set_number', referencedTable: 'workout_exercise_sets', ascending: true)
          .single();

      return response;
    } catch (error) {
      // Fallback para join padrão
      try {
        final response = await _client
            .from('user_workouts')
            .select('''
              id, name, started_at, completed_at, total_duration_seconds,
              notes, is_completed,
              workout_templates(name, workout_type, estimated_duration_minutes),
              workout_exercise_sets(
                id, set_number, reps, weight_kg, duration_seconds,
                distance_meters, rest_seconds, completed_at, notes,
                order_index, exercise_db_id, free_name,
                exercises(
                  id, name, primary_muscle_group,
                  exercise_db_id, instructions
                )
              )
            ''')
            .eq('id', workoutId)
            .order('order_index', referencedTable: 'workout_exercise_sets', ascending: true)
            .order('set_number', referencedTable: 'workout_exercise_sets', ascending: true)
            .single();

        return response;
      } catch (e) {
        throw Exception('Failed to get workout details: $error');
      }
    }
  }

  // =============== Suporte ao banner em tempo real ===============

  //
  // =========================================================================
  // ============= ESTA É A FUNÇÃO QUE FOI CORRIGIDA =============
  // =========================================================================
  //
  /// Marca uma série como concluída
  Future<void> completeSet({
    required String setId,
    double? weight, // Recebe o peso da UI
    int? reps,      // Recebe as reps da UI
  }) async {
    try {
      // 1. Cria o mapa de atualização básico
      final Map<String, dynamic> updates = {
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      };

      // 2. Só adiciona carga e reps se eles não forem nulos (para não apagar dados existentes sem querer)
      if (weight != null) {
        updates['weight_kg'] = weight; // Atenção: nome da coluna no banco deve ser 'weight_kg'
      }
      if (reps != null) {
        updates['reps'] = reps;
      }

      // 3. Envia o mapa completo
      await _client
          .from('workout_exercise_sets')
          .update(updates)
          .eq('id', setId);

    } catch (e) {
      throw Exception('Failed to complete set: $e');
    }
  }
  // =========================================================================

  //
  // =========================================================================
  // ============= ESTA É A FUNÇÃO QUE FOI CORRIGIDA =============
  // =========================================================================
  //
  /// Desfaz a conclusão de uma série
  Future<void> undoSet({required String setId}) async {
    try {
      await _client
          .from('workout_exercise_sets')
          .update({
        'completed_at': null,
        // 'is_completed': false, // REMOVIDO - A coluna não existe no seu schema
      })
          .eq('id', setId);
    } catch (e) {
      throw Exception('Failed to undo set: $e');
    }
  }
  // =========================================================================


  /// (Opcional) Desfaz por workout + número da série
  Future<void> undoSetByWorkoutAndNumber({
    required String userWorkoutId,
    required int setNumber,
  }) async {
    try {
      await _client
          .from('workout_exercise_sets')
          .update({
        'completed_at': null,
        // 'is_completed': false, // REMOVIDO
      })
          .eq('user_workout_id', userWorkoutId)
          .eq('set_number', setNumber);
    } catch (e) {
      throw Exception('Failed to undo set by workout/set number: $e');
    }
  }

  /// Retorna o "head" (id) do treino ativo (não concluído)
  Future<Map<String, dynamic>?> _getActiveWorkoutHead() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) throw Exception('User must be authenticated');

    final rows = await _client
        .from('user_workouts')
        .select('id, is_completed')
        .eq('user_id', currentUser.id)
        .eq('is_completed', false)
        .order('started_at', ascending: false)
        .limit(1);

    if (rows.isNotEmpty) {
      return Map<String, dynamic>.from(rows.first as Map);
    }
    return null;
  }

  /// Checa (true/false) se existe um treino ativo não concluído.
  Future<bool> hasActiveWorkout() async {
    try {
      // Reutiliza a lógica que você já tem
      final head = await _getActiveWorkoutHead();

      // Se 'head' não for nulo, significa que há um treino ativo
      return head != null;
    } catch (e) {
      // Em caso de erro (ex: usuário deslogado), assume que não há treino.
      print('Erro ao checar hasActiveWorkout: $e');
      return false;
    }
  }

  /// Injeta `is_completed` em cada set com base em `completed_at`, caso não exista
  Map<String, dynamic>? _decorateSetsWithIsCompleted(Map<String, dynamic>? workout) {
    if (workout == null) return null;
    final sets = workout['workout_exercise_sets'];
    if (sets is List) {
      final newSets = sets.map<Map<String, dynamic>>((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        if (!m.containsKey('is_completed')) {
          // ESTA É A LÓGICA QUE SEU APP USA:
          m['is_completed'] = m['completed_at'] != null;
        }
        return m;
      }).toList();
      workout = {...workout, 'workout_exercise_sets': newSets};
    }
    return workout;
  }

  /// Stream do treino ativo com detalhes; fecha imediatamente quando o treino atual é concluído
  Stream<Map<String, dynamic>?> activeWorkoutStream() {
    final controller = StreamController<Map<String, dynamic>?>.broadcast();

    RealtimeChannel? setsChannel;
    RealtimeChannel? workoutsChannel;
    String? currentWorkoutId;

    Future<void> _emitById(String workoutId) async {
      final details = await getWorkoutDetails(workoutId);
      final decorated = _decorateSetsWithIsCompleted(details);
      controller.add(decorated);
    }

    Future<void> _wireForActiveWorkout() async {
      final head = await _getActiveWorkoutHead();
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
          .channel('sets_${workoutId}_${DateTime.now().millisecondsSinceEpoch}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'workout_exercise_sets',
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
        .channel('uw_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'user_workouts',
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

  /// (Opcional) Apenas pega o ativo com detalhes uma vez
  Future<Map<String, dynamic>?> getActiveWorkoutWithDetailsOnce() async {
    final head = await _getActiveWorkoutHead();
    if (head == null) return null;
    final details = await getWorkoutDetails(head['id'] as String);
    return _decorateSetsWithIsCompleted(details);
  }

  // ── Paused workout summaries ───────────────────────────────────────────────

  /// Returns up to [limit] paused (is_completed=false) workouts across both
  /// free mode (user_workouts) and BLDR Club (club_user_workouts), merged and
  /// sorted by started_at descending.
  ///
  /// Each map contains:
  ///   id, name, started_at, source ('free' | 'club'),
  ///   current_exercise_name, completed_exercises, total_exercises
  Future<List<Map<String, dynamic>>> getPausedWorkoutSummaries({
    int limit = 2,
  }) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return [];

    try {
      // Fetch candidates from both tables in parallel
      final results = await Future.wait([
        _client
            .from('user_workouts')
            .select('id, name, started_at')
            .eq('user_id', currentUser.id)
            .eq('is_completed', false)
            .order('started_at', ascending: false)
            .limit(limit),
        _client
            .from('club_user_workouts')
            .select('id, name, started_at')
            .eq('user_id', currentUser.id)
            .eq('is_completed', false)
            .order('started_at', ascending: false)
            .limit(limit),
      ]);

      final free  = (results[0] as List).map((r) => {...(r as Map<String, dynamic>), 'source': 'free'}).toList();
      final club  = (results[1] as List).map((r) => {...(r as Map<String, dynamic>), 'source': 'club'}).toList();

      // Merge, dedup by id, sort desc, take top [limit]
      final merged = [...free, ...club]
        ..sort((a, b) {
          final aT = DateTime.tryParse(a['started_at'] as String? ?? '') ?? DateTime(0);
          final bT = DateTime.tryParse(b['started_at'] as String? ?? '') ?? DateTime(0);
          return bT.compareTo(aT);
        });

      final seen = <String>{};
      final deduped =
          merged.where((w) => seen.add(w['id'] as String)).toList();
      final candidates = deduped.take(limit).toList();
      if (candidates.isEmpty) return [];

      // Enrich each with exercise progress
      final enriched = await Future.wait(candidates.map(_enrichPausedWorkout));
      return enriched;
    } catch (e) {
      debugPrint('[WorkoutService] getPausedWorkoutSummaries error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _enrichPausedWorkout(
      Map<String, dynamic> head) async {
    final id     = head['id'] as String;
    final source = head['source'] as String;

    try {
      List<Map<String, dynamic>> sets = [];

      if (source == 'free') {
        final rows = await _client
            .from('workout_exercise_sets')
            .select('order_index, completed_at, exercises(name), exercise_db_id')
            .eq('user_workout_id', id)
            .order('order_index', ascending: true)
            .order('set_number', ascending: true);
        sets = List<Map<String, dynamic>>.from(rows);
      } else {
        final rows = await _client
            .from('club_workout_exercise_sets')
            .select('order_index, completed_at, exercises(name)')
            .eq('user_workout_id', id)
            .order('order_index', ascending: true)
            .order('set_number', ascending: true);
        sets = List<Map<String, dynamic>>.from(rows);
      }

      // Group by order_index
      final byOrder = <int, List<Map<String, dynamic>>>{};
      for (final s in sets) {
        final idx = (s['order_index'] as int?) ?? 0;
        byOrder.putIfAbsent(idx, () => []).add(s);
      }

      final totalExercises = byOrder.length;
      int completedExercises = 0;
      String currentExerciseName = '';

      for (final entry in byOrder.entries) {
        final exSets = entry.value;
        final allDone = exSets.every((s) => s['completed_at'] != null);
        if (allDone) {
          completedExercises++;
        } else if (currentExerciseName.isEmpty) {
          // First incomplete exercise = where they left off
          final ex = exSets.first['exercises'] as Map?;
          currentExerciseName = ex?['name'] as String? ?? '';

          // Fallback: look up in ExerciseDB cache if name is empty
          if (currentExerciseName.isEmpty && source == 'free') {
            final dbId = exSets.first['exercise_db_id'] as String?;
            if (dbId != null && dbId.isNotEmpty) {
              final cached = ExerciseDbRapidService.instance
                  .musclesFromCache([dbId]); // just to check cache
              // Try a direct cache lookup by id
              currentExerciseName = dbId; // fallback to id if name unavailable
            }
          }
        }
      }

      return {
        ...head,
        'total_exercises':     totalExercises,
        'completed_exercises': completedExercises,
        'current_exercise_name': currentExerciseName,
      };
    } catch (e) {
      debugPrint('[WorkoutService] _enrichPausedWorkout error: $e');
      return {
        ...head,
        'total_exercises':     0,
        'completed_exercises': 0,
        'current_exercise_name': '',
      };
    }
  }
}