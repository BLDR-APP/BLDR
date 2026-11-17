import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/design_system/bldr_workout_hub_v2_components.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

void main() {
  group('paginateMyWorkouts', () {
    test('vazio não gera páginas', () {
      expect(paginateMyWorkouts(<int>[]), isEmpty);
    });
    test('4 itens cabem numa página', () {
      expect(paginateMyWorkouts([1, 2, 3, 4]), [
        [1, 2, 3, 4]
      ]);
    });
    test('5 itens geram 2 páginas, a segunda com 1', () {
      expect(paginateMyWorkouts([1, 2, 3, 4, 5]), [
        [1, 2, 3, 4],
        [5]
      ]);
    });
  });

  group('contagem de treinos (plural)', () {
    final pt = lookupAppLocalizations(const Locale('pt'));
    test('0, 1 e N', () {
      expect(pt.hub_count(0), '0 treinos');
      expect(pt.hub_count(1), '1 treino');
      expect(pt.hub_count(8), '8 treinos');
    });
    test('exercícios no card', () {
      expect(pt.hub_card_exercises(1), '1 exercício');
      expect(pt.hub_card_exercises(6), '6 exercícios');
    });
  });
}
