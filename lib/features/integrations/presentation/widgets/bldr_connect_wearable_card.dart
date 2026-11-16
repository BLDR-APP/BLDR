import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/routes/app_routes.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Card "Conecte seu wearable" (Figma 57:382). Fica SEMPRE por último na
/// pilha de wearables. Com algum wearable já conectado, o título vira
/// "Conecte outro dispositivo" (mesmo visual).
///
/// O botão abre Configurações (seção Integrações) pela rota existente —
/// o app não tem tela própria de dispositivos. Nunca leva à tela do WHOOP.
class BldrConnectWearableCard extends StatelessWidget {
  final bool hasConnectedDevice;

  const BldrConnectWearableCard({super.key, this.hasConnectedDevice = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BldrSolidCard(
      height: BldrStackV2.activeHeight,
      color: BldrWearableColorsV2.connectSurface,
      borderColor: BldrColorsV2.whoopCardBorder,
      radius: BldrRadiusV2.wearableCard,
      // Posições do mockup (relativas ao card): rótulo 15, título 37,
      // texto 67, CTA 115 (40 de altura), margens laterais 17.
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.wearable_connect_label, style: BldrTextV2.wearableLabel),
          const SizedBox(height: 9.9),
          Text(
            hasConnectedDevice
                ? l10n.wearable_connect_title_other
                : l10n.wearable_connect_title_first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BldrTextV2.wearableTitle,
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 27,
            child: Text(
              l10n.wearable_connect_body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BldrTextV2.wearableBody11,
            ),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pushNamed(context, AppRoutes.settingsScreen),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    BldrWearableColorsV2.connectCtaRadius),
                border: Border.all(color: BldrColorsV2.gold),
              ),
              child: Text('${l10n.wearable_connect_cta}   ›',
                  style: BldrTextV2.wearableCta),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
