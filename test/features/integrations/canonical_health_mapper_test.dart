import 'package:bldr_fitness/features/integrations/data/mappers/canonical_health_mapper.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/canonical_health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps WHOOP daily metrics preserving provenance and nulls', () {
    final snapshot = CanonicalHealthMapper.whoop({
      'id': 'whoop-row',
      'user_id': 'user-1',
      'date': '2026-09-01',
      'synced_at': '2026-09-01T12:00:00Z',
      'recovery_score': 82,
      'hrv_rmssd': 55.5,
      'resting_hr': 48,
      'strain_score': 9.2,
      'sleep_score': null,
      'sleep_duration': 430,
    });
    expect(snapshot.source, CanonicalHealthSource.whoop);
    expect(snapshot.sourceRecordId, 'whoop-row');
    expect(snapshot.hrvRmssd, 55.5);
    expect(snapshot.sleepScore, isNull);
    expect(snapshot.sleepDurationMinutes, 430);
  });

  test('maps Apple Health workout and normalizes kilometers to meters', () {
    final activity = CanonicalHealthMapper.appleHealth(userId: 'user-1', row: {
      'id': 'health-1',
      'activity_type': 'Corrida',
      'source_name': 'Apple Watch',
      'started_at': '2026-09-01T10:00:00Z',
      'ended_at': '2026-09-01T11:00:00Z',
      'duration_s': 3600,
      'calories': 450,
      'distance_km': 5.2,
      'average_heart_rate': 142,
    });
    expect(activity.source, CanonicalHealthSource.appleHealth);
    expect(activity.distanceMeters, 5200);
    expect(activity.activeEnergyKcal, 450);
    expect(activity.averageHeartRateBpm, 142);
  });
}
