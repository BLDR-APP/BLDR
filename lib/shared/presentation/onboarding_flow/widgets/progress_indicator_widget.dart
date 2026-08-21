import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/theme/app_theme.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ProgressIndicatorWidget({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Passo ${currentStep + 1} de $totalSteps',
                    style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${((currentStep + 1) / totalSteps * 100).round()}%',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          // Progress track
          Container(
            width: double.infinity,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.dividerGray,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (currentStep + 1) / totalSteps,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC8952C), Color(0xFFD4AF37)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
