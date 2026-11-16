import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Card ativo do Garmin (Figma 57:383). Componente VISUAL: recebe valores
/// prontos; não existe integração Garmin no app. Só entra na pilha da Home
/// quando houver conexão Garmin.
///
/// Cores exatamente as do mockup (`BldrGarminColors`), por exigência do
/// manual de marca da Garmin. Logo oficial sem recolorir (sem
/// colorBlendMode).
class BldrGarminCard extends StatelessWidget {
  final int? bodyBattery;
  final int? restingHr;
  final int? sleepScore;

  const BldrGarminCard({
    super.key,
    this.bodyBattery,
    this.restingHr,
    this.sleepScore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BldrSolidCard(
      height: BldrStackV2.activeHeight,
      color: BldrGarminColors.surface,
      borderColor: BldrGarminColors.border,
      radius: BldrRadiusV2.wearableCard,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 25.773,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Image.asset(
                    'assets/images/garmin/garmin_logo_tag_white.jpg',
                    width: 75,
                    height: 25.773,
                    fit: BoxFit.cover,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 3, right: 33),
                  child: Text(l10n.whoop_card_today_caps,
                      style: BldrTextV2.whoopToday
                          .copyWith(color: BldrGarminColors.today)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11.2),
          SizedBox(
            height: 74,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Metric(
                    value: bodyBattery?.toString() ?? '--',
                    label: l10n.garmin_body_battery,
                    valueColor: BldrGarminColors.bodyBattery,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    value: restingHr == null ? '--' : '$restingHr bpm',
                    label: l10n.garmin_resting_hr,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    value: sleepScore?.toString() ?? '--',
                    label: l10n.garmin_sleep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              l10n.garmin_footer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrTextV2.garminFooter,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _Metric({
    required this.value,
    required this.label,
    this.valueColor = BldrGarminColors.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 6, 0),
      decoration: BoxDecoration(
        color: BldrGarminColors.metricBox,
        borderRadius: BorderRadius.circular(BldrGarminColors.metricRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: BldrTextV2.garminValue.copyWith(color: valueColor)),
          ),
          const SizedBox(height: 8.8),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrTextV2.garminLabel),
        ],
      ),
    );
  }
}
