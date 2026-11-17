import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_share_data.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_summary_data.dart';
import 'package:bldr_fitness/features/workouts/presentation/share/workout_share_preview.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_map.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/muscle_normalizer.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/summary_v2_format.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutSummaryData data;
  const WorkoutSummaryScreen({super.key, required this.data});
  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  late WorkoutShareData _shareData;
  bool _isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _shareData = WorkoutShareData.fromSummary(widget.data);
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) BldrMuscleMap.precache(context);
    });
  }

  Future<void> _loadProfile() async {
    WorkoutShareData? loadedShareData;
    try {
      final profile = await UserService.instance.getCurrentUserProfile();
      if (profile != null) {
        debugPrint(
            '[ShareCard] username="${profile.username}" avatarUrl="${profile.avatarUrl}" fullName="${profile.fullName}"');
        loadedShareData = WorkoutShareData.fromSummary(
          widget.data,
          username: profile.username,
          fullName: profile.fullName,
          avatarUrl: profile.avatarUrl,
        );
      } else {
        debugPrint('[ShareCard] profile is null — handle não será exibido');
      }
    } catch (error) {
      debugPrint('[WorkoutShare] Perfil indisponível: $error');
    } finally {
      if (mounted) {
        setState(() {
          if (loadedShareData != null) _shareData = loadedShareData;
          _isProfileLoading = false;
        });
      }
    }
  }

  void _goHome() => Navigator.popUntil(context, (r) => r.isFirst);

  void _openShare() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutSharePreview(data: _shareData),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = _shareData;
    final hasHighlights = d.prs.isNotEmpty || d.xpEarned != null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        backgroundColor: BldrColorsV2.bg,
        body: BldrBackground(
          v2: true,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 40, 18, 24),
              children: [
                _SummaryHeaderV2(data: d),
                const SizedBox(height: 22),
                _SectionLabel(l10n.sm_session),
                _MetricsCardV2(data: d),
                if (hasHighlights) ...[
                  const SizedBox(height: 24),
                  _SectionLabel(l10n.sm_highlights),
                  _HighlightsCardV2(data: d),
                ],
                if (d.muscleMapData != null) ...[
                  const SizedBox(height: 24),
                  _SectionLabel(l10n.sm_muscles),
                  _MusclesCardV2(data: d),
                ],
                const SizedBox(height: 29),
                _SummaryButton(
                  label: l10n.sm_share,
                  icon: TablerIcons.arrow_up_right,
                  onTap: _isProfileLoading ? null : _openShare,
                ),
                const SizedBox(height: 12),
                _SummaryButton(
                  label: l10n.sm_finish,
                  filled: true,
                  onTap: _goHome,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Text(text, style: BldrSummaryTextV2.section),
      );
}

class _SummaryHeaderV2 extends StatelessWidget {
  final WorkoutShareData data;
  const _SummaryHeaderV2({required this.data});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: BldrSummaryColorsV2.badgeBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: BldrSummaryColorsV2.badgeBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(TablerIcons.check,
                size: 12, color: BldrActiveColorsV2.gold),
            const SizedBox(width: 6),
            Text(l10n.sm_done_badge, style: BldrSummaryTextV2.badge),
          ]),
        ),
        const SizedBox(height: 14),
        Text(data.workoutName.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BldrSummaryTextV2.name),
        const SizedBox(height: 4),
        Text(data.summary.completedAtLabel.toUpperCase(),
            style: BldrSummaryTextV2.meta),
        const SizedBox(height: 16),
        Text(l10n.sm_message, style: BldrSummaryTextV2.message),
      ],
    );
  }
}

/// Layout estreito: 320 px ou fonte grande (largura útil / escala < 330).
bool _isNarrow(BuildContext context, double width) =>
    width / MediaQuery.textScalerOf(context).scale(1) < 330;

BoxDecoration _cardDecoration() => BoxDecoration(
      color: BldrActiveColorsV2.mediaBg,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: BldrSummaryColorsV2.cardBorder),
    );

class _MetricsCardV2 extends StatelessWidget {
  final WorkoutShareData data;
  const _MetricsCardV2({required this.data});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final metrics =
        <({String label, String value, String? suffix, bool accent})>[
      if (data.durationSeconds case final s?)
        (
          label: l10n.sm_duration,
          value: SummaryV2Format.clock(s),
          suffix: null,
          accent: false
        ),
      if (data.totalVolume case final v?)
        (
          label: l10n.sm_volume,
          value: HomeV2Format.thousands(v, locale),
          suffix: l10n.sm_kg,
          accent: true
        ),
      if (data.totalSets case final n?)
        (label: l10n.sm_sets, value: '$n', suffix: null, accent: false),
      if (data.exerciseCount case final n?)
        (label: l10n.sm_exercises, value: '$n', suffix: null, accent: false),
    ];
    if (metrics.isEmpty) return const SizedBox.shrink();
    Widget cell(int i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(children: [
            Text(metrics[i].label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrSummaryTextV2.metricLabel),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(metrics[i].value,
                  maxLines: 1,
                  style: metrics[i].accent
                      ? BldrSummaryTextV2.metricAccent
                      : BldrSummaryTextV2.metricValue),
            ),
            if (metrics[i].suffix != null) ...[
              const SizedBox(height: 4),
              Text(metrics[i].suffix!, style: BldrSummaryTextV2.metricSuffix),
            ],
          ]),
        );
    Widget row(List<int> idx) => IntrinsicHeight(
          child: Row(children: [
            for (var j = 0; j < idx.length; j++) ...[
              if (j > 0)
                Container(width: 1, color: BldrSummaryColorsV2.divider),
              Expanded(child: cell(idx[j])),
            ],
          ]),
        );
    return LayoutBuilder(builder: (context, c) {
      final all = [for (var i = 0; i < metrics.length; i++) i];
      final narrow = _isNarrow(context, c.maxWidth) && metrics.length > 2;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: _cardDecoration(),
        child: narrow
            ? Column(children: [
                row(all.take(2).toList()),
                const SizedBox(height: 10),
                row(all.skip(2).toList()),
              ])
            : row(all),
      );
    });
  }
}

class _HighlightsCardV2 extends StatelessWidget {
  final WorkoutShareData data;
  const _HighlightsCardV2({required this.data});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pr = data.prs.isEmpty ? null : data.prs.first;
    final xp = data.xpEarned;
    Widget box({required Widget child, required Color bg}) => Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BldrSummaryColorsV2.badgeBorder),
          ),
          child: child,
        );
    final prBox = pr == null
        ? null
        : box(
            bg: BldrSummaryColorsV2.prBg,
            child: Column(children: [
              Text(l10n.sm_new_pr, style: BldrSummaryTextV2.hlLabel),
              const SizedBox(height: 6),
              Text(
                  l10n.sm_pr_value(
                      pr.exerciseName, SummaryV2Format.kg(pr.newWeightKg)),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BldrSummaryTextV2.prValue),
              if (pr.previousWeightKg case final prev?
                  when pr.newWeightKg > prev) ...[
                const SizedBox(height: 4),
                Text(
                    l10n.sm_pr_delta(SummaryV2Format.kg(pr.newWeightKg - prev)),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrSummaryTextV2.hlHint),
              ],
            ]),
          );
    final xpBox = xp == null
        ? null
        : box(
            bg: BldrSummaryColorsV2.badgeBg,
            child: Column(children: [
              Text(l10n.sm_xp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrSummaryTextV2.hlLabel),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('+$xp', style: BldrSummaryTextV2.xpValue),
              ),
              Text(l10n.sm_xp_hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrSummaryTextV2.hlHint),
            ]),
          );
    return LayoutBuilder(builder: (context, c) {
      final narrow = _isNarrow(context, c.maxWidth);
      return Container(
        padding: const EdgeInsets.all(13),
        decoration: _cardDecoration(),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (prBox != null) prBox,
                  if (prBox != null && xpBox != null)
                    const SizedBox(height: 12),
                  if (xpBox != null) xpBox,
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (prBox != null) Expanded(flex: 2, child: prBox),
                    if (prBox != null && xpBox != null)
                      const SizedBox(width: 12),
                    if (xpBox != null) Expanded(child: xpBox),
                  ],
                ),
              ),
      );
    });
  }
}

class _MusclesCardV2 extends StatelessWidget {
  final WorkoutShareData data;
  const _MusclesCardV2({required this.data});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final map = data.muscleMapData!;
    final view = MuscleNormalizer.dominantView(map.muscles);
    final top = SummaryV2Format.topMuscles(data);
    final phrase = top.length >= 2
        ? l10n.sm_phrase_two(top[0].label, top[1].label.toLowerCase())
        : top.length == 1
            ? l10n.sm_phrase_one(top[0].label)
            : null;
    final rows = [
      for (final m in top)
        if (SummaryV2Format.level(m.score) case final lv?) (m.label, lv),
    ];
    final mapBox = Container(
      width: 112,
      height: 132,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: BldrActiveColorsV2.mediaInner,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BldrActiveColorsV2.mediaInnerBorder),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: BldrMuscleMap(
          muscles: map.muscles,
          view: view,
          size: BldrMuscleMapSize.summary,
        ),
      ),
    );
    final details = Column(children: [
      const SizedBox(height: 4),
      Text(
          view == BldrMuscleMapView.back
              ? l10n.sm_emphasis_back
              : l10n.sm_emphasis_front,
          textAlign: TextAlign.center,
          style: BldrSummaryTextV2.emphasis),
      if (phrase != null) ...[
        const SizedBox(height: 8),
        Text(phrase,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: BldrSummaryTextV2.phrase),
      ],
      const SizedBox(height: 12),
      for (final (label, lv) in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Expanded(
              child: Text(label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrSummaryTextV2.muscle),
            ),
            Expanded(
              child: Text(
                  lv == SummaryMuscleLevel.high
                      ? l10n.sm_level_high
                      : l10n.sm_level_moderate,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: lv == SummaryMuscleLevel.high
                      ? BldrSummaryTextV2.levelHigh
                      : BldrSummaryTextV2.levelModerate),
            ),
          ]),
        ),
    ]);
    return LayoutBuilder(builder: (context, c) {
      final narrow = _isNarrow(context, c.maxWidth);
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: narrow
            ? Column(children: [mapBox, const SizedBox(height: 12), details])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mapBox,
                  const SizedBox(width: 16),
                  Expanded(child: details),
                ],
              ),
      );
    });
  }
}

class _SummaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback? onTap;
  const _SummaryButton(
      {required this.label, this.icon, this.filled = false, this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: onTap == null ? 0.5 : 1,
            child: Container(
              height: filled ? 52 : 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filled ? BldrSummaryColorsV2.doneBg : null,
                borderRadius: BorderRadius.circular(filled ? 26 : 29),
                border: Border.all(color: BldrActiveColorsV2.goldBrand),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: BldrActiveColorsV2.goldBrand),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: filled
                          ? BldrSummaryTextV2.done
                          : BldrSummaryTextV2.share),
                ),
              ]),
            ),
          ),
        ),
      );
}
