import 'package:bldr_fitness/features/nutrition/domain/entities/food_country.dart';

/// País do banco de alimentos: escolha manual salva no aparelho; sem
/// escolha, a região do dispositivo.
abstract class FoodCountryRepository {
  Future<FoodCountry> current();
  Future<void> save(FoodCountry country);
}
