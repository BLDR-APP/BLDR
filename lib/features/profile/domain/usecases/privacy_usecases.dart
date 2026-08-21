import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/profile/domain/entities/privacy_settings.dart';
import 'package:bldr_fitness/features/profile/domain/repositories/privacy_repository.dart';

class GetPrivacySettings {
  final PrivacyRepository _repo;
  const GetPrivacySettings(this._repo);
  Future<Result<PrivacySettings>> call(String userId) => _repo.getPrivacySettings(userId);
}

class SavePrivacySettings {
  final PrivacyRepository _repo;
  const SavePrivacySettings(this._repo);
  Future<Result<void>> call(String userId, PrivacySettings settings) =>
      _repo.savePrivacySettings(userId, settings);
}
