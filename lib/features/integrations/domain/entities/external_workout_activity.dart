class ExternalWorkoutActivity {
  final String id;
  final String provider;
  final String externalActivityId;
  final String activityType;
  final DateTime startedAt;
  final DateTime endedAt;
  final int? durationSeconds;
  final double? strain;
  final int? averageHeartRate;
  final int? maxHeartRate;
  final int? calories;
  final double? distanceKm;
  final String status;
  final String? linkedWorkoutId;
  final String? linkedWorkoutSource;

  const ExternalWorkoutActivity({
    required this.id,
    required this.provider,
    required this.externalActivityId,
    required this.activityType,
    required this.startedAt,
    required this.endedAt,
    this.durationSeconds,
    this.strain,
    this.averageHeartRate,
    this.maxHeartRate,
    this.calories,
    this.distanceKm,
    required this.status,
    this.linkedWorkoutId,
    this.linkedWorkoutSource,
  });

  factory ExternalWorkoutActivity.fromMap(Map<String, dynamic> map) {
    return ExternalWorkoutActivity(
      id: map['id'] as String,
      provider: map['provider'] as String? ?? 'wearable',
      externalActivityId: map['external_activity_id'] as String? ?? '',
      activityType: map['activity_type'] as String? ?? 'Atividade',
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: DateTime.parse(map['ended_at'] as String),
      durationSeconds: (map['duration_seconds'] as num?)?.toInt(),
      strain: (map['strain'] as num?)?.toDouble(),
      averageHeartRate: (map['average_heart_rate'] as num?)?.toInt(),
      maxHeartRate: (map['max_heart_rate'] as num?)?.toInt(),
      calories: (map['calories'] as num?)?.toInt(),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'pending',
      linkedWorkoutId: map['linked_workout_id'] as String?,
      linkedWorkoutSource: map['linked_workout_source'] as String?,
    );
  }
}

class PreparedWearableWorkout {
  final String workoutId;
  final String source;

  const PreparedWearableWorkout({
    required this.workoutId,
    required this.source,
  });
}
