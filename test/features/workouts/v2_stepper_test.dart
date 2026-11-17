import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';

void main() {
  group('BldrV2Stepper.format', () {
    test('inteiro sem decimal', () {
      expect(BldrV2Stepper.format(30, decimal: true), '30');
      expect(BldrV2Stepper.format(10), '10');
    });
    test('decimal com vírgula', () {
      expect(BldrV2Stepper.format(32.5, decimal: true), '32,5');
    });
  });

  group('BldrV2Stepper.parse', () {
    test('aceita vírgula e ponto', () {
      expect(BldrV2Stepper.parse('32,5'), 32.5);
      expect(BldrV2Stepper.parse(' 40.0 '), 40.0);
    });
    test('inválido vira null', () {
      expect(BldrV2Stepper.parse(''), isNull);
      expect(BldrV2Stepper.parse('abc'), isNull);
    });
  });
}
