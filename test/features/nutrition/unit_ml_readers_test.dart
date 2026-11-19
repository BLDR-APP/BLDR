import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/nutrition/data/models/meal_entry_model.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/saved_meal.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/food_catalog_repository.dart';
import 'package:bldr_fitness/features/nutrition/data/models/saved_meal_model.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/daily_nutrition_summary.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_copy_meal_sheets.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_hub_sections.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_saved_meal_sheets.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

import 'nutrition_usecases_test.dart' show FakeDiaryRepository;

final _day = DateTime(2026, 9, 3);
final _today = DateTime(2026, 9, 4);
final _milk = MealEntry(
    id: 'ml',
    userId: 'u',
    mealType: 'snack',
    date: _day,
    foodName: 'Leite',
    quantityGrams: 200,
    macros: const MacroNutrients(calories: 120, protein: 6, carbs: 10, fat: 6),
    unit: 'ml');
final _rice = MealEntry(
    id: 'g',
    userId: 'u',
    mealType: 'snack',
    date: _day,
    foodName: 'Arroz',
    quantityGrams: 150,
    macros: const MacroNutrients(calories: 186, protein: 4, carbs: 39, fat: 2));

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

Future<void> _openSheet(WidgetTester t, Future<void> Function(BuildContext) open) async {
  t.view.physicalSize = const Size(440 * 3, 956 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(_app(Builder(
      builder: (c) => TextButton(onPressed: () => open(c), child: const Text('abrir')))));
  await t.tap(find.text('abrir'));
  await t.pumpAndSettle();
}

void main() {
  test('registro antigo sem unit continua em g', () {
    final old = MealEntryModel.fromMap({'food_name': 'X', 'quantity_grams': 50});
    expect(old.unit, 'g');
    expect(MealEntryModel.fromMap(MealEntryModel.toMap(_milk)).unit, 'ml');
  });

  testWidgets('hub (dia passado / histórico): ml e g na refeição expandida',
      (t) async {
    t.view.physicalSize = const Size(440 * 3, 1600 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(NutritionHubView(
      date: _day,
      today: _today,
      summary: DailyNutritionSummary.fromEntries(_day, [_milk, _rice]),
      goals: NutritionGoals.defaults,
      iqd: null,
      iqdLocked: false,
      waterMl: 0,
      entries: [_milk, _rice],
      expandedKey: 'snack',
      editMode: false,
      fabVisible: false,
      onRefresh: () async {},
      onDateTap: () {},
      onUnlockIqd: () {},
      onAddWater: null,
      onToggleMeal: (_) {},
      onAddFood: (_) {},
      onToggleEdit: () {},
      onEditFood: (_) {},
      onRemoveFood: (_) {},
      onFab: () {},
    )));
    await t.pumpAndSettle();
    expect(find.text('200 ml'), findsOneWidget);
    expect(find.text('150g'), findsOneWidget);
  });

  testWidgets('Copiar refeição: revisão mostra ml e g', (t) async {
    await _openSheet(
        t,
        (c) => NutritionCopyMealSheets.review(c,
            dest: CopyDestination(_today, NutritionMealSlot.all[1]),
            entries: [_milk, _rice],
            today: _today));
    expect(find.textContaining('200 ml'), findsOneWidget);
    expect(find.textContaining('150g'), findsOneWidget);
  });

  test('Copiar refeição e Desfazer preservam unit', () async {
    final diary = FakeDiaryRepository();
    await CopyMeal(diary)(entries: [_milk], toDate: _today, toMealType: 'dinner');
    expect(diary.entries.single.unit, 'ml');
    await RestoreMealEntry(diary)(_milk);
    expect(diary.entries.last.unit, 'ml');
    // Edição de quantidade mantém a unidade.
    expect(_milk.copyWith(quantityGrams: 300).unit, 'ml');
  });

  testWidgets('Salvar como refeição: unit vai para o doc e o detalhe mostra ml',
      (t) async {
    final cat = _Catalog();
    final saved = (await SaveMealFromEntries(cat)(
            name: 'Lanche', entries: [_milk, _rice], userId: 'u'))
        .valueOrNull!;
    final map = SavedMealModel.toMap(saved, 'u');
    expect((map['items'] as List)[0]['unit'], 'ml');
    expect((map['items'] as List)[1].containsKey('unit'), isFalse);
    final back = SavedMealModel.fromMap(map);
    await _openSheet(t, (c) => NutritionSavedMealSheets.detail(c, meal: back));
    expect(find.textContaining('200 ml'), findsOneWidget);
    expect(find.textContaining('150g'), findsOneWidget);
  });

  test('edição troca a unidade e grava unit no update', () async {
    final diary = FakeDiaryRepository();
    final rice = MealEntry(
        id: 'g', userId: 'u', mealType: 'snack', date: _day, foodName: 'Suco',
        quantityGrams: 100,
        macros: const MacroNutrients(calories: 50, protein: 0, carbs: 12, fat: 0));
    await UpdateMealQuantity(diary)(entry: rice, newQuantityGrams: 300, newUnit: 'ml');
    final up = diary.updates['g']!;
    expect(up.unit, 'ml');
    expect(up.macros.calories, 150);
    expect(MealEntryModel.toQuantityUpdate(up)['unit'], 'ml');
  });
}

class _Catalog implements FoodCatalogRepository {
  @override
  Future<Result<SavedMeal>> saveMeal(SavedMeal meal, String userId) async =>
      Result.success(SavedMeal(id: 'x', name: meal.name, items: meal.items));
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError();
}
