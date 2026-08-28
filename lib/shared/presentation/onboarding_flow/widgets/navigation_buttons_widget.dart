import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class NavigationButtonsWidget extends StatelessWidget {
  final bool canGoBack;
  final bool canGoNext;
  final bool isLastStep;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const NavigationButtonsWidget({
    Key? key,
    required this.canGoBack,
    required this.canGoNext,
    required this.isLastStep,
    this.isLoading = false,
    required this.onBack,
    required this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Opacity(
          opacity: canGoBack ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !canGoBack,
            child: TextButton(
              onPressed: onBack,
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    size: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    l10n.common_back_btn,
                    style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: canGoNext && !isLoading ? onNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGold,
            foregroundColor: AppTheme.primaryBlack,
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 2.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            disabledBackgroundColor: AppTheme.inactiveGray,
          ),
          child: isLoading
              ? SizedBox(
            width: 20.sp,
            height: 20.sp,
            child: const CircularProgressIndicator(
              color: AppTheme.primaryBlack,
              strokeWidth: 2.0,
            ),
          )
              : Text(
            isLastStep ? l10n.common_finish_btn : l10n.common_next_btn,
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
