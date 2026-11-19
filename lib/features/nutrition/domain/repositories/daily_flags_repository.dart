/// Marcas "uma vez por dia" guardadas no aparelho (ex.: toast de meta).
abstract class DailyFlagsRepository {
  /// `true` só na primeira chamada de [key] no [day] local; marca o dia.
  Future<bool> firstTimeToday(String key, DateTime day);
}
