import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/subscription/data/revenue_cat_config.dart';

void main() {
  test('configuração de release usa flag e chave específicas da plataforma',
      () {
    final config = RevenueCatConfig.fromMap({
      'REVENUECAT_BILLING_ENABLED': 'true',
      'REVENUECAT_IOS_PUBLIC_SDK_KEY': 'ios_public_key',
      'REVENUECAT_ANDROID_PUBLIC_SDK_KEY': 'android_public_key',
    });

    expect(config.billingEnabled, isTrue);
    expect(config.keyFor(RevenueCatPlatform.ios), 'ios_public_key');
    expect(config.keyFor(RevenueCatPlatform.android), 'android_public_key');
    expect(config.keyFor(RevenueCatPlatform.unsupported), isEmpty);
  });
}
