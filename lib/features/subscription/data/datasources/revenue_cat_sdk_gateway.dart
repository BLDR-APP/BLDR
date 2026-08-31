import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:bldr_fitness/features/subscription/data/revenue_cat_config.dart';

abstract class RevenueCatSdkGateway {
  RevenueCatPlatform get platform;
  Future<bool> isConfigured();
  Future<void> configure({required String apiKey, required String appUserId});
  Future<String> currentAppUserId();
  Future<rc.LogInResult> logIn(String appUserId);
  Future<rc.CustomerInfo> getCustomerInfo();
  Future<rc.Offerings> getOfferings();
  Future<rc.PurchaseResult> purchase(rc.Package package);
  Future<rc.CustomerInfo> restorePurchases();
  Future<void> syncPurchases();
  Future<void> trackCustomPaywallImpression();
  Future<void> presentOfferCodeRedemption();
  Future<PaywallResult> presentPaywall();
  void addCustomerInfoListener(rc.CustomerInfoUpdateListener listener);
}

class PurchasesRevenueCatSdkGateway implements RevenueCatSdkGateway {
  @override
  RevenueCatPlatform get platform {
    if (kIsWeb) return RevenueCatPlatform.unsupported;
    if (Platform.isIOS) return RevenueCatPlatform.ios;
    if (Platform.isAndroid) return RevenueCatPlatform.android;
    return RevenueCatPlatform.unsupported;
  }

  @override
  Future<bool> isConfigured() => rc.Purchases.isConfigured;

  @override
  Future<void> configure({required String apiKey, required String appUserId}) {
    final configuration = rc.PurchasesConfiguration(apiKey)
      ..appUserID = appUserId
      ..pendingTransactionsForPrepaidPlansEnabled = true;
    return rc.Purchases.configure(configuration);
  }

  @override
  Future<String> currentAppUserId() => rc.Purchases.appUserID;

  @override
  Future<rc.LogInResult> logIn(String appUserId) =>
      rc.Purchases.logIn(appUserId);

  @override
  Future<rc.CustomerInfo> getCustomerInfo() => rc.Purchases.getCustomerInfo();

  @override
  Future<rc.Offerings> getOfferings() => rc.Purchases.getOfferings();

  @override
  Future<rc.PurchaseResult> purchase(rc.Package package) =>
      rc.Purchases.purchase(rc.PurchaseParams.package(package));

  @override
  Future<rc.CustomerInfo> restorePurchases() => rc.Purchases.restorePurchases();

  @override
  Future<void> syncPurchases() => rc.Purchases.syncPurchases();

  @override
  Future<void> trackCustomPaywallImpression() =>
      rc.Purchases.trackCustomPaywallImpression();

  @override
  Future<void> presentOfferCodeRedemption() =>
      rc.Purchases.presentCodeRedemptionSheet();

  @override
  Future<PaywallResult> presentPaywall() => RevenueCatUI.presentPaywall(
        displayCloseButton: true,
      );

  @override
  void addCustomerInfoListener(rc.CustomerInfoUpdateListener listener) =>
      rc.Purchases.addCustomerInfoUpdateListener(listener);
}

rc.PurchasesErrorCode revenueCatErrorCode(Object error) {
  if (error is! PlatformException) return rc.PurchasesErrorCode.unknownError;
  return rc.PurchasesErrorHelper.getErrorCode(error);
}
