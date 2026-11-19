import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_add_food_sheets.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_hub_sections.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

const _oats = FoodItem(
    id: 'a',
    name: 'Aveia',
    caloriesPer100g: 380,
    proteinPer100g: 13,
    carbsPer100g: 67,
    fatPer100g: 7);
final _catalog = AddFoodCatalog(
  search: (_) async => [_oats],
  byCategory: (_) async => [_oats],
  recents: () async => [_oats],
  favorites: () async => const [],
);

Future<T?> _open<T>(WidgetTester t, Future<T?> Function(BuildContext) open,
    Future<void> Function(WidgetTester) act) async {
  T? result;
  t.view.physicalSize = const Size(440 * 3, 956 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    locale: const Locale('pt'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (c) => Scaffold(
        body: TextButton(
            onPressed: () async => result = await open(c),
            child: const Text('abrir')),
      ),
    ),
  ));
  await t.tap(find.text('abrir'));
  await t.pumpAndSettle();
  await act(t);
  await t.pumpAndSettle();
  return result;
}

void main() {
  final lunch = NutritionMealSlot.all[2];

  testWidgets('tocar num recente devolve o alimento', (t) async {
    final r = await _open(t,
        (c) => NutritionAddFoodSheet.show(c, catalog: _catalog), (t) async {
      await t.tap(find.text('Aveia'));
    });
    expect(r?.food?.id, 'a');
  });

  testWidgets('atalhos Em breve não fecham o sheet', (t) async {
    final r = await _open(t,
        (c) => NutritionAddFoodSheet.show(c, catalog: _catalog), (t) async {
      expect(find.text('EM BREVE'), findsNWidgets(3));
      await t.tap(find.text('CÓD. BARRAS'));
      await t.pumpAndSettle();
      expect(find.text('Adicionar Alimentos'), findsOneWidget);
      await t.tap(find.text('Cadastrar alimento'));
    });
    expect(r?.createManual, isTrue);
  });

  testWidgets('porção: unidade multiplica pelo peso e troca refeição',
      (t) async {
    final r = await _open(
        t, (c) => NutritionPortionSheet.add(c, food: _oats, slot: lunch),
        (t) async {
      await t.tap(find.text('UNIDADE'));
      await t.pumpAndSettle();
      await t.tap(find.text('+').first);
      await t.pump();
      await t.enterText(find.byType(TextField), '40');
      await t.pump();
      await t.tap(find.text('LANCHE'));
      await t.pump();
      await t.tap(find.text('ADICIONAR ALIMENTO'));
    });
    expect(r?.grams, 80); // 2 un × 40 g
    expect(r?.slot.dbKey, 'snack');
  });

  testWidgets('edição: remover devolve o pedido de remoção', (t) async {
    final entry = MealEntry(
        id: '1',
        userId: 'u',
        mealType: 'lunch',
        date: DateTime(2026, 9, 4),
        foodName: 'Arroz',
        quantityGrams: 150,
        macros: const MacroNutrients(
            calories: 186, protein: 4, carbs: 39, fat: 2));
    final r = await _open(
        t, (c) => NutritionPortionSheet.edit(c, entry: entry, slot: lunch),
        (t) async {
      expect(find.text('150'), findsOneWidget);
      await t.tap(find.text('REMOVER ALIMENTO'));
    });
    expect(r?.remove, isTrue);
  });
}
