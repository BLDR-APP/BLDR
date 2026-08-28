import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class SummaryWidget extends StatelessWidget {
  final Map<String, dynamic> responses;
  final Function(String) onEdit;

  const SummaryWidget({
    Key? key,
    required this.responses,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).onboarding_summary_review_title,
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.accentGold,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          ...responses.entries
              .map((entry) => _buildSummaryItem(context, entry.key, entry.value)),
          SizedBox(height: 4.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.accentGold,
                  size: 8.w,
                ),
                SizedBox(height: 2.h),
                Text(
                  AppLocalizations.of(context).onboarding_summary_perfect_body,
                  textAlign: TextAlign.center,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String key, dynamic value) {
    String displayValue = '';
    if (value is List) {
      displayValue = (value).join(', ');
    } else {
      displayValue = value.toString();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatKey(key),
                style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => onEdit(key),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppLocalizations.of(context).onboarding_summary_edit_btn,
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            displayValue,
            style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  static const Map<String, String> _keyLabels = {
    'experience_level': 'Nível de Experiência',
    'workout_frequency_days': 'Frequência de Treino',
    'workout_duration_range': 'Duração por Sessão',
    'workout_environment': 'Local de Treino',
    'home_equipment': 'Equipamentos em Casa',
    'muscle_focus': 'Foco Muscular',
    'split_preference': 'Divisão de Treino',
    'injuries': 'Lesões / Limitações',
  };

  String _formatKey(String key) {
    if (_keyLabels.containsKey(key)) return _keyLabels[key]!;
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
