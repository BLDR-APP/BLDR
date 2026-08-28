import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:bldr_fitness/models/version_check_model.dart';

class VersionService {
  static const _edgeFunctionUrl =
      'https://vhxwujoymxkxyiognual.supabase.co/functions/v1/app-version';

  static Future<bool> shouldForceUpdate() async {
    try {
      final dio = Dio();
      final response = await dio.get(_edgeFunctionUrl);

      final model = VersionCheckModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = packageInfo.version;

      return _isOlderThan(installedVersion, model.minimumVersion);
    } catch (_) {
      return false;
    }
  }

  static bool _isOlderThan(String installed, String minimum) {
    final a = installed.split('.').map(int.parse).toList();
    final b = minimum.split('.').map(int.parse).toList();

    for (int i = 0; i < b.length; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = b[i];
      if (av < bv) return true;
      if (av > bv) return false;
    }
    return false;
  }
}
