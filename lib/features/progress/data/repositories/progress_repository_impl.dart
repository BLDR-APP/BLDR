import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/services/progress_service.dart';
import 'package:bldr_fitness/features/progress/domain/entities/body_measurement.dart';
import 'package:bldr_fitness/features/progress/domain/repositories/progress_repository.dart';

/// Strangler (Fase 5): delega ao ProgressService legado, tipando a borda.
Future<Result<T>> _guard<T>(Future<T> Function() action) async {
  try {
    return Result.success(await action());
  } on Failure catch (f) {
    return Result.failure(f);
  } on supabase.PostgrestException catch (e) {
    return Result.failure(ServerFailure(e.message, cause: e));
  } on SocketException catch (e) {
    return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
  } on TimeoutException catch (e) {
    return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
  } catch (e) {
    return Result.failure(UnexpectedFailure('Ocorreu um erro inesperado.', e));
  }
}

BodyMeasurement _measurementFromMap(Map<String, dynamic> map) =>
    BodyMeasurement(
      id: map['id'] as String?,
      measurementType: map['measurement_type'] as String? ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? 'kg',
      measuredAt: DateTime.tryParse(map['measured_at']?.toString() ?? ''),
      notes: map['notes'] as String?,
    );

class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressService _service;

  ProgressRepositoryImpl(this._service);

  @override
  Future<Result<BodyMeasurement>> recordMeasurement(BodyMeasurement m) =>
      _guard(() async {
        final map = await _service.recordMeasurement(
          measurementType: m.measurementType,
          value: m.value,
          unit: m.unit,
          measuredAt: m.measuredAt,
          notes: m.notes,
        );
        return _measurementFromMap(map);
      });

  @override
  Future<Result<List<BodyMeasurement>>> measurements({
    String? measurementType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) =>
      _guard(() async {
        final rows = await _service.getUserMeasurements(
          measurementType: measurementType,
          startDate: startDate,
          endDate: endDate,
          limit: limit,
        );
        return rows.map(_measurementFromMap).toList();
      });

  @override
  Future<Result<MeasurementProgress>> measurementProgress({
    required String measurementType,
    int daysPeriod = 30,
  }) =>
      _guard(() async {
        final map = await _service.getMeasurementProgress(
          measurementType: measurementType,
          daysPeriod: daysPeriod,
        );
        return MeasurementProgress(
          hasData: map['has_data'] as bool? ?? false,
          latestValue: (map['latest_value'] as num?)?.toDouble(),
          previousValue: (map['previous_value'] as num?)?.toDouble(),
          change: (map['change'] as num?)?.toDouble(),
          changePercentage: (map['change_percentage'] as num?)?.toDouble(),
          measurementCount: map['measurement_count'] as int? ?? 0,
          periodDays: map['period_days'] as int? ?? daysPeriod,
        );
      });

  @override
  Future<Result<void>> logWater(int amountMl) =>
      _guard(() => _service.logWaterIntake(amountMl: amountMl));

  @override
  Future<Result<void>> removeWater(int amountMl) =>
      _guard(() => _service.removeWaterIntake(amountMl: amountMl));

  @override
  Future<Result<DailyWaterIntake>> dailyWaterIntake(DateTime date) =>
      _guard(() async {
        final map = await _service.getDailyWaterIntake(date: date);
        return DailyWaterIntake(
            totalAmountMl: (map['total_amount_ml'] as num?)?.toInt() ?? 0);
      });

  @override
  Future<Result<void>> deleteMeasurement(String id) =>
      _guard(() => _service.deleteMeasurement(id));
}
