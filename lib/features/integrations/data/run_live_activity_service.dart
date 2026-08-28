import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';

const _kRunActivityId = 'bldr_run_activity';

class RunLiveActivityService {
  static final _instance = RunLiveActivityService._();
  factory RunLiveActivityService() => _instance;
  RunLiveActivityService._();

  final _plugin = LiveActivities();
  bool _initialized = false;

  // ID retornado pelo ActivityKit (UUID real), usado para update e end
  String? _activityId;
  DateTime? _startTime;

  // Cache para pause/resume sem precisar repassar todos os valores
  double _lastDistance = 0;
  double _lastPace = 0;
  double _lastHr = 0;

  Future<void> _init() async {
    if (_initialized) return;
    await _plugin.init(appGroupId: 'group.com.bldr.fitness');
    _initialized = true;
  }

  Future<void> start({String runTitle = 'BLDR Run'}) async {
    if (!Platform.isIOS) return;
    try {
      await _init();
      _startTime = DateTime.now();
      _lastDistance = 0;
      _lastPace = 0;
      _lastHr = 0;
      _activityId = await _plugin.createActivity(
        _kRunActivityId,
        _buildState(0, 0, 0, true),
      );
    } catch (e) {
      debugPrint('[RUN-LIVE] start error: $e');
    }
  }

  Future<void> update({
    required double distanceMeters,
    required double paceSecPerKm,
    double heartRate = 0,
    bool isActive = true,
  }) async {
    if (!Platform.isIOS || _activityId == null) return;
    try {
      await _plugin.updateActivity(
        _activityId!,
        _buildState(distanceMeters, paceSecPerKm, heartRate, isActive),
      );
    } catch (e) {
      debugPrint('[RUN-LIVE] update error: $e');
    }
  }

  Future<void> pause() => update(
        distanceMeters: _lastDistance,
        paceSecPerKm: _lastPace,
        heartRate: _lastHr,
        isActive: false,
      );

  Future<void> resume() => update(
        distanceMeters: _lastDistance,
        paceSecPerKm: _lastPace,
        heartRate: _lastHr,
        isActive: true,
      );

  Future<void> end() async {
    if (!Platform.isIOS || _activityId == null) return;
    try {
      await _plugin.endActivity(_activityId!);
    } catch (e) {
      debugPrint('[RUN-LIVE] end error: $e');
    } finally {
      _activityId = null;
      _startTime = null;
    }
  }

  bool get isActive => _activityId != null;

  Map<String, dynamic> _buildState(
    double distanceM,
    double paceSec,
    double hr,
    bool active,
  ) {
    _lastDistance = distanceM;
    _lastPace = paceSec;
    _lastHr = hr;
    return {
      'activityType': 'run',
      'startTimestamp': (_startTime?.millisecondsSinceEpoch ?? 0) / 1000.0,
      'distanceM': distanceM,
      'paceSec': paceSec,
      'hr': hr,
      'isActive': active,
    };
  }
}
