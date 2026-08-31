import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart' as rc_ui;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/subscription/data/datasources/revenue_cat_sdk_gateway.dart';
import 'package:bldr_fitness/features/subscription/data/revenue_cat_config.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/revenue_cat_models.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/revenue_cat_service.dart';

class RevenueCatServiceImpl implements RevenueCatService {
  final RevenueCatSdkGateway _gateway;
  final RevenueCatConfig _config;
  final StreamController<RevenueCatCustomerInfo> _updates =
      StreamController<RevenueCatCustomerInfo>.broadcast();
  final Map<String, rc.Package> _packages = {};

  Future<void> _serial = Future<void>.value();
  bool _configured = false;
  bool _listenerAttached = false;
  String? _identifiedUserId;

  RevenueCatServiceImpl(this._gateway, this._config);

  @override
  bool get billingEnabled => _config.billingEnabled;

  @override
  bool get supportsAppleMigration =>
      _gateway.platform == RevenueCatPlatform.ios;

  @override
  Stream<RevenueCatCustomerInfo> get customerInfoUpdates => _updates.stream;

  @override
  Future<Result<void>> configure(String? supabaseUserId) => _enqueue(() async {
        if (!billingEnabled) return const Result.success(null);
        if (supabaseUserId == null) {
          _clearLocalSession();
          _safeLog('RevenueCat aguardando sessão Supabase.');
          return const Result.success(null);
        }
        final validation = _validateUserId(supabaseUserId);
        if (validation != null) return Result.failure(validation);

        try {
          _configured = await _gateway.isConfigured();
          if (!_configured) {
            final apiKey = _config.keyFor(_gateway.platform);
            if (apiKey.isEmpty) {
              return const Result.failure(ValidationFailure(
                'RevenueCat não está configurado para esta plataforma.',
              ));
            }
            await _gateway.configure(apiKey: apiKey, appUserId: supabaseUserId);
            _configured = true;
            _identifiedUserId = supabaseUserId;
            _attachListener();
            _safeLog('RevenueCat configured; App User ID Supabase associado.');
            return const Result.success(null);
          }

          _attachListener();
          final currentId = await _gateway.currentAppUserId();
          if (currentId != supabaseUserId) {
            _clearLocalSession();
            final result = await _gateway.logIn(supabaseUserId);
            _identifiedUserId = supabaseUserId;
            _emit(result.customerInfo);
          } else {
            _identifiedUserId = supabaseUserId;
          }
          _safeLog('RevenueCat App User ID Supabase associado.');
          return const Result.success(null);
        } catch (error) {
          return Result.failure(_failureFor(error));
        }
      });

  @override
  Future<Result<RevenueCatCustomerInfo>> identify(String supabaseUserId) =>
      _enqueue(() async {
        if (!billingEnabled) {
          return Result.success(RevenueCatCustomerInfo(
            appUserId: supabaseUserId,
            hasClubAccess: false,
          ));
        }
        final configured = await _configureInsideQueue(supabaseUserId);
        if (configured != null) return Result.failure(configured);
        try {
          final currentId = await _gateway.currentAppUserId();
          final rc.CustomerInfo customerInfo;
          if (currentId == supabaseUserId) {
            customerInfo = await _gateway.getCustomerInfo();
          } else {
            _clearLocalSession();
            customerInfo = (await _gateway.logIn(supabaseUserId)).customerInfo;
          }
          _identifiedUserId = supabaseUserId;
          final identityFailure = _customerInfoIdentityFailure(customerInfo);
          if (identityFailure != null) return Result.failure(identityFailure);
          return Result.success(_mapCustomerInfo(customerInfo));
        } catch (error) {
          return Result.failure(_failureFor(error));
        }
      });

  @override
  Future<Result<RevenueCatCustomerInfo>> getCustomerInfo() =>
      _enqueue(() async {
        final ready = _requireReady();
        if (ready != null) return Result.failure(ready);
        try {
          final customerInfo = await _gateway.getCustomerInfo();
          final identityFailure = _customerInfoIdentityFailure(customerInfo);
          if (identityFailure != null) return Result.failure(identityFailure);
          return Result.success(_mapCustomerInfo(customerInfo));
        } catch (error) {
          return Result.failure(_failureFor(error));
        }
      });

  @override
  Future<Result<RevenueCatOffering?>> getOfferings() => _enqueue(() async {
        final ready = _requireReady();
        if (ready != null) return Result.failure(ready);
        try {
          final offerings = await _gateway.getOfferings();
          final current = offerings.current;
          if (current == null) {
            _safeLog('RevenueCat: nenhum Offering atual encontrado.');
            return const Result.success(null);
          }
          _packages.clear();
          final mapped = <RevenueCatPackage>[];
          for (final package in current.availablePackages) {
            final period = _mapPeriod(package.packageType);
            if (period == null) continue;
            _packages[package.identifier] = package;
            mapped.add(RevenueCatPackage(
              identifier: package.identifier,
              productIdentifier: package.storeProduct.identifier,
              period: period,
              localizedPrice: package.storeProduct.priceString,
              currencyCode: package.storeProduct.currencyCode,
            ));
          }
          _safeLog(
              'RevenueCat Offering encontrado; ${mapped.length} packages comerciais.');
          return Result.success(RevenueCatOffering(
            identifier: current.identifier,
            packages: mapped,
          ));
        } catch (error) {
          return Result.failure(_failureFor(error));
        }
      });

  @override
  Future<Result<RevenueCatPurchaseResult>> purchasePackage(
          RevenueCatPackage package) =>
      _enqueue(() async {
        final ready = _requireReady();
        if (ready != null) return Result.failure(ready);
        final sdkPackage = _packages[package.identifier];
        if (sdkPackage == null) {
          return const Result.failure(ValidationFailure(
            'Atualize as opções de assinatura e tente novamente.',
          ));
        }
        try {
          final result = await _gateway.purchase(sdkPackage);
          final identityFailure =
              _customerInfoIdentityFailure(result.customerInfo);
          if (identityFailure != null) return Result.failure(identityFailure);
          final customerInfo = _mapCustomerInfo(result.customerInfo);
          _updates.add(customerInfo);
          return Result.success(RevenueCatPurchaseResult(
            status: RevenueCatPurchaseStatus.success,
            customerInfo: customerInfo,
          ));
        } catch (error) {
          final code = revenueCatErrorCode(error);
          if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
            return const Result.success(RevenueCatPurchaseResult(
              status: RevenueCatPurchaseStatus.cancelled,
            ));
          }
          if (code == rc.PurchasesErrorCode.paymentPendingError) {
            return const Result.success(RevenueCatPurchaseResult(
              status: RevenueCatPurchaseStatus.pending,
            ));
          }
          return Result.failure(_failureFor(error));
        }
      });

  @override
  Future<Result<RevenueCatCustomerInfo>> restorePurchases() =>
      _enqueue(() async {
        final ready = _requireReady();
        if (ready != null) return Result.failure(ready);
        try {
          final customerInfo = await _gateway.restorePurchases();
          final identityFailure = _customerInfoIdentityFailure(customerInfo);
          if (identityFailure != null) return Result.failure(identityFailure);
          final mapped = _mapCustomerInfo(customerInfo);
          _updates.add(mapped);
          _safeLog('RevenueCat restore concluído; entitlement atualizado.');
          return Result.success(mapped);
        } catch (error) {
          return Result.failure(_failureFor(error));
        }
      });

  @override
  Future<Result<void>> trackCustomPaywallImpression() => _enqueue(() async {
        final ready = _requireReady();
        if (ready != null) return Result.failure(ready);
        try {
          await _gateway.trackCustomPaywallImpression();
          return const Result.success(null);
        } catch (error) {
          return Result.failure(_failureFor(error));
        }
      });

  @override
  Future<Result<RevenueCatCustomerInfo>> syncPurchasesForMigration({
    required bool eligible,
  }) =>
      _enqueue(() async {
        if (!eligible) {
          return const Result.failure(ValidationFailure(
            'Usuário não elegível para sincronização de migração.',
          ));
        }
        final ready = _requireReady();
        if (ready != null) return Result.failure(ready);
        try {
          await _gateway.syncPurchases();
          final customerInfo = await _gateway.getCustomerInfo();
          final identityFailure = _customerInfoIdentityFailure(customerInfo);
          if (identityFailure != null) return Result.failure(identityFailure);
          final mapped = _mapCustomerInfo(customerInfo);
          _updates.add(mapped);
          _safeLog('RevenueCat migration sync concluído.');
          return Result.success(mapped);
        } catch (error) {
          return Result.failure(_failureFor(error));
        }
      });

  @override
  Future<Result<bool>> entitlementActive() async {
    final result = await getCustomerInfo();
    return result.map((info) => info.hasClubAccess);
  }

  @override
  Future<Result<void>> clearSession() => _enqueue(() async {
        _clearLocalSession();
        _safeLog('RevenueCat: contexto local da sessão BLDR limpo.');
        return const Result.success(null);
      });

  @override
  Future<Result<RevenueCatPaywallResult>> presentPaywallForDebug() =>
      _enqueue(() async {
        final ready = _requireReady();
        if (ready != null) return Result.failure(ready);
        try {
          final result = await _gateway.presentPaywall();
          return Result.success(switch (result) {
            rc_ui.PaywallResult.notPresented =>
              RevenueCatPaywallResult.notPresented,
            rc_ui.PaywallResult.cancelled => RevenueCatPaywallResult.cancelled,
            rc_ui.PaywallResult.purchased => RevenueCatPaywallResult.purchased,
            rc_ui.PaywallResult.restored => RevenueCatPaywallResult.restored,
            rc_ui.PaywallResult.error => RevenueCatPaywallResult.error,
          });
        } catch (error) {
          return Result.failure(_failureFor(error));
        }
      });

  @override
  Future<Result<void>> presentOfferCodeRedemption() => _enqueue(() async {
        final ready = _requireReady();
        if (ready != null) return Result.failure(ready);
        if (_gateway.platform != RevenueCatPlatform.ios) {
          return const Result.failure(ValidationFailure(
            'Resgate de código está disponível apenas no iOS.',
          ));
        }
        try {
          await _gateway.presentOfferCodeRedemption();
          return const Result.success(null);
        } catch (error) {
          return Result.failure(_failureFor(error));
        }
      });

  Future<Failure?> _configureInsideQueue(String userId) async {
    final validation = _validateUserId(userId);
    if (validation != null) return validation;
    if (!billingEnabled) {
      return const ValidationFailure('RevenueCat está desativado.');
    }
    try {
      _configured = await _gateway.isConfigured();
      if (!_configured) {
        final apiKey = _config.keyFor(_gateway.platform);
        if (apiKey.isEmpty) {
          return const ValidationFailure(
              'RevenueCat não está configurado para esta plataforma.');
        }
        await _gateway.configure(apiKey: apiKey, appUserId: userId);
        _configured = true;
        _identifiedUserId = userId;
        _attachListener();
      }
      return null;
    } catch (error) {
      return _failureFor(error);
    }
  }

  Failure? _requireReady() {
    if (!billingEnabled) {
      return const ValidationFailure('RevenueCat está desativado.');
    }
    if (!_configured || _identifiedUserId == null) {
      return const AuthFailure('Entre na sua conta para continuar.');
    }
    return null;
  }

  void _clearLocalSession() {
    _packages.clear();
    _identifiedUserId = null;
  }

  Failure? _validateUserId(String userId) {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    if (!uuid.hasMatch(userId)) {
      return const ValidationFailure('Identidade de assinatura inválida.');
    }
    return null;
  }

  void _attachListener() {
    if (_listenerAttached) return;
    _listenerAttached = true;
    _gateway.addCustomerInfoListener(_emit);
  }

  void _emit(rc.CustomerInfo info) {
    if (_identifiedUserId == null) return;
    if (_customerInfoIdentityFailure(info) != null) {
      _safeLog('RevenueCat CustomerInfo de outra identidade foi ignorado.');
      return;
    }
    final mapped = _mapCustomerInfo(info);
    _updates.add(mapped);
    _safeLog(mapped.hasClubAccess
        ? 'RevenueCat entitlement bldr_club ativo.'
        : 'RevenueCat entitlement bldr_club inativo.');
  }

  RevenueCatCustomerInfo _mapCustomerInfo(rc.CustomerInfo info) =>
      RevenueCatCustomerInfo(
        appUserId: info.originalAppUserId,
        hasClubAccess: info.entitlements.active
            .containsKey(RevenueCatService.clubEntitlementId),
      );

  Failure? _customerInfoIdentityFailure(rc.CustomerInfo info) {
    if (_identifiedUserId == null ||
        info.originalAppUserId != _identifiedUserId) {
      return const AuthFailure(
        'A identidade da assinatura não corresponde à sua conta.',
      );
    }
    return null;
  }

  RevenueCatPackagePeriod? _mapPeriod(rc.PackageType type) => switch (type) {
        rc.PackageType.weekly => RevenueCatPackagePeriod.weekly,
        rc.PackageType.monthly => RevenueCatPackagePeriod.monthly,
        rc.PackageType.annual => RevenueCatPackagePeriod.annual,
        _ => null,
      };

  Failure _failureFor(Object error) {
    final code = revenueCatErrorCode(error);
    if (code == rc.PurchasesErrorCode.networkError ||
        code == rc.PurchasesErrorCode.offlineConnectionError) {
      return NetworkFailure('Sem conexão com a loja.', error);
    }
    return ServerFailure(
      'Não foi possível atualizar a assinatura. Tente novamente.',
      cause: error,
    );
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _serial = _serial.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  void _safeLog(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
