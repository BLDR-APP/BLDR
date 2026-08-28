import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/profile/domain/entities/feedback_result.dart';

abstract interface class FeedbackRepository {
  Future<Result<FeedbackResult>> sendFeedback({
    required String tipo,
    required String mensagem,
    String? screenshotUrl,
  });
}
