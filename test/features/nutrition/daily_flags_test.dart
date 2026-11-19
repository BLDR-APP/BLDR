import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bldr_fitness/features/nutrition/data/repositories/daily_flags_repository_impl.dart';

void main() {
  test('uma vez por dia, persistido; outro dia libera de novo', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = DailyFlagsRepositoryImpl();
    final d1 = DateTime(2026, 9, 4, 10);
    expect(await repo.firstTimeToday('kcal', d1), isTrue);
    expect(await repo.firstTimeToday('kcal', DateTime(2026, 9, 4, 22)), isFalse);
    // "Reinício": nova instância lê o mesmo armazenamento.
    expect(await DailyFlagsRepositoryImpl().firstTimeToday('kcal', d1), isFalse);
    expect(await repo.firstTimeToday('kcal', DateTime(2026, 9, 5)), isTrue);
    expect(DailyFlagsRepositoryImpl.keyFor('kcal', d1),
        'daily_flag_kcal_2026-09-04');
  });
}
