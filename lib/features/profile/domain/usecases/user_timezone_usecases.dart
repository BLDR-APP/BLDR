import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/core/time/device_timezone_service.dart';
import 'package:bldr_fitness/features/profile/domain/repositories/user_timezone_repository.dart';

class SyncDeviceTimezone {
  const SyncDeviceTimezone(this._repository, this._deviceTimezone);

  final UserTimezoneRepository _repository;
  final DeviceTimezoneService _deviceTimezone;

  Future<Result<void>> call(String userId) async {
    final timezone = await _deviceTimezone.getIanaTimezone();
    if (timezone == null) return const Result.success(null);
    return _repository.syncTimezone(userId, timezone);
  }
}
