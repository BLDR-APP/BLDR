import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/progress/domain/entities/body_measurement.dart';
import 'package:bldr_fitness/features/progress/domain/repositories/progress_repository.dart';

class RecordMeasurement {
  final ProgressRepository _repo;
  const RecordMeasurement(this._repo);

  Future<Result<BodyMeasurement>> call(BodyMeasurement m) =>
      _repo.recordMeasurement(m);
}

class GetMeasurements {
  final ProgressRepository _repo;
  const GetMeasurements(this._repo);

  Future<Result<List<BodyMeasurement>>> call({
    String? measurementType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) =>
      _repo.measurements(
        measurementType: measurementType,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
}

class GetMeasurementProgress {
  final ProgressRepository _repo;
  const GetMeasurementProgress(this._repo);

  Future<Result<MeasurementProgress>> call({
    required String measurementType,
    int daysPeriod = 30,
  }) =>
      _repo.measurementProgress(
          measurementType: measurementType, daysPeriod: daysPeriod);
}

class LogWater {
  final ProgressRepository _repo;
  const LogWater(this._repo);

  Future<Result<void>> call(int amountMl) => _repo.logWater(amountMl);
}

class RemoveWater {
  final ProgressRepository _repo;
  const RemoveWater(this._repo);

  Future<Result<void>> call(int amountMl) => _repo.removeWater(amountMl);
}

class GetDailyWaterIntake {
  final ProgressRepository _repo;
  const GetDailyWaterIntake(this._repo);

  Future<Result<DailyWaterIntake>> call(DateTime date) =>
      _repo.dailyWaterIntake(date);
}

class DeleteMeasurement {
  final ProgressRepository _repo;
  const DeleteMeasurement(this._repo);

  Future<Result<void>> call(String id) => _repo.deleteMeasurement(id);
}
