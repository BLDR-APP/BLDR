import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/whoop_entities.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/whoop_repository.dart';

class ConnectWhoop {
  final WhoopRepository _repo;
  const ConnectWhoop(this._repo);
  Future<Result<WhoopConnection>> call(String authCode) =>
      _repo.connectWhoop(authCode);
}

class DisconnectWhoop {
  final WhoopRepository _repo;
  const DisconnectWhoop(this._repo);
  Future<Result<void>> call() => _repo.disconnectWhoop();
}

class GetWhoopConnection {
  final WhoopRepository _repo;
  const GetWhoopConnection(this._repo);
  Future<Result<WhoopConnection?>> call() => _repo.getConnection();
}

class SyncWhoopData {
  final WhoopRepository _repo;
  const SyncWhoopData(this._repo);
  Future<Result<WhoopDailyData>> call() => _repo.syncTodayData();
}

class GetTodayWhoopData {
  final WhoopRepository _repo;
  const GetTodayWhoopData(this._repo);
  Future<Result<WhoopDailyData?>> call() => _repo.getTodayData();
}
