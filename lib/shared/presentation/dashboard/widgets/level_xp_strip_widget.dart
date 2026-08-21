import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// D2 — faixa fina de Nível/XP abaixo do nome.
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

  String _formatXp(int xp) {
    if (xp >= 1000) {
      final k = xp / 1000;
      final s = k == k.truncateToDouble()
          ? k.toStringAsFixed(0)
          : k.toStringAsFixed(1);
      return '${s}k';
    }
    return '$xp';
  }

  @override
  Widget build(BuildContext context) {
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
      xpFractionText =
          '${_formatXp(totalXp)}/${_formatXp(xpNextLevelTarget)} XP';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BldrSpacing.pageX,
        10,
        BldrSpacing.pageX,
        0,
      ),
      child: BldrGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        radius: BldrRadius.pill,
        background: BldrColors.surfaceSubtle,
        borderColor: BldrColors.borderSubtle,
        child: Row(
          children: [
            const Icon(Icons.military_tech_outlined,
                color: BldrColors.goldBright, size: 16),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).dashboard_level_label(levelText),
                style: BldrText.label.copyWith(
                  color: BldrColors.textPrimary,
                )),
            const SizedBox(width: 10),
            Expanded(
              child: BldrProgressBar(value: progress, height: 5),
            ),
            const SizedBox(width: 10),
            Text(xpFractionText, style: BldrText.meta),
          ],
        ),
      ),
    );
  }
}
