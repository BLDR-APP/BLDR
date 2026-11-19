import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/toast/toast_controller.dart';
import 'package:bldr_fitness/core/toast/toast_host.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

ToastRequest _r(String m,
        {String? key,
        ToastPriority p = ToastPriority.normal,
        Duration? d = const Duration(seconds: 3),
        VoidCallback? onAction}) =>
    ToastRequest(
        variant: onAction == null ? ToastVariant.success : ToastVariant.undo,
        message: m,
        dedupeKey: key,
        priority: p,
        duration: d,
        actionLabel: onAction == null ? null : 'Desfazer',
        onAction: onAction);

void main() {
  group('ToastController', () {
    testWidgets('mostra um por vez, na ordem de chegada', (t) async {
      final c = ToastController();
      c.show(_r('a'));
      c.show(_r('b'));
      expect(c.current!.message, 'a');
      expect(c.pending.map((e) => e.message), ['b']);
      await t.pump(const Duration(seconds: 3));
      expect(c.current, isNull); // intervalo de saída
      await t.pump(c.gap);
      expect(c.current!.message, 'b');
      await t.pump(const Duration(seconds: 4));
      c.dispose();
    });

    testWidgets('dedupe por chave visível ou na fila', (t) async {
      final c = ToastController();
      c.show(_r('a', key: 'k'));
      c.show(_r('a2', key: 'k'));
      c.show(_r('b', key: 'j'));
      c.show(_r('b2', key: 'j'));
      expect(c.pending.map((e) => e.message), ['b']);
      c.dispose();
    });

    testWidgets('prioridade alta passa à frente sem interromper', (t) async {
      final c = ToastController();
      c.show(_r('atual'));
      c.show(_r('n1'));
      c.show(_r('alta', p: ToastPriority.high));
      c.show(_r('n2'));
      expect(c.current!.message, 'atual');
      expect(c.pending.map((e) => e.message), ['alta', 'n1', 'n2']);
      c.dispose();
    });

    testWidgets('triggerAction fecha e executa o undo', (t) async {
      final c = ToastController();
      var undone = 0;
      c.show(_r('removido', onAction: () => undone++));
      c.triggerAction();
      expect(undone, 1);
      expect(c.current, isNull);
      await t.pump(c.gap);
      c.dispose();
    });

    testWidgets('persistente não expira; pausa segura a fila', (t) async {
      final c = ToastController();
      c.setPaused(true);
      c.show(_r('offline', d: null));
      expect(c.current, isNull);
      c.setPaused(false);
      expect(c.current!.message, 'offline');
      await t.pump(const Duration(minutes: 1));
      expect(c.current!.message, 'offline');
      c.dismiss(dedupeKey: null);
      expect(c.current, isNull);
      await t.pump(c.gap);
      c.dispose();
    });

    testWidgets('expanded sem duração explícita fica 5 s', (t) async {
      final c = ToastController();
      c.show(const ToastRequest(
          variant: ToastVariant.error,
          message: 'm',
          title: 't',
          description: 'd'));
      await t.pump(const Duration(seconds: 4));
      expect(c.current, isNotNull);
      await t.pump(const Duration(seconds: 1));
      expect(c.current, isNull);
      await t.pump(c.gap);
      c.dispose();
    });
  });

  group('ToastHost', () {
    Widget app(ToastController c, {bool paused = false}) => MaterialApp(
          locale: const Locale('pt'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (_, child) =>
              ToastHost(controller: c, paused: paused, child: child!),
          home: Scaffold(
            body: Center(
              child: ElevatedButton(onPressed: () {}, child: const Text('x')),
            ),
          ),
        );

    testWidgets('aparece sobre um sheet e o undo funciona', (t) async {
      final c = ToastController();
      var undone = false;
      await t.pumpWidget(app(c));
      showModalBottomSheet<void>(
          context: t.element(find.byType(Scaffold)),
          builder: (_) => const SizedBox(height: 300));
      await t.pumpAndSettle();
      c.show(_r('Alimento removido', onAction: () => undone = true));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Alimento removido'), findsOneWidget);
      await t.tap(find.text('Desfazer'));
      expect(undone, isTrue);
      await t.pumpAndSettle();
      expect(find.text('Alimento removido'), findsNothing);
    });

    testWidgets('swipe para cima dispensa', (t) async {
      final c = ToastController();
      await t.pumpWidget(app(c));
      c.show(_r('Oi', d: null));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.drag(find.text('Oi'), const Offset(0, -60));
      await t.pumpAndSettle();
      expect(c.current, isNull);
      expect(find.text('Oi'), findsNothing);
    });

    testWidgets('não intercepta toques fora do toast', (t) async {
      final c = ToastController();
      var tapped = false;
      await t.pumpWidget(MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (_, child) => ToastHost(controller: c, child: child!),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => tapped = true,
                child: const SizedBox(width: 12, height: 200)),
          ),
        ),
      ));
      c.show(_r('Curto', d: null));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.tapAt(const Offset(4, 30));
      expect(tapped, isTrue);
    });

    testWidgets('pausado segura a fila (conquista no topo)', (t) async {
      final c = ToastController();
      await t.pumpWidget(app(c, paused: true));
      c.show(_r('Depois'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Depois'), findsNothing);
      await t.pumpWidget(app(c));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Depois'), findsOneWidget);
      await t.pump(const Duration(seconds: 4));
    });
  });
}
