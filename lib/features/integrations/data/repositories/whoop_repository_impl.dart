import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/integrations/data/datasources/whoop_datasource.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/whoop_entities.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/whoop_repository.dart';

class WhoopRepositoryImpl implements WhoopRepository {
  final WhoopDatasource _ds;
  WhoopRepositoryImpl(this._ds);

  @override
  Future<Result<WhoopConnection>> connectWhoop(String authCode) =>
      _ds.connectWhoop(authCode);

  @override
  Future<Result<void>> disconnectWhoop() => _ds.disconnectWhoop();

  @override
  Future<Result<WhoopConnection?>> getConnection() => _ds.getConnection();

  @override
  Future<Result<WhoopDailyData>> syncTodayData() => _ds.syncTodayData();

  @override
  Future<Result<WhoopDailyData?>> getTodayData() =>
      _ds.getDataForDate(DateTime.now());

  @override
  Future<Result<WhoopDailyData?>> getDataForDate(DateTime date) =>
      _ds.getDataForDate(date);
}
