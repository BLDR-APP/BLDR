import 'dart:async';
import 'dart:io';

import 'package:flutter_stripe/flutter_stripe.dart' show BillingDetails;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/models/subscription_plan.dart';
import 'package:bldr_fitness/services/payment_service.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/subscription_repository.dart';

/// Strangler (Fase 7): delega ao PaymentService legado.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final PaymentService _service;

  SubscriptionRepositoryImpl(this._service);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on Failure catch (f) {
      return Result.failure(f);
    } on supabase.PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message, cause: e));
    } on SocketException catch (e) {
      return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
    } on TimeoutException catch (e) {
      return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
    } catch (e) {
      return Result.failure(UnexpectedFailure(
          e.toString().replaceFirst('Exception: ', ''), e));
    }
  }

  @override
  Stream<bool> get purchaseSuccessStream => _service.purchaseSuccessStream;

  @override
  Stream<String> get purchaseErrorStream => _service.purchaseErrorStream;

  @override
  Future<Result<List<SubscriptionPlan>>> plans() =>
      _guard(_service.getSubscriptionPlans);

  @override
  Future<Result<UserSubscription?>> currentSubscription() =>
      _guard(_service.getCurrentUserSubscription);

  @override
  Future<Result<PaymentIntentResponse>> createStripeSubscription({
    required String planId,
    required String billingPeriod,
    String? couponCode,
  }) =>
      _guard(() => _service.createSubscription(
            planId: planId,
            billingPeriod: billingPeriod,
            couponCode: couponCode,
          ));

  @override
  Future<Result<PaymentResult>> processStripePayment({
    required String clientSecret,
    required BillingDetails billingDetails,
  }) =>
      _guard(() => _service.processPayment(
            clientSecret: clientSecret,
            billingDetails: billingDetails,
          ));

  @override
  Future<Result<bool>> processApplePurchase(String productId) =>
      _guard(() => _service.processApplePurchase(productId: productId));

  @override
  Future<Result<bool>> cancelSubscription() =>
      _guard(_service.cancelSubscription);
}
