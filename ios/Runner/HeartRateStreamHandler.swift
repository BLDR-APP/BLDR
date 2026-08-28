import Flutter

class HeartRateStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(
      withArguments arguments: Any?,
      eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    HealthKitService.shared.startHeartRateMonitoring(eventSink: events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    HealthKitService.shared.stopHeartRateMonitoring()
    return nil
  }
}
