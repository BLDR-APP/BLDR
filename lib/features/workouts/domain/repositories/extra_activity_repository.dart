import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/activity_type.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/extra_activity.dart';

abstract class ExtraActivityRepository {
  Future<Result<void>> logExtraActivity({
    required DateTime date,
    required ActivityType activityType,
    int? durationMin,
    String? notes,
  });

  Future<Result<List<ExtraActivity>>> getExtraActivities(
    DateTime weekStart,
    DateTime weekEnd,
  );
}
