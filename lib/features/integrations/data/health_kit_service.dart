import 'package:flutter/services.dart';

class HealthKitService {
  static final HealthKitService _instance = HealthKitService._();
  factory HealthKitService() => _instance;
  HealthKitService._();

  static const _channel = MethodChannel('bldr/healthkit');
  static const _hrChannel = EventChannel('bldr/healthkit/heartrate');

  Stream<double>? _heartRateStream;

  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isAuthorized() async {
    try {
      return await _channel.invokeMethod<bool>('checkPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Stream<double> get heartRateStream {
    _heartRateStream ??= _hrChannel
        .receiveBroadcastStream()
        .map((event) => (event as num).toDouble());
    return _heartRateStream!;
  }

  Future<double> fetchTodayCaloriesBurned() async {
    try {
      return await _channel.invokeMethod<double>('fetchTodayCaloriesBurned') ??
          0;
    } catch (_) {
      return 0;
    }
  }

  /// Retorna treinos recentes disponibilizados pelo Apple Health.
  ///
  /// Exceções do canal são preservadas para que o repository possa convertê-las
  /// em [Failure] e exibir um erro observável na interface.
  Future<List<Map<String, dynamic>>> fetchRecentWorkouts({
    Duration lookback = const Duration(days: 7),
    int limit = 20,
  }) async {
    final raw = await _channel.invokeMethod<List<dynamic>>(
          'fetchRecentWorkouts',
          {
            'lookbackHours': lookback.inHours,
            'limit': limit,
          },
        ) ??
        const <dynamic>[];

    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<bool> saveCalories({
    required double calories,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('saveCalories', {
            'calories': calories,
            'startTimestamp': startTime.millisecondsSinceEpoch.toDouble(),
            'endTimestamp': endTime.millisecondsSinceEpoch.toDouble(),
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  void stopHeartRateMonitoring() {
    _channel.invokeMethod<void>('stopHeartRateMonitoring');
    _heartRateStream = null;
  }
}
