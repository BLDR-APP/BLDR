import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/widgets/achievement_badge.dart';

class AchievementModal extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final VoidCallback          onDismiss;
  final VoidCallback?         onViewAll;

  const AchievementModal({
    Key? key,
    required this.achievement,
    required this.onDismiss,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name        = achievement['name']        as String? ?? '';
    final description = achievement['description'] as String? ?? '';
    final iconName    = achievement['icon_name']   as String? ?? 'emoji_events';
    final xpValue     = (achievement['xp_value']   as int?)  ?? 50;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accentGold, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetes decorativos
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 10.h,
                width: double.infinity,
                child: const _ConfettiDecoration(),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                children: [
                  // Badge grande
                  AchievementBadge(iconName: iconName, unlocked: true, size: 64),
                  SizedBox(height: 2.h),

                  // Label
                  Text(
                    'CONQUISTA DESBLOQUEADA',
                    style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 1.h),

                  // Nome
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 0.8.h),

                  // Descrição
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Chip de XP
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3a2e10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '+$xpValue XP',
                      style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Botão Continuar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGold,
                        foregroundColor: const Color(0xFF1a1200),
                        padding: EdgeInsets.symmetric(vertical: 3.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continuar',
                        style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF1a1200),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  // Link "Ver todas"
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onViewAll?.call();
                    },
                    child: Text(
                      'Ver todas as conquistas →',
                      style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF888888),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confetes estáticos decorativos
// ---------------------------------------------------------------------------

class _ConfettiDecoration extends StatelessWidget {
  const _ConfettiDecoration();

  static const _colors = [
    Color(0xFFEF9F27),
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF45B7D1),
    Color(0xFF96CEB4),
    Color(0xFFFECEA8),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rng = Random(42);
        final w   = constraints.maxWidth;
        final h   = constraints.maxHeight;
        return Stack(
          children: List.generate(22, (i) {
            final x     = rng.nextDouble() * w;
            final y     = rng.nextDouble() * h;
            final cw    = 6.0 + rng.nextDouble() * 8;
            final ch    = 4.0 + rng.nextDouble() * 6;
            final angle = rng.nextDouble() * pi;
            final color = _colors[rng.nextInt(_colors.length)];
            return Positioned(
              left: x,
              top:  y,
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  width:  cw,
                  height: ch,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
