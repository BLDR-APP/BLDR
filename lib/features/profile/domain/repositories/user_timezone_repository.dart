import 'package:bldr_fitness/core/errors/result.dart';

abstract class UserTimezoneRepository {
  Future<Result<String?>> getTimezone(String userId);

  /// Sincroniza somente um identificador IANA válido do dispositivo.
  Future<Result<void>> syncTimezone(String userId, String timezone);
}
