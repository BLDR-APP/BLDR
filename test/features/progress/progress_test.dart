import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/achievements/domain/entities/achievement.dart';
import 'package:bldr_fitness/features/achievements/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/features/progress/domain/entities/body_measurement.dart';
import 'package:bldr_fitness/features/progress/domain/repositories/progress_repository.dart';
import 'package:bldr_fitness/features/progress/domain/usecases/progress_usecases.dart';

class FakeProgressRepository implements ProgressRepository {
  final List<BodyMeasurement> saved = [];
  int waterLogged = 0;

  @override
  Future<Result<BodyMeasurement>> recordMeasurement(BodyMeasurement m) async {
    saved.add(m);
    return Result.success(m);
  }

  @override
  Future<Result<List<BodyMeasurement>>> measurements(
          {String? measurementType,
          DateTime? startDate,
          DateTime? endDate,
          int limit = 50}) async =>
      Result.success(saved
          .where((m) =>
              measurementType == null || m.measurementType == measurementType)
          .toList());

  @override
  Future<Result<MeasurementProgress>> measurementProgress(
          {required String measurementType, int daysPeriod = 30}) async =>
      const Result.success(MeasurementProgress(hasData: false));

  @override
  Future<Result<void>> logWater(int amountMl) async {
    waterLogged += amountMl;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> removeWater(int amountMl) async {
    waterLogged -= amountMl;
    return const Result.success(null);
  }

  @override
  Future<Result<DailyWaterIntake>> dailyWaterIntake(DateTime date) async =>
      Result.success(DailyWaterIntake(totalAmountMl: waterLogged));

  @override
  Future<Result<void>> deleteMeasurement(String id) async {
    saved.removeWhere((m) => m.id == id);
    return const Result.success(null);
  }
}

void main() {
  late FakeProgressRepository repo;

  setUp(() => repo = FakeProgressRepository());

  test('RecordMeasurement grava e GetMeasurements filtra por tipo', () async {
    await RecordMeasurement(repo)(const BodyMeasurement(
        measurementType: 'weight', value: 82.5, unit: 'kg'));
    await RecordMeasurement(repo)(const BodyMeasurement(
        measurementType: 'body_fat', value: 18, unit: '%'));

    final weights =
        await GetMeasurements(repo)(measurementType: 'weight');
    expect(weights.valueOrNull, hasLength(1));
    expect(weights.valueOrNull!.first.value, 82.5);
  });

  test('fluxo de água: log, remove e total do dia', () async {
    await LogWater(repo)(250);
    await LogWater(repo)(500);
    await RemoveWater(repo)(250);

    final daily = await GetDailyWaterIntake(repo)(DateTime.now());
    expect(daily.valueOrNull?.totalAmountMl, 500);
    expect(daily.valueOrNull?.totalAmountLiters, '0.5');
  });

  test('DailyWaterIntake formata litros com 1 casa', () {
    expect(const DailyWaterIntake(totalAmountMl: 1250).totalAmountLiters, '1.3');
    expect(const DailyWaterIntake().totalAmountLiters, '0.0');
  });

  group('B1 — average_workout_duration_minutes (bug fix)', () {
    // Simula a lógica corrigida de progress_service.dart:
    // só workouts com duration > 0 entram no cálculo (numerador E denominador).
    int? calcAvg(List<int?> durations) {
      final qualifying = durations.where((d) => d != null && d > 0).cast<int>().toList();
      if (qualifying.isEmpty) return null;
      final totalSeconds = qualifying.fold(0, (a, b) => a + b);
      return ((totalSeconds / qualifying.length) / 60).round();
    }

    test('[53min, 22min, 0min, null] → 38min (avg de 53 e 22, ignorando 0 e null)', () {
      // (53+22)/2 = 37.5 → arredonda para 38
      expect(calcAvg([53 * 60, 22 * 60, 0, null]), 38);
    });

    test('todos com duration=0 → null (não divide por zero)', () {
      expect(calcAvg([0, 0, 0]), isNull);
    });

    test('lista vazia → null', () {
      expect(calcAvg([]), isNull);
    });

    test('lista só com null → null', () {
      expect(calcAvg([null, null]), isNull);
    });

    test('single qualifying workout → usa só ele como denominador', () {
      expect(calcAvg([60 * 60, 0, null]), 60); // 3600s / 1 = 60min
    });
  });

  test('achievementToLegacyMap preserva as chaves dos widgets', () {
    final map = achievementToLegacyMap(const Achievement(
      id: '1',
      name: 'Primeira Série',
      description: 'Complete 1 treino',
      category: 'workout',
      iconName: 'medal',
      xpValue: 100,
      criteriaType: 'workout_count',
      criteriaValue: 1,
    ));

    expect(map['name'], 'Primeira Série');
    expect(map['icon_name'], 'medal');
    expect(map['xp_value'], 100);
    expect(map['criteria_type'], 'workout_count');
  });
}
