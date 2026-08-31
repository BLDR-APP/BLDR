import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/theme/bldr_tokens.dart';

class WearableActivityGridCard extends StatelessWidget {
  static const _whoopStrain = Color(0xFF0093E7);
  static const _appleAccent = Color(0xFFE5E5EA);

  final Map<String, dynamic> data;
  final bool selected;
  final VoidCallback onTap;

  const WearableActivityGridCard({
    super.key,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final durationSeconds = (data['duration_s'] as num?)?.toInt();
    final calories = (data['calories'] as num?)?.round();
    final averageHeartRate = (data['average_heart_rate'] as num?)?.round();
    final strain = data['strain'] as num?;
    final activity = _formatActivity(data['activity_type']?.toString());
    final provider = data['provider']?.toString() ?? 'whoop';
    final isWhoop = provider == 'whoop';
    final accent = isWhoop ? _whoopStrain : _appleAccent;
    final providerName = isWhoop ? 'WHOOP' : 'Apple Watch';

    return Semantics(
      button: true,
      selected: selected,
      label: '$activity, atividade importada do $providerName',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color:
                selected ? accent.withValues(alpha: 0.12) : BldrColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : BldrColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isWhoop)
                    Image.asset(
                      'assets/images/whoop/whoop_puck_white.png',
                      width: 30,
                      height: 30,
                    )
                  else
                    const Icon(
                      TablerIcons.brand_apple,
                      size: 30,
                      color: Colors.white,
                    ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? accent : Colors.transparent,
                      border: Border.all(
                        color: selected ? accent : BldrColors.textTertiary,
                      ),
                    ),
                    child: selected
                        ? Icon(
                            TablerIcons.check,
                            size: 14,
                            color: isWhoop ? Colors.white : Colors.black,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                activity,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BldrText.cardTitle,
              ),
              const Spacer(),
              if (strain != null)
                _Metric(
                  value: strain.toStringAsFixed(1),
                  label: 'STRAIN',
                  emphasized: true,
                  accent: accent,
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 5,
                children: [
                  if (durationSeconds != null)
                    _InlineMetric(
                      icon: TablerIcons.clock,
                      value: '${durationSeconds ~/ 60} min',
                    ),
                  if (averageHeartRate != null)
                    _InlineMetric(
                      icon: TablerIcons.heart_rate_monitor,
                      value: '$averageHeartRate bpm',
                    ),
                  if (calories != null)
                    _InlineMetric(
                      icon: TablerIcons.flame,
                      value: '$calories kcal',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IMPORTED FROM', style: BldrText.metaSm),
                  const SizedBox(height: 4),
                  if (isWhoop)
                    Image.asset(
                      'assets/images/whoop/whoop_logo_white.png',
                      width: 100,
                      fit: BoxFit.contain,
                    )
                  else
                    Text(
                      'Apple Watch',
                      style: BldrText.cardTitle.copyWith(fontSize: 14),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatActivity(String? value) {
    if (value == null || value.trim().isEmpty) return 'Atividade';
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final bool emphasized;
  final Color? accent;

  const _Metric({
    required this.value,
    required this.label,
    this.emphasized = false,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: BldrText.kpiMd.copyWith(
            color: emphasized
                ? accent ?? WearableActivityGridCard._whoopStrain
                : BldrColors.textPrimary,
          ),
        ),
        Text(label, style: BldrText.label),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InlineMetric({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: BldrColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: BldrText.meta.copyWith(color: BldrColors.textSecondary),
        ),
      ],
    );
  }
}
