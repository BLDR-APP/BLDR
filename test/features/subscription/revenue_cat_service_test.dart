import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart' as rc_ui;

import 'package:bldr_fitness/features/subscription/data/datasources/revenue_cat_sdk_gateway.dart';
import 'package:bldr_fitness/features/subscription/data/repositories/revenue_cat_service_impl.dart';
import 'package:bldr_fitness/features/subscription/data/revenue_cat_config.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/revenue_cat_models.dart';

const userA = '194ff474-bf0e-455a-ba3c-e35706d2d9e3';
const userB = '4a4ed139-5f98-46b8-8648-b7f6dc8d628c';

void main() {
  group('RevenueCatService foundation', () {
    test('sem usuário não configura identidade anônima', () async {
      final gateway = FakeRevenueCatGateway();
      final service = createService(gateway);

      final result = await service.configure(null);

      expect(result.isSuccess, isTrue);
      expect(gateway.configureCalls, 0);
    });

    test('configura com UUID Supabase exato', () async {
      final gateway = FakeRevenueCatGateway();
      final service = createService(gateway);

      final result = await service.configure(userA);

      expect(result.isSuccess, isTrue);
      expect(gateway.configuredAppUserId, userA);
      expect(gateway.configuredApiKey, 'ios_public_key');
    });

    test('rejeita identidade que não seja UUID Supabase', () async {
      final gateway = FakeRevenueCatGateway();
      final service = createService(gateway);

      final result = await service.configure('email@exemplo.com');

      expect(result.isFailure, isTrue);
      expect(gateway.configureCalls, 0);
    });

    test('sessão A, limpeza local e sessão B usam logIn direto', () async {
      final gateway = FakeRevenueCatGateway(
        customerByUser: {
          userA: customerInfo(active: true, originalAppUserId: userA),
          userB: customerInfo(active: false, originalAppUserId: userB),
        },
      );
      final service = createService(gateway);

      await service.configure(userA);
      expect(
          (await service.getCustomerInfo()).valueOrNull?.hasClubAccess, isTrue);
      await service.clearSession();
      final userBInfo = await service.identify(userB);

      expect(gateway.sdkLogOutCalls, 0);
      expect(gateway.loginIds, [userB]);
      expect(userBInfo.valueOrNull?.appUserId, userB);
      expect(userBInfo.valueOrNull?.hasClubAccess, isFalse);
    });

    test('troca direta A para B não cria identidade anônima', () async {
      final gateway = FakeRevenueCatGateway();
      final service = createService(gateway);

      await service.configure(userA);
      final result = await service.configure(userB);

      expect(result.isSuccess, isTrue);
      expect(gateway.loginIds, [userB]);
      expect(gateway.currentId, userB);
      expect(gateway.sdkLogOutCalls, 0);
    });

    test('ignora atualização atrasada da identidade anterior', () async {
      final gateway = FakeRevenueCatGateway(
        customerByUser: {
          userA: customerInfo(active: true, originalAppUserId: userA),
          userB: customerInfo(active: false, originalAppUserId: userB),
        },
      );
      final service = createService(gateway);
      final updates = <RevenueCatCustomerInfo>[];
      final subscription = service.customerInfoUpdates.listen(updates.add);

      await service.configure(userA);
      await service.configure(userB);
      updates.clear();
      gateway.listener!(
        customerInfo(active: true, originalAppUserId: userA),
      );

      await Future<void>.delayed(Duration.zero);
      expect(updates, isEmpty);
      await subscription.cancel();
    });

    test('falha fechado quando CustomerInfo não pertence ao usuário atual',
        () async {
      final gateway = FakeRevenueCatGateway(
        customerByUser: {
          userA: customerInfo(active: true, originalAppUserId: userB),
        },
      );
      final service = createService(gateway);
      await service.configure(userA);

      final result = await service.getCustomerInfo();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('identidade'));
    });

    test('sem sessão limpa cache e bloqueia ações de compra', () async {
      final gateway = FakeRevenueCatGateway(
        offerings: offeringsWithCommercialPackages(),
      );
      final service = createService(gateway);

      await service.configure(userA);
      await service.getOfferings();
      await service.clearSession();
      final result = await service.getOfferings();

      expect(result.isFailure, isTrue);
      expect(gateway.sdkLogOutCalls, 0);
      expect(gateway.currentId, userA);
    });

    test('getOfferings expõe weekly, monthly e annual com preço localizado',
        () async {
      final gateway = FakeRevenueCatGateway(
        offerings: offeringsWithCommercialPackages(),
      );
      final service = createService(gateway);
      await service.configure(userA);

      final offering = (await service.getOfferings()).valueOrNull;

      expect(offering?.packages, hasLength(3));
      expect(
        offering?.packageFor(RevenueCatPackagePeriod.weekly)?.localizedPrice,
        r'R$ 6,90',
      );
      expect(
        offering
            ?.packageFor(RevenueCatPackagePeriod.monthly)
            ?.productIdentifier,
        'bldr_monthly',
      );
      expect(
        offering?.packageFor(RevenueCatPackagePeriod.annual)?.currencyCode,
        'BRL',
      );
    });

    test('Offering ausente retorna sucesso nulo', () async {
      final gateway = FakeRevenueCatGateway(
        offerings: const rc.Offerings({}, current: null),
      );
      final service = createService(gateway);
      await service.configure(userA);

      final result = await service.getOfferings();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('entitlement bldr_club ativo concede leitura RevenueCat', () async {
      final gateway = FakeRevenueCatGateway(
        customerByUser: {
          userA: customerInfo(active: true, originalAppUserId: userA),
        },
      );
      final service = createService(gateway);
      await service.configure(userA);

      expect((await service.entitlementActive()).valueOrNull, isTrue);
    });

    test('entitlement ausente não concede leitura RevenueCat', () async {
      final gateway = FakeRevenueCatGateway();
      final service = createService(gateway);
      await service.configure(userA);

      expect((await service.entitlementActive()).valueOrNull, isFalse);
    });

    test('restore é explícito e devolve CustomerInfo atualizado', () async {
      final gateway = FakeRevenueCatGateway(
        restoreInfo: customerInfo(active: true, originalAppUserId: userA),
      );
      final service = createService(gateway);
      await service.configure(userA);

      final result = await service.restorePurchases();

      expect(gateway.restoreCalls, 1);
      expect(result.valueOrNull?.hasClubAccess, isTrue);
    });

    test('registra impressão customizada somente com SDK identificado',
        () async {
      final gateway = FakeRevenueCatGateway();
      final service = createService(gateway);
      await service.configure(userA);

      final result = await service.trackCustomPaywallImpression();

      expect(result.isSuccess, isTrue);
      expect(gateway.customPaywallImpressionCalls, 1);
    });

    test('cancelamento de compra é resultado controlado, não Failure',
        () async {
      final gateway = FakeRevenueCatGateway(
        offerings: offeringsWithCommercialPackages(),
        purchaseError: PlatformException(
          code: '${rc.PurchasesErrorCode.purchaseCancelledError.index}',
        ),
      );
      final service = createService(gateway);
      await service.configure(userA);
      final offering = (await service.getOfferings()).valueOrNull!;

      final result = await service.purchasePackage(offering.packages.first);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.status, RevenueCatPurchaseStatus.cancelled);
    });

    test('pagamento pendente não concede acesso antecipadamente', () async {
      final gateway = FakeRevenueCatGateway(
        offerings: offeringsWithCommercialPackages(),
        purchaseError: PlatformException(
          code: '${rc.PurchasesErrorCode.paymentPendingError.index}',
        ),
      );
      final service = createService(gateway);
      await service.configure(userA);
      final offering = (await service.getOfferings()).valueOrNull!;

      final result = await service.purchasePackage(offering.packages.first);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.status, RevenueCatPurchaseStatus.pending);
      expect(result.valueOrNull?.customerInfo, isNull);
    });

    test('compra concluída devolve CustomerInfo atualizado', () async {
      final gateway = FakeRevenueCatGateway(
        offerings: offeringsWithCommercialPackages(),
        purchaseInfo: customerInfo(active: true, originalAppUserId: userA),
      );
      final service = createService(gateway);
      await service.configure(userA);
      final offering = (await service.getOfferings()).valueOrNull!;

      final result = await service.purchasePackage(offering.packages.first);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.status, RevenueCatPurchaseStatus.success);
      expect(result.valueOrNull?.customerInfo?.hasClubAccess, isTrue);
    });

    test('erro da store vira Failure em pt-BR', () async {
      final gateway = FakeRevenueCatGateway(
        offerings: offeringsWithCommercialPackages(),
        purchaseError: PlatformException(
          code: '${rc.PurchasesErrorCode.storeProblemError.index}',
        ),
      );
      final service = createService(gateway);
      await service.configure(userA);
      final offering = (await service.getOfferings()).valueOrNull!;

      final result = await service.purchasePackage(offering.packages.first);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('assinatura'));
    });

    test('sync de migração exige elegibilidade explícita', () async {
      final gateway = FakeRevenueCatGateway();
      final service = createService(gateway);
      await service.configure(userA);

      final denied = await service.syncPurchasesForMigration(eligible: false);
      final allowed = await service.syncPurchasesForMigration(eligible: true);

      expect(denied.isFailure, isTrue);
      expect(gateway.syncCalls, 1);
      expect(allowed.isSuccess, isTrue);
    });

    test('feature flag OFF preserva billing atual e não chama SDK', () async {
      final gateway = FakeRevenueCatGateway();
      final service = createService(gateway, enabled: false);

      final configured = await service.configure(userA);
      final identified = await service.identify(userA);

      expect(configured.isSuccess, isTrue);
      expect(identified.isSuccess, isTrue);
      expect(identified.valueOrNull?.hasClubAccess, isFalse);
      expect(gateway.configureCalls, 0);
      expect(gateway.loginIds, isEmpty);
    });

    test('Android sem chave pública falha fechado antes de configurar o SDK',
        () async {
      final gateway =
          FakeRevenueCatGateway(platform: RevenueCatPlatform.android);
      final service = createService(gateway, androidKey: '');

      final configured = await service.configure(userA);

      expect(configured.isFailure, isTrue);
      expect(gateway.configureCalls, 0);
    });

    test('iOS sem chave pública falha fechado antes de configurar o SDK',
        () async {
      final gateway = FakeRevenueCatGateway(platform: RevenueCatPlatform.ios);
      final service = createService(gateway, iosKey: '');

      final configured = await service.configure(userA);

      expect(configured.isFailure, isTrue);
      expect(gateway.configureCalls, 0);
    });
  });
}

RevenueCatServiceImpl createService(
  FakeRevenueCatGateway gateway, {
  bool enabled = true,
  String iosKey = 'ios_public_key',
  String androidKey = 'android_public_key',
}) =>
    RevenueCatServiceImpl(
      gateway,
      RevenueCatConfig(
        billingEnabled: enabled,
        iosPublicSdkKey: iosKey,
        androidPublicSdkKey: androidKey,
      ),
    );

rc.CustomerInfo customerInfo({
  required bool active,
  required String originalAppUserId,
}) {
  final entitlement = rc.EntitlementInfo(
    'bldr_club',
    active,
    true,
    '2026-08-30T00:00:00Z',
    '2026-08-30T00:00:00Z',
    'bldr_club_monthly',
    true,
  );
  final activeEntitlements =
      active ? {'bldr_club': entitlement} : <String, rc.EntitlementInfo>{};
  return rc.CustomerInfo(
    rc.EntitlementInfos({'bldr_club': entitlement}, activeEntitlements),
    const {},
    const [],
    const [],
    const [],
    '2026-08-30T00:00:00Z',
    originalAppUserId,
    const {},
    '2026-08-30T00:00:00Z',
  );
}

rc.Offerings offeringsWithCommercialPackages() {
  final context = rc.PresentedOfferingContext('current', null, null);
  rc.Package package(
    String id,
    rc.PackageType type,
    String productId,
    String price,
  ) =>
      rc.Package(
        id,
        type,
        rc.StoreProduct(
          productId,
          'BLDR Club',
          'BLDR Club',
          1,
          price,
          'BRL',
          presentedOfferingContext: context,
        ),
        context,
      );
  final packages = [
    package(r'$rc_weekly', rc.PackageType.weekly, 'bldr_weekly', r'R$ 6,90'),
    package(
        r'$rc_monthly', rc.PackageType.monthly, 'bldr_monthly', r'R$ 29,90'),
    package(r'$rc_annual', rc.PackageType.annual, 'bldr_annual', r'R$ 149,90'),
  ];
  final offering = rc.Offering('current', 'Current', const {}, packages);
  return rc.Offerings({'current': offering}, current: offering);
}

class FakeRevenueCatGateway implements RevenueCatSdkGateway {
  final Map<String, rc.CustomerInfo> customerByUser;
  final rc.Offerings offerings;
  final rc.CustomerInfo? restoreInfo;
  final rc.CustomerInfo? purchaseInfo;
  final Object? purchaseError;
  final RevenueCatPlatform _platform;

  bool configured = false;
  String currentId = r'$RCAnonymous:test';
  int configureCalls = 0;
  int sdkLogOutCalls = 0;
  int restoreCalls = 0;
  int syncCalls = 0;
  int customPaywallImpressionCalls = 0;
  String? configuredApiKey;
  String? configuredAppUserId;
  final List<String> loginIds = [];
  rc.CustomerInfoUpdateListener? listener;

  FakeRevenueCatGateway({
    Map<String, rc.CustomerInfo>? customerByUser,
    rc.Offerings? offerings,
    this.restoreInfo,
    this.purchaseInfo,
    this.purchaseError,
    RevenueCatPlatform platform = RevenueCatPlatform.ios,
  })  : customerByUser = customerByUser ?? {},
        offerings = offerings ?? const rc.Offerings({}, current: null),
        _platform = platform;

  @override
  RevenueCatPlatform get platform => _platform;

  rc.CustomerInfo get currentInfo =>
      customerByUser[currentId] ??
      customerInfo(active: false, originalAppUserId: currentId);

  @override
  Future<bool> isConfigured() async => configured;

  @override
  Future<void> configure(
      {required String apiKey, required String appUserId}) async {
    configureCalls++;
    configured = true;
    configuredApiKey = apiKey;
    configuredAppUserId = appUserId;
    currentId = appUserId;
  }

  @override
  Future<String> currentAppUserId() async => currentId;

  @override
  Future<rc.LogInResult> logIn(String appUserId) async {
    loginIds.add(appUserId);
    currentId = appUserId;
    return rc.LogInResult(customerInfo: currentInfo, created: false);
  }

  @override
  Future<rc.CustomerInfo> getCustomerInfo() async => currentInfo;

  @override
  Future<rc.Offerings> getOfferings() async => offerings;

  @override
  Future<rc.PurchaseResult> purchase(rc.Package package) async {
    if (purchaseError != null) throw purchaseError!;
    return rc.PurchaseResult(
      purchaseInfo ?? currentInfo,
      rc.StoreTransaction(
        'transaction-id',
        package.storeProduct.identifier,
        '2026-08-30T00:00:00Z',
      ),
    );
  }

  @override
  Future<rc.CustomerInfo> restorePurchases() async {
    restoreCalls++;
    return restoreInfo ?? currentInfo;
  }

  @override
  Future<void> syncPurchases() async {
    syncCalls++;
  }

  @override
  Future<void> trackCustomPaywallImpression() async {
    customPaywallImpressionCalls++;
  }

  @override
  Future<void> presentOfferCodeRedemption() async {}

  @override
  Future<rc_ui.PaywallResult> presentPaywall() async =>
      rc_ui.PaywallResult.notPresented;

  @override
  void addCustomerInfoListener(rc.CustomerInfoUpdateListener listener) {
    this.listener = listener;
  }
}
