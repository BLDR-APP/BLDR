// lib/services/push_notification_service.dart (VERSÃO CORRIGIDA)

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
  PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. SOLICITAR PERMISSÕES (necessário no iOS e Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Permissão de Notificação concedida, status: ${settings.authorizationStatus}');
    }

    // 2. OBTER TOKEN (AGORA COM TRY-CATCH)

    // Este método é seguro e lida com a recuperação do token FCM,
    // que é a chave que você envia para o seu servidor.
    String? token = await _fcm.getToken();

    if (kDebugMode) {
      print("Token FCM do dispositivo: $token");
    }

    // AJUSTE CRÍTICO: Isolar a recuperação do token APNS em um try-catch.
    // O erro 'apns-token-not-set' ocorre APENAS aqui e não deve quebrar a inicialização.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        String? apnsToken = await _fcm.getAPNSToken();
        if (kDebugMode) {
          print("APNS Token (iOS): $apnsToken");
        }
      } catch (e) {
        // Ignora a falha, pois o app deve continuar mesmo sem o token APNS inicial.
        if (kDebugMode) {
          print("ATENÇÃO: Não foi possível obter o token APNS inicial, mas a inicialização continuará. Erro: $e");
        }
      }
    }


    // 3. CONFIGURAR LISTENERS (para receber mensagens em foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print('Message also contained a notification: ${message.notification!.body}');
        }
      }
    });

    // 4. CONFIGURAR INTERAÇÕES (usuário clica na notificação)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('App aberto por notificação: ${message.data}');
        }
      }
    });
  }

  // Método opcional para obter o token a qualquer momento.
  Future<String?> getDeviceToken() async {
    return _fcm.getToken();
  }
}