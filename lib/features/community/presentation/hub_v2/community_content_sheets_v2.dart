import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/entities/pr_history.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';
import 'package:bldr_fitness/features/integrations/presentation/widgets/bldr_whoop_card.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Ver atividade (Figma 22:391). Métricas sem dado não aparecem.
class CommunityActivitySheetV2 extends StatelessWidget {
  final CommunityPost post;
  const CommunityActivitySheetV2({super.key, required this.post});

  static Future<void> show(BuildContext context, CommunityPost post) {
    final l10n = AppLocalizations.of(context);
    final p = post.typedPayload;
    final name = post.eventType == CommunityEventType.wearableActivity
        ? p.wearableActivityType?.trim()
        : p.activityType?.trim();
    return BldrV2Sheet.show<void>(
      context,
      title: name == null || name.isEmpty
          ? l10n.comm_activity_default
          : CommunityV2Format.activityName(name),
      child: CommunityActivitySheetV2(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final p = post.typedPayload;
    final wearable = post.eventType == CommunityEventType.wearableActivity;
    final km = wearable ? p.wearableDistanceKm : p.distanceKm;
    final seconds = wearable ? p.wearableDurationSeconds : p.durationSeconds;
    final calories = wearable ? p.wearableCalories : p.calories;
    final source = CommunityV2Format.providerLabel(p.wearableProvider);
    final pace = CommunityV2Format.pace(seconds, km);
    final started = p.wearableStartedAt;
    final isWhoop = p.wearableProvider?.toLowerCase().trim() == 'whoop';

    final metrics = <(String, String)>[
      if (km != null)
        (
          '${CommunityV2Format.decimal(km, locale)} km',
          l10n.comm_label_distance
        ),
      if (seconds != null)
        (CommunityV2Format.clock(seconds), l10n.comm_label_duration),
      if (p.wearableAverageHeartRate case final hr?)
        ('$hr bpm', l10n.comm_label_hr),
      if (pace != null) ('$pace/km', l10n.comm_label_pace),
      if (calories != null) ('$calories kcal', l10n.comm_label_calories),
      if (p.wearableMaxHeartRate case final hr?)
        ('$hr bpm', l10n.comm_label_hr_max),
      if (p.wearableStrain case final s?)
        (
          CommunityV2Format.decimal(s, locale, digits: 1),
          l10n.comm_label_strain
        ),
    ];
    final rows = <List<(String, String)>>[
      for (var i = 0; i < metrics.length; i += 3)
        metrics.sublist(i, i + 3 > metrics.length ? metrics.length : i + 3),
    ];
    final details = <(String, String)>[
      if (source != null) (l10n.comm_detail_source, source),
      if (started != null)
        (l10n.comm_detail_start, DateFormat.Hm(locale).format(started)),
    ];
    final handle = post.username == null ? null : '@${post.username}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (handle != null)
          Text(
            [l10n.comm_imported_by(handle), if (source != null) source]
                .join(' · '),
            textAlign: TextAlign.center,
            style: BldrCommunityTextV2.sheetSub,
          ),
        const SizedBox(height: 16),
        Text(l10n.comm_type_imported, style: BldrCommunityTextV2.type),
        for (final row in rows) ...[
          const SizedBox(height: 12),
          BldrCommunitySheetMetrics(items: row),
          const SizedBox(height: 12),
          const BldrCommunitySheetDivider(),
        ],
        if (details.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.comm_section_details, style: BldrCommunityTextV2.section),
          const SizedBox(height: 4),
          for (final d in details)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(d.$1, style: BldrCommunityTextV2.detailLabel),
                  Text(d.$2, style: BldrCommunityTextV2.detailValue),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const BldrCommunitySheetDivider(),
        ],
        const SizedBox(height: 16),
        Text(l10n.comm_activity_note, style: BldrCommunityTextV2.sheetSub),
        if (isWhoop) ...[
          const SizedBox(height: 12),
          const BldrWhoopAttribution(),
        ],
      ],
    );
  }
}

/// Ver evolução do PR (Figma 22:525).
class CommunityPrSheetV2 extends StatefulWidget {
  final CommunityPost post;
  const CommunityPrSheetV2({super.key, required this.post});

  static Future<void> show(BuildContext context, CommunityPost post) =>
      BldrV2Sheet.show<void>(
        context,
        title: post.exerciseName ?? AppLocalizations.of(context).comm_type_pr,
        child: CommunityPrSheetV2(post: post),
      );

  @override
  State<CommunityPrSheetV2> createState() => _CommunityPrSheetV2State();
}

class _CommunityPrSheetV2State extends State<CommunityPrSheetV2> {
  bool _loading = true;
  List<PrHistoryEntry> _history = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exercise = widget.post.exerciseName;
    if (exercise == null) {
      setState(() => _loading = false);
      return;
    }
    final result = await getIt<CommunityFeedRepository>()
        .fetchPrHistory(userId: widget.post.userId, exercise: exercise);
    if (!mounted) return;
    setState(() {
      _history = result.valueOrNull ?? const [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final post = widget.post;
    final weight = post.prWeightKg ?? 0;
    final reps = post.prReps ?? 1;
    final e1rm = post.e1rm ?? PrEvolution.epley(weight, reps);
    final evolution = PrEvolution.from(
      history: _history,
      postDate: post.createdAt.toLocal(),
      weightKg: weight,
      e1rm: e1rm,
    );
    String signed(double v, int digits) =>
        '${v >= 0 ? '+' : ''}${CommunityV2Format.decimal(v, locale, digits: digits)}';
    final now = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (post.username != null)
          Text(l10n.comm_pr_by('@${post.username}'),
              textAlign: TextAlign.center, style: BldrCommunityTextV2.sheetSub),
        const SizedBox(height: 16),
        Text(l10n.comm_type_pr, style: BldrCommunityTextV2.type),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${CommunityV2Format.kg(weight, locale)} × $reps',
            maxLines: 1,
            style: BldrCommunityTextV2.prValue,
          ),
        ),
        if (evolution.deltaKg case final d?) ...[
          const SizedBox(height: 2),
          Text(l10n.comm_pr_delta(signed(d, d % 1 == 0 ? 0 : 1)),
              style: BldrCommunityTextV2.prDelta),
        ],
        const SizedBox(height: 16),
        BldrCommunitySheetMetrics(items: [
          (
            CommunityV2Format.kg(e1rm.roundToDouble(), locale),
            l10n.comm_label_e1rm
          ),
          if (evolution.previous case final prev?)
            (
              CommunityV2Format.kg(prev.weightKg, locale),
              l10n.comm_label_prev_pr
            ),
          if (evolution.deltaPercent case final pct?)
            ('${signed(pct, 1)}%', l10n.comm_label_evolution),
        ]),
        const SizedBox(height: 14),
        const BldrCommunitySheetDivider(),
        const SizedBox(height: 16),
        Text(l10n.comm_section_recent, style: BldrCommunityTextV2.section),
        const SizedBox(height: 4),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                  color: BldrCommunityColorsV2.gold, strokeWidth: 2),
            ),
          )
        else if (_history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child:
                Text(l10n.comm_pr_private, style: BldrCommunityTextV2.sheetSub),
          )
        else
          for (var i = 0; i < _history.length && i < 5; i++) ...[
            if (i > 0) const BldrCommunitySheetDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isToday(_history[i].performedOn)
                        ? l10n.comm_today
                        : CommunityV2Format.shortDate(
                            _history[i].performedOn, locale),
                    style: BldrCommunityTextV2.historyDate,
                  ),
                  Text(
                    '${CommunityV2Format.kg(_history[i].weightKg, locale)} × ${_history[i].reps}',
                    style: BldrCommunityTextV2.exercise,
                  ),
                ],
              ),
            ),
          ],
        const SizedBox(height: 16),
        Text(l10n.comm_pr_note, style: BldrCommunityTextV2.sheetSub),
      ],
    );
  }
}

/// Editar a legenda do próprio post. Devolve o texto ao salvar.
class CommunityEditPostSheetV2 extends StatefulWidget {
  final String initial;
  const CommunityEditPostSheetV2({super.key, required this.initial});

  static Future<String?> show(BuildContext context, String initial) =>
      BldrV2Sheet.show<String>(
        context,
        title: AppLocalizations.of(context).comm_action_edit,
        child: CommunityEditPostSheetV2(initial: initial),
      );

  @override
  State<CommunityEditPostSheetV2> createState() =>
      _CommunityEditPostSheetV2State();
}

class _CommunityEditPostSheetV2State extends State<CommunityEditPostSheetV2> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextSelectionTheme(
          data: const TextSelectionThemeData(
            selectionHandleColor: BldrCommunityColorsV2.gold,
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            cursorColor: BldrCommunityColorsV2.gold,
            style: BldrCommunityTextV2.exercise
                .copyWith(fontWeight: FontWeight.w400),
            decoration: InputDecoration(
              hintText: l10n.comm_edit_hint,
              hintStyle: BldrCommunityTextV2.sheetSub,
              counterStyle: BldrCommunityTextV2.sheetSub,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BldrCommunityV2.ctaRadius),
                borderSide: const BorderSide(
                    color: BldrCommunityColorsV2.discoverBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BldrCommunityV2.ctaRadius),
                borderSide: const BorderSide(color: BldrCommunityColorsV2.gold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        BldrV2SheetButton(
          label: l10n.comm_edit_save,
          onTap: () => Navigator.pop(context, _controller.text),
        ),
      ],
    );
  }
}
