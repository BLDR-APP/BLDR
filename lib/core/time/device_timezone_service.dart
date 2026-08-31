import 'package:flutter/services.dart';

/// Obtém o identificador IANA do fuso configurado no dispositivo.
///
/// O offset nunca é usado como identidade de timezone: ele não consegue
/// representar alterações de horário de verão nem regiões distintas.
class DeviceTimezoneService {
  static const _channel = MethodChannel('bldr/device_timezone');

  Future<String?> getIanaTimezone() async {
    try {
      final value = await _channel.invokeMethod<String>('getIanaTimezone');
      final timezone = value?.trim();
      if (timezone == null || timezone.isEmpty || !timezone.contains('/')) {
        return null;
      }
      return timezone;
    } on PlatformException {
      // O sincronismo não pode bloquear um usuário legado em uma plataforma
      // que ainda não exponha o canal nativo.
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
