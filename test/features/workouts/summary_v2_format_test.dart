import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/summary_v2_format.dart';

void main() {
  test('clock em mm:ss e h:mm:ss', () {
    expect(SummaryV2Format.clock(2852), '47:32');
    expect(SummaryV2Format.clock(65), '01:05');
    expect(SummaryV2Format.clock(3725), '1:02:05');
  });

  test('faixas Alto / Moderado', () {
    expect(SummaryV2Format.level(0.9), SummaryMuscleLevel.high);
    expect(SummaryV2Format.level(0.66), SummaryMuscleLevel.high);
    expect(SummaryV2Format.level(0.5), SummaryMuscleLevel.moderate);
    expect(SummaryV2Format.level(0.33), SummaryMuscleLevel.moderate);
    expect(SummaryV2Format.level(0.2), isNull);
  });

  test('kg com vírgula', () {
    expect(SummaryV2Format.kg(42.5), '42,5');
    expect(SummaryV2Format.kg(40), '40');
  });
}
