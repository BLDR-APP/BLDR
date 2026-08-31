import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/subscription/domain/entities/revenue_cat_models.dart';
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';

void main() {
  RevenueCatPackage package(RevenueCatPackagePeriod period) =>
      RevenueCatPackage(
        identifier: r'$rc_${period.name}',
        productIdentifier: 'bldr_club_${period.name}',
        period: period,
        localizedPrice: 'localized-${period.name}',
        currencyCode: 'BRL',
      );

  test('ordena packages disponíveis anual, mensal e semanal', () {
    final packages = {
      RevenueCatPackagePeriod.weekly: package(RevenueCatPackagePeriod.weekly),
      RevenueCatPackagePeriod.annual: package(RevenueCatPackagePeriod.annual),
      RevenueCatPackagePeriod.monthly: package(RevenueCatPackagePeriod.monthly),
    };

    expect(
      ClubPaywallPlanLayout.availablePeriods(packages),
      [
        RevenueCatPackagePeriod.annual,
        RevenueCatPackagePeriod.monthly,
        RevenueCatPackagePeriod.weekly,
      ],
    );
    expect(
      ClubPaywallPlanLayout.defaultPeriod(packages),
      RevenueCatPackagePeriod.annual,
    );
  });

  test('faz fallback de seleção sem renderizar package ausente', () {
    final monthlyOnly = {
      RevenueCatPackagePeriod.monthly: package(RevenueCatPackagePeriod.monthly),
    };
    final weeklyOnly = {
      RevenueCatPackagePeriod.weekly: package(RevenueCatPackagePeriod.weekly),
    };

    expect(
      ClubPaywallPlanLayout.availablePeriods(monthlyOnly),
      [RevenueCatPackagePeriod.monthly],
    );
    expect(
      ClubPaywallPlanLayout.defaultPeriod(monthlyOnly),
      RevenueCatPackagePeriod.monthly,
    );
    expect(
      ClubPaywallPlanLayout.defaultPeriod(weeklyOnly),
      RevenueCatPackagePeriod.weekly,
    );
  });
}
