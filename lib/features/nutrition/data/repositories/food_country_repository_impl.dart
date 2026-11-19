import 'dart:ui' as ui;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:bldr_fitness/features/nutrition/domain/entities/food_country.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/food_country_repository.dart';

class FoodCountryRepositoryImpl implements FoodCountryRepository {
  FoodCountryRepositoryImpl({String? Function()? regionCode})
      : _region = regionCode ??
            (() => ui.PlatformDispatcher.instance.locale.countryCode);

  static const _key = 'nutrition_food_country';
  final String? Function() _region;

  @override
  Future<FoodCountry> current() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = FoodCountry.byName(prefs.getString(_key));
      if (saved != null) return saved;
    } catch (_) {}
    return FoodCountry.fromRegion(_region());
  }

  @override
  Future<void> save(FoodCountry country) async {
    if (!country.available) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, country.name);
  }
}
