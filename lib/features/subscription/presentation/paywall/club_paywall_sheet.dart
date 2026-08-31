import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/revenue_cat_models.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/revenue_cat_service.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart'
    as sub_uc;
import 'package:bldr_fitness/features/subscription/presentation/checkout_screen/widgets/payment_form_widget.dart';
import 'package:bldr_fitness/models/subscription_plan.dart';
import 'package:bldr_fitness/services/profile_notifier.dart';
import 'package:bldr_fitness/services/supabase_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

/// Paywall do BLDR Club — bottom sheet único, substitui o antigo popup
/// "Exclusivo para Membros" + tela de Checkout separada.
///
/// Lógica de compra intocada: chama exatamente os mesmos use cases que
/// `checkout_screen.dart` já usava (`CreateStripeSubscription` +
/// `ProcessStripePayment` no Android, `ProcessApplePurchase` +
/// `WatchPurchaseSuccess`/`WatchPurchaseError` no iOS).
class ClubPaywallSheet extends StatefulWidget {
  /// Chamado depois que a assinatura é confirmada, antes do sheet fechar —
  /// dá ao chamador (Dashboard) a chance de recarregar `_userSubscription`
  /// e trocar de aba.
  final VoidCallback? onSubscribed;

  const ClubPaywallSheet({super.key, this.onSubscribed});

  /// Abre o paywall como bottom sheet, com o X fora do card (na área
  /// esmaecida, canto superior direito da tela) — padrão 7.12.
  static Future<void> show(BuildContext context, {VoidCallback? onSubscribed}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ClubPaywallSheet(onSubscribed: onSubscribed),
    );
  }

  @override
  State<ClubPaywallSheet> createState() => _ClubPaywallSheetState();
}

enum _Step { plan, payment }

enum _BillingPeriod { weekly, monthly, annual }

/// Regras visuais puras para a ordem e a seleção inicial dos packages.
/// A compra continua usando o package selecionado pela implementação existente.
abstract final class ClubPaywallPlanLayout {
  static const displayOrder = <RevenueCatPackagePeriod>[
    RevenueCatPackagePeriod.annual,
    RevenueCatPackagePeriod.monthly,
    RevenueCatPackagePeriod.weekly,
  ];

  static List<RevenueCatPackagePeriod> availablePeriods(
    Map<RevenueCatPackagePeriod, RevenueCatPackage> packages,
  ) =>
      [
        for (final period in displayOrder)
          if (packages.containsKey(period)) period,
      ];

  static RevenueCatPackagePeriod defaultPeriod(
    Map<RevenueCatPackagePeriod, RevenueCatPackage> packages,
  ) =>
      availablePeriods(packages).first;
}

class _ClubPaywallSheetState extends State<ClubPaywallSheet> {
  bool _isLoadingPlan = true;
  SubscriptionPlan? _plan;
  Map<RevenueCatPackagePeriod, RevenueCatPackage> _revenueCatPackages = {};
  bool _revenueCatPurchaseFlow = false;
  bool _revenueCatBillingRequired = false;
  bool _customPaywallImpressionTracked = false;
  _BillingPeriod _period = _BillingPeriod.annual;
  _Step _step = _Step.plan;

  bool _isProcessing = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  StreamSubscription<bool>? _purchaseSub;
  StreamSubscription<String>? _purchaseErrorSub;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _loadPlan();
    if (!getIt<RevenueCatService>().billingEnabled) {
      _prefillBillingData();

      // Compatibilidade temporária para builds legados com a flag desligada.
      _purchaseSub = getIt<sub_uc.WatchPurchaseSuccess>()().listen((success) {
        if (success && mounted) _onPurchaseConfirmed();
      });
      _purchaseErrorSub = getIt<sub_uc.WatchPurchaseError>()().listen((error) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _errorMessage = error;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _purchaseErrorSub?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    try {
      final revenueCat = getIt<RevenueCatService>();
      if (revenueCat.billingEnabled) {
        _revenueCatBillingRequired = true;
        final userId = getIt<AuthRepository>().currentUser?.id;
        if (userId == null) {
          throw Exception(_l10n.paywall_sign_in_required);
        }
        final identity = await revenueCat.identify(userId);
        final offering = identity.isFailure
            ? null
            : (await revenueCat.getOfferings()).valueOrNull;
        final packages = offering?.packages ?? const <RevenueCatPackage>[];
        final byPeriod = {
          for (final package in packages) package.period: package,
        };
        if (byPeriod.isEmpty) {
          throw Exception(_l10n.paywall_options_unavailable);
        }
        if (mounted) {
          setState(() {
            _revenueCatPackages = byPeriod;
            _revenueCatPurchaseFlow = true;
            _period = _billingPeriodFor(
              ClubPaywallPlanLayout.defaultPeriod(byPeriod),
            );
            _isLoadingPlan = false;
          });
          _trackCustomPaywallImpression();
        }
        return;
      }
      final plans = (await getIt<sub_uc.GetSubscriptionPlans>()()).fold(
          onSuccess: (p) => p, onFailure: (f) => throw Exception(f.message));
      final plan = plans.isEmpty
          ? null
          : (plans.firstWhere((p) => p.isPopular, orElse: () => plans.first));
      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoadingPlan = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPlan = false);
    }
  }

  Future<void> _prefillBillingData() async {
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user?.email != null) _emailController.text = user!.email!;
      final userProfile = await SupabaseService.instance.client
          .from('user_profiles')
          .select('full_name, email')
          .eq('id', user?.id ?? '')
          .maybeSingle();
      if (userProfile != null && mounted) {
        setState(() {
          _nameController.text = userProfile['full_name'] ?? '';
          _emailController.text = userProfile['email'] ?? user?.email ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _trackCustomPaywallImpression() async {
    if (_customPaywallImpressionTracked || !_revenueCatPurchaseFlow) return;
    _customPaywallImpressionTracked = true;
    await getIt<RevenueCatService>().trackCustomPaywallImpression();
  }

  void _onPurchaseConfirmed() {
    if (!mounted) return;
    Provider.of<ProfileNotifier>(context, listen: false).notifyProfileUpdated();
    widget.onSubscribed?.call();
    Navigator.of(context).pop();
  }

  Future<void> _onCtaPressed() async {
    if (_isProcessing) return;
    if (_revenueCatPurchaseFlow) {
      await _processRevenueCatPurchase();
      return;
    }
    if (_revenueCatBillingRequired) {
      setState(() => _errorMessage = _l10n.paywall_options_retry_later);
      return;
    }
    if (_plan == null) return;
    if (Platform.isIOS) {
      await _processApplePayment();
    } else {
      setState(() => _step = _Step.payment);
    }
  }

  Future<void> _processRevenueCatPurchase() async {
    final package = _revenueCatPackages[_revenueCatPeriod];
    if (package == null) {
      setState(() => _errorMessage = _l10n.paywall_option_unavailable);
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    final result = await getIt<RevenueCatService>().purchasePackage(package);
    if (!mounted) return;
    result.fold(
      onSuccess: (purchase) {
        switch (purchase.status) {
          case RevenueCatPurchaseStatus.success:
            if (purchase.customerInfo?.hasClubAccess == true) {
              _onPurchaseConfirmed();
            } else {
              setState(() {
                _isProcessing = false;
                _errorMessage = _l10n.paywall_access_confirmation_failed;
              });
            }
            return;
          case RevenueCatPurchaseStatus.cancelled:
            setState(() => _isProcessing = false);
            return;
          case RevenueCatPurchaseStatus.pending:
            setState(() {
              _isProcessing = false;
              _errorMessage = _l10n.paywall_payment_pending;
            });
            return;
        }
      },
      onFailure: (failure) => setState(() {
        _isProcessing = false;
        _errorMessage = failure.message;
      }),
    );
  }

  Future<void> _processApplePayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      final productId = switch (_period) {
        _BillingPeriod.weekly => 'bldr_club_weekly', // TODO RevenueCat
        _BillingPeriod.monthly => 'MENSAL',
        _BillingPeriod.annual => 'ANUAL',
      };
      final result = await getIt<sub_uc.ProcessApplePurchase>()(productId);
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);
      // Sucesso chega pelo stream WatchPurchaseSuccess.
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processStripePayment() async {
    if (_plan == null) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      final billingPeriod = switch (_period) {
        _BillingPeriod.weekly => 'weekly',
        _BillingPeriod.monthly => 'monthly',
        _BillingPeriod.annual => 'annual',
      };
      final intentResult = await getIt<sub_uc.CreateStripeSubscription>()(
        planId: _plan!.id,
        billingPeriod: billingPeriod,
      );
      final paymentIntent = intentResult.fold(
        onSuccess: (r) => r,
        onFailure: (f) => throw Exception(f.message),
      );

      if (paymentIntent.clientSecret == null) {
        _onPurchaseConfirmed();
        return;
      }

      final billingDetails = stripe.BillingDetails(
        name: _nameController.text,
        email: _emailController.text,
      );

      final payResult = await getIt<sub_uc.ProcessStripePayment>()(
        clientSecret: paymentIntent.clientSecret!,
        billingDetails: billingDetails,
      );
      final result = payResult.fold(
        onSuccess: (r) => r,
        onFailure: (f) => throw Exception(f.message),
      );

      if (result.success) {
        _onPurchaseConfirmed();
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _redeemCode() async {
    try {
      if (_revenueCatBillingRequired) {
        if (!_revenueCatPurchaseFlow) {
          setState(() => _errorMessage = _l10n.paywall_redeem_unavailable);
          return;
        }
        final result =
            await getIt<RevenueCatService>().presentOfferCodeRedemption();
        if (result.isFailure && mounted) {
          setState(() => _errorMessage = result.failureOrNull!.message);
        }
        return;
      }
      await InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>()
          .presentCodeRedemptionSheet();
    } catch (e) {
      if (kDebugMode) print('Erro ao abrir resgate de código: $e');
    }
  }

  Future<void> _restorePurchases() async {
    if (_isProcessing) return;
    if (!_revenueCatPurchaseFlow) {
      setState(() => _errorMessage = _revenueCatBillingRequired
          ? _l10n.paywall_restore_unavailable
          : _l10n.paywall_restore_after_update);
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    final result = await getIt<RevenueCatService>().restorePurchases();
    if (!mounted) return;
    result.fold(
      onSuccess: (info) {
        setState(() => _isProcessing = false);
        if (info.hasClubAccess) _onPurchaseConfirmed();
      },
      onFailure: (failure) => setState(() {
        _isProcessing = false;
        _errorMessage = failure.message;
      }),
    );
  }

  RevenueCatPackagePeriod get _revenueCatPeriod => switch (_period) {
        _BillingPeriod.weekly => RevenueCatPackagePeriod.weekly,
        _BillingPeriod.monthly => RevenueCatPackagePeriod.monthly,
        _BillingPeriod.annual => RevenueCatPackagePeriod.annual,
      };

  _BillingPeriod _billingPeriodFor(RevenueCatPackagePeriod period) =>
      switch (period) {
        RevenueCatPackagePeriod.weekly => _BillingPeriod.weekly,
        RevenueCatPackagePeriod.monthly => _BillingPeriod.monthly,
        RevenueCatPackagePeriod.annual => _BillingPeriod.annual,
      };

  List<RevenueCatPackagePeriod> get _visiblePeriods =>
      _revenueCatBillingRequired
          ? ClubPaywallPlanLayout.availablePeriods(_revenueCatPackages)
          : ClubPaywallPlanLayout.displayOrder;

  String _displayPrice(RevenueCatPackagePeriod period) {
    if (_revenueCatBillingRequired) {
      return _revenueCatPackages[period]?.localizedPrice ??
          _l10n.paywall_unavailable;
    }
    return switch (period) {
      RevenueCatPackagePeriod.monthly => _plan?.monthlyPriceText ?? '—',
      RevenueCatPackagePeriod.annual => _plan?.annualPriceText ?? '—',
      RevenueCatPackagePeriod.weekly => _l10n.paywall_unavailable,
    };
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.86,
            child: _buildSheetCard(context),
          ),
        ),
        Positioned(
          top: topInset + 8,
          right: 16,
          child: _CloseButton(onTap: () => Navigator.of(context).pop()),
        ),
      ],
    );
  }

  Widget _buildSheetCard(BuildContext context) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(BldrRadius.screen)),
      child: BldrBackground(
        secondaryGlow: false,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: BldrColors.textMuted,
                  borderRadius: BldrRadius.all(BldrRadius.bar),
                ),
              ),
              Expanded(
                child: _isLoadingPlan
                    ? const _PaywallLoadingState()
                    : _plan == null && !_revenueCatPurchaseFlow
                        ? _buildErrorState()
                        : _step == _Step.plan
                            ? _buildPlanStep()
                            : _buildPaymentStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BldrSpacing.pageX),
        child: BldrGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  color: BldrColors.goldBright, size: 24),
              const SizedBox(height: 12),
              Text(l10n.paywall_load_error_title,
                  style: BldrText.cardTitle, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(l10n.paywall_load_error_body,
                  style: BldrText.description, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              BldrSecondaryButton(
                  label: l10n.common_retry, onPressed: _loadPlan),
            ],
          ),
        ),
      ),
    );
  }

  // ── Etapa 1 — escolha do plano ──────────────────────────────────────────────

  Widget _buildPlanStep() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 22, BldrSpacing.pageX, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: BldrSpacing.gapSection),
          _buildComparison(),
          const SizedBox(height: BldrSpacing.gapSection),
          Text(l10n.paywall_choose_plan, style: BldrText.sectionTitle),
          const SizedBox(height: BldrSpacing.gapCard),
          for (var index = 0; index < _visiblePeriods.length; index++) ...[
            _buildPlanCard(_visiblePeriods[index]),
            if (index != _visiblePeriods.length - 1)
              const SizedBox(height: BldrSpacing.gapCard),
          ],
          const SizedBox(height: BldrSpacing.gapSection),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          image: true,
          label: l10n.paywall_club_logo_semantics,
          child: Image.asset(
            'assets/images/bldr_club_paywall.png',
            width: 190,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.paywall_elevate_performance,
            style: BldrText.screenTitle, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          l10n.paywall_performance_subtitle,
          style: BldrText.description,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildComparison() => const _ClubBenefitsComparison();

  Widget _buildPlanCard(RevenueCatPackagePeriod period) => switch (period) {
        RevenueCatPackagePeriod.weekly => _buildWeeklyCard(),
        RevenueCatPackagePeriod.monthly => _buildMonthlyCard(),
        RevenueCatPackagePeriod.annual => _buildAnnualCard(),
      };

  Widget _buildWeeklyCard() {
    final l10n = AppLocalizations.of(context);
    return _PlanCard(
      selected: _period == _BillingPeriod.weekly,
      planName: l10n.paywall_plan_weekly,
      description: l10n.paywall_weekly_description,
      priceMain: _displayPrice(RevenueCatPackagePeriod.weekly),
      priceUnit: l10n.paywall_per_week,
      onTap: () => setState(() => _period = _BillingPeriod.weekly),
    );
  }

  Widget _buildMonthlyCard() {
    final l10n = AppLocalizations.of(context);
    return _PlanCard(
      selected: _period == _BillingPeriod.monthly,
      planName: l10n.paywall_plan_monthly,
      description: l10n.paywall_monthly_description,
      priceMain: _displayPrice(RevenueCatPackagePeriod.monthly),
      priceUnit: l10n.paywall_per_month,
      onTap: () => setState(() => _period = _BillingPeriod.monthly),
    );
  }

  Widget _buildAnnualCard() {
    final l10n = AppLocalizations.of(context);
    return _PlanCard(
      selected: _period == _BillingPeriod.annual,
      planName: l10n.paywall_plan_annual,
      description: l10n.paywall_annual_description,
      priceMain: _displayPrice(RevenueCatPackagePeriod.annual),
      priceUnit: l10n.paywall_per_year,
      badge: l10n.paywall_best_value,
      onTap: () => setState(() => _period = _BillingPeriod.annual),
    );
  }

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context);
    final ctaLabel =
        _isProcessing ? l10n.paywall_processing : l10n.paywall_join_cta;

    final subText = l10n.paywall_selected_price_caption(
      _displayPrice(_revenueCatPeriod),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_errorMessage != null) ...[
          Text(
            _errorMessage!,
            style: BldrText.metaSm.copyWith(color: BldrColors.danger),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
        ],
        BldrPrimaryButton(
          label: ctaLabel,
          icon: _isProcessing ? null : Icons.workspace_premium_outlined,
          onPressed: _isProcessing ? null : _onCtaPressed,
        ),
        const SizedBox(height: 8),
        Text(
          subText,
          style: const TextStyle(
            color: Color(0x59FFFFFF),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (Platform.isIOS)
              GestureDetector(
                onTap: _isProcessing ? null : _redeemCode,
                child: Text(
                  l10n.paywall_redeem,
                  style: BldrText.metaSm,
                ),
              ),
            if (Platform.isIOS) const Text('  ·  ', style: BldrText.metaSm),
            GestureDetector(
              onTap: _isProcessing ? null : _restorePurchases,
              child: Text(
                l10n.paywall_restore,
                style: BldrText.metaSm,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _LegalLinks(onOpen: _openLegalLink),
      ],
    );
  }

  Future<void> _openLegalLink(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Etapa 2 (Android/Stripe) — cobrança + cartão ────────────────────────────

  Widget _buildPaymentStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                BldrSpacing.pageX, 14, BldrSpacing.pageX, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _step = _Step.plan),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_ios_new,
                          size: 14, color: BldrColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context).common_back_btn,
                          style: BldrText.description),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context).paywall_billing_title,
                    style: BldrText.cardTitleLg),
                const SizedBox(height: 16),
                _billingField(_nameController,
                    AppLocalizations.of(context).paywall_billing_name_label),
                const SizedBox(height: 12),
                _billingField(_emailController,
                    AppLocalizations.of(context).paywall_billing_email_label,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 22),
                PaymentFormWidget(
                  onPaymentProcess: _processStripePayment,
                  isProcessing: _isProcessing,
                  errorMessage: _errorMessage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _billingField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BldrText.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: BldrText.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: BldrColors.surfaceInset,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BldrRadius.all(BldrRadius.input),
              borderSide: const BorderSide(color: BldrColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BldrRadius.all(BldrRadius.input),
              borderSide: const BorderSide(color: BldrColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BldrRadius.all(BldrRadius.input),
              borderSide: const BorderSide(color: BldrColors.goldBright),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClubBenefitsComparison extends StatelessWidget {
  const _ClubBenefitsComparison();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final benefits =
        <({IconData icon, String label, String free, String club})>[
      (
        icon: TablerIcons.users,
        label: l10n.paywall_benefit_community,
        free: l10n.paywall_limited,
        club: l10n.paywall_complete,
      ),
      (
        icon: TablerIcons.brain,
        label: l10n.paywall_benefit_havok,
        free: l10n.paywall_limited,
        club: l10n.paywall_complete,
      ),
      (
        icon: TablerIcons.camera,
        label: l10n.paywall_benefit_photo_workout,
        free: l10n.paywall_unavailable,
        club: l10n.paywall_available,
      ),
      (
        icon: TablerIcons.chart_line,
        label: l10n.paywall_benefit_analytics,
        free: l10n.paywall_basic,
        club: l10n.paywall_advanced,
      ),
      (
        icon: TablerIcons.barbell,
        label: l10n.paywall_benefit_library,
        free: l10n.paywall_limited,
        club: l10n.paywall_complete,
      ),
      (
        icon: TablerIcons.apple,
        label: l10n.paywall_benefit_nutrition,
        free: l10n.paywall_basic,
        club: l10n.paywall_advanced,
      ),
    ];
    return Semantics(
      label: l10n.paywall_comparison_semantics,
      child: BldrGlassCard(
        padding: const EdgeInsets.symmetric(
            horizontal: BldrSpacing.padCard, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    flex: 5,
                    child: Text(l10n.paywall_feature, style: BldrText.label)),
                Expanded(
                  flex: 2,
                  child: Text(l10n.paywall_free,
                      textAlign: TextAlign.center, style: BldrText.label),
                ),
                Expanded(
                  flex: 2,
                  child: Text(l10n.paywall_club,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: BldrText.family,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .6,
                          color: BldrColors.goldBright)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < benefits.length; index++) ...[
              _BenefitComparisonRow(benefit: benefits[index]),
              if (index != benefits.length - 1)
                const Divider(height: 16, color: BldrColors.borderSubtle),
            ],
          ],
        ),
      ),
    );
  }
}

class _BenefitComparisonRow extends StatelessWidget {
  final ({IconData icon, String label, String free, String club}) benefit;

  const _BenefitComparisonRow({required this.benefit});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Icon(benefit.icon, size: 16, color: BldrColors.goldBright),
                const SizedBox(width: 8),
                Expanded(child: Text(benefit.label, style: BldrText.metaSm)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              benefit.free,
              textAlign: TextAlign.center,
              style: BldrText.metaSm.copyWith(color: BldrColors.textMuted),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              benefit.club,
              textAlign: TextAlign.center,
              style: BldrText.metaSm.copyWith(
                color: BldrColors.goldBright,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
}

class _LegalLinks extends StatelessWidget {
  final ValueChanged<Uri> onOpen;

  const _LegalLinks({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LegalLink(
          label: l10n.paywall_terms,
          onTap: () => onOpen(Uri.parse('https://www.bldrapp.com.br/termos')),
        ),
        const Text('  ·  ', style: BldrText.metaSm),
        _LegalLink(
          label: l10n.paywall_privacy,
          onTap: () =>
              onOpen(Uri.parse('https://www.bldrapp.com.br/privacidade')),
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        link: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BldrRadius.all(BldrRadius.button),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(label,
                style: BldrText.metaSm.copyWith(
                  decoration: TextDecoration.underline,
                )),
          ),
        ),
      );
}

class _PaywallLoadingState extends StatelessWidget {
  const _PaywallLoadingState();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(BldrSpacing.pageX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _PaywallSkeleton(height: 18, widthFactor: .32),
            SizedBox(height: 16),
            _PaywallSkeleton(height: 28, widthFactor: .72),
            SizedBox(height: 10),
            _PaywallSkeleton(height: 16, widthFactor: .9),
            SizedBox(height: 24),
            _PaywallSkeleton(height: 250),
            SizedBox(height: 24),
            _PaywallSkeleton(height: 86),
            SizedBox(height: 12),
            _PaywallSkeleton(height: 86),
          ],
        ),
      );
}

class _PaywallSkeleton extends StatelessWidget {
  final double height;
  final double? widthFactor;

  const _PaywallSkeleton({required this.height, this.widthFactor});

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: Alignment.centerLeft,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: BldrColors.surface,
            borderRadius: BldrRadius.all(BldrRadius.cardSm),
          ),
        ),
      );
}

// ── Card de plano ─────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final bool selected;
  final String planName;
  final String description;
  final String priceMain;
  final String priceUnit;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.selected,
    required this.planName,
    required this.description,
    required this.priceMain,
    required this.priceUnit,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBadge = badge != null;
    return Semantics(
      button: true,
      selected: selected,
      label: '$planName, $priceMain $priceUnit',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            BldrAnimatedBorderCard(
              selected: selected,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      selected ? BldrColors.goldTintStrong : BldrColors.surface,
                  borderRadius: BldrRadius.all(BldrRadius.cardSm),
                ),
                child: Row(
                  children: [
                    // Radio
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? BldrColors.goldBright
                              : BldrColors.border,
                          width: 2,
                        ),
                        color: selected
                            ? BldrColors.goldSolid
                            : Colors.transparent,
                      ),
                      child: selected
                          ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0A0A0A),
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planName,
                            style: const TextStyle(
                              color: BldrColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            description,
                            style: const TextStyle(
                              color: BldrColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Preço
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          priceMain,
                          style: TextStyle(
                            color: selected
                                ? BldrColors.goldBright
                                : BldrColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          priceUnit,
                          style: const TextStyle(
                            color: BldrColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (hasBadge)
              Positioned(
                top: -8,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: BldrColors.goldTintChip,
                    border: Border.all(color: BldrColors.goldBorderChip),
                    borderRadius: BldrRadius.all(BldrRadius.pill),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: BldrColors.goldBright,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Borda premium animada isolada do restante do paywall. O repaint fica
/// restrito ao painter e o controller é descartado com o card.
class BldrAnimatedBorderCard extends StatefulWidget {
  final bool selected;
  final Widget child;

  const BldrAnimatedBorderCard({
    super.key,
    required this.selected,
    required this.child,
  });

  @override
  State<BldrAnimatedBorderCard> createState() => _BldrAnimatedBorderCardState();
}

class _BldrAnimatedBorderCardState extends State<BldrAnimatedBorderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    if (widget.selected) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant BldrAnimatedBorderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _controller.repeat();
    } else if (!widget.selected && oldWidget.selected) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) => CustomPaint(
            foregroundPainter: _GoldBorderPainter(
              progress: _controller.value,
              emphasized: widget.selected,
            ),
            child: child,
          ),
        ),
      );
}

class _GoldBorderPainter extends CustomPainter {
  final double progress;
  final bool emphasized;

  const _GoldBorderPainter({
    required this.progress,
    required this.emphasized,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!emphasized) return;
    final rect = Offset.zero & size;
    final border = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      const Radius.circular(16),
    );
    final shader = SweepGradient(
      transform: GradientRotation(progress * math.pi * 2),
      colors: const [
        Color(0x00E0B830),
        Color(0xFFE0B830),
        Color(0x00E0B830),
      ],
      stops: const [0.0, 0.16, 0.32],
    ).createShader(rect);
    canvas.drawRRect(
      border,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _GoldBorderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.emphasized != emphasized;
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0x12FFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: const Icon(Icons.close, color: Color(0x99FFFFFF), size: 18),
      ),
    );
  }
}
