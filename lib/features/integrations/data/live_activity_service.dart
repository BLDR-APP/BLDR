import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:bldr_fitness/core/async_latest_wins_queue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:live_activities/live_activities.dart';

const _kGroupId = 'group.com.bldr.fitness';
const _kActivityId = 'bldr_workout_activity';

class LiveActivityService {
  LiveActivityService._();

  static final _plugin = LiveActivities();
  static const _appGroupChannel = MethodChannel('com.bldr.fitness/appgroup');
  static bool _active = false;
  static bool _initialized = false;
  // ID real retornado pelo ActivityKit (UUID), diferente do _kActivityId que é só um alias nosso
  static String? _activityKitId;
  static int _sequence = 0;
  static bool _ending = false;
  static Future<void>? _startOperation;
  static Future<void>? _endOperation;
  static String? _lastConsumedNativeActionId;
  static final _updates = AsyncLatestWinsQueue<_PendingLiveActivityUpdate>(
    handler: _performUpdate,
    onDropped: (update) => _log(
      'update_dropped',
      mode: update.mode,
      sequence: update.sequence,
      exerciseIndex: update.exerciseIndex,
      exerciseSet: update.exerciseSet,
      isResting: update.isResting,
    ),
  );

  static Future<void> init() async {
    if (!Platform.isIOS) return;
    if (_initialized) return;
    await _plugin.init(appGroupId: _kGroupId);
    _initialized = true;
  }

  static Future<void> startWorkout({
    String mode = 'unknown',
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
    final inFlight = _startOperation;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    final operation = _startWorkoutInternal(
      mode: mode,
      workoutName: workoutName,
      exerciseName: exerciseName,
      exerciseSet: exerciseSet,
      exerciseTotalSets: exerciseTotalSets,
      exerciseIndex: exerciseIndex,
      exerciseTotalExercises: exerciseTotalExercises,
      weightKg: weightKg,
      reps: reps,
      workoutStartTimestamp: workoutStartTimestamp,
    );
    _startOperation = operation;
    try {
      await operation;
    } finally {
      if (identical(_startOperation, operation)) _startOperation = null;
    }
  }

  static Future<void> _startWorkoutInternal({
    required String mode,
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
    final startedAt = DateTime.now();
    _log('start_requested',
        mode: mode,
        sequence: _sequence + 1,
        exerciseIndex: exerciseIndex,
        exerciseSet: exerciseSet,
        isResting: false);
    try {
      await init();
      final ending = _endOperation;
      if (ending != null) await ending;
      if (_active || _activityKitId != null) {
        await _requestEnd(reason: 'resync', mode: mode, waitForStart: false);
      }
      // Não crie uma segunda Activity se o encerramento anterior falhou.
      if (_activityKitId != null) {
        _log('start_blocked_pending_end', mode: mode);
        return;
      }
      _ending = false;
      _sequence = 0;
      _updates.reopen();
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
      _log('start_completed',
          mode: mode,
          sequence: _sequence,
          exerciseIndex: exerciseIndex,
          exerciseSet: exerciseSet,
          isResting: false,
          latencyMs: DateTime.now().difference(startedAt).inMilliseconds);
    } catch (e) {
      _log('start_failed', mode: mode, error: e);
    }
  }

  static Future<void> update({
    String mode = 'unknown',
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
    if (!Platform.isIOS) return;
    final sequence = ++_sequence;
    if (!_active || _ending) {
      _log('update_dropped',
          mode: mode,
          sequence: sequence,
          exerciseIndex: exerciseIndex,
          exerciseSet: exerciseSet,
          isResting: isResting);
      return;
    }
    final data = _buildData(
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
        )
      ..['sequence'] = sequence;
    final update = _PendingLiveActivityUpdate(
      sequence: sequence,
      mode: mode,
      data: data,
      exerciseIndex: exerciseIndex,
      exerciseSet: exerciseSet,
      isResting: isResting,
    );
    _log('update_requested',
        mode: mode,
        sequence: sequence,
        exerciseIndex: exerciseIndex,
        exerciseSet: exerciseSet,
        isResting: isResting);
    await _updates.submit(update);
  }

  static Future<void> end({
    String reason = 'finish',
    String mode = 'unknown',
  }) =>
      _requestEnd(reason: reason, mode: mode, waitForStart: true);

  static Future<void> _requestEnd({
    required String reason,
    required String mode,
    required bool waitForStart,
  }) async {
    if (!Platform.isIOS) return;
    if (waitForStart) {
      final starting = _startOperation;
      if (starting != null) await starting;
    }
    final inFlight = _endOperation;
    if (inFlight != null) {
      await inFlight;
      return;
    }
    final operation = _endInternal(reason: reason, mode: mode);
    _endOperation = operation;
    try {
      await operation;
    } finally {
      if (identical(_endOperation, operation)) _endOperation = null;
    }
  }

  static Future<void> _endInternal({
    required String reason,
    required String mode,
  }) async {
    _ending = true;
    _active = false;
    final sequence = ++_sequence;
    final startedAt = DateTime.now();
    _log('end_requested', mode: mode, sequence: sequence, reason: reason);
    try {
      await _updates.close();
      // Usa o UUID real do ActivityKit para encerrar; fallback para endAllActivities
      if (_activityKitId != null) {
        await _plugin.endActivity(_activityKitId!);
      } else {
        await _plugin.endAllActivities();
      }
      _activityKitId = null;
      _log('end_completed',
          mode: mode,
          sequence: sequence,
          reason: reason,
          latencyMs: DateTime.now().difference(startedAt).inMilliseconds);
    } catch (e) {
      _log('end_failed',
          mode: mode, sequence: sequence, reason: reason, error: e);
    } finally {
      _ending = false;
    }
  }

  static bool get isActive => _active;

  static Future<NativeRestAction?> consumeNativeRestAction() async {
    if (!Platform.isIOS) return null;
    try {
      final raw = await _appGroupChannel
          .invokeMapMethod<String, dynamic>('readRestAction');
      if (raw == null) return null;
      final action = NativeRestAction(
        action: raw['action']?.toString() ?? '',
        endTimestamp: (raw['endTimestamp'] as num?)?.toDouble() ?? 0,
        totalSeconds: (raw['totalSeconds'] as num?)?.toInt() ?? 0,
        activityId: raw['activityId']?.toString() ?? '',
        actionId: raw['actionId']?.toString() ?? '',
      );
      if (!isNativeRestActionForCurrentActivity(
        action: action,
        activityId: _activityKitId,
        lastActionId: _lastConsumedNativeActionId,
      )) {
        if (action.actionId.isNotEmpty) {
          await _appGroupChannel.invokeMethod<bool>(
            'discardRestAction',
            {'actionId': action.actionId},
          );
        }
        return null;
      }
      final acknowledged = await _appGroupChannel.invokeMethod<bool>(
        'ackRestAction',
        {'actionId': action.actionId, 'activityId': action.activityId},
      );
      if (acknowledged != true) return null;
      _lastConsumedNativeActionId = action.actionId;
      return action;
    } catch (error) {
      _log('rest_reconcile_failed', mode: 'unknown', error: error);
      return null;
    }
  }

  // ── Deep link confirm-set event ───────────────────────────────────────────
  // Emitido pelo handler de deep link (bldr://workout/confirm) e escutado
  // pela tela de treino ativa (grátis ou Club), evitando dependência de rota
  // nomeada no popUntil.
  static final _confirmSetController = StreamController<void>.broadcast();
  static Stream<void> get onConfirmSet => _confirmSetController.stream;
  static void triggerConfirmSet() => _confirmSetController.add(null);

  static Future<void> _performUpdate(_PendingLiveActivityUpdate update) async {
    final startedAt = DateTime.now();
    try {
      await _plugin.updateActivity(_kActivityId, update.data);
      _log('update_completed',
          mode: update.mode,
          sequence: update.sequence,
          exerciseIndex: update.exerciseIndex,
          exerciseSet: update.exerciseSet,
          isResting: update.isResting,
          latencyMs: DateTime.now().difference(startedAt).inMilliseconds);
    } catch (error) {
      _log('update_failed',
          mode: update.mode,
          sequence: update.sequence,
          exerciseIndex: update.exerciseIndex,
          exerciseSet: update.exerciseSet,
          isResting: update.isResting,
          error: error);
    }
  }

  static void _log(
    String event, {
    required String mode,
    int? sequence,
    int? exerciseIndex,
    int? exerciseSet,
    bool? isResting,
    String? reason,
    int? latencyMs,
    Object? error,
  }) {
    final fields = <String, Object?>{
      'mode': mode,
      if (sequence != null) 'sequence': sequence,
      if (exerciseIndex != null) 'exerciseIndex': exerciseIndex,
      if (exerciseSet != null) 'exerciseSet': exerciseSet,
      if (isResting != null) 'isResting': isResting,
      if (reason != null) 'reason': reason,
      if (latencyMs != null) 'latencyMs': latencyMs,
      if (error != null) 'errorType': error.runtimeType.toString(),
    };
    developer.log(fields.toString(), name: 'LiveActivity.$event');
  }

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

class _PendingLiveActivityUpdate {
  final int sequence;
  final String mode;
  final Map<String, dynamic> data;
  final int exerciseIndex;
  final int exerciseSet;
  final bool isResting;

  _PendingLiveActivityUpdate({
    required this.sequence,
    required this.mode,
    required this.data,
    required this.exerciseIndex,
    required this.exerciseSet,
    required this.isResting,
  });
}

class NativeRestAction {
  final String action;
  final double endTimestamp;
  final int totalSeconds;
  final String activityId;
  final String actionId;

  const NativeRestAction({
    required this.action,
    required this.endTimestamp,
    required this.totalSeconds,
    required this.activityId,
    required this.actionId,
  });
}

bool isNativeRestActionForCurrentActivity({
  required NativeRestAction action,
  required String? activityId,
  required String? lastActionId,
}) =>
    action.activityId.isNotEmpty &&
    action.activityId == activityId &&
    action.actionId.isNotEmpty &&
    action.actionId != lastActionId;
