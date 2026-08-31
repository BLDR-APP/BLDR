import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/models/subscription_plan.dart';

void main() {
  UserSubscription subscription(String status) => UserSubscription(
        id: 'subscription-1',
        userId: 'user-1',
        planId: '9bc1296d-8ee0-4a80-a2b0-5fc2c8a75e7a',
        status: status,
        billingPeriod: 'monthly',
        createdAt: DateTime.utc(2026, 8, 30),
        updatedAt: DateTime.utc(2026, 8, 30),
      );

  test('concede acesso Club para assinatura ativa ou em trial', () {
    expect(subscription('active').hasClubAccess, isTrue);
    expect(subscription('trialing').hasClubAccess, isTrue);
  });

  test('não usa planId textual e bloqueia status sem entitlement', () {
    expect(subscription('canceled').hasClubAccess, isFalse);
    expect(subscription('past_due').hasClubAccess, isFalse);
  });
}
