import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';

/// Edita a legenda do próprio post. Só a legenda muda (o banco também garante).
class EditCommunityPost {
  static const int maxCaptionLength = 2000;

  final CommunityFeedRepository _repository;
  const EditCommunityPost(this._repository);

  Future<Result<CommunityPost>> call(CommunityPost post, String caption) async {
    if (!post.isOwnPost) {
      return const Result.failure(
        ValidationFailure('Você só pode editar as suas publicações.'),
      );
    }
    final text = caption.trim();
    if (text.length > maxCaptionLength) {
      return const Result.failure(
        ValidationFailure('O texto pode ter até 2.000 caracteres.'),
      );
    }
    final hasOtherContent = post.eventType != CommunityEventType.manual ||
        (post.photoUrl?.isNotEmpty ?? false) ||
        post.payload['workout_id'] != null;
    if (text.isEmpty && !hasOtherContent) {
      return const Result.failure(
        ValidationFailure('Escreva algo para manter a publicação.'),
      );
    }

    final payload = Map<String, dynamic>.from(post.payload);
    if (text.isEmpty) {
      payload.remove('caption');
    } else {
      payload['caption'] = text;
    }
    final result =
        await _repository.editPost(postId: post.id, payload: payload);
    return result.map((_) => post.copyWith(payload: payload));
  }
}
