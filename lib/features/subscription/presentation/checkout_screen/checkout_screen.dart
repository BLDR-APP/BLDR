import 'dart:io' show Platform;
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart'
    as subUc;
import 'dart:async'; // Necessário para o Stream
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:provider/provider.dart';
import 'package:bldr_fitness/services/profile_notifier.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/models/subscription_plan.dart';
import 'package:bldr_fitness/services/supabase_service.dart';
import 'package:bldr_fitness/theme/app_theme.dart';
import 'package:bldr_fitness/features/subscription/presentation/checkout_screen/widgets/billing_period_toggle_widget.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/features/subscription/presentation/checkout_screen/widgets/payment_form_widget.dart';
import 'package:bldr_fitness/features/subscription/presentation/checkout_screen/widgets/plan_card_widget.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/revenue_cat_service.dart';
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  bool _isAnnualBilling = false;
  bool _isProcessingPayment = false;
  String? _errorMessage;
  String? _successMessage;

  // Variáveis para ouvir sucesso e erro da Apple
  StreamSubscription<bool>? _purchaseSubscription;
  StreamSubscription<String>? _purchaseErrorSubscription;

  List<SubscriptionPlan> _plans = [];
  SubscriptionPlan? _selectedPlan;
  bool _isLoadingPlans = true;
  int _currentPageIndex = 0;

  final _nameController = TextEditingController(text: '');
  final _emailController = TextEditingController(text: '');
  final _phoneController = TextEditingController(text: '');
  final _addressController = TextEditingController(text: '');
  final _cityController = TextEditingController(text: '');
  final _stateController = TextEditingController(text: '');
  final _zipCodeController = TextEditingController(text: '');
  final _couponController = TextEditingController();
  String? _appliedCouponCode;
  late final bool _revenueCatCheckout;

  @override
  void initState() {
    super.initState();
    _revenueCatCheckout = getIt<RevenueCatService>().billingEnabled;
    if (_revenueCatCheckout) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await ClubPaywallSheet.show(context);
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return;
    }
    _loadSubscriptionPlans();
    _loadUserData();

    // Inicia a escuta do sucesso (Apple)
    _purchaseSubscription =
        getIt<subUc.WatchPurchaseSuccess>()().listen((success) {
      if (success && mounted) {
        setState(() {
          _isProcessingPayment = false;
          _successMessage =
              AppLocalizations.of(context).checkout_apple_success_message;
        });
        _showSuccessDialog(null);
      }
    });

    // Inicia a escuta de erros de verificação (Apple)
    _purchaseErrorSubscription =
        getIt<subUc.WatchPurchaseError>()().listen((error) {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _errorMessage = error;
        });
      }
    });
  }

  // --- AQUI ESTÁ O DISPOSE UNIFICADO (CORREÇÃO) ---
  @override
  void dispose() {
    _purchaseSubscription?.cancel(); // Cancela o stream de sucesso da Apple
    _purchaseErrorSubscription?.cancel(); // Cancela o stream de erro da Apple

    // Cancela os controladores originais
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _couponController.dispose();

    super.dispose();
  }
  // -----------------------------------------------

  Future<void> _loadSubscriptionPlans() async {
    try {
      setState(() => _isLoadingPlans = true);
      final plans = (await getIt<subUc.GetSubscriptionPlans>()()).fold(
          onSuccess: (p) => p, onFailure: (f) => throw Exception(f.message));
      if (mounted) {
        setState(() {
          _plans = plans;
          _selectedPlan = plans.isNotEmpty ? plans.first : null;
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load subscription plans: $e';
          _isLoadingPlans = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user?.email != null) {
        _emailController.text = user!.email!;
      }
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
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load user data: $e');
      }
    }
  }

  void _selectPlan(SubscriptionPlan plan) {
    setState(() {
      _selectedPlan = plan;
    });
  }

  void _nextPage() {
    if (_currentPageIndex == 0 && Platform.isIOS) {
      _pageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentPageIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPageIndex == 2 && Platform.isIOS) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Lógica Apple
  Future<void> _processApplePayment() async {
    if (_selectedPlan == null) return;

    setState(() {
      _isProcessingPayment = true;
      _errorMessage = null;
    });

    try {
      final String appleProductId = _isAnnualBilling ? 'ANUAL' : 'MENSAL';
      final appleResult =
          await getIt<subUc.ProcessApplePurchase>()(appleProductId);
      final appleFailure = appleResult.failureOrNull;
      if (appleFailure != null) throw Exception(appleFailure.message);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isProcessingPayment = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_selectedPlan == null) return;

    setState(() {
      _isProcessingPayment = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final billingPeriod = _isAnnualBilling ? 'annual' : 'monthly';
      final intentResult = await getIt<subUc.CreateStripeSubscription>()(
        planId: _selectedPlan!.id,
        billingPeriod: billingPeriod,
        couponCode: _appliedCouponCode,
      );
      final paymentIntentResponse = intentResult.fold(
        onSuccess: (r) => r,
        onFailure: (f) => throw Exception(f.message),
      );

      final billingDetails = stripe.BillingDetails(
        name: _nameController.text,
        email: _emailController.text,
      );

      if (paymentIntentResponse.clientSecret == null) {
        if (mounted) {
          setState(() {
            _successMessage = "Assinatura ativada com sucesso!";
            _errorMessage = null;
            _isProcessingPayment = false;
          });
          _showSuccessDialog(paymentIntentResponse.subscriptionId);
        }
        return;
      }

      final payResult = await getIt<subUc.ProcessStripePayment>()(
        clientSecret: paymentIntentResponse.clientSecret!,
        billingDetails: billingDetails,
      );
      final result = payResult.fold(
        onSuccess: (r) => r,
        onFailure: (f) => throw Exception(f.message),
      );

      if (result.success && mounted) {
        setState(() {
          _successMessage = result.message;
          _errorMessage = null;
        });
        _showSuccessDialog(paymentIntentResponse.subscriptionId);
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _successMessage = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  void _showSuccessDialog(String? subscriptionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.dialogDark,
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen, size: 28),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).checkout_success_title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _successMessage ??
                    AppLocalizations.of(context)
                        .checkout_success_default_message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)
                    .checkout_success_plan(_selectedPlan?.name ?? ''),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              if (kDebugMode && subscriptionId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Subscription ID: $subscriptionId',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Provider.of<ProfileNotifier>(context, listen: false)
                    .notifyProfileUpdated();

                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.dashboard,
                  (route) => false,
                );
              },
              child: Text(AppLocalizations.of(context).common_continue_btn),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_revenueCatCheckout) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).checkout_screen_title),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: _currentPageIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: _isLoadingPlans
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            )
          : Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      for (int i = 0; i < (Platform.isIOS ? 2 : 3); i++)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <=
                                      (Platform.isIOS && _currentPageIndex == 2
                                          ? 1
                                          : _currentPageIndex)
                                  ? AppTheme.accentGold
                                  : AppTheme.dividerGray,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    children: [
                      _buildPlanSelectionPage(),
                      _buildBillingInformationPage(),
                      _buildPaymentPage(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlanSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).checkout_choose_plan_title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).checkout_choose_plan_subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          BillingPeriodToggleWidget(
            isAnnual: _isAnnualBilling,
            onToggle: (isAnnual) {
              setState(() {
                _isAnnualBilling = isAnnual;
              });
            },
          ),
          const SizedBox(height: 24),
          for (final plan in _plans)
            PlanCardWidget(
              plan: plan,
              isAnnual: _isAnnualBilling,
              isSelected: _selectedPlan?.id == plan.id,
              onTap: () => _selectPlan(plan),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedPlan != null ? _nextPage : null,
              child: Text(AppLocalizations.of(context).common_continue_btn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingInformationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).checkout_billing_info_title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).checkout_billing_info_subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            _buildTextField(_nameController,
                AppLocalizations.of(context).checkout_name_label, true),
            _buildTextField(_emailController,
                AppLocalizations.of(context).checkout_email_label, true,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _nextPage();
                  }
                },
                child: Text(
                    AppLocalizations.of(context).checkout_continue_payment_btn),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).checkout_payment_title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).checkout_payment_subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          if (_selectedPlan != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).checkout_order_summary,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedPlan!.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      Text(
                        _isAnnualBilling
                            ? _selectedPlan!.annualPriceText
                            : _selectedPlan!.monthlyPriceText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAnnualBilling
                        ? AppLocalizations.of(context).checkout_billing_annual
                        : AppLocalizations.of(context).checkout_billing_monthly,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (Platform.isIOS) ...[
            _buildApplePaymentArea()
          ] else ...[
            Text(
              AppLocalizations.of(context).checkout_coupon_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: TextFormField(
                      controller: _couponController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).checkout_coupon_label,
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                        fillColor: AppTheme.surfaceDark,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.dividerGray),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.dividerGray),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppTheme.accentGold, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final code = _couponController.text.trim();
                    if (code.isNotEmpty) {
                      setState(() {
                        _appliedCouponCode = code.toUpperCase();
                      });
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)
                              .checkout_coupon_applied(
                                  _appliedCouponCode ?? '')),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  ),
                  child: Text(
                      AppLocalizations.of(context).checkout_coupon_apply_btn),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PaymentFormWidget(
              onPaymentProcess: _processPayment,
              isProcessing: _isProcessingPayment,
              errorMessage: _errorMessage,
              successMessage: _successMessage,
            ),
          ]
        ],
      ),
    );
  }

  // URLs fornecidos
  final Uri _urlTerms = Uri.parse('https://www.bldrapp.com.br/termos');
  final Uri _urlPrivacy = Uri.parse('https://www.bldrapp.com.br/privacidade');

// Função para abrir links
  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      // Adicionar um log ou tratamento de erro
      print('Não foi possível abrir a URL: $url');
    }
  }

  Widget _buildApplePaymentArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        children: [
          if (_isProcessingPayment)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            )
          else ...[
            Icon(Icons.apple, size: 48, color: AppTheme.textPrimary),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).checkout_apple_payment_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).checkout_apple_payment_subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _processApplePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child:
                    Text(AppLocalizations.of(context).checkout_subscribe_btn),
              ),
            ),
            // --- NOVO: BOTÃO DE RESGATAR CÓDIGO ---
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                // Chama a tela nativa da Apple para digitar o código
                try {
                  await InAppPurchase.instance
                      .getPlatformAddition<
                          InAppPurchaseStoreKitPlatformAddition>()
                      .presentCodeRedemptionSheet();
                } catch (e) {
                  print("Erro ao abrir resgate de código: $e");
                }
              },
              child: Text(
                AppLocalizations.of(context).checkout_redeem_btn,
                style: const TextStyle(
                  color: AppTheme.accentGold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegalLinks(), // Chamada do novo Widget
          ]
        ],
      ),
    );
  }

  // Novo Widget para agrupar os links legais
  Widget _buildLegalLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          // Link 1: Política de Privacidade
          TextButton(
            onPressed: () => _launchUrl(_urlPrivacy), // Chamada funcional
            child: Text(
              AppLocalizations.of(context).checkout_privacy_policy,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                decoration: TextDecoration.underline,
                fontSize: 12,
              ),
            ),
          ),

          // Link 2: Termos de Uso (EULA)
          TextButton(
            onPressed: () => _launchUrl(_urlTerms),
            child: Text(
              AppLocalizations.of(context).checkout_terms_of_use,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                decoration: TextDecoration.underline,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool required, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.textSecondary),
          fillColor: AppTheme.surfaceDark,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.dividerGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.dividerGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.accentGold, width: 2),
          ),
        ),
        validator: required
            ? (value) {
                final l10n = AppLocalizations.of(context);
                if (value == null || value.isEmpty) {
                  return l10n.checkout_field_required(label);
                }
                if (label == l10n.checkout_email_label &&
                    !value.contains('@')) {
                  return l10n.checkout_email_invalid;
                }
                return null;
              }
            : null,
      ),
    );
  }
}
