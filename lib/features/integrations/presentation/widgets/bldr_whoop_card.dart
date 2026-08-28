import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/whoop_entities.dart';
import 'package:bldr_fitness/features/integrations/presentation/whoop_connect_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

// Paleta oficial Whoop — Brand & Design Guidelines
const _kWhoopRecoveryHigh = Color(0xFF16EC06); // High Recovery 100–67%
const _kWhoopRecoveryMed  = Color(0xFFFFDE00); // Medium Recovery 66–34%
const _kWhoopRecoveryLow  = Color(0xFFFF0026); // Low Recovery 33–0%
const _kWhoopRecoveryBlue = Color(0xFF67AEE6); // Recovery sem valor
const _kWhoopStrain       = Color(0xFF0093E7); // Strain
const _kWhoopSleep        = Color(0xFF7BA1BB); // Sleep
const _kWhoopTrack        = Color(0x12FFFFFF);

Color _recoveryColor(int? score) {
  if (score == null) return _kWhoopRecoveryBlue;
  if (score >= 67) return _kWhoopRecoveryHigh;
  if (score >= 34) return _kWhoopRecoveryMed;
  return _kWhoopRecoveryLow;
}

class BldrWhoopCard extends StatelessWidget {
  final WhoopDailyData? data;
  final bool isConnected;
  final bool isSyncing;

  const BldrWhoopCard({
    super.key,
    required this.data,
    required this.isConnected,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isConnected) return _buildDisconnected(context);
    if (isSyncing || data == null) return _buildSyncing(context);
    return _buildConnected(context, data!);
  }

  Widget _buildDisconnected(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WhoopHeader(),
          const SizedBox(height: 10),
          Text(
            l10n.whoop_card_connect_subtitle,
            style: BldrText.description,
          ),
          const SizedBox(height: 14),
          BldrSecondaryButton(
            label: l10n.whoop_card_connect_btn,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WhoopConnectScreen()),
            ),
          ),
          const SizedBox(height: 12),
          const _WhoopAttribution(),
        ],
      ),
    );
  }

  Widget _buildSyncing(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WhoopHeader(trailing: Text(l10n.whoop_card_today)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (_) => _SkeletonRing()),
          ),
          const SizedBox(height: 12),
          const _WhoopAttribution(),
        ],
      ),
    );
  }

  Widget _buildConnected(BuildContext context, WhoopDailyData d) {
    final l10n = AppLocalizations.of(context);
    final tip = _recoveryTip(l10n, d.recoveryScore);
    final recovColor = _recoveryColor(d.recoveryScore);
    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WhoopHeader(trailing: Text(l10n.whoop_card_today)),
          const SizedBox(height: 16),
          // Ordem correta: Sleep → Recovery → Strain
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Ring(
                value: (d.sleepScore ?? 0) / 100,
                color: _kWhoopSleep,
                label: l10n.whoop_card_sleep_label,
                display: '${d.sleepScore ?? '--'}%',
              ),
              _Ring(
                value: (d.recoveryScore ?? 0) / 100,
                color: recovColor,
                label: l10n.whoop_card_recovery_label,
                display: '${d.recoveryScore ?? '--'}%',
              ),
              _Ring(
                value: ((d.strainScore ?? 0) / 21).clamp(0.0, 1.0),
                color: _kWhoopStrain,
                label: l10n.whoop_card_strain_label,
                display: d.strainScore != null
                    ? d.strainScore!.toStringAsFixed(1)
                    : '--',
              ),
            ],
          ),
          if (tip != null) ...[
            const SizedBox(height: 12),
            Text(tip, style: BldrText.meta),
          ],
          const SizedBox(height: 12),
          const _WhoopAttribution(),
        ],
      ),
    );
  }

  String? _recoveryTip(AppLocalizations l10n, int? score) {
    if (score == null) return null;
    if (score < 34) return l10n.whoop_card_recovery_tip_low;
    if (score < 67) return l10n.whoop_card_recovery_tip_med;
    return l10n.whoop_card_recovery_tip_high;
  }
}

// Header com Wordmark oficial WHOOP (branco) — guidelines: min 100px de largura.
// Height 18 em @2x garante nitidez equivalente a ≥100px lógicos.
class _WhoopHeader extends StatelessWidget {
  final Widget? trailing;

  const _WhoopHeader({this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/whoop/whoop_logo_white.png',
          height: 18,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        if (trailing != null)
          DefaultTextStyle(style: BldrText.meta, child: trailing!),
      ],
    );
  }
}

// Atribuição obrigatória — "DATA BY WHOOP" conforme Attribution guidelines.
// Logo deve ser branco ou preto; não usar colorBlendMode para mudar a cor.
class _WhoopAttribution extends StatelessWidget {
  const _WhoopAttribution();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'DATA BY ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          Image.asset(
            'assets/images/whoop/whoop_logo_white.png',
            height: 9,
            fit: BoxFit.contain,
            // Sem colorBlendMode — logo permanece branco conforme guidelines
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double value;
  final Color color;
  final String label;
  final String display;

  const _Ring({
    required this.value,
    required this.color,
    required this.label,
    required this.display,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(
            painter: _RingPainter(value: value.clamp(0.0, 1.0), color: color),
            child: Center(
              child: Text(
                display,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Labels em ALL CAPS + 10% letter-spacing conforme Whoop Typography
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9, // ≈10% de 9px
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;

  const _RingPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    paint.color = _kWhoopTrack;
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}

class _SkeletonRing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kWhoopTrack, width: 10),
      ),
    );
  }
}
