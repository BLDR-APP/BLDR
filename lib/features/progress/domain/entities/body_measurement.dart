/// Medida corporal registrada (Supabase `user_measurements`).
class BodyMeasurement {
  final String? id;
  final String measurementType; // ex.: 'weight', 'body_fat', 'waist'
  final double value;
  final String unit;
  final DateTime? measuredAt;
  final String? notes;

  const BodyMeasurement({
    this.id,
    required this.measurementType,
    required this.value,
    this.unit = 'kg',
    this.measuredAt,
    this.notes,
  });
}

/// Evolução de uma medida no período (comparação primeiro × último registro).
class MeasurementProgress {
  final bool hasData;
  final double? latestValue;
  final double? previousValue;
  final double? change;
  final double? changePercentage;
  final int measurementCount;
  final int periodDays;

  const MeasurementProgress({
    this.hasData = false,
    this.latestValue,
    this.previousValue,
    this.change,
    this.changePercentage,
    this.measurementCount = 0,
    this.periodDays = 0,
  });
}

/// Total de água consumida no dia (Supabase `user_water_intake`).
class DailyWaterIntake {
  final int totalAmountMl;

  const DailyWaterIntake({this.totalAmountMl = 0});

  String get totalAmountLiters => (totalAmountMl / 1000.0).toStringAsFixed(1);
}
