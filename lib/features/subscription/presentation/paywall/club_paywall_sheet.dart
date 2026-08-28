import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:provider/provider.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart'
    as sub_uc;
import 'package:bldr_fitness/features/subscription/presentation/checkout_screen/widgets/payment_form_widget.dart';
import 'package:bldr_fitness/models/subscription_plan.dart';
import 'package:bldr_fitness/services/profile_notifier.dart';
import 'package:bldr_fitness/services/supabase_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
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

// TODO RevenueCat: produto ID semanal
// App Store: 'bldr_club_weekly'
// Google Play: 'bldr_club_weekly'
// Cadastrar em:
//   App Store Connect → In-App Purchases → Auto-Renewable Subscription
//   Google Play Console → Monetização → Assinaturas

// ── Preços por moeda ────────────────────────────────────────────────────────
const _kPrices = {
  'BRL': {'weekly': 6.90,  'monthly': 29.90,  'annual': 149.90},
  'CAD': {'weekly': 1.99,  'monthly': 8.99,   'annual': 34.99},
  'USD': {'weekly': 1.49,  'monthly': 6.99,   'annual': 29.99},
  'EUR': {'weekly': 1.29,  'monthly': 5.99,   'annual': 34.99},
};

class _ClubPaywallSheetState extends State<ClubPaywallSheet> {
  bool _isLoadingPlan = true;
  SubscriptionPlan? _plan;
  _BillingPeriod _period = _BillingPeriod.monthly;
  _Step _step = _Step.plan;

  bool _isProcessing = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  StreamSubscription<bool>? _purchaseSub;
  StreamSubscription<String>? _purchaseErrorSub;

  @override
  void initState() {
    super.initState();
    _loadPlan();
    _prefillBillingData();

    // Apple IAP é assíncrono via stream (sem client secret local) — mesma
    // escuta que checkout_screen.dart já fazia.
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
      final plans = (await getIt<sub_uc.GetSubscriptionPlans>()())
          .fold(onSuccess: (p) => p, onFailure: (f) => throw Exception(f.message));
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

  void _onPurchaseConfirmed() {
    if (!mounted) return;
    Provider.of<ProfileNotifier>(context, listen: false).notifyProfileUpdated();
    widget.onSubscribed?.call();
    Navigator.of(context).pop();
  }

  Future<void> _onCtaPressed() async {
    if (_plan == null) return;
    if (Platform.isIOS) {
      await _processApplePayment();
    } else {
      setState(() => _step = _Step.payment);
    }
  }

  Future<void> _processApplePayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      final productId = switch (_period) {
        _BillingPeriod.weekly  => 'bldr_club_weekly',  // TODO RevenueCat
        _BillingPeriod.monthly => 'MENSAL',
        _BillingPeriod.annual  => 'ANUAL',
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
        _BillingPeriod.weekly  => 'weekly',
        _BillingPeriod.monthly => 'monthly',
        _BillingPeriod.annual  => 'annual',
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
      await InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>()
          .presentCodeRedemptionSheet();
    } catch (e) {
      if (kDebugMode) print('Erro ao abrir resgate de código: $e');
    }
  }

  // ── Helpers de moeda ────────────────────────────────────────────────────────

  String _currency() {
    final country = Localizations.localeOf(context).countryCode ?? '';
    if (country == 'CA') return 'CAD';
    if (country == 'US') return 'USD';
    const euroZone = {'DE','FR','ES','IT','PT','AT','BE','NL','FI','IE','GR','SK','SI','EE','LV','LT','LU','MT','CY'};
    if (euroZone.contains(country)) return 'EUR';
    return 'BRL';
  }

  String _fmt(String currency, double amount) {
    final s = amount.toStringAsFixed(2);
    switch (currency) {
      case 'CAD': return 'CA\$ ${s.replaceAll('.', ',')}';
      case 'USD': return 'US\$ ${s.replaceAll('.', ',')}';
      case 'EUR': return '€${s.replaceAll('.', ',')}';
      default:    return 'R\$ ${s.replaceAll('.', ',')}';
    }
  }

  double _price(String currency, String period) =>
      (_kPrices[currency]?[period] ?? _kPrices['BRL']![period])!;

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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Stack(
        children: [
          // Fundo escuro
          Positioned.fill(child: Container(color: const Color(0xFF050505))),
          // Glow dourado radial no topo
          Positioned(
            top: -60,
            left: -80,
            right: -80,
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.75,
                  colors: [Color(0x47C9A227), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF444240),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: _isLoadingPlan
                      ? const Center(
                          child: CircularProgressIndicator(color: BldrColors.goldBright))
                      : _plan == null
                          ? _buildErrorState()
                          : _step == _Step.plan
                              ? _buildPlanStep()
                              : _buildPaymentStep(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BldrSpacing.pageX),
        child: Text(
          l10n.paywall_load_error,
          style: BldrText.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ── Etapa 1 — escolha do plano ──────────────────────────────────────────────

  Widget _buildPlanStep() {
    final plan = _plan!;
    final currency = _currency();
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildFeatures(plan.features),
                const SizedBox(height: 14),
                _buildWeeklyCard(currency),
                const SizedBox(height: 8),
                _buildMonthlyCard(currency),
                const SizedBox(height: 8),
                _buildAnnualCard(currency),
              ],
            ),
          ),
        ),
        _buildFooter(plan, currency),
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge "BLDR CLUB"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x1FE0B830),
            border: Border.all(color: const Color(0x4DE0B830)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.workspace_premium_rounded,
                  size: 10, color: Color(0xFFE0B830)),
              SizedBox(width: 5),
              Text(
                'BLDR CLUB',
                style: TextStyle(
                  color: Color(0xFFE0B830),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.paywall_title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.paywall_subtitle,
          style: const TextStyle(
            color: Color(0x66FFFFFF),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(List<String> features) {
    final items = features.isNotEmpty
        ? features
        : const [
            'HAVOK — treinador com IA ilimitado',
            'Ranking com premiação e squad exclusivo',
            'Treinos exclusivos do Club',
            'Cancele quando quiser, sem taxas',
          ];

    final icons = [
      Icons.smart_toy_outlined,
      Icons.emoji_events_outlined,
      Icons.fitness_center_outlined,
      Icons.block_outlined,
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  i < icons.length ? icons[i] : Icons.check_circle_outline,
                  size: 13,
                  color: const Color(0xFFE0B830),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWeeklyCard(String currency) {
    final price = _price(currency, 'weekly');
    final monthlyEquiv = price * 52 / 12;
    return _PlanCard(
      selected: _period == _BillingPeriod.weekly,
      planName: 'Semanal',
      description: 'equivale a ${_fmt(currency, monthlyEquiv)}/mês',
      priceMain: _fmt(currency, price),
      priceUnit: 'por semana',
      onTap: () => setState(() => _period = _BillingPeriod.weekly),
    );
  }

  Widget _buildMonthlyCard(String currency) {
    final price = _price(currency, 'monthly');
    return _PlanCard(
      selected: _period == _BillingPeriod.monthly,
      planName: 'Mensal',
      description: 'flexibilidade total',
      priceMain: _fmt(currency, price),
      priceUnit: 'por mês',
      onTap: () => setState(() => _period = _BillingPeriod.monthly),
    );
  }

  Widget _buildAnnualCard(String currency) {
    final price = _price(currency, 'annual');
    final perMonth = price / 12;
    return _PlanCard(
      selected: _period == _BillingPeriod.annual,
      planName: 'Anual',
      description: 'economia de 53% vs semanal',
      priceMain: _fmt(currency, price),
      priceUnit: '${_fmt(currency, perMonth)}/mês',
      badge: 'MELHOR VALOR',
      onTap: () => setState(() => _period = _BillingPeriod.annual),
    );
  }

  Widget _buildFooter(SubscriptionPlan plan, String currency) {
    final l10n = AppLocalizations.of(context);
    final isAnnual = _period == _BillingPeriod.annual;

    final ctaLabel = _isProcessing
        ? l10n.paywall_processing
        : isAnnual
            ? 'Começar 7 dias grátis'
            : 'Assinar BLDR Club';

    final ctaIcon = isAnnual ? Icons.card_giftcard_rounded : Icons.workspace_premium_rounded;

    final subText = switch (_period) {
      _BillingPeriod.weekly  => '${_fmt(currency, _price(currency, 'weekly'))}/semana · cancele quando quiser',
      _BillingPeriod.monthly => 'Sem compromisso — cancele quando quiser',
      _BillingPeriod.annual  => '7 dias grátis, depois ${_fmt(currency, _price(currency, 'annual'))}/ano',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Column(
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
          // Botão CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _onCtaPressed,
              icon: Icon(ctaIcon, size: 16, color: const Color(0xFF0A0A0A)),
              label: Text(
                ctaLabel,
                style: const TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0B830),
                foregroundColor: const Color(0xFF0A0A0A),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
            ),
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
              GestureDetector(
                onTap: _redeemCode,
                child: Text(
                  l10n.paywall_redeem,
                  style: const TextStyle(color: Color(0x40FFFFFF), fontSize: 10),
                ),
              ),
              const Text('  ·  ',
                  style: TextStyle(color: Color(0x40FFFFFF), fontSize: 10)),
              Text(
                l10n.paywall_restore,
                style: const TextStyle(color: Color(0x40FFFFFF), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
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
                      Text(AppLocalizations.of(context).common_back_btn, style: BldrText.description),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context).paywall_billing_title, style: BldrText.cardTitleLg),
                const SizedBox(height: 16),
                _billingField(_nameController, AppLocalizations.of(context).paywall_billing_name_label),
                const SizedBox(height: 12),
                _billingField(_emailController, AppLocalizations.of(context).paywall_billing_email_label,
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
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0x1AE0B830)
                  : hasBadge
                      ? const Color(0x14E0B830)
                      : const Color(0x0AFFFFFF),
              border: Border.all(
                color: selected
                    ? const Color(0xFFE0B830)
                    : hasBadge
                        ? const Color(0x59E0B830)
                        : const Color(0x14FFFFFF),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
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
                          ? const Color(0xFFE0B830)
                          : const Color(0x33FFFFFF),
                      width: 2,
                    ),
                    color: selected ? const Color(0xFFE0B830) : Colors.transparent,
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
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0x66FFFFFF),
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
                            ? const Color(0xFFE0B830)
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      priceUnit,
                      style: const TextStyle(
                        color: Color(0x59FFFFFF),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasBadge)
            Positioned(
              top: -8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A227),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
