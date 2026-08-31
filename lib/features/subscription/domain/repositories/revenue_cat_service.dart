import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/revenue_cat_models.dart';

abstract class RevenueCatService {
  static const String clubEntitlementId = 'bldr_club';

  bool get billingEnabled;

  /// A reconciliação Apple legado nunca é executada em Android/Web.
  bool get supportsAppleMigration;
  Stream<RevenueCatCustomerInfo> get customerInfoUpdates;

  /// Configura o SDK diretamente com o UUID Supabase quando há sessão.
  /// Sem usuário, não cria identidade anônima antecipadamente.
  Future<Result<void>> configure(String? supabaseUserId);

  Future<Result<RevenueCatCustomerInfo>> identify(String supabaseUserId);
  Future<Result<RevenueCatCustomerInfo>> getCustomerInfo();
  Future<Result<RevenueCatOffering?>> getOfferings();
  Future<Result<RevenueCatPurchaseResult>> purchasePackage(
      RevenueCatPackage package);
  Future<Result<RevenueCatCustomerInfo>> restorePurchases();

  /// Registra uma única impressão do paywall customizado na sessão atual.
  Future<Result<void>> trackCustomPaywallImpression();

  /// Deve ser acionado uma única vez e apenas para usuário previamente
  /// classificado como elegível pela estratégia de migração Apple.
  Future<Result<RevenueCatCustomerInfo>> syncPurchasesForMigration({
    required bool eligible,
  });

  Future<Result<bool>> entitlementActive();

  /// Encerra o contexto local da sessão BLDR sem chamar `Purchases.logOut()`.
  /// O SDK permanece identificado até que uma nova sessão conhecida use logIn.
  Future<Result<void>> clearSession();

  /// Entradas isoladas para futura validação; nenhuma é ligada ao paywall atual.
  Future<Result<RevenueCatPaywallResult>> presentPaywallForDebug();
  Future<Result<void>> presentOfferCodeRedemption();
}
