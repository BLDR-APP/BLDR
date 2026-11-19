import 'package:shared_preferences/shared_preferences.dart';

import 'package:bldr_fitness/features/nutrition/domain/repositories/daily_flags_repository.dart';

/// SharedPreferences com a data local na chave: `daily_flag_<key>_<aaaa-mm-dd>`.
class DailyFlagsRepositoryImpl implements DailyFlagsRepository {
  static String keyFor(String key, DateTime day) =>
      'daily_flag_${key}_${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  @override
  Future<bool> firstTimeToday(String key, DateTime day) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final k = keyFor(key, day);
      if (prefs.getBool(k) ?? false) return false;
      await prefs.setBool(k, true);
      return true;
    } catch (_) {
      return true; // sem armazenamento: comporta-se como antes
    }
  }
}
