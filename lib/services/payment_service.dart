import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

import 'package:bldr_fitness/services/supabase_service.dart';
import 'package:bldr_fitness/models/subscription_plan.dart';

class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();
  static const bool isTestMode = false;

  // Construtor privado
  PaymentService._() {
    _inAppPurchase.purchaseStream.listen(_handlePurchaseUpdates);
  }

  // --- STREAMS PARA AVISAR A TELA DE CHECKOUT ---
  final StreamController<bool> _purchaseSuccessController = StreamController<bool>.broadcast();
  Stream<bool> get purchaseSuccessStream => _purchaseSuccessController.stream;

  final StreamController<String> _purchaseErrorController = StreamController<String>.broadcast();
  Stream<String> get purchaseErrorStream => _purchaseErrorController.stream;
  // -----------------------------------------------

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final Dio _dio = Dio();
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1/create-subscription';

  // --- MÉTODOS ORIGINAIS (STRIPE/SUPABASE) MANTIDOS INTACTOS ---

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final client = SupabaseService.instance.client;
      final response = await client
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('plan_type', ascending: true);

      return response
          .map<SubscriptionPlan>((json) => SubscriptionPlan.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch subscription plans: $e');
    }
  }

  Future<PaymentIntentResponse> createSubscription({
    required String planId,
    required String billingPeriod,
    String? couponCode,
  }) async {
    print('FLUTTER (PaymentService): Método createSubscription chamado com couponCode: $couponCode');
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please login and try again.');
      }

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session found. Please login again.');
      }

      final response = await _dio.post(
        _baseUrl,
        data: {
          'plan_id': planId,
          'billing_period': billingPeriod,
          'coupon_code': couponCode,

          'is_test_mode': isTestMode,
          'trial_period_days': 7,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return PaymentIntentResponse.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to create subscription: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error occurred';

      if (e.response?.data != null) {
        errorMessage = 'Payment error: ${e.response?.data['error'] ?? 'Unknown server error'}';
      } else if (e.message?.contains('SocketException') == true) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentResult> processPayment({
    required String clientSecret,
    required BillingDetails billingDetails,
  }) async {
    try {
      if (Stripe.publishableKey.isEmpty) {
        throw Exception('Payment service not properly initialized');
      }

      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        return PaymentResult(
          success: true,
          message: 'Payment completed successfully',
          paymentIntentId: paymentIntent.id,
        );
      } else {
        return PaymentResult(
          success: false,
          message: 'Payment was not completed. Status: ${paymentIntent.status}',
        );
      }
    } on StripeException catch (e) {
      return PaymentResult(
        success: false,
        message: _getStripeErrorMessage(e),
        errorCode: e.error.code.name,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment failed: ${e.toString()}',
      );
    }
  }

  String _getStripeErrorMessage(StripeException e) {
    switch (e.error.code) {
      case FailureCode.Canceled:
        return 'Payment was cancelled';
      case FailureCode.Failed:
        return 'Payment failed. Please try again.';
      case FailureCode.Timeout:
        return 'Payment timed out. Please try again.';
      default:
        return e.error.localizedMessage ?? 'Payment failed. Please try again.';
    }
  }

  // --- MÉTODOS APPLE IAP (STOREKIT) ---

  Future<List<ProductDetails>> fetchAppleProducts(Set<String> productIds) async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print('FLUTTER (PaymentService): StoreKit não está disponível no dispositivo.');
      return [];
    }

    final ProductDetailsResponse response =
    await _inAppPurchase.queryProductDetails(productIds);

    if (response.error != null) {
      print('FLUTTER (PaymentService): ERRO ao buscar produtos Apple: ${response.error!.message}');
      throw Exception(response.error!.message);
    }

    return response.productDetails;
  }

  Future<bool> processApplePurchase({required String productId}) async {
    final products = await fetchAppleProducts({productId});

    if (products.isEmpty) {
      throw Exception('Produto Apple não encontrado ($productId). Verifique o App Store Connect.');
    }

    final ProductDetails productDetails = products.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

    // Inicia o fluxo de compra
    final bool initiated = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

    if (initiated) {
      return true;
    } else {
      throw Exception("Não foi possível iniciar o pagamento.");
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('FLUTTER (PaymentService): Compra pendente na Apple.');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          print('FLUTTER (PaymentService): Erro na compra: ${purchaseDetails.error}');
          // Para erros, encerra a transação imediatamente para limpar a fila da Apple
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Aguarda a verificação terminar antes de prosseguir.
          // O completePurchase agora é chamado DENTRO de _verifyPurchase,
          // somente após o backend confirmar com sucesso.
          await _verifyPurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) {
        print('ERRO: Usuário deslogado durante validação.');
        _purchaseErrorController.add('Usuário não autenticado. Faça login e tente novamente.');
        return;
      }

      final String receiptData = purchaseDetails.verificationData.serverVerificationData;

      // Debug
      print('DEBUG IAP: User ID: ${user.id}');
      print('DEBUG IAP: Receipt Data Length: ${receiptData.length}');

      // Chamada à Edge Function
      final response = await _dio.post(
          '${SupabaseService.supabaseUrl}/functions/v1/verify-apple-receipt',
          data: {
            'user_id': user.id,
            'receipt_data': receiptData,
            'product_id': purchaseDetails.productID,
          },
          options: Options(
              headers: {
                'Authorization': 'Bearer ${SupabaseService.instance.client.auth.currentSession?.accessToken}',
                'Content-Type': 'application/json', // CRÍTICO: Header necessário para o Supabase
              }
          )
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('FLUTTER (PaymentService): Validação BEM SUCEDIDA!');
        // Encerra a transação na Apple somente após o backend confirmar
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        // Avisa a tela que deu certo
        _purchaseSuccessController.add(true);
      } else {
        print('FLUTTER (PaymentService): Validação FALHOU: ${response.data}');
        // Não chama completePurchase — a transação ficará na fila da Apple
        // e será reprocessada automaticamente na próxima abertura do app.
        _purchaseErrorController.add('Não foi possível ativar sua assinatura. Abra o app novamente para tentar.');
      }

    } catch (e) {
      print('FLUTTER (PaymentService): Erro de validação: $e');
      // Não chama completePurchase — permite retry automático no próximo app launch.
      _purchaseErrorController.add('Erro ao ativar assinatura. Abra o app novamente para tentar.');
    }
  }

  // --- MÉTODOS DE USUÁRIO (RESTAUROU O CÓDIGO ORIGINAL) ---

  Future<UserSubscription?> getCurrentUserSubscription() async {
    final client = SupabaseService.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      print("DEBUG: getCurrentUserSubscription chamado, mas o usuário não está logado.");
      return null;
    }

    print("DEBUG: ID do usuário LOGADO NO APP: ${user.id}");

    try {
      final response = await client
          .from('user_subscriptions')
          .select()
          .eq('user_id', user.id)
          .or('status.eq.active,status.eq.trialing')
          .maybeSingle();

      if (response == null) {
        print("DEBUG: Nenhuma assinatura ativa encontrada.");
        return null;
      }

      return UserSubscription.fromJson(response);

    } catch (e) {
      print("DEBUG: ERRO ao buscar assinatura: $e");
      return null;
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user == null) throw Exception('User not authenticated');

      await client
          .from('user_subscriptions')
          .update({
        'status': 'canceled',
        'canceled_at': DateTime.now().toIso8601String(),
      })
          .eq('user_id', user.id)
          .eq('status', 'active');

      return true;
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
    }
  }
}

class PaymentIntentResponse {
  final String? clientSecret;
  final String? subscriptionId;

  PaymentIntentResponse({
    this.clientSecret,
    this.subscriptionId,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      clientSecret: json['client_secret'],
      subscriptionId: json['subscription_id'],
    );
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final String? errorCode;
  final String? paymentIntentId;

  PaymentResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.paymentIntentId,
  });
}