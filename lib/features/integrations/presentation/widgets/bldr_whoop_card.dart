import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/whoop_entities.dart';
import 'package:bldr_fitness/features/integrations/presentation/whoop_connect_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

Color _recoveryColor(int? score) {
  if (score == null) return BldrWhoopColors.recoveryEmpty;
  if (score >= 67) return BldrWhoopColors.recoveryHigh;
  if (score >= 34) return BldrWhoopColors.recoveryMed;
  return BldrWhoopColors.recoveryLow;
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
    if (isSyncing) return _buildSyncing(context);
    // Sincronização terminou sem nenhum valor: antes caía no skeleton para
    // sempre. Agora mostra "Dados indisponíveis" (Figma 57:381).
    if (data == null) return _buildUnavailable(context);
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

  /// Rebranding v2 (Figma 57:384): sincronizando = mesma superfície do card
  /// conectado, com os anéis só no trilho.
  Widget _buildSyncing(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _WhoopV2Surface(
      rings: [
        _RingSpec(null, BldrColorsV2.ringTrack, '', l10n.whoop_card_sleep_label),
        _RingSpec(
            null, BldrColorsV2.ringTrack, '', l10n.whoop_card_recovery_label),
        _RingSpec(null, BldrColorsV2.ringTrack, '', l10n.whoop_card_strain_label),
      ],
    );
  }

  /// Rebranding v2 (Figma 57:381): conectado, mas sem dados de hoje.
  /// Sem atribuição "DATA BY WHOOP" — nenhum dado do WHOOP é exibido.
  Widget _buildUnavailable(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BldrSolidCard(
      height: _WhoopV2Surface.height,
      gradient: BldrColorsV2.whoopCardGradient,
      borderColor: BldrColorsV2.whoopCardBorder,
      radius: BldrRadiusV2.wearableCard,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth + 2;
        double x(double ref) => ref * w / 386 - 1;
        return Stack(
          children: [
            Positioned(
              left: x(17),
              top: 13,
              child: Image.asset(
                'assets/images/whoop/whoop_logo_white.png',
                height: 18,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: x(315),
              top: 16,
              child: Text('—', style: BldrTextV2.whoopToday),
            ),
            Positioned(
              left: x(18),
              right: x(18),
              top: 62,
              child: Text(
                l10n.whoop_unavailable_title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrTextV2.wearableTitle
                    .copyWith(color: BldrWearableColorsV2.unavailableTitle),
              ),
            ),
            Positioned(
              left: x(18),
              right: x(18),
              top: 94,
              child: Text(
                l10n.whoop_unavailable_body,
                maxLines: 2,
                style: BldrTextV2.wearableBody12,
              ),
            ),
            Positioned(
              left: x(18) - 4,
              top: 129,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WhoopConnectScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text('${l10n.whoop_unavailable_cta}   ›',
                      style: BldrTextV2.wearableLink),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Rebranding v2 (Figma 57:384). Ordem oficial: Sleep → Recovery → Strain.
  /// A dica de recovery saiu da Home (decisão 4 do plano aprovado);
  /// `_recoveryTip` continua aqui para quando houver slot.
  Widget _buildConnected(BuildContext context, WhoopDailyData d) {
    final l10n = AppLocalizations.of(context);
    return _WhoopV2Surface(
      rings: [
        _RingSpec(
          (d.sleepScore ?? 0) / 100,
          BldrWhoopColors.sleep,
          '${d.sleepScore ?? '--'}%',
          l10n.whoop_card_sleep_label,
        ),
        _RingSpec(
          (d.recoveryScore ?? 0) / 100,
          _recoveryColor(d.recoveryScore),
          '${d.recoveryScore ?? '--'}%',
          l10n.whoop_card_recovery_label,
        ),
        _RingSpec(
          ((d.strainScore ?? 0) / 21).clamp(0.0, 1.0),
          BldrWhoopColors.strain,
          d.strainScore != null ? d.strainScore!.toStringAsFixed(1) : '--',
          l10n.whoop_card_strain_label,
        ),
      ],
    );
  }

  // ignore: unused_element
  String? _recoveryTip(AppLocalizations l10n, int? score) {
    if (score == null) return null;
    if (score < 34) return l10n.whoop_card_recovery_tip_low;
    if (score < 67) return l10n.whoop_card_recovery_tip_med;
    return l10n.whoop_card_recovery_tip_high;
  }
}

class _RingSpec {
  final double? value;
  final Color color;
  final String display;
  final String label;
  const _RingSpec(this.value, this.color, this.display, this.label);
}

/// Superfície do card ativo do WHOOP (v2): gradiente #283339 → #101518,
/// borda rgba(57,71,76,0.8), raio 18, altura 173. Posições horizontais são
/// frações da largura do mockup (386) para adaptar em telas menores.
class _WhoopV2Surface extends StatelessWidget {
  final List<_RingSpec> rings;

  const _WhoopV2Surface({required this.rings});

  static const double _refWidth = 386;
  static const double height = 173;
  static const double _ring = 73;
  static const _ringCenters = [68.5, 190.5, 312.5];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BldrSolidCard(
      height: height,
      gradient: BldrColorsV2.whoopCardGradient,
      borderColor: BldrColorsV2.whoopCardBorder,
      radius: BldrRadiusV2.wearableCard,
      child: LayoutBuilder(builder: (context, c) {
        // A borda de 1 px fica por dentro: compensa para manter as posições
        // do mockup relativas à borda externa.
        final w = c.maxWidth + 2;
        double x(double ref) => ref * w / _refWidth - 1;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Wordmark oficial — guidelines: ≥100 px de largura (altura 18).
            Positioned(
              left: x(17),
              top: 13,
              child: Image.asset(
                'assets/images/whoop/whoop_logo_white.png',
                height: 18,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: x(315),
              top: 16,
              child: Text(l10n.whoop_card_today_caps,
                  style: BldrTextV2.whoopToday),
            ),
            for (var i = 0; i < rings.length; i++) ...[
              Positioned(
                left: x(_ringCenters[i]) - _ring / 2,
                top: 51,
                child: BldrMetricRing(
                  value: rings[i].value,
                  color: rings[i].color,
                  display: rings[i].display,
                ),
              ),
              Positioned(
                left: x(_ringCenters[i]) - 52.5,
                width: 105,
                top: 130,
                child: Text(
                  rings[i].label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: BldrTextV2.ringLabel,
                ),
              ),
            ],
            Positioned(
              left: x(17),
              top: 151,
              child: const _WhoopAttribution(v2: true),
            ),
          ],
        );
      }),
    );
  }
}

// Header com Wordmark oficial WHOOP (branco) — guidelines: min 100px de largura.
// Height 18 em @2x garante nitidez equivalente a ≥100px lógicos.
class _WhoopHeader extends StatelessWidget {
  const _WhoopHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/whoop/whoop_logo_white.png',
          height: 18,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

// Atribuição obrigatória — "DATA BY WHOOP" conforme Attribution guidelines.
// Logo deve ser branco ou preto; não usar colorBlendMode para mudar a cor.
class _WhoopAttribution extends StatelessWidget {
  /// `false` = visual da fase 1 (alinhado à direita, 45% de opacidade),
  /// usado pelo estado desconectado enquanto o node 57:382 não é feito.
  final bool v2;

  const _WhoopAttribution({this.v2 = false});

  // Tamanhos mínimos mantidos (texto 9, logo com altura 9) — exceção às
  // medidas do Figma registrada no CLAUDE.md. Branco, sem colorBlendMode.
  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: v2 ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: v2 ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        const Text(
          'DATA BY ',
          style: TextStyle(
            fontFamily: BldrText.family,
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
    );
    return v2 ? row : Opacity(opacity: 0.45, child: row);
  }
}
