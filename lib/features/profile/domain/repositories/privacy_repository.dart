import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/profile/domain/entities/privacy_settings.dart';

abstract class PrivacyRepository {
  Future<Result<PrivacySettings>> getPrivacySettings(String userId);
  Future<Result<void>> savePrivacySettings(String userId, PrivacySettings settings);
}
