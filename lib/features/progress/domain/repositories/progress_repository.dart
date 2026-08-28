import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/progress/domain/entities/body_measurement.dart';

/// Medidas corporais do usuário.
abstract class ProgressRepository {
  Future<Result<BodyMeasurement>> recordMeasurement(BodyMeasurement m);

  Future<Result<List<BodyMeasurement>>> measurements({
    String? measurementType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  });

  Future<Result<MeasurementProgress>> measurementProgress({
    required String measurementType,
    int daysPeriod = 30,
  });

  // --- Água ---

  Future<Result<void>> logWater(int amountMl);

  Future<Result<void>> removeWater(int amountMl);

  Future<Result<DailyWaterIntake>> dailyWaterIntake(DateTime date);

  Future<Result<void>> deleteMeasurement(String id);
}
