import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';

/// Alimento de uma refeição salva: snapshot igual ao do diário (totais da
/// quantidade, não por 100 g).
class SavedMealItem {
  final String foodName;
  final String? foodItemId;
  final double quantityGrams;
  final MacroNutrients macros;
  final String unit;
  const SavedMealItem({
    required this.foodName,
    required this.quantityGrams,
    required this.macros,
    this.foodItemId,
    this.unit = 'g',
  });
}

/// Refeição salva (N7). Gravada em `user_favorites` com `type: 'meal'`.
class SavedMeal {
  final String? id;
  final String name;
  final List<SavedMealItem> items;
  const SavedMeal({this.id, required this.name, required this.items});

  MacroNutrients get totals =>
      items.fold(MacroNutrients.zero, (a, i) => a + i.macros);

  /// "Frango, arroz e feijão" — nomes dos alimentos.
  String get description => items.map((i) => i.foodName).join(', ');
}
