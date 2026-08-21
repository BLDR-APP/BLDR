import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/main.dart' show appNavigatorKey;
import 'package:bldr_fitness/features/achievements/presentation/achievements/widgets/achievement_badge.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/widgets/achievement_modal.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class AchievementToast extends StatefulWidget {
  final Map<String, dynamic> achievement;
  final VoidCallback onDismiss;
  /// Número de conquistas ainda na fila (inclui a atual)
  final int queueLength;

  const AchievementToast({
    Key? key,
    required this.achievement,
    required this.onDismiss,
    this.queueLength = 1,
  }) : super(key: key);

  @override
  State<AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<AchievementToast>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final AnimationController _progressCtrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  static const _kDismissDuration = Duration(seconds: 5);

  bool get _isEpic {
    final rarity = widget.achievement['rarity'] as String?;
    return rarity == 'epic' || rarity == 'legendary';
  }

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _progressCtrl = AnimationController(
      vsync: this,
      duration: _kDismissDuration,
      value: 1.0, // começa cheio e vai para 0
    );

    _slideCtrl.forward();
    _progressCtrl.reverse().then((_) => _dismiss());
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    _progressCtrl.stop();
    _slideCtrl.duration = const Duration(milliseconds: 250);
    await _slideCtrl.reverse();
    if (mounted) widget.onDismiss();
  }

  void _openModal() {
    _dismiss();
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      barrierColor: Colors.black87,
      builder: (_) => AchievementModal(
        achievement: widget.achievement,
        onDismiss: widget.onDismiss,
      ),
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name        = widget.achievement['name'] as String? ?? '';
    final description = widget.achievement['description'] as String? ?? '';
    final iconName    = widget.achievement['icon_name'] as String? ?? 'emoji_events';
    final xpValue     = (widget.achievement['xp_value'] as num?)?.toInt() ?? 0;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: _openModal,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCard(name, description, iconName, xpValue),
              const SizedBox(height: 4),
              _buildProgressBar(),
              if (widget.queueLength > 1) ...[
                const SizedBox(height: 6),
                _buildQueueDots(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      String name, String description, String iconName, int xpValue) {
    final borderColor = _isEpic
        ? const Color(0x80E0B830) // 0.5 opacity
        : const Color(0x59E0B830); // 0.35 opacity

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: BldrColors.sheetBg, // rgba(18,18,18,0.92)
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            const BoxShadow(
              color: Color(0x80000000),
              blurRadius: 32,
              offset: Offset(0, 8),
            ),
            if (_isEpic)
              BoxShadow(
                color: BldrColors.goldBright.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEpic) _buildEpicTopStripe(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildIcon(iconName),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextBlock(name, description)),
                  const SizedBox(width: 10),
                  if (xpValue > 0) _buildXpBadge(xpValue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpicTopStripe() {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8A6D1A), BldrColors.goldBright, Color(0xFF8A6D1A)],
        ),
      ),
    );
  }

  Widget _buildIcon(String iconName) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: BldrColors.goldTint,
            border: Border.all(color: BldrColors.goldBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: BldrColors.goldBright.withValues(alpha: 0.25),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: AchievementBadge(
              iconName: iconName,
              unlocked: true,
              size: 36,
            ),
          ),
        ),
        if (_isEpic)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BldrColors.goldBright,
                border: Border.all(color: BldrColors.sheetBg, width: 1.5),
              ),
              child: const Center(
                child: Text('★',
                    style: TextStyle(fontSize: 8, color: Color(0xFF121212))),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextBlock(String name, String description) {
    final label = _isEpic ? 'CONQUISTA ÉPICA' : 'CONQUISTA DESBLOQUEADA';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: BldrColors.goldBright,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: const TextStyle(
            color: BldrColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            description,
            style: const TextStyle(
              color: BldrColors.textMuted,
              fontSize: 11,
              decoration: TextDecoration.none,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildXpBadge(int xpValue) {
    final fontSize = _isEpic ? 16.0 : 12.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: BldrColors.goldTintChip,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BldrColors.goldBorderChip, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+$xpValue',
            style: TextStyle(
              color: BldrColors.goldBright,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
          const Text(
            'XP',
            style: TextStyle(
              color: BldrColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (_, __) {
        return Container(
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: BldrColors.track,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressCtrl.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: const LinearGradient(
                  colors: [BldrColors.goldDeep, BldrColors.goldBright],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueueDots() {
    final count = widget.queueLength.clamp(1, 5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == 0;
        return Container(
          width: isActive ? 8 : 5,
          height: isActive ? 8 : 5,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? BldrColors.goldBright : BldrColors.track,
          ),
        );
      }),
    );
  }
}
