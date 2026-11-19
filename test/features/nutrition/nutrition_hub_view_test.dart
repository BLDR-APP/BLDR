import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/design_system/bldr_nutrition_v2_components.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/daily_nutrition_summary.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/services/iqd_calculator.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_hub_sections.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

final _today = DateTime(2026, 9, 4);
final _entry = MealEntry(
    id: '1',
    userId: 'u',
    mealType: 'post_workout',
    date: _today,
    foodName: 'Whey',
    quantityGrams: 30,
    macros: const MacroNutrients(calories: 120, protein: 24, carbs: 3, fat: 1));

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

Widget _hub({
  IqdWeeklyComparison? iqd,
  String? expanded,
  bool edit = false,
  bool fab = true,
  VoidCallback? onFab,
  ValueChanged<MealEntry>? onRemove,
}) =>
    NutritionHubView(
      date: _today,
      today: _today,
      summary: DailyNutritionSummary.fromEntries(_today, [_entry]),
      goals: NutritionGoals.defaults,
      iqd: iqd,
      iqdLocked: false,
      waterMl: 0,
      entries: [_entry],
      expandedKey: expanded,
      editMode: edit,
      fabVisible: fab,
      onRefresh: () async {},
      onDateTap: () {},
      onUnlockIqd: () {},
      onAddWater: () {},
      onToggleMeal: (_) {},
      onAddFood: (_) {},
      onToggleEdit: () {},
      onEditFood: (_) {},
      onRemoveFood: onRemove ?? (_) {},
      onFab: onFab ?? () {},
    );

void main() {
  testWidgets('6 refeições, incluindo Pós-treino', (t) async {
    await t.pumpWidget(_app(_hub()));
    await t.scrollUntilVisible(find.text('JANTAR'), 200);
    expect(find.text('PÓS-TREINO'), findsOneWidget);
    expect(find.text('Whey'), findsOneWidget);
  });

  testWidgets('sem dia anterior com registro, sem linha de pontos', (t) async {
    await t.pumpWidget(_app(_hub(
        iqd: const IqdWeeklyComparison(score: 84, band: IqdBand.veryGood))));
    expect(find.text('MUITO BOM'), findsOneWidget);
    expect(find.textContaining('pontos'), findsNothing);
    await t.pumpWidget(_app(_hub(
        iqd: const IqdWeeklyComparison(
            score: 84, band: IqdBand.veryGood, weekAverage: 78))));
    expect(find.textContaining('6 pontos'), findsOneWidget);
  });

  testWidgets('FAB oculto não recebe toque', (t) async {
    var taps = 0;
    await t.pumpWidget(_app(_hub(fab: false, onFab: () => taps++)));
    await t.pumpAndSettle();
    await t.tap(find.byType(BldrNutritionFab), warnIfMissed: false);
    expect(taps, 0);
    await t.pumpWidget(_app(_hub(onFab: () => taps++)));
    await t.pumpAndSettle();
    await t.tap(find.byType(BldrNutritionFab));
    expect(taps, 1);
  });

  testWidgets('modo de edição mostra remover no item expandido', (t) async {
    MealEntry? removed;
    await t.pumpWidget(_app(_hub(expanded: 'post_workout')));
    expect(find.bySemanticsLabel('Remover alimento'), findsNothing);
    await t.pumpWidget(_app(_hub(
        expanded: 'post_workout', edit: true, onRemove: (e) => removed = e)));
    final trash = find.byIcon(TablerIcons.trash);
    await t.scrollUntilVisible(trash, 200);
    await t.pumpAndSettle();
    await t.tap(trash);
    expect(removed?.id, '1');
  });

  test('sugestão de refeição pelo horário', () {
    expect(NutritionMealSlot.suggested(DateTime(2026, 1, 1, 8)).dbKey,
        'breakfast');
    expect(NutritionMealSlot.suggested(DateTime(2026, 1, 1, 12)).dbKey,
        'lunch');
    expect(NutritionMealSlot.suggested(DateTime(2026, 1, 1, 20)).dbKey,
        'dinner');
  });
}
