import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/services/notification_service.dart';

class WatchService {
  static final WatchService _instance = WatchService._();
  factory WatchService() => _instance;
  WatchService._();

  final _watch = WatchConnectivity();
  bool _initialized = false;

  static const _channel = MethodChannel('com.bldr.fitness/appgroup');

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final supported = await _watch.isSupported;
      if (!supported) return;
      _initialized = true;
      _listenForRunMessages();
    } catch (e) {
      debugPrint('[WATCH] initialize error: $e');
    }
  }

  Future<bool> get isReachable async {
    try {
      return await _watch.isReachable;
    } catch (_) {
      return false;
    }
  }

  // Envia estado do treino de força ao Watch
  Future<void> sendWorkoutState({
    required String workoutName,
    required String bpm,
    required List<Map<String, dynamic>> exercises,
    String status = 'active',
  }) async {
    if (!_initialized) return;
    try {
      await _watch.updateApplicationContext({
        'treino': workoutName,
        'status': status,
        'bpm': bpm,
        'exercicios': exercises,
      });
    } catch (e) {
      debugPrint('[WATCH] sendWorkoutState error: $e');
    }
  }

  Future<void> sendWorkoutFinished() async {
    if (!_initialized) return;
    try {
      await _watch.updateApplicationContext({
        'treino': '',
        'status': 'finished',
        'bpm': '',
        'exercicios': <Map<String, dynamic>>[],
      });
    } catch (e) {
      debugPrint('[WATCH] sendWorkoutFinished error: $e');
    }
  }

  // Envia estado da corrida ao Watch (modo conectado)
  Future<void> sendRunState({
    required double distanceMeters,
    required double paceSecPerKm,
    double heartRate = 0,
    bool isActive = true,
    bool finished = false,
  }) async {
    if (!_initialized) return;
    try {
      await _watch.updateApplicationContext({
        'corrida': {
          'distance': distanceMeters,
          'pace': paceSecPerKm,
          'hr': heartRate,
          'active': isActive,
          'finished': finished,
        },
      });
    } catch (e) {
      debugPrint('[WATCH] sendRunState error: $e');
    }
  }

  Stream<Map<String, dynamic>> get watchActions =>
      _watch.messageStream.map((msg) => Map<String, dynamic>.from(msg));

  // Receptor de corridas autônomas via messageStream (Watch → iPhone)
  // O Watch envia { 'type': 'run_synced', 'key': 'pending_run_<ts>' }
  // e os dados ficam no App Group — o iPhone busca via MethodChannel.
  void _listenForRunMessages() {
    _watch.messageStream.listen((msg) async {
      try {
        if (msg['type'] != 'run_synced') return;
        final key = msg['key'] as String?;
        if (key == null) return;
        await _processRunFromAppGroup(key);
      } catch (e) {
        debugPrint('[WATCH] messageStream error: $e');
      }
    });
  }

  Future<void> _processRunFromAppGroup(String key) async {
    try {
      final raw = await _channel.invokeMethod<String>('getAppGroupValue', {'key': key});
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final distanceMeters = (json['distanceMeters'] as num).toDouble();
      final elapsedSeconds = json['elapsedSeconds'] as int;
      final avgPaceSec = (json['averagePaceSecPerKm'] as num).toDouble();
      final locations = (json['locations'] as List)
          .map((l) => Map<String, dynamic>.from(l as Map))
          .toList();

      final result = await getIt<SaveRunActivity>()(
        distanceMeters: distanceMeters,
        durationSeconds: elapsedSeconds,
        paceText: _formatPace(avgPaceSec),
        routeData: locations,
        earnedXp: 100,
      );

      if (result.failureOrNull == null) {
        debugPrint('[WATCH] Corrida autônoma sincronizada: '
            '${(distanceMeters / 1000).toStringAsFixed(2)}km');
        // Remove do App Group após salvar
        await _channel.invokeMethod('removeAppGroupValue', {'key': key});
        await getIt<NotificationService>().showPushNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Corrida registrada!',
          body: '${(distanceMeters / 1000).toStringAsFixed(2)} km '
              'em ${_formatElapsed(elapsedSeconds)} '
              '· Pace ${_formatPace(avgPaceSec)}/km',
          payload: 'run_synced',
        );
      } else {
        debugPrint('[WATCH] Erro ao salvar corrida: ${result.failureOrNull?.message}');
      }
    } catch (e) {
      debugPrint('[WATCH] _processRunFromAppGroup error: $e');
    }
  }

  String _formatPace(double sec) {
    if (sec <= 0) return '--:--';
    final m = sec ~/ 60;
    final s = (sec % 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatElapsed(int seconds) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      final rem = (seconds % 3600) ~/ 60;
      return '${h}h${rem.toString().padLeft(2, '0')}min';
    }
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}min${s.toString().padLeft(2, '0')}s';
  }
}
