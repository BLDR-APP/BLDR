import UIKit
import Flutter
import FirebaseCore // <-- 1. IMPORTAMOS O CORE
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 2. CONFIGURA O FIREBASE NATIVAMENTE (Lê o .plist)
    //    Isso conserta o Push. O Dart vai se conectar a isto.
    FirebaseApp.configure()

    // 3. PEDE AO IOS PARA SE REGISTRAR
    application.registerForRemoteNotifications()

    // 4. DEFINE O DELEGATE (O "OUVINTE")
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)

    // HealthKit channels
    if let controller = window?.rootViewController as? FlutterViewController {
      let methodChannel = FlutterMethodChannel(
        name: "bldr/healthkit",
        binaryMessenger: controller.binaryMessenger)
      methodChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "requestPermission":
          HealthKitService.shared.requestPermission(result: result)
        case "checkPermission":
          HealthKitService.shared.checkPermission(result: result)
        case "fetchTodayCaloriesBurned":
          HealthKitService.shared.fetchTodayCaloriesBurned(result: result)
        case "fetchRecentWorkouts":
          let args = call.arguments as? [String: Any]
          let lookbackHours = (args?["lookbackHours"] as? NSNumber)?.doubleValue ?? 168
          let limit = (args?["limit"] as? NSNumber)?.intValue ?? 20
          HealthKitService.shared.fetchRecentWorkouts(
            lookbackHours: lookbackHours,
            limit: limit,
            result: result)
        case "saveCalories":
          guard let args = call.arguments as? [String: Any],
                let calories = args["calories"] as? Double,
                let startTs = args["startTimestamp"] as? Double,
                let endTs = args["endTimestamp"] as? Double else {
            result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            return
          }
          HealthKitService.shared.saveWorkoutCalories(
            calories: calories,
            startTimestamp: startTs,
            endTimestamp: endTs,
            result: result)
        case "stopHeartRateMonitoring":
          HealthKitService.shared.stopHeartRateMonitoring()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let eventChannel = FlutterEventChannel(
        name: "bldr/healthkit/heartrate",
        binaryMessenger: controller.binaryMessenger)
      eventChannel.setStreamHandler(HeartRateStreamHandler())

      // App Group channel — lê/remove runs autônomos do Watch
      let appGroupChannel = FlutterMethodChannel(
        name: "com.bldr.fitness/appgroup",
        binaryMessenger: controller.binaryMessenger)
      appGroupChannel.setMethodCallHandler { call, result in
        let defaults = UserDefaults(suiteName: "group.com.bldr.fitness")
        switch call.method {
        case "getAppGroupValue":
          guard let args = call.arguments as? [String: Any],
                let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            return
          }
          if let data = defaults?.data(forKey: key),
             let str = String(data: data, encoding: .utf8) {
            result(str)
          } else {
            result(nil)
          }
        case "removeAppGroupValue":
          guard let args = call.arguments as? [String: Any],
                let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            return
          }
          defaults?.removeObject(forKey: key)
          result(nil)
        case "readRestAction":
          guard let action = defaults?.string(forKey: "bldr_rest_action") else {
            result(nil)
            return
          }
          let payload: [String: Any] = [
            "action": action,
            "activityId": defaults?.string(forKey: "bldr_rest_action_activity_id") ?? "",
            "actionId": defaults?.string(forKey: "bldr_rest_action_id") ?? "",
            "endTimestamp": defaults?.double(forKey: "bldr_rest_action_end") ?? 0,
            "totalSeconds": defaults?.integer(forKey: "bldr_rest_action_total") ?? 0,
            "timestamp": defaults?.double(forKey: "bldr_rest_action_timestamp") ?? 0,
          ]
          result(payload)
        case "ackRestAction":
          guard let args = call.arguments as? [String: Any],
                let actionId = args["actionId"] as? String,
                let activityId = args["activityId"] as? String,
                defaults?.string(forKey: "bldr_rest_action_id") == actionId,
                defaults?.string(forKey: "bldr_rest_action_activity_id") == activityId else {
            result(false)
            return
          }
          defaults?.removeObject(forKey: "bldr_rest_action")
          defaults?.removeObject(forKey: "bldr_rest_action_activity_id")
          defaults?.removeObject(forKey: "bldr_rest_action_id")
          defaults?.removeObject(forKey: "bldr_rest_action_end")
          defaults?.removeObject(forKey: "bldr_rest_action_total")
          defaults?.removeObject(forKey: "bldr_rest_action_timestamp")
          result(true)
        case "discardRestAction":
          guard let args = call.arguments as? [String: Any],
                let actionId = args["actionId"] as? String,
                defaults?.string(forKey: "bldr_rest_action_id") == actionId else {
            result(false)
            return
          }
          defaults?.removeObject(forKey: "bldr_rest_action")
          defaults?.removeObject(forKey: "bldr_rest_action_activity_id")
          defaults?.removeObject(forKey: "bldr_rest_action_id")
          defaults?.removeObject(forKey: "bldr_rest_action_end")
          defaults?.removeObject(forKey: "bldr_rest_action_total")
          defaults?.removeObject(forKey: "bldr_rest_action_timestamp")
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let timezoneChannel = FlutterMethodChannel(
        name: "bldr/device_timezone",
        binaryMessenger: controller.binaryMessenger)
      timezoneChannel.setMethodCallHandler { call, result in
        guard call.method == "getIanaTimezone" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(TimeZone.current.identifier)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 5. MÉTODO CRUCIAL: Entrega o token APNS (da Apple) para o Firebase
  override func application(_ application: UIApplication,
  didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // 6. MÉTODO CRUCIAL: Lida com falha no registro
  override func application(_ application: UIApplication,
  didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Falha ao registrar para notificações remotas: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
