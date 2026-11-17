import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/workouts/domain/entities/workout_share_data.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_summary_data.dart';
import 'package:bldr_fitness/features/workouts/presentation/share/workout_share_v2_templates.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

void main() {
  final data = WorkoutShareData.fromSummary(
    WorkoutSummaryData(
      workoutId: 'w',
      workoutName: 'Pull A',
      source: 'free',
      durationSeconds: 2852,
      volumeKg: 8420,
      setsCompleted: 14,
      muscleGroups: const [],
      newPRs: const [],
      xpEarned: 0,
      completedAt: DateTime(2026, 9, 14),
    ),
    username: 'bldrapp',
  );

  Widget host(Widget child) => MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Center(child: SizedBox(width: 216, child: child)),
      );

  for (final (name, widget) in [
    ('overlay', WorkoutShareOverlayV2(data: data)),
    ('card', WorkoutShareCardV2(data: data)),
  ]) {
    testWidgets('$name em 9:16 com métricas e @usuário', (tester) async {
      await tester.pumpWidget(host(widget));
      final size = tester.getSize(find.byWidget(widget));
      expect(size.width / size.height, closeTo(9 / 16, 0.001));
      expect(find.text('47:32'), findsOneWidget);
      expect(find.text('@bldrapp'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
