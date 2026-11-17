import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';

abstract class WorkoutAnalyticsReader {
  Future<Result<WorkoutAnalyticsSummary>> summarize({
    required String userId,
    required WorkoutAnalyticsRange range,
    bool comparePreviousPeriod = true,
    int pageSize = 50,
    int maxPages = 50,
  });
}
