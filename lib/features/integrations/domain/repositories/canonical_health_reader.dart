import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/canonical_health.dart';

abstract class CanonicalHealthReader {
  Future<Result<CanonicalHealthDailyPage>> whoopDailySnapshots({
    required String userId,
    required DateTime start,
    required DateTime end,
    DateTime? beforeDate,
    int limit = 30,
  });

  Future<Result<List<CanonicalHealthActivity>>> appleHealthActivities({
    required String userId,
    Duration lookback = const Duration(days: 7),
    int limit = 20,
  });
}
