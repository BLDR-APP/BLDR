import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/nutrition/domain/services/food_search_matcher.dart';

void main() {
  const names = [
    'Azeite de Oliva (Extra Virgem)',
    'Arroz Integral Cozido',
    'Feijão Carioca',
    'Pão Francês',
    'Café com leite',
    'Leite integral',
  ];

  test('ignora maiúsculas/minúsculas', () {
    expect(FoodSearchMatcher.match(names, 'AZEITE'), [0]);
    expect(FoodSearchMatcher.match(names, 'azeite'), [0]);
    expect(FoodSearchMatcher.match(names, 'aRrOz'), [1]);
  });

  test('ignora acentos nos dois lados', () {
    expect(FoodSearchMatcher.match(names, 'feijao'), [2]);
    expect(FoodSearchMatcher.match(names, 'PAO FRANCES'), [3]);
    expect(FoodSearchMatcher.match(names, 'cafe'), [4]);
  });

  test('várias palavras em qualquer ordem; prefixo primeiro', () {
    expect(FoodSearchMatcher.match(names, 'integral arroz'), [1]);
    // "Leite integral" começa com "leite" → antes de "Café com leite".
    expect(FoodSearchMatcher.match(names, 'leite'), [5, 4]);
  });

  test('vazio e limite', () {
    expect(FoodSearchMatcher.match(names, '   '), isEmpty);
    expect(FoodSearchMatcher.match(names, 'a', limit: 2), hasLength(2));
  });

  test('normalize', () {
    expect(FoodSearchMatcher.normalize('  ÁGUA  de  Côco '), 'agua de coco');
  });
}
