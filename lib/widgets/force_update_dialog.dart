import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bldr_fitness/theme/app_theme.dart';

class ForceUpdateDialog extends StatelessWidget {
  const ForceUpdateDialog({super.key});

  // TODO: substituir pela URL real da Play Store do app
  static const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.bldr_fitness.app';

  // TODO: substituir pela URL real da App Store do app
  static const _appStoreUrl = 'https://apps.apple.com/us/app/bldr/id6754264412';

  Future<void> _openStore() async {
    final url = Uri.parse(Platform.isIOS ? _appStoreUrl : _playStoreUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppTheme.darkTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Text(
          'Atualização Necessária',
          textAlign: TextAlign.center,
          style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Uma nova versão do BLDR está disponível. Atualize agora para continuar usando o app.',
          textAlign: TextAlign.center,
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openStore,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Atualizar agora',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
