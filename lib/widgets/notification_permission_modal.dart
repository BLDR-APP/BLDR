import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/services/popup_service.dart';
import 'package:bldr_fitness/services/push_notification_service.dart';
import 'package:bldr_fitness/theme/app_theme.dart';

class NotificationPermissionModal extends StatelessWidget {
  const NotificationPermissionModal({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NotificationPermissionModal(),
    );
  }

  /// Após o SO conceder a permissão, sincroniza o token FCM centralizado.
  Future<void> _syncAppToggle() async {
    try {
      await GetIt.instance<PushNotificationService>()
          .syncTokenToProfile(enabled: true);
    } catch (_) {
      // Silent: se o sync falhar, o usuário ativa pelo toggle no perfil.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.dialogDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(6.w, 5.h, 6.w, 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.accentGold.withOpacity(0.4), width: 1.5),
              ),
              child: Icon(Icons.notifications_active_outlined,
                  color: AppTheme.accentGold, size: 8.w),
            ),
            SizedBox(height: 3.h),
            Text(
              'Fique por Dentro',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.5.h),
            Text(
              'Receba lembretes de treino, conquistas e dicas personalizadas para manter sua sequência em dia.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  final settings =
                      await FirebaseMessaging.instance.requestPermission(
                    alert: true,
                    badge: true,
                    sound: true,
                  );

                  if (settings.authorizationStatus ==
                      AuthorizationStatus.authorized) {
                    await PopupService.markNotificationGranted();
                    // Sincroniza toggle interno do app (notifications_enabled +
                    // fcm_token no Supabase) para refletir no perfil.
                    await _syncAppToggle();
                  } else {
                    await PopupService.markNotificationDismissed();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.primaryBlack,
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Ativar notificações',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.5.h),
            GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
                await PopupService.markNotificationDismissed();
              },
              child: Text(
                'Agora não',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
