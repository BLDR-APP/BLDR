import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/whoop_entities.dart';

abstract class WhoopRepository {
  Future<Result<WhoopConnection>> connectWhoop(String authCode);
  Future<Result<void>> disconnectWhoop();
  Future<Result<WhoopConnection?>> getConnection();
  Future<Result<WhoopDailyData>> syncTodayData();
  Future<Result<WhoopDailyData?>> getTodayData();
  Future<Result<WhoopDailyData?>> getDataForDate(DateTime date);
}
