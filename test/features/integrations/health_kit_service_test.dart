import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/integrations/data/health_kit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('bldr/healthkit');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('fetchRecentWorkouts preserva o contrato tipado do Apple Health',
      () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      capturedCall = call;
      return <Map<String, dynamic>>[
        {
          'id': 'health-workout-1',
          'provider': 'apple_watch',
          'activity_type': 'Musculação',
          'duration_s': 2700,
          'calories': 320,
          'average_heart_rate': 118,
        },
      ];
    });

    final workouts = await HealthKitService().fetchRecentWorkouts(
      lookback: const Duration(days: 3),
      limit: 12,
    );

    expect(capturedCall?.method, 'fetchRecentWorkouts');
    expect(capturedCall?.arguments, {
      'lookbackHours': 72,
      'limit': 12,
    });
    expect(workouts, hasLength(1));
    expect(workouts.single['provider'], 'apple_watch');
    expect(workouts.single['activity_type'], 'Musculação');
    expect(workouts.single['duration_s'], 2700);
  });

  test('fetchRecentWorkouts não transforma falha nativa em lista vazia',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'HEALTH_WORKOUT_QUERY_FAILED');
    });

    expect(
      HealthKitService().fetchRecentWorkouts(),
      throwsA(isA<PlatformException>()),
    );
  });
}
