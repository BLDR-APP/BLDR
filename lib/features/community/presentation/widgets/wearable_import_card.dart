import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/theme/bldr_tokens.dart';

class WearableImportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onImport;
  final VoidCallback onDismiss;

  const WearableImportCard({
    super.key,
    required this.data,
    required this.onImport,
    required this.onDismiss,
  });

  bool get _isWhoop => data['provider'] == 'whoop' || data['source'] == 'whoop';

  // ── Detecção estática ──────────────────────────────────────────────────────

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bgColor = _isWhoop
        ? const Color(0x14FF0000) // rgba(255,0,0,0.08)
        : BldrColors.surface;
    final borderColor = _isWhoop
        ? const Color(0x33FF0000) // rgba(255,0,0,0.2)
        : BldrColors.border;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildMetrics(),
          const SizedBox(height: 12),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final dotColor = _isWhoop ? const Color(0xFFFF0000) : BldrColors.goldBright;
    final name = _isWhoop ? 'Whoop' : 'Apple Health';

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: BldrText.cardTitle.copyWith(
            color: _isWhoop ? const Color(0xFFFF5050) : BldrColors.textPrimary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            data['activity_type']?.toString() ?? 'Atividade recente',
            style: BldrText.meta,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics() {
    final metrics = <(String label, String? value)>[];

    if (_isWhoop) {
      final strain = data['strain'];
      final duration = (data['duration_s'] as num?)?.toInt();
      final averageHr = data['average_heart_rate'];
      if (strain != null) metrics.add(('STRAIN', strain.toStringAsFixed(1)));
      if (duration != null) metrics.add(('DURAÇÃO', '${duration ~/ 60}min'));
      if (averageHr != null) metrics.add(('FC MÉD.', '${averageHr}bpm'));
    } else {
      final dur = data['duration_min'];
      final kcal = data['calorias'];
      final fc = data['fc_media'];
      if (dur != null) metrics.add(('DURAÇÃO', '${dur}min'));
      if (kcal != null) metrics.add(('KCAL', '$kcal'));
      if (fc != null) metrics.add(('FC MÉD.', '${fc}bpm'));
    }

    if (metrics.isEmpty) return const SizedBox.shrink();

    return Row(
      children: metrics
          .map((m) => Expanded(
                child: Column(
                  children: [
                    Text(
                      m.$2 ?? '—',
                      style: BldrText.kpiMd.copyWith(
                        color: _isWhoop
                            ? const Color(0xFFFF5050)
                            : BldrColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(m.$1, style: BldrText.metaSm),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildActions() {
    final accentColor =
        _isWhoop ? const Color(0xFFFF5050) : BldrColors.goldBright;
    final btnBg = _isWhoop
        ? const Color(0x26FF0000) // rgba(255,0,0,0.15)
        : const Color(0x1FE0B830);
    final btnBorder =
        _isWhoop ? const Color(0x4DFF0000) : const Color(0x33E0B830);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onImport,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: btnBg,
                border: Border.all(color: btnBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(TablerIcons.download, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    'Importar',
                    style: BldrText.buttonPrimary.copyWith(color: accentColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onDismiss,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: BldrColors.surface,
              border: Border.all(color: BldrColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Ignorar', style: BldrText.body),
          ),
        ),
      ],
    );
  }
}
