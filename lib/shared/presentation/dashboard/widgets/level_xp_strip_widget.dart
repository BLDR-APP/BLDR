import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// D2 — faixa fina de Nível/XP abaixo do nome (visual v2, Figma 57:388).
///
/// Consome o use case JÁ EXISTENTE `GetMyRankingEntry` (nenhuma assinatura de
/// domain/data foi tocada).
///
/// Nunca retorna vazio: enquanto carrega ou se genuinamente não há entrada de
/// ranking, mostra "—" nos campos em vez de esconder a faixa — evita que
/// a tela pareça travada/quebrada enquanto o dado ainda não chegou.
///
/// DUPLICAÇÃO CONHECIDA: a curva de níveis (`_levelThresholds`) é uma cópia
/// do literal em `bldr_club_screen.dart:238`. Não existe hoje um lugar
/// compartilhado para essa regra — documentado como dívida no INVENTARIO.md.
/// Se a curva mudar, os dois pontos precisam ser atualizados juntos até que
/// seja extraída para o domain do Club.
class LevelXpStripWidget extends StatefulWidget {
  const LevelXpStripWidget({super.key});

  @override
  State<LevelXpStripWidget> createState() => _LevelXpStripWidgetState();
}

class _LevelXpStripWidgetState extends State<LevelXpStripWidget> {
  static const Map<int, int> _levelThresholds = {
    1: 0,
    2: 1000,
    3: 2500,
    4: 5000,
    5: 10000,
  };

  ClubRankingEntry? _entry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<GetMyRankingEntry>()();
    if (mounted) setState(() => _entry = result.valueOrNull);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final entry = _entry;

    String levelText = '—';
    double progress = 0;
    String xpFractionText = '—';

    if (entry != null) {
      final level = entry.currentLevel;
      final totalXp = entry.xpTotal;
      levelText = '$level';

      final xpStartOfLevel = _levelThresholds[level] ?? 0;
      final xpNextLevelTarget =
          _levelThresholds[level + 1] ?? (xpStartOfLevel + 10000);
      final xpGainedInThisLevel = totalXp - xpStartOfLevel;
      final xpNeededForThisLevel = xpNextLevelTarget - xpStartOfLevel;
      progress = xpNeededForThisLevel > 0
          ? (xpGainedInThisLevel / xpNeededForThisLevel).clamp(0.0, 1.0)
          : 0.0;
      xpFractionText = l10n.dashboard_v2_level_xp(
        HomeV2Format.xpCompact(totalXp, locale),
        HomeV2Format.xpCompact(xpNextLevelTarget, locale),
      );
    }

    final pageX = BldrSpacingV2.pageX(MediaQuery.sizeOf(context).width);

    // Faixa v2 (Figma "02 — LEVEL & XP"): pílula 386 × 28 só com borda;
    // texto em x=16, trilho de 139 em x=126, fração alinhada a 13 da borda.
    return Padding(
      padding: EdgeInsets.fromLTRB(pageX, BldrSpacingV2.headerToLevel, pageX, 0),
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BldrRadiusV2.levelStrip),
          border: Border.all(color: BldrColorsV2.goldBorderSoft),
        ),
        child: LayoutBuilder(builder: (context, c) {
          final s = (c.maxWidth + 2) / 386;
          return Padding(
            padding: const EdgeInsets.only(left: 15, right: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 110 * s,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '✦  ${l10n.dashboard_level_label(levelText)}',
                      maxLines: 1,
                      style: BldrTextV2.level,
                    ),
                  ),
                ),
                SizedBox(
                  width: 139 * s,
                  child: BldrBarV2(
                    value: progress,
                    height: 2.5,
                    radius: BldrRadiusV2.levelBar,
                    trackColor: BldrColorsV2.levelTrack,
                    fillGradient: BldrColorsV2.levelFillGradient,
                    borderColor: BldrColorsV2.goldBorderSoft,
                  ),
                ),
                const Spacer(),
                Text(xpFractionText, maxLines: 1, style: BldrTextV2.xp),
              ],
            ),
          );
        }),
      ),
    );
  }
}
