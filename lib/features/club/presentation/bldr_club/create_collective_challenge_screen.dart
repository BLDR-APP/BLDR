import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_challenge_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/challenges_v2/challenge_v2_labels.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Criar desafio em 3 passos (121:960, 121:980, 121:1016), limitado às
/// métricas que o servidor aceita.
class CreateCollectiveChallengeScreen extends StatefulWidget {
  const CreateCollectiveChallengeScreen({super.key});

  @override
  State<CreateCollectiveChallengeScreen> createState() =>
      _CreateCollectiveChallengeScreenState();
}

class _CreateCollectiveChallengeScreenState
    extends State<CreateCollectiveChallengeScreen> {
  static const _maxCoverBytes = 5 * 1024 * 1024;
  static const _durations = [7, 14, 21, 30, 60, 90];

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _target = TextEditingController(text: '20');
  int _step = 0;
  String _type = 'workouts';
  int _days = 30;
  File? _cover;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(_refresh);
    _target.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  int? get _targetValue {
    final v = int.tryParse(_target.text.trim());
    return v != null && v > 0 ? v : null;
  }

  bool get _canContinue => switch (_step) {
        0 => _title.text.trim().length >= 3,
        1 => _targetValue != null,
        _ => !_saving,
      };

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.maybePop(context);
    }
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pickCover() async {
    final l10n = AppLocalizations.of(context);
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (!mounted || picked == null) return;
    final file = File(picked.path);
    if (await file.length() > _maxCoverBytes) {
      if (mounted) _snack(l10n.chal_cover_big);
      return;
    }
    if (mounted) setState(() => _cover = file);
  }

  Future<void> _pickMetric() async {
    final l10n = AppLocalizations.of(context);
    final options = [
      (
        'workouts',
        TablerIcons.barbell,
        l10n.chal_metric_workouts,
        l10n.chal_metric_workouts_sub
      ),
      (
        'streak',
        TablerIcons.flame,
        l10n.chal_metric_streak,
        l10n.chal_metric_streak_sub
      ),
      (
        'xp_total',
        TablerIcons.bolt,
        l10n.chal_metric_xp,
        l10n.chal_metric_xp_sub
      ),
    ];
    final choice = await BldrV2Sheet.show<String>(
      context,
      title: l10n.chal_counts,
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              BldrV2SheetOption(
                icon: o.$2,
                label: o.$3,
                subtitle: o.$4,
                onTap: () => Navigator.pop(ctx, o.$1),
              ),
          ],
        ),
      ),
    );
    if (mounted && choice != null) setState(() => _type = choice);
  }

  Future<void> _pickDuration() async {
    final l10n = AppLocalizations.of(context);
    final choice = await BldrV2Sheet.show<int>(
      context,
      title: l10n.chal_duration,
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in _durations)
              BldrV2SheetOption(
                icon: TablerIcons.calendar,
                label: l10n.chal_duration_days(d),
                onTap: () => Navigator.pop(ctx, d),
              ),
          ],
        ),
      ),
    );
    if (mounted && choice != null) setState(() => _days = choice);
  }

  Future<void> _publish() async {
    final target = _targetValue;
    if (_saving || target == null) return;
    setState(() => _saving = true);
    final result = await getIt<CreateCollectiveChallenge>()(
      NewCollectiveChallenge(
        title: _title.text.trim(),
        description: _description.text.trim(),
        challengeType: _type,
        targetValue: target,
        rewardXp: 0,
        endsAt: DateTime.now().add(Duration(days: _days)).toUtc(),
        coverImagePath: _cover?.path,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      onSuccess: (_) => Navigator.pop(context, true),
      onFailure: (failure) => _snack(failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stepLabel =
        [l10n.chal_step1, l10n.chal_step2, l10n.chal_step3][_step];
    final last = _step == 2;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: BldrBackground(
        v2: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(4, 8, BldrCommunityV2.pageX, 0),
                  child: Row(
                    children: [
                      BldrCommunityBackButton(onTap: _back),
                      Expanded(
                        child: Text(l10n.chal_new_title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BldrChallengeTextV2.heading),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      BldrCommunityV2.pageX, 8, BldrCommunityV2.pageX, 0),
                  child: Text(stepLabel, style: BldrChallengeTextV2.step),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        BldrCommunityV2.pageX, 20, BldrCommunityV2.pageX, 24),
                    children: switch (_step) {
                      0 => _details(l10n),
                      1 => _rules(l10n),
                      _ => _review(l10n),
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      BldrCommunityV2.pageX, 0, BldrCommunityV2.pageX, 16),
                  child: BldrChallengeCta(
                    label: !last
                        ? l10n.chal_continue
                        : _saving
                            ? l10n.chal_publishing
                            : l10n.chal_publish,
                    onTap: !_canContinue
                        ? null
                        : last
                            ? _publish
                            : () => setState(() => _step++),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _details(AppLocalizations l10n) {
    final cover = _cover;
    return [
      Text(l10n.chal_cover, style: BldrChallengeTextV2.section),
      const SizedBox(height: 8),
      Semantics(
        button: true,
        label: l10n.chal_cover_add,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _pickCover,
          child: Container(
            constraints: const BoxConstraints(minHeight: 180),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BldrCommunityColorsV2.fieldBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BldrCommunityColorsV2.gold, width: 0.9),
            ),
            child: cover != null
                ? BldrChallengeCover(file: cover, height: 180)
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(TablerIcons.plus,
                            size: 30, color: BldrCommunityColorsV2.gold),
                        const SizedBox(height: 12),
                        Text(l10n.chal_cover_add,
                            textAlign: TextAlign.center,
                            style: BldrChallengeTextV2.pickerTitle),
                        const SizedBox(height: 4),
                        Text(l10n.chal_cover_hint,
                            textAlign: TextAlign.center,
                            style: BldrChallengeTextV2.meta),
                      ],
                    ),
                  ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      BldrSquadField(
        label: l10n.chal_name,
        hint: l10n.chal_name_hint,
        controller: _title,
        maxLength: 80,
      ),
      const SizedBox(height: 24),
      BldrSquadField(
        label: l10n.chal_desc,
        hint: l10n.chal_desc_hint,
        controller: _description,
        maxLines: 4,
        maxLength: 280,
      ),
      const SizedBox(height: 16),
      Text(l10n.chal_cover_note, style: BldrChallengeTextV2.meta),
    ];
  }

  BoxDecoration get _selectBox => BoxDecoration(
        color: BldrChallengeColorsV2.selectBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BldrChallengeColorsV2.selectBorder),
      );

  String _metricSub(AppLocalizations l10n) => switch (_type) {
        'workouts' => l10n.chal_metric_workouts_sub,
        'streak' => l10n.chal_metric_streak_sub,
        _ => l10n.chal_metric_xp_sub,
      };

  String _unit(AppLocalizations l10n) => switch (_type) {
        'workouts' => l10n.chal_metric_workouts,
        'streak' => l10n.chal_metric_streak,
        _ => l10n.chal_metric_xp,
      };

  Widget _chip(String label, bool on) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? BldrChallengeColorsV2.chipOnBg : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: on
                ? BldrCommunityColorsV2.goldBrand
                : BldrChallengeColorsV2.chipOffBorder,
          ),
        ),
        child: Text(label,
            style:
                on ? BldrChallengeTextV2.chipOn : BldrChallengeTextV2.chipOff),
      );

  List<Widget> _rules(AppLocalizations l10n) => [
        Text(l10n.chal_counts, style: BldrChallengeTextV2.section),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _pickMetric,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _selectBox,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ChallengeV2Labels.metric(l10n, _type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BldrChallengeTextV2.selectTitle),
                        const SizedBox(height: 2),
                        Text(_metricSub(l10n),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: BldrChallengeTextV2.meta),
                      ],
                    ),
                  ),
                  const Icon(TablerIcons.chevron_down,
                      size: 18, color: BldrCommunityColorsV2.goldBrand),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.chal_goal_label, style: BldrChallengeTextV2.section),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  decoration: _selectBox,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _target,
                        keyboardType: TextInputType.number,
                        maxLength: 7,
                        cursorColor: BldrCommunityColorsV2.gold,
                        style: BldrChallengeTextV2.targetValue,
                        decoration: const InputDecoration(
                          isDense: true,
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(_unit(l10n),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BldrChallengeTextV2.meta),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Semantics(
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _pickDuration,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 8, 10, 10),
                      decoration: _selectBox,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(l10n.chal_duration_days(_days),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: BldrChallengeTextV2.durationValue),
                                const SizedBox(height: 2),
                                Text(l10n.chal_duration,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: BldrChallengeTextV2.meta),
                              ],
                            ),
                          ),
                          const Icon(TablerIcons.chevron_down,
                              size: 18, color: BldrCommunityColorsV2.goldBrand),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.chal_who, style: BldrChallengeTextV2.section),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _chip(l10n.chal_public, true),
            _chip(l10n.chal_friends_soon, false),
            _chip(l10n.chal_squad_soon, false),
          ],
        ),
        const SizedBox(height: 10),
        Text(l10n.chal_public_note, style: BldrChallengeTextV2.meta),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: BldrCommunityColorsV2.fieldBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BldrChallengeColorsV2.track),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.chal_metrics_title, style: BldrChallengeTextV2.section),
              const SizedBox(height: 6),
              Text(l10n.chal_metrics_list,
                  style: BldrChallengeTextV2.infoValue),
            ],
          ),
        ),
      ];

  Widget _reviewFact(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrChallengeTextV2.pill),
          const SizedBox(height: 3),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BldrChallengeTextV2.reviewValue),
        ],
      );

  List<Widget> _review(AppLocalizations l10n) {
    final description = _description.text.trim();
    return [
      BldrChallengeCard(
        radius: 18,
        borderColor: BldrChallengeColorsV2.selectBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BldrChallengeCover(file: _cover, height: 110),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title.text.trim().toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BldrChallengeTextV2.featured),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.chal_review_meta(
                              ChallengeV2Labels.metric(l10n, _type), _days),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BldrChallengeTextV2.meta,
                        ),
                      ),
                      const SizedBox(width: 8),
                      BldrChallengePill(l10n.chal_public),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const BldrChallengeProgressBar(value: 0.06),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _reviewFact(
                          l10n.chal_goal_label,
                          ChallengeV2Labels.goal(l10n, _type, _targetValue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _reviewFact(l10n.chal_duration_upper,
                            l10n.chal_duration_days(_days)),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(
                        height: 1, color: BldrCommunityColorsV2.composeBorder),
                    const SizedBox(height: 12),
                    Text('“$description”', style: BldrChallengeTextV2.meta),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      BldrChallengeSection(l10n.chal_before),
      BldrChallengeCard(
        radius: 16,
        borderColor: BldrChallengeColorsV2.rowBorder,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.chal_before_title,
                  style: BldrChallengeTextV2.reviewNote),
              const SizedBox(height: 8),
              Text(l10n.chal_before_body, style: BldrChallengeTextV2.meta),
            ],
          ),
        ),
      ),
    ];
  }
}
