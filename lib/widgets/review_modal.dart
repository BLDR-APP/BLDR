import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bldr_fitness/services/popup_service.dart';
import 'package:bldr_fitness/theme/app_theme.dart';

class ReviewModal extends StatelessWidget {
  const ReviewModal({Key? key}) : super(key: key);

  // TODO: update with actual Apple App Store numeric ID after publishing
  static const _appStoreUrl = 'https://apps.apple.com/br/app/bldr/id6745490620';
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.bldr_fitness.app';

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ReviewModal(),
    );
  }

  Future<void> _openStore() async {
    final url = Platform.isIOS ? _appStoreUrl : _playStoreUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
              child: Icon(Icons.emoji_events_outlined,
                  color: AppTheme.accentGold, size: 8.w),
            ),
            SizedBox(height: 3.h),
            Text(
              'Adorando o BLDR?',
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
              'Sua avaliação ajuda outras pessoas a encontrar o app e nos motiva a continuar melhorando.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.w),
                  child: Icon(Icons.star_rounded,
                      color: AppTheme.accentGold, size: 8.w),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await PopupService.markReviewRated();
                  await _openStore();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.primaryBlack,
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Avaliar agora',
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
                await PopupService.markReviewRated();
              },
              child: Text(
                'Já avaliei',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            SizedBox(height: 2.h),
            GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
                await PopupService.markReviewDismissed();
              },
              child: Text(
                'Agora não',
                style: TextStyle(
                  color: AppTheme.inactiveGray,
                  fontSize: 13,
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
