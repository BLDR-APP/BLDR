import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/connectivity/connectivity_repository.dart';
import 'package:bldr_fitness/core/toast/connectivity_toast_listener.dart';
import 'package:bldr_fitness/core/toast/toast_controller.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class _FakeConnectivity implements ConnectivityRepository {
  _FakeConnectivity({this.initial = true});
  final bool initial;
  final _ctrl = StreamController<bool>.broadcast();
  void emit(bool v) => _ctrl.add(v);
  @override
  Future<bool> isOnline() async => initial;
  @override
  Stream<bool> onlineChanges() => _ctrl.stream;
}

Widget _app(ConnectivityRepository r, ToastController c) => MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (_, child) => ConnectivityToastListener(
          repository: r, controller: c, child: child!),
      home: const SizedBox(),
    );

void main() {
  testWidgets('offline vira toast persistente; volta → info', (t) async {
    final r = _FakeConnectivity();
    final c = ToastController();
    await t.pumpWidget(_app(r, c));
    r.emit(false);
    await t.pump(const Duration(seconds: 2));
    expect(c.current?.variant, ToastVariant.offline);
    expect(c.current?.message, 'Você está offline');
    expect(c.current?.duration, isNull);
    await t.pump(const Duration(minutes: 1));
    expect(c.current?.variant, ToastVariant.offline);
    r.emit(true);
    await t.pump(const Duration(seconds: 2));
    expect(c.current, isNull);
    await t.pump(c.gap);
    expect(c.current?.message, 'Conexão restabelecida');
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('oscilação curta não gera toast', (t) async {
    final r = _FakeConnectivity();
    final c = ToastController();
    await t.pumpWidget(_app(r, c));
    r.emit(false);
    await t.pump(const Duration(milliseconds: 500));
    r.emit(true);
    await t.pump(const Duration(seconds: 3));
    expect(c.current, isNull);
    expect(c.pending, isEmpty);
  });

  testWidgets('abre o app já offline', (t) async {
    final r = _FakeConnectivity(initial: false);
    final c = ToastController();
    await t.pumpWidget(_app(r, c));
    await t.pump(const Duration(seconds: 2));
    expect(c.current?.variant, ToastVariant.offline);
  });

  testWidgets('online inicial não mostra nada', (t) async {
    final r = _FakeConnectivity();
    final c = ToastController();
    await t.pumpWidget(_app(r, c));
    r.emit(true);
    await t.pump(const Duration(seconds: 3));
    expect(c.current, isNull);
  });
}
