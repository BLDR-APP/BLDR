import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/whoop_entities.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/whoop_repository.dart';
import 'package:bldr_fitness/features/integrations/domain/usecases/whoop_usecases.dart';

class FakeWhoopRepository implements WhoopRepository {
  WhoopConnection? storedConnection;
  WhoopDailyData? storedData;
  bool disconnected = false;

  String? lastAuthCode;

  @override
  Future<Result<WhoopConnection>> connectWhoop(String authCode) async {
    lastAuthCode = authCode;
    if (authCode == 'bad') {
      return const Result.failure(ServerFailure('Falha na autenticação Whoop.'));
    }
    storedConnection = WhoopConnection(
      isConnected: true,
      whoopUserId: 'whoop-123',
      connectedAt: DateTime(2026, 8, 4),
    );
    return Result.success(storedConnection!);
  }

  @override
  Future<Result<void>> disconnectWhoop() async {
    disconnected = true;
    storedConnection = null;
    return const Result.success(null);
  }

  @override
  Future<Result<WhoopConnection?>> getConnection() async =>
      Result.success(storedConnection);

  @override
  Future<Result<WhoopDailyData>> syncTodayData() async {
    if (storedConnection == null) {
      return const Result.failure(ServerFailure('Whoop não conectado.'));
    }
    storedData = WhoopDailyData(
      userId: 'user-1',
      date: DateTime(2026, 8, 4),
      recoveryScore: 75,
      strainScore: 10.5,
      sleepScore: 82,
      syncedAt: DateTime.now(),
    );
    return Result.success(storedData!);
  }

  @override
  Future<Result<WhoopDailyData?>> getTodayData() async =>
      Result.success(storedData);

  @override
  Future<Result<WhoopDailyData?>> getDataForDate(DateTime date) async =>
      Result.success(storedData);
}

void main() {
  group('Whoop use cases', () {
    late FakeWhoopRepository repo;

    setUp(() => repo = FakeWhoopRepository());

    test('ConnectWhoop — sucesso retorna WhoopConnection com isConnected=true',
        () async {
      final result = await ConnectWhoop(repo)('valid-code');
      expect(result.valueOrNull?.isConnected, true);
      expect(result.valueOrNull?.whoopUserId, 'whoop-123');
      expect(repo.lastAuthCode, 'valid-code');
    });

    test('ConnectWhoop — falha propaga Failure sem lançar exceção', () async {
      final result = await ConnectWhoop(repo)('bad');
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.message, contains('Whoop'));
    });

    test('DisconnectWhoop — zera conexão armazenada', () async {
      repo.storedConnection = const WhoopConnection(isConnected: true);
      await DisconnectWhoop(repo)();
      expect(repo.disconnected, true);
      final conn = await GetWhoopConnection(repo)();
      expect(conn.valueOrNull, isNull);
    });

    test('GetWhoopConnection — retorna null quando não conectado', () async {
      final result = await GetWhoopConnection(repo)();
      expect(result.valueOrNull, isNull);
    });

    test('SyncWhoopData — retorna WhoopDailyData com campos corretos', () async {
      repo.storedConnection =
          const WhoopConnection(isConnected: true, whoopUserId: 'w-1');
      final result = await SyncWhoopData(repo)();
      final data = result.valueOrNull;
      expect(data, isNotNull);
      expect(data!.recoveryScore, 75);
      expect(data.strainScore, 10.5);
      expect(data.sleepScore, 82);
    });

    test('SyncWhoopData — falha quando não conectado', () async {
      final result = await SyncWhoopData(repo)();
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('GetTodayWhoopData — retorna null quando sem dado local', () async {
      final result = await GetTodayWhoopData(repo)();
      expect(result.valueOrNull, isNull);
    });

    test(
        'GetTodayWhoopData — retorna dado após sincronização bem-sucedida',
        () async {
      repo.storedConnection =
          const WhoopConnection(isConnected: true, whoopUserId: 'w-1');
      await SyncWhoopData(repo)();
      final result = await GetTodayWhoopData(repo)();
      expect(result.valueOrNull?.recoveryScore, 75);
    });
  });
}
