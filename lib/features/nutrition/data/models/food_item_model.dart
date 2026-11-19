import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';

/// Conversão FoodItem <-> documentos do Firestore.
///
/// A base `alimentos`/`user_favorites` usa chaves `*_per_100g`; alguns
/// documentos antigos usam `sodium`/`fiber`/`added_sugar` sem sufixo —
/// o parse aceita ambos (mesmo fallback do service legado).
class FoodItemModel {
  static FoodItem fromMap(Map<String, dynamic> map, {String? id}) {
    double read(String key, [String? fallbackKey]) =>
        (map[key] as num?)?.toDouble() ??
        (fallbackKey != null ? (map[fallbackKey] as num?)?.toDouble() : null) ??
        0.0;

    return FoodItem(
      id: id ?? map['id'] as String?,
      name: map['name'] as String? ?? '',
      brand: map['brand'] as String?,
      category: map['category'] as String?,
      createdBy: map['created_by'] as String?,
      caloriesPer100g: read('calories_per_100g'),
      proteinPer100g: read('protein_per_100g'),
      carbsPer100g: read('carbs_per_100g'),
      fatPer100g: read('fat_per_100g'),
      sodiumPer100g: read('sodium_per_100g', 'sodium'),
      fiberPer100g: read('fiber_per_100g', 'fiber'),
      // Açúcar: adicionado (favoritos), `added_sugars` (base BR) ou, nos
      // EUA/Canadá, só o total `sugars_per_100g` (aproximação aprovada).
      addedSugarPer100g: [
            'added_sugar_per_100g',
            'added_sugars',
            'added_sugar',
            'sugars_per_100g',
          ]
              .map((k) => (map[k] as num?)?.toDouble())
              .firstWhere((v) => v != null, orElse: () => 0.0) ??
          0.0,
      isLiquid: map['unit'] == 'ml',
      unitWeight: (map['unit_weight'] as num?)?.toDouble(),
      unitDescription: map['unit_description'] as String?,
    );
  }

  static Map<String, dynamic> toFavoriteMap(FoodItem item, String userId) => {
        'user_id': userId,
        'name': item.name,
        // `brand` já é lido por fromMap (mesmo campo de `alimentos`).
        if (item.brand != null && item.brand!.isNotEmpty) 'brand': item.brand,
        'calories_per_100g': item.caloriesPer100g,
        'protein_per_100g': item.proteinPer100g,
        'carbs_per_100g': item.carbsPer100g,
        'fat_per_100g': item.fatPer100g,
        'sodium_per_100g': item.sodiumPer100g,
        'fiber_per_100g': item.fiberPer100g,
        'added_sugar_per_100g': item.addedSugarPer100g,
        // Campos opcionais da N4 (só gravados quando existem).
        if (item.isLiquid) 'unit': 'ml',
        if (item.unitWeight != null) 'unit_weight': item.unitWeight,
        if (item.unitDescription != null && item.unitDescription!.isNotEmpty)
          'unit_description': item.unitDescription,
      };
}
