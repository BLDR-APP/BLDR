enum RevenueCatPackagePeriod { weekly, monthly, annual }

class RevenueCatPackage {
  final String identifier;
  final String productIdentifier;
  final RevenueCatPackagePeriod period;
  final String localizedPrice;
  final String currencyCode;

  const RevenueCatPackage({
    required this.identifier,
    required this.productIdentifier,
    required this.period,
    required this.localizedPrice,
    required this.currencyCode,
  });
}

class RevenueCatOffering {
  final String identifier;
  final List<RevenueCatPackage> packages;

  const RevenueCatOffering({
    required this.identifier,
    required this.packages,
  });

  RevenueCatPackage? packageFor(RevenueCatPackagePeriod period) {
    for (final package in packages) {
      if (package.period == period) return package;
    }
    return null;
  }
}

class RevenueCatCustomerInfo {
  final String? appUserId;
  final bool hasClubAccess;

  const RevenueCatCustomerInfo({
    required this.appUserId,
    required this.hasClubAccess,
  });
}

enum RevenueCatPurchaseStatus { success, cancelled, pending }

class RevenueCatPurchaseResult {
  final RevenueCatPurchaseStatus status;
  final RevenueCatCustomerInfo? customerInfo;

  const RevenueCatPurchaseResult({
    required this.status,
    this.customerInfo,
  });
}

enum RevenueCatPaywallResult {
  notPresented,
  cancelled,
  purchased,
  restored,
  error,
}
