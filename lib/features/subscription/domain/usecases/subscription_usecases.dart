import 'package:flutter_stripe/flutter_stripe.dart' show BillingDetails;

import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/models/subscription_plan.dart';
import 'package:bldr_fitness/services/payment_service.dart'
    show PaymentIntentResponse, PaymentResult;
import 'package:bldr_fitness/features/subscription/domain/repositories/subscription_repository.dart';

class GetSubscriptionPlans {
  final SubscriptionRepository _repo;
  const GetSubscriptionPlans(this._repo);

  Future<Result<List<SubscriptionPlan>>> call() => _repo.plans();
}

class GetCurrentSubscription {
  final SubscriptionRepository _repo;
  const GetCurrentSubscription(this._repo);

  Future<Result<UserSubscription?>> call() => _repo.currentSubscription();
}

class CreateStripeSubscription {
  final SubscriptionRepository _repo;
  const CreateStripeSubscription(this._repo);

  Future<Result<PaymentIntentResponse>> call({
    required String planId,
    required String billingPeriod,
    String? couponCode,
  }) =>
      _repo.createStripeSubscription(
          planId: planId, billingPeriod: billingPeriod, couponCode: couponCode);
}

class ProcessStripePayment {
  final SubscriptionRepository _repo;
  const ProcessStripePayment(this._repo);

  Future<Result<PaymentResult>> call({
    required String clientSecret,
    required BillingDetails billingDetails,
  }) =>
      _repo.processStripePayment(
          clientSecret: clientSecret, billingDetails: billingDetails);
}

class ProcessApplePurchase {
  final SubscriptionRepository _repo;
  const ProcessApplePurchase(this._repo);

  Future<Result<bool>> call(String productId) =>
      _repo.processApplePurchase(productId);
}

class CancelSubscription {
  final SubscriptionRepository _repo;
  const CancelSubscription(this._repo);

  Future<Result<bool>> call() => _repo.cancelSubscription();
}

class WatchPurchaseSuccess {
  final SubscriptionRepository _repo;
  const WatchPurchaseSuccess(this._repo);

  Stream<bool> call() => _repo.purchaseSuccessStream;
}

class WatchPurchaseError {
  final SubscriptionRepository _repo;
  const WatchPurchaseError(this._repo);

  Stream<String> call() => _repo.purchaseErrorStream;
}
