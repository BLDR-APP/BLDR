import UIKit
import Flutter
import FirebaseCore // <-- 1. IMPORTAMOS O CORE
import FirebaseMessaging

@UIApplicationMain
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