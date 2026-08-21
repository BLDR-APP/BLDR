import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/profile/domain/entities/feedback_result.dart';
import 'package:bldr_fitness/features/profile/domain/repositories/feedback_repository.dart';

class SendFeedback {
  final FeedbackRepository _repository;
  const SendFeedback(this._repository);

  Future<Result<FeedbackResult>> call({
    required String tipo,
    required String mensagem,
    String? screenshotUrl,
  }) =>
      _repository.sendFeedback(
        tipo: tipo,
        mensagem: mensagem,
        screenshotUrl: screenshotUrl,
      );
}
