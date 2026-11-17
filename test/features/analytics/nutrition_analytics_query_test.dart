import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/features/analytics/domain/services/analytics_queries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns an explicit typed failure for unavailable history', () async {
    final result = await const NutritionAnalyticsQuery().history();

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(result.failureOrNull!.message, contains('indisponível'));
  });

  test('does not represent unavailable history as an empty result', () async {
    final result = await const NutritionAnalyticsQuery().history();

    expect(result.isSuccess, isFalse);
    expect(result.valueOrNull, isNull);
  });

  test('keeps the Firestore limitation distinct from a datasource failure',
      () async {
    final result = await const NutritionAnalyticsQuery().history();

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(result.failureOrNull, isNot(isA<NetworkFailure>()));
    expect(result.failureOrNull, isNot(isA<ServerFailure>()));
  });
}
