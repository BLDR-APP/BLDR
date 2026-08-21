import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';

/// Alimento do catálogo (Firestore `alimentos`), favorito ou recente —
/// sempre com valores nutricionais por 100g.
class FoodItem {
  final String? id;
  final String name;
  final String? brand;
  final String? category;
  final String? createdBy;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double sodiumPer100g;
  final double fiberPer100g;
  final double addedSugarPer100g;

  const FoodItem({
    this.id,
    required this.name,
    this.brand,
    this.category,
    this.createdBy,
    this.caloriesPer100g = 0,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    this.sodiumPer100g = 0,
    this.fiberPer100g = 0,
    this.addedSugarPer100g = 0,
  });

  /// Macros totais para uma quantidade consumida.
  MacroNutrients macrosFor(double quantityGrams) => MacroNutrients.fromPer100g(
        quantityGrams: quantityGrams,
        caloriesPer100g: caloriesPer100g,
        proteinPer100g: proteinPer100g,
        carbsPer100g: carbsPer100g,
        fatPer100g: fatPer100g,
        sodiumPer100g: sodiumPer100g,
        fiberPer100g: fiberPer100g,
        addedSugarPer100g: addedSugarPer100g,
      );
}
