import 'package:flutter_stripe/flutter_stripe.dart' show BillingDetails;

import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/models/subscription_plan.dart';
import 'package:bldr_fitness/services/payment_service.dart'
    show PaymentIntentResponse, PaymentResult;

/// Assinaturas e pagamentos (Stripe + Apple IAP).
///
/// Nota: os tipos de payload (PaymentIntentResponse/PaymentResult/
/// BillingDetails) ainda vêm do stack legado/Stripe — tipar entidades
/// próprias quando o checkout for reformulado.
abstract class SubscriptionRepository {
  Stream<bool> get purchaseSuccessStream;
  Stream<String> get purchaseErrorStream;

  Future<Result<List<SubscriptionPlan>>> plans();

  Future<Result<UserSubscription?>> currentSubscription();

  Future<Result<PaymentIntentResponse>> createStripeSubscription({
    required String planId,
    required String billingPeriod,
    String? couponCode,
  });

  Future<Result<PaymentResult>> processStripePayment({
    required String clientSecret,
    required BillingDetails billingDetails,
  });

  Future<Result<bool>> processApplePurchase(String productId);

  Future<Result<bool>> cancelSubscription();
}
