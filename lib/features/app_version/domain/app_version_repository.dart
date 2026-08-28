import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/services/version_service.dart';

/// Checagem de versão mínima do app (edge function `app-version`).
abstract class AppVersionRepository {
  Future<Result<bool>> shouldForceUpdate();
}

class AppVersionRepositoryImpl implements AppVersionRepository {
  const AppVersionRepositoryImpl();

  @override
  Future<Result<bool>> shouldForceUpdate() async {
    // VersionService já engole erros e retorna false (não bloqueia o app).
    return Result.success(await VersionService.shouldForceUpdate());
  }
}

class ShouldForceUpdate {
  final AppVersionRepository _repo;
  const ShouldForceUpdate(this._repo);

  Future<Result<bool>> call() => _repo.shouldForceUpdate();
}
