import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_challenge_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenge_hub_rules.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/challenges_v2/challenge_v2_labels.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/collective_challenge_detail_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Detalhe em sheet (143:1051) com "Ver tudo" para a tela completa (D10).
class ChallengeDetailSheetV2 extends StatefulWidget {
  final CollectiveChallenge challenge;
  const ChallengeDetailSheetV2({super.key, required this.challenge});

  /// Retorna true quando algo mudou e o hub precisa recarregar.
  static Future<bool> show(
      BuildContext context, CollectiveChallenge challenge) async {
    final changed = await BldrV2Sheet.show<bool>(
      context,
      title: challenge.title.toUpperCase(),
      child: ChallengeDetailSheetV2(challenge: challenge),
    );
    return changed ?? false;
  }

  @override
  State<ChallengeDetailSheetV2> createState() => _ChallengeDetailSheetV2State();
}

class _ChallengeDetailSheetV2State extends State<ChallengeDetailSheetV2> {
  bool _joining = false;

  Future<void> _join() async {
    if (_joining) return;
    setState(() => _joining = true);
    final result = await getIt<JoinCollectiveChallenge>()(widget.challenge.id);
    if (!mounted) return;
    setState(() => _joining = false);
    result.fold(
      onSuccess: (_) => Navigator.pop(context, true),
      onFailure: (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  Future<void> _openFull() async {
    final navigator = Navigator.of(context);
    navigator.pop(true);
    await navigator.push(MaterialPageRoute(
      builder: (_) =>
          CollectiveChallengeDetailScreen(challengeId: widget.challenge.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = widget.challenge;
    final days = ChallengeHubRules.daysLeft(c.endsAt, DateTime.now());
    final description = c.description?.trim() ?? '';
    final facts = [
      if (days != null)
        (days <= 1 ? l10n.chal_last_day : l10n.chal_duration_days(days))
            .toUpperCase(),
      ChallengeV2Labels.goal(l10n, c.challengeType, c.targetValue)
          .toUpperCase(),
      l10n
          .chal_participants(ChallengeV2Labels.number(l10n, c.participantCount))
          .toUpperCase(),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          BldrChallengeCover(
            imageUrl: c.coverImageUrl,
            height: 100,
            radius: BorderRadius.circular(18),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(description, style: BldrChallengeTextV2.meta),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              for (final fact in facts)
                Text(fact, style: BldrChallengeTextV2.goal),
            ],
          ),
          const SizedBox(height: 20),
          Text(l10n.chal_how, style: BldrChallengeTextV2.section),
          const SizedBox(height: 8),
          Text(ChallengeV2Labels.how(l10n, c.challengeType),
              style: BldrChallengeTextV2.sheetBody),
          const SizedBox(height: 28),
          if (!c.joined) ...[
            BldrChallengeCta(
              label: l10n.chal_join,
              minHeight: 52,
              onTap: _joining ? null : _join,
            ),
            const SizedBox(height: 10),
          ],
          BldrChallengeCta(
            label: l10n.chal_see_all,
            minHeight: 46,
            onTap: _openFull,
          ),
        ],
      ),
    );
  }
}
