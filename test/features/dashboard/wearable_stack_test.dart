import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/wearable_card_state.dart';

void main() {
  group('resolveWhoopCardState', () {
    test('não verificado → unknown', () {
      expect(
        resolveWhoopCardState(
            checked: false, connected: true, syncing: false, hasData: true),
        WhoopCardState.unknown,
      );
    });
    test('sem conexão → disconnected', () {
      expect(
        resolveWhoopCardState(
            checked: true, connected: false, syncing: false, hasData: false),
        WhoopCardState.disconnected,
      );
    });
    test('sincronizando → syncing', () {
      expect(
        resolveWhoopCardState(
            checked: true, connected: true, syncing: true, hasData: false),
        WhoopCardState.syncing,
      );
    });
    test('sincronizou sem valores → unavailable (antes: skeleton infinito)',
        () {
      expect(
        resolveWhoopCardState(
            checked: true, connected: true, syncing: false, hasData: false),
        WhoopCardState.unavailable,
      );
    });
    test('com dados → data', () {
      expect(
        resolveWhoopCardState(
            checked: true, connected: true, syncing: false, hasData: true),
        WhoopCardState.data,
      );
    });
  });

  group('wearableStackOrder', () {
    test('ciclo a partir da frente', () {
      expect(wearableStackOrder(3, 0), [0, 1, 2]);
      expect(wearableStackOrder(3, 1), [1, 2, 0]);
      expect(wearableStackOrder(3, 2), [2, 0, 1]);
    });
    test('um card volta sempre para a frente', () {
      expect(wearableStackOrder(1, 0), [0]);
    });
  });

  test('camadas: mínimo 3, quatro com 4+ cards', () {
    expect(wearableStackLayerCount(1), 3);
    expect(wearableStackLayerCount(3), 3);
    expect(wearableStackLayerCount(4), 4);
    expect(wearableStackLayerCount(7), 4);
  });
}
