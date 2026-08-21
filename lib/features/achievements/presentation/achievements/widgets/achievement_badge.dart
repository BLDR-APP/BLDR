import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/widgets/custom_icon_widget.dart';

class AchievementBadge extends StatelessWidget {
  final String iconName;
  final bool   unlocked;
  final double size;

  const AchievementBadge({
    Key? key,
    required this.iconName,
    required this.unlocked,
    this.size = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: unlocked
            ? const Color(0xFF3a2e10)
            : const Color(0xFF2a2a2a),
        border: Border.all(
          color: unlocked
              ? AppTheme.accentGold
              : const Color(0xFF333333),
          width: unlocked ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: iconName,
          color: unlocked
              ? AppTheme.accentGold
              : const Color(0xFF555555),
          size: size * 0.48,
        ),
      ),
    );
  }
}
