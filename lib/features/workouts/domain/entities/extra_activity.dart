import 'package:bldr_fitness/features/workouts/domain/entities/activity_type.dart';

class ExtraActivity {
  final String? id;
  final String userId;
  final DateTime date;
  final ActivityType activityType;
  final int? durationMin;
  final String? notes;
  final int xpEarned;
  final DateTime? createdAt;

  const ExtraActivity({
    this.id,
    required this.userId,
    required this.date,
    required this.activityType,
    this.durationMin,
    this.notes,
    this.xpEarned = 50,
    this.createdAt,
  });
}
