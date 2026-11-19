import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bldr_fitness/core/toast/toast_controller.dart';
import 'package:bldr_fitness/core/toast/toast_host.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_overlay.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_provider.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

/// Fila fake: mesma API pública que o overlay usa.
class _FakeAchievements extends AchievementProvider {
  final List<Map<String, dynamic>> items;
  _FakeAchievements(this.items);
  @override
  Map<String, dynamic>? get current => items.isEmpty ? null : items.first;
  @override
  bool get hasPending => items.isNotEmpty;
  @override
  void dismissCurrent() {
    if (items.isEmpty) return;
    items.removeAt(0);
    notifyListeners();
  }
}

void main() {
  testWidgets('conquistas entram em ordem, uma por vez, via Toast v2',
      (t) async {
    final c = ToastController();
    final ach = _FakeAchievements([
      {'name': 'Primeiro treino', 'description': 'Você treinou'},
      {'name': 'Hidratado'},
    ]);
    await t.pumpWidget(ChangeNotifierProvider<AchievementProvider>.value(
      value: ach,
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (_, child) => ToastHost(
          controller: c,
          child: AchievementOverlay(controller: c, child: child!),
        ),
        home: const SizedBox(),
      ),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(c.current?.variant, ToastVariant.achievement);
    expect(find.text('Primeiro treino'), findsOneWidget);
    // Não duplica enquanto visível.
    expect(c.pending, isEmpty);
    await t.pump(const Duration(seconds: 5)); // expira → dismissCurrent
    expect(ach.items.single['name'], 'Hidratado');
    await t.pump(c.gap);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(c.current?.message, 'Hidratado');
    c.dismiss();
    await t.pump(const Duration(seconds: 1));
    expect(ach.items, isEmpty);
  });

  testWidgets('onDismissed roda em swipe/ação/tempo', (t) async {
    final c = ToastController();
    var n = 0;
    c.show(ToastRequest(
        variant: ToastVariant.info,
        message: 'a',
        onDismissed: () => n++,
        actionLabel: 'x',
        onAction: () {}));
    c.triggerAction();
    expect(n, 1);
    await t.pump(c.gap);
    c.show(ToastRequest(
        variant: ToastVariant.info, message: 'b', onDismissed: () => n++));
    await t.pump(const Duration(seconds: 3));
    expect(n, 2);
    await t.pump(c.gap);
  });
}
