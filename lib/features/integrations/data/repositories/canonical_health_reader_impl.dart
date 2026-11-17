import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/integrations/data/datasources/canonical_health_datasource.dart';
import 'package:bldr_fitness/features/integrations/data/health_kit_service.dart';
import 'package:bldr_fitness/features/integrations/data/mappers/canonical_health_mapper.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/canonical_health.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/canonical_health_reader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CanonicalHealthReaderImpl implements CanonicalHealthReader {
  final CanonicalHealthReadDatasource _datasource;
  final Future<List<Map<String, dynamic>>> Function({
    Duration lookback,
    int limit,
  }) _fetchRecentWorkouts;
  final String? Function() _currentUserId;

  CanonicalHealthReaderImpl({
    required CanonicalHealthReadDatasource datasource,
    required HealthKitService healthKit,
    required String? Function() currentUserId,
    Future<List<Map<String, dynamic>>> Function({
      Duration lookback,
      int limit,
    })? fetchRecentWorkouts,
  })  : _datasource = datasource,
        _fetchRecentWorkouts =
            fetchRecentWorkouts ?? healthKit.fetchRecentWorkouts,
        _currentUserId = currentUserId;

  bool _owns(String userId) => _currentUserId() == userId;

  @override
  Future<Result<CanonicalHealthDailyPage>> whoopDailySnapshots({
    required String userId,
    required DateTime start,
    required DateTime end,
    DateTime? beforeDate,
    int limit = 30,
  }) async {
    if (!_owns(userId)) {
      return const Result.failure(AuthFailure('Usuário não autenticado.'));
    }
    if (limit <= 0 || !end.isAfter(start)) {
      return const Result.failure(
          ValidationFailure('Intervalo ou limite inválido.'));
    }
    if (beforeDate != null &&
        (!beforeDate.isAfter(start) || beforeDate.isAfter(end))) {
      return const Result.failure(ValidationFailure('Cursor inválido.'));
    }
    try {
      if (!await _datasource.hasWhoopConnection(userId)) {
        return const Result.success(CanonicalHealthDailyPage(
          availability: CanonicalHealthAvailability.disconnected,
          snapshots: [],
        ));
      }
      final rows = await _datasource.whoopDaily(
        userId: userId,
        start: start,
        end: end,
        beforeDate: beforeDate,
        limit: limit + 1,
      );
      final hasMore = rows.length > limit;
      final pageRows = hasMore ? rows.take(limit).toList() : rows;
      return Result.success(CanonicalHealthDailyPage(
        availability: pageRows.isEmpty
            ? CanonicalHealthAvailability.empty
            : CanonicalHealthAvailability.data,
        snapshots: pageRows.map(CanonicalHealthMapper.whoop).toList(),
        nextBeforeDate:
            hasMore ? DateTime.parse(pageRows.last['date'].toString()) : null,
      ));
    } on PostgrestException catch (error) {
      return Result.failure(
          ServerFailure('Não foi possível ler os dados WHOOP.', cause: error));
    } catch (error) {
      return Result.failure(
          UnexpectedFailure('Não foi possível ler os dados de saúde.', error));
    }
  }

  @override
  Future<Result<List<CanonicalHealthActivity>>> appleHealthActivities({
    required String userId,
    Duration lookback = const Duration(days: 7),
    int limit = 20,
  }) async {
    if (!_owns(userId)) {
      return const Result.failure(AuthFailure('Usuário não autenticado.'));
    }
    if (lookback <= Duration.zero || limit <= 0 || limit > 50) {
      return const Result.failure(
          ValidationFailure('Intervalo ou limite inválido.'));
    }
    try {
      final rows = await _fetchRecentWorkouts(lookback: lookback, limit: limit);
      return Result.success(rows
          .map((row) =>
              CanonicalHealthMapper.appleHealth(userId: userId, row: row))
          .toList());
    } catch (error) {
      return Result.failure(DataFailure(
          'Não foi possível ler atividades do Apple Health.',
          cause: error));
    }
  }
}
