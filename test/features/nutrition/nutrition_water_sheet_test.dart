import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_water_sheet.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

Future<WaterSheetResult?> _open(WidgetTester t,
    Future<void> Function(WidgetTester) act) async {
  WaterSheetResult? result;
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
          onPressed: () async => result = await NutritionWaterSheet.show(c,
              intakeMl: 1800, goalMl: 2500),
          child: const Text('abrir'),
        ),
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
  testWidgets('preset 500 + ADICIONAR ÁGUA retorna 500 ml', (t) async {
    final r = await _open(t, (t) async {
      await t.tap(find.text('500 ml'));
      await t.pump();
      await t.ensureVisible(find.text('ADICIONAR ÁGUA'));
      await t.pumpAndSettle();
      await t.tap(find.text('ADICIONAR ÁGUA'));
    });
    expect(r?.addMl, 500);
  });

  testWidgets('PERSONALIZADO abre a digitação', (t) async {
    await _open(t, (t) async {
      await t.tap(find.text('PERSONALIZADO'));
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await t.enterText(find.byType(TextField), '750');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(find.text('750'), findsOneWidget);
    });
  });

  testWidgets('link de remover devolve remove', (t) async {
    final r = await _open(t, (t) async {
      await t.ensureVisible(find.text('Remover última entrada'));
      await t.pumpAndSettle();
      await t.tap(find.text('Remover última entrada'));
    });
    expect(r?.remove, isTrue);
  });
}
