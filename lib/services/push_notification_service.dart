import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';

import 'package:bldr_fitness/routes/app_routes.dart';
import 'package:bldr_fitness/services/notification_service.dart';
import 'package:bldr_fitness/services/user_service.dart';

/// Roteador central para navegação por push.
/// Usado tanto no foreground (onMessageOpenedApp) quanto na central
/// de notificações (NotificationsScreen).
class NotificationRouter {
  static void navigate(
    String? type,
    Map<String, dynamic> data, {
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (type) {
      case 'duel_invite':
        final duelId = data['duel_id'] as String?;
        nav.pushNamed(AppRoutes.comunidadeScreen,
            arguments: duelId != null ? {'duel_id': duelId} : null);
      case 'ranking':
        nav.pushNamed(AppRoutes.rankingScreen);
      case 'challenge':
        nav.pushNamed(AppRoutes.comunidadeScreen);
      case 'community_post':
        nav.pushNamed(
          AppRoutes.comunidadeScreen,
          arguments:
              data['feed_id'] == null ? null : {'feed_id': data['feed_id']},
        );
      case 'community_profile':
        nav.pushNamed(
          AppRoutes.comunidadeScreen,
          arguments:
              data['user_id'] == null ? null : {'user_id': data['user_id']},
        );
      case 'streak':
        nav.pushNamed(AppRoutes.dashboard);
      case 'level_up':
        nav.pushNamed(AppRoutes.profileScreen);
      case 'run_synced':
        nav.pushNamed(AppRoutes.esportesScreen);
      case 'wearable_workout_detected':
        final activityId = data['activity_id'] as String?;
        if (activityId == null) {
          nav.pushNamed(AppRoutes.workoutsScreen);
        } else {
          nav.pushNamed(
            AppRoutes.wearableWorkoutConfirmation,
            arguments: {'activity_id': activityId},
          );
        }
      default:
        nav.pushNamed(AppRoutes.notificacoesScreen);
    }
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    // 1. Solicitar permissões
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Foreground: exibir via flutter_local_notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;

      await GetIt.instance<NotificationService>().showPushNotification(
        id: message.hashCode,
        title: notification.title ?? 'BLDR',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    });

    // 3. Background → foreground: usuário toca na notificação
    if (navigatorKey != null) {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationNavigation(message.data, navigatorKey: navigatorKey);
      });

      // App fechado: usuário toca na notificação
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationNavigation(initialMessage.data,
              navigatorKey: navigatorKey);
        });
      }
    }
  }

  void _handleNotificationNavigation(
    Map<String, dynamic> data, {
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    final type = data['type'] as String?;
    final rawActionData = data['action_data'];
    final parsed = rawActionData is String && rawActionData.isNotEmpty
        ? (jsonDecode(rawActionData) as Map<String, dynamic>)
        : rawActionData is Map
            ? Map<String, dynamic>.from(rawActionData)
            : <String, dynamic>{};

    NotificationRouter.navigate(type, parsed, navigatorKey: navigatorKey);
  }

  /// Centraliza a sincronização do token FCM com o perfil do usuário.
  /// Chamado ao ativar notificações em qualquer ponto do app.
  Future<void> syncTokenToProfile({required bool enabled}) async {
    try {
      final Map<String, dynamic> updates = {
        'notifications_enabled': enabled,
        'platform_type': Platform.isIOS ? 'ios' : 'android',
      };

      if (enabled) {
        if (Platform.isIOS) await _waitForAPNSToken();
        final token = await _fcm.getToken();
        if (token == null) throw Exception('Token FCM não obtido.');
        updates['fcm_token'] = token;
      } else {
        updates['fcm_token'] = null;
        await _fcm.deleteToken();
      }

      await UserService.instance.updateCurrentUserProfile(updates: updates);
    } catch (e) {
      if (kDebugMode) print('[PushNotificationService] syncTokenToProfile: $e');
      rethrow;
    }
  }

  Future<void> _waitForAPNSToken() async {
    for (int i = 0; i < 5; i++) {
      try {
        final apns = await _fcm.getAPNSToken();
        if (apns != null) return;
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<String?> getDeviceToken() => _fcm.getToken();
}

/// Handler de background — roda em isolate separado, não pode usar getIt.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  ));

  final notification = message.notification;
  if (notification == null) return;

  await plugin.show(
    message.hashCode,
    notification.title ?? 'BLDR',
    notification.body ?? '',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'bldr_push_channel',
        'Notificações BLDR',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: jsonEncode(message.data),
  );
}
