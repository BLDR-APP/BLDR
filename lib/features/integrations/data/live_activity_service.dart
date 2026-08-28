import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';

const _kGroupId = 'group.com.bldr.fitness';
const _kActivityId = 'bldr_workout_activity';

class LiveActivityService {
  LiveActivityService._();

  static final _plugin = LiveActivities();
  static bool _active = false;
  static bool _initialized = false;
  // ID real retornado pelo ActivityKit (UUID), diferente do _kActivityId que é só um alias nosso
  static String? _activityKitId;

  static Future<void> init() async {
    if (!Platform.isIOS) return;
    if (_initialized) return;
    await _plugin.init(appGroupId: _kGroupId);
    _initialized = true;
  }

  static Future<void> startWorkout({
    required String workoutName,
    required String exerciseName,
    required int exerciseSet,
    required int exerciseTotalSets,
    required int exerciseIndex,
    required int exerciseTotalExercises,
    required double weightKg,
    required int reps,
    required double workoutStartTimestamp,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await init();
      _activityKitId = await _plugin.createActivity(
        _kActivityId,
        _buildData(
          workoutName: workoutName,
          exerciseName: exerciseName,
          exerciseSet: exerciseSet,
          exerciseTotalSets: exerciseTotalSets,
          exerciseIndex: exerciseIndex,
          exerciseTotalExercises: exerciseTotalExercises,
          isResting: false,
          restEndTimestamp: 0,
          restTotalSeconds: 0,
          weightKg: weightKg,
          reps: reps,
          workoutStartTimestamp: workoutStartTimestamp,
        ),
      );
      _active = true;
    } catch (e) {
      debugPrint('LiveActivityService.startWorkout error: $e');
    }
  }

  static Future<void> update({
    required String workoutName,
    required String exerciseName,
    required int exerciseSet,
    required int exerciseTotalSets,
    required int exerciseIndex,
    required int exerciseTotalExercises,
    required bool isResting,
    required double restEndTimestamp,
    required int restTotalSeconds,
    required double weightKg,
    required int reps,
    required double workoutStartTimestamp,
  }) async {
    if (!Platform.isIOS || !_active) return;
    try {
      await _plugin.updateActivity(
        _kActivityId,
        _buildData(
          workoutName: workoutName,
          exerciseName: exerciseName,
          exerciseSet: exerciseSet,
          exerciseTotalSets: exerciseTotalSets,
          exerciseIndex: exerciseIndex,
          exerciseTotalExercises: exerciseTotalExercises,
          isResting: isResting,
          restEndTimestamp: restEndTimestamp,
          restTotalSeconds: restTotalSeconds,
          weightKg: weightKg,
          reps: reps,
          workoutStartTimestamp: workoutStartTimestamp,
        ),
      );
    } catch (e) {
      debugPrint('LiveActivityService.update error: $e');
    }
  }

  static Future<void> end() async {
    if (!Platform.isIOS) return;
    try {
      // Usa o UUID real do ActivityKit para encerrar; fallback para endAllActivities
      if (_activityKitId != null) {
        await _plugin.endActivity(_activityKitId!);
      } else {
        await _plugin.endAllActivities();
      }
      _active = false;
      _activityKitId = null;
    } catch (e) {
      debugPrint('LiveActivityService.end error: $e');
    }
  }

  static bool get isActive => _active;

  // ── Deep link confirm-set event ───────────────────────────────────────────
  // Emitido pelo handler de deep link (bldr://workout/confirm) e escutado
  // pela tela de treino ativa (grátis ou Club), evitando dependência de rota
  // nomeada no popUntil.
  static final _confirmSetController = StreamController<void>.broadcast();
  static Stream<void> get onConfirmSet => _confirmSetController.stream;
  static void triggerConfirmSet() => _confirmSetController.add(null);

  static Map<String, dynamic> _buildData({
    required String workoutName,
    required String exerciseName,
    required int exerciseSet,
    required int exerciseTotalSets,
    required int exerciseIndex,
    required int exerciseTotalExercises,
    required bool isResting,
    required double restEndTimestamp,
    required int restTotalSeconds,
    required double weightKg,
    required int reps,
    required double workoutStartTimestamp,
  }) =>
      {
        'workoutName': workoutName,
        'exerciseName': exerciseName,
        'exerciseSet': exerciseSet,
        'exerciseTotalSets': exerciseTotalSets,
        'exerciseIndex': exerciseIndex,
        'exerciseTotalExercises': exerciseTotalExercises,
        'isResting': isResting,
        'restEndTimestamp': restEndTimestamp,
        'restTotalSeconds': restTotalSeconds,
        'weightKg': weightKg,
        'reps': reps,
        'workoutStartTimestamp': workoutStartTimestamp,
      };
}
