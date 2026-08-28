import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/theme/app_theme.dart';

class MultipleChoiceWidget extends StatelessWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final Function(List<String>) onOptionsChanged;
  final Map<String, String>? subtitles;

  const MultipleChoiceWidget({
    Key? key,
    required this.options,
    required this.selectedOptions,
    required this.onOptionsChanged,
    this.subtitles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedOptions.contains(option);
        final subtitle = subtitles?[option];

        return _MultiSelectCard(
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.lightImpact();
            final newSelection = List<String>.from(selectedOptions);
            if (isSelected) {
              newSelection.remove(option);
            } else {
              newSelection.add(option);
            }
            onOptionsChanged(newSelection);
          },
          child: Row(
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? AppTheme.accentGold : AppTheme.dividerGray,
                    width: 2,
                  ),
                  color: isSelected ? AppTheme.accentGold : Colors.transparent,
                ),
                child: isSelected
                    ? CustomIconWidget(
                        iconName: 'check',
                        color: AppTheme.primaryBlack,
                        size: 4.w,
                      )
                    : null,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option,
                      style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                        color: isSelected ? AppTheme.accentGold : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 0.4.h),
                      Text(
                        subtitle,
                        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MultiSelectCard extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _MultiSelectCard({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  State<_MultiSelectCard> createState() => _MultiSelectCardState();
}

class _MultiSelectCardState extends State<_MultiSelectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _shimmerAnim = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
    if (widget.isSelected) _shimmerCtrl.repeat();
  }

  @override
  void didUpdateWidget(_MultiSelectCard old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _shimmerCtrl.repeat();
    } else if (!widget.isSelected && old.isSelected) {
      _shimmerCtrl.stop();
      _shimmerCtrl.reset();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.accentGold.withValues(alpha: 0.1)
                : AppTheme.cardDark,
            border: Border.all(
              color: widget.isSelected ? AppTheme.accentGold : AppTheme.dividerGray,
              width: widget.isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.5.h),
                child: widget.child,
              ),
              if (widget.isSelected)
                AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (context, _) {
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(_shimmerAnim.value - 1, 0),
                              end: Alignment(_shimmerAnim.value + 1, 0),
                              colors: [
                                Colors.transparent,
                                const Color(0xFFD4AF37).withOpacity(0.06),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
