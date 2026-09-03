enum CommunityPayloadKind { manual, workout, activity, wearable }

class CommunityPostPayload {
  static const currentVersion = 1;

  final int version;
  final CommunityPayloadKind kind;
  final String? caption;
  final String? photoUrl;
  final String? workoutId;
  final String? workoutSource;
  final String? workoutName;
  final double? volumeKg;
  final int? completedSetCount;
  final List<String> muscleGroups;
  final int? durationSeconds;
  final String? activityType;
  final double? distanceKm;
  final int? calories;
  final Map<String, dynamic> wearable;
  final List<CommunityPostPr> prs;

  String? get wearableProvider =>
      wearable['provider']?.toString() ?? wearable['source']?.toString();

  String? get wearableActivityType =>
      wearable['activity_type']?.toString() ?? activityType;

  int? get wearableDurationSeconds =>
      (wearable['duration_s'] as num?)?.toInt() ?? durationSeconds;

  double? get wearableStrain => (wearable['strain'] as num?)?.toDouble();

  int? get wearableAverageHeartRate =>
      (wearable['average_heart_rate'] as num?)?.toInt() ??
      (wearable['fc_media'] as num?)?.toInt();

  int? get wearableCalories =>
      (wearable['calories'] as num?)?.toInt() ??
      (wearable['calorias'] as num?)?.toInt() ??
      calories;

  const CommunityPostPayload({
    this.version = currentVersion,
    required this.kind,
    this.caption,
    this.photoUrl,
    this.workoutId,
    this.workoutSource,
    this.workoutName,
    this.volumeKg,
    this.completedSetCount,
    this.muscleGroups = const [],
    this.durationSeconds,
    this.activityType,
    this.distanceKm,
    this.calories,
    this.wearable = const {},
    this.prs = const [],
  });

  factory CommunityPostPayload.fromJson(Map<String, dynamic> json) {
    final kind = switch (json['kind']) {
      'workout' => CommunityPayloadKind.workout,
      'activity' => CommunityPayloadKind.activity,
      'wearable' => CommunityPayloadKind.wearable,
      'manual' => CommunityPayloadKind.manual,
      _ => null,
    };
    return CommunityPostPayload(
      version: (json['version'] as num?)?.toInt() ?? 0,
      kind: kind ?? _inferLegacyKind(json),
      caption: json['caption'] as String?,
      photoUrl: json['photo_url'] as String?,
      workoutId: json['workout_id'] as String?,
      workoutSource: json['source'] as String?,
      workoutName: json['workout_name'] as String?,
      volumeKg: (json['volume_kg'] as num?)?.toDouble(),
      completedSetCount: (json['set_count'] as num?)?.toInt(),
      muscleGroups: (json['muscle_groups'] as List?)
              ?.map((value) => value.toString())
              .toList() ??
          const [],
      durationSeconds: (json['duration_s'] as num?)?.toInt(),
      activityType: json['activity_type'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      calories: (json['calories'] as num?)?.toInt(),
      wearable: json['wearable'] is Map
          ? Map<String, dynamic>.from(json['wearable'] as Map)
          : const {},
      prs: (json['prs'] as List?)
              ?.whereType<Map>()
              .map((value) =>
                  CommunityPostPr.fromJson(Map<String, dynamic>.from(value)))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': version,
        'kind': kind.name,
        if (caption != null && caption!.isNotEmpty) 'caption': caption,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (workoutId != null) 'workout_id': workoutId,
        if (workoutSource != null) 'source': workoutSource,
        if (workoutName != null) 'workout_name': workoutName,
        if (volumeKg != null) 'volume_kg': volumeKg,
        if (completedSetCount != null) 'set_count': completedSetCount,
        if (muscleGroups.isNotEmpty) 'muscle_groups': muscleGroups,
        if (durationSeconds != null) 'duration_s': durationSeconds,
        if (activityType != null) 'activity_type': activityType,
        if (distanceKm != null) 'distance_km': distanceKm,
        if (calories != null) 'calories': calories,
        if (wearable.isNotEmpty) 'wearable': wearable,
        if (prs.isNotEmpty) 'prs': prs.map((pr) => pr.toJson()).toList(),
      };

  static CommunityPayloadKind _inferLegacyKind(Map<String, dynamic> json) {
    if (json['workout_id'] != null) return CommunityPayloadKind.workout;
    if (json['activity_type'] != null) return CommunityPayloadKind.activity;
    if (json['source'] == 'whoop') return CommunityPayloadKind.wearable;
    return CommunityPayloadKind.manual;
  }
}

class CommunityPostPr {
  final String exerciseName;
  final double weightKg;
  final double? e1rm;

  const CommunityPostPr({
    required this.exerciseName,
    required this.weightKg,
    this.e1rm,
  });

  factory CommunityPostPr.fromJson(Map<String, dynamic> json) =>
      CommunityPostPr(
        exerciseName: json['exercise_name']?.toString() ?? 'Exercício',
        weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
        e1rm: (json['e1rm'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'exercise_name': exerciseName,
        'weight_kg': weightKg,
        if (e1rm != null) 'e1rm': e1rm,
      };
}
