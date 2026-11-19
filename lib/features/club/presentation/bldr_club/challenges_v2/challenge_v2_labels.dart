import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

/// Textos derivados do tipo do desafio.
abstract final class ChallengeV2Labels {
  static String number(AppLocalizations l10n, num? value) =>
      CommunityV2Format.thousands(value ?? 0, l10n.localeName);

  static String progress(AppLocalizations l10n, CollectiveChallenge c) {
    final a = number(l10n, c.currentValue);
    final b = number(l10n, c.targetValue);
    return switch (c.challengeType) {
      'workouts' => l10n.chal_prog_workouts(a, b),
      'streak' => l10n.chal_prog_streak(a, b),
      _ => l10n.chal_prog_xp(a, b),
    };
  }

  static String goal(AppLocalizations l10n, String? type, num? target) {
    final a = number(l10n, target);
    return switch (type) {
      'workouts' => l10n.chal_unit_workouts(a),
      'streak' => l10n.chal_unit_streak(a),
      _ => l10n.chal_unit_xp(a),
    };
  }

  static String metric(AppLocalizations l10n, String? type) => switch (type) {
        'workouts' => l10n.chal_metric_workouts,
        'streak' => l10n.chal_metric_streak,
        _ => l10n.chal_metric_xp,
      };

  static String how(AppLocalizations l10n, String? type) => switch (type) {
        'workouts' => l10n.chal_how_workouts,
        'streak' => l10n.chal_how_streak,
        _ => l10n.chal_how_xp,
      };
}
