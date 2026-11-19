import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bldr_fitness/features/nutrition/data/models/food_item_model.dart';
import 'package:bldr_fitness/features/nutrition/data/repositories/food_country_repository_impl.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_country.dart';

void main() {
  test('região do aparelho escolhe o país; Itália/outros → Brasil', () {
    expect(FoodCountry.fromRegion('US'), FoodCountry.us);
    expect(FoodCountry.fromRegion('ca'), FoodCountry.ca);
    expect(FoodCountry.fromRegion('IT'), FoodCountry.br);
    expect(FoodCountry.fromRegion(null), FoodCountry.br);
    expect(FoodCountry.it.available, isFalse);
    expect(FoodCountry.us.collection, 'alimentos_us');
  });

  test('escolha manual persiste e vence a região', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = FoodCountryRepositoryImpl(regionCode: () => 'US');
    expect(await repo.current(), FoodCountry.us);
    await repo.save(FoodCountry.ca);
    expect(await repo.current(), FoodCountry.ca);
    await repo.save(FoodCountry.it); // indisponível: ignorado
    expect(await repo.current(), FoodCountry.ca);
  });

  test('açúcar: adicionado > added_sugars (BR) > sugars_per_100g (US/CA)', () {
    expect(FoodItemModel.fromMap({'name': 'a', 'added_sugars': 12}).addedSugarPer100g, 12);
    expect(FoodItemModel.fromMap({'name': 'a', 'sugars_per_100g': 7.96}).addedSugarPer100g, 7.96);
    expect(
        FoodItemModel.fromMap({'name': 'a', 'added_sugar_per_100g': 3, 'sugars_per_100g': 9})
            .addedSugarPer100g,
        3);
    expect(FoodItemModel.fromMap({'name': 'a'}).addedSugarPer100g, 0);
  });
}
