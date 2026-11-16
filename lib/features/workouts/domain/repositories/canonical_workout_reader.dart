import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/canonical_workout.dart';

/// Cursor opaco de uma leitura paginada de treinos canônicos.
///
/// Consumers apenas devolvem este valor ao reader; o formato do token continua
/// uma decisão da implementação futura (personal, CLUB ou uma composição).
class CanonicalWorkoutCursor {
  final String _token;

  const CanonicalWorkoutCursor(String token) : _token = token;

  @override
  String toString() => _token;
}

/// Página de sessões do modelo canônico.
class CanonicalWorkoutPage {
  final List<CanonicalWorkoutSession> sessions;
  final CanonicalWorkoutCursor? nextCursor;
  final bool hasMore;

  const CanonicalWorkoutPage({
    required this.sessions,
    this.nextCursor,
    required this.hasMore,
  });
}

/// Leitura paginada e independente da origem de sessões canônicas.
abstract class CanonicalWorkoutReader {
  Future<Result<CanonicalWorkoutPage>> history({
    required String userId,
    CanonicalWorkoutCursor? cursor,
    int limit = 20,
  });
}
