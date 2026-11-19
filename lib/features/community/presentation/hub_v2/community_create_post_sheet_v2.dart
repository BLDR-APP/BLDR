import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post_draft.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_profile.dart';
import 'package:bldr_fitness/features/community/domain/entities/recent_workout.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';
import 'package:bldr_fitness/features/community/presentation/widgets/wearable_activity_grid_card.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Criar publicação (Figma 32:202, 42:452, 42:1022, 46:602, 50:702).
/// Atividade manual fica oculta (D3) e cada post tem uma foto (D5).
class CommunityCreatePostSheetV2 extends StatefulWidget {
  final String? preselectedWorkoutId;
  final String? preselectedSource;
  final List<CommunityDraftPr> preselectedPrs;

  const CommunityCreatePostSheetV2({
    super.key,
    this.preselectedWorkoutId,
    this.preselectedSource,
    this.preselectedPrs = const [],
  });

  /// Devolve true quando a publicação foi criada.
  static Future<bool> show(
    BuildContext context, {
    String? preselectedWorkoutId,
    String? preselectedSource,
    List<CommunityDraftPr> preselectedPrs = const [],
  }) async {
    final created = await BldrV2Sheet.show<bool>(
      context,
      title: AppLocalizations.of(context).comm_create_post,
      child: CommunityCreatePostSheetV2(
        preselectedWorkoutId: preselectedWorkoutId,
        preselectedSource: preselectedSource,
        preselectedPrs: preselectedPrs,
      ),
    );
    return created ?? false;
  }

  @override
  State<CommunityCreatePostSheetV2> createState() =>
      _CommunityCreatePostSheetV2State();
}

class _CommunityCreatePostSheetV2State
    extends State<CommunityCreatePostSheetV2> {
  final _repo = getIt<CommunityFeedRepository>();
  final _caption = TextEditingController();

  CommunityProfile? _profile;
  List<RecentWorkout> _workouts = const [];
  bool _workoutsLoading = true;

  String? _workoutId;
  String? _workoutSource;
  RecentWorkout? _workout;
  bool _includePrs = true;
  Map<String, dynamic>? _wearable;
  File? _photo;

  String _visibility = 'public';
  String? _squadId;
  String? _squadTitle;
  bool _publishing = false;

  bool get _canPublish =>
      _caption.text.trim().isNotEmpty ||
      _workoutId != null ||
      _wearable != null ||
      _photo != null;

  @override
  void initState() {
    super.initState();
    _workoutId = widget.preselectedWorkoutId;
    _workoutSource = widget.preselectedSource;
    _caption.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await _repo.fetchCurrentCommentProfile();
    final workouts = await _repo.fetchRecentWorkouts();
    if (!mounted) return;
    setState(() {
      _profile = profile.valueOrNull;
      _workouts = workouts.valueOrNull ?? const [];
      _workoutsLoading = false;
      for (final w in _workouts) {
        if (w.id == _workoutId) {
          _workout = w;
          _workoutSource = w.source;
        }
      }
    });
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pickWorkout() async {
    final l10n = AppLocalizations.of(context);
    final picked = await BldrV2Sheet.show<RecentWorkout>(
      context,
      title: l10n.comm_pick_workout,
      child: _WorkoutPicker(workouts: _workouts, loading: _workoutsLoading),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _workoutId = picked.id;
      _workoutSource = picked.source;
      _workout = picked;
      _wearable = null;
    });
  }

  Future<void> _pickWearable() async {
    final l10n = AppLocalizations.of(context);
    final provider = await BldrV2Sheet.show<String>(
      context,
      title: l10n.comm_pick_wearable,
      child: const _WearableSourcePicker(),
    );
    if (!mounted || provider == null) return;
    final record = await BldrV2Sheet.show<Map<String, dynamic>>(
      context,
      title: l10n.comm_records_title,
      child: _WearableRecordPicker(provider: provider),
    );
    if (!mounted || record == null) return;
    setState(() {
      _wearable = record;
      _workoutId = null;
      _workoutSource = null;
      _workout = null;
    });
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    final source = await BldrV2Sheet.show<ImageSource>(
      context,
      title: l10n.comm_add_photo,
      child: Builder(
        builder: (ctx) => Column(
          children: [
            BldrV2SheetOption(
              icon: TablerIcons.photo,
              label: l10n.comm_photo_gallery,
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            BldrV2SheetOption(
              icon: TablerIcons.camera,
              label: l10n.comm_photo_camera,
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (!mounted || picked == null) return;
    setState(() => _photo = File(picked.path));
  }

  Future<void> _pickVisibility() async {
    final l10n = AppLocalizations.of(context);
    final choice = await BldrV2Sheet.show<String>(
      context,
      title: l10n.comm_visibility,
      child: Builder(
        builder: (ctx) => Column(
          children: [
            BldrCommunitySheetRow(
              icon: TablerIcons.world,
              title: l10n.comm_vis_public,
              subtitle: l10n.comm_vis_public_sub,
              onTap: () => Navigator.pop(ctx, 'public'),
            ),
            BldrCommunitySheetRow(
              icon: TablerIcons.users_group,
              title: l10n.comm_vis_squad,
              subtitle: l10n.comm_vis_squad_sub,
              onTap: () => Navigator.pop(ctx, 'squad'),
            ),
            BldrCommunitySheetRow(
              icon: TablerIcons.lock,
              title: l10n.comm_vis_private,
              subtitle: l10n.comm_vis_private_sub,
              onTap: () => Navigator.pop(ctx, 'private'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice != 'squad') {
      setState(() {
        _visibility = choice;
        _squadId = null;
        _squadTitle = null;
      });
      return;
    }
    final squads = (await getIt<ArenaRepository>().mySquads()).valueOrNull ??
        const <Map<String, dynamic>>[];
    if (!mounted) return;
    if (squads.isEmpty) {
      _snack(l10n.comm_vis_no_squad);
      return;
    }
    final squad = await BldrV2Sheet.show<Map<String, dynamic>>(
      context,
      title: l10n.comm_pick_squad,
      child: Builder(
        builder: (ctx) => Column(
          children: [
            for (final s in squads)
              BldrCommunitySheetRow(
                icon: TablerIcons.users_group,
                title: s['title']?.toString() ?? 'Squad',
                subtitle: l10n.comm_vis_squad_sub,
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (!mounted || squad == null) return;
    setState(() {
      _visibility = 'squad';
      _squadId = squad['id'].toString();
      _squadTitle = squad['title']?.toString() ?? 'Squad';
    });
  }

  Future<void> _publish() async {
    if (!_canPublish || _publishing) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _publishing = true);
    String? photoUrl;
    final photo = _photo;
    if (photo != null) {
      final upload = await _repo.uploadCommunityPhoto(
        bytes: await photo.readAsBytes(),
        extension: photo.path.split('.').last,
      );
      if (!mounted) return;
      if (upload.isFailure) {
        _snack(upload.failureOrNull!.message);
        setState(() => _publishing = false);
        return;
      }
      photoUrl = upload.valueOrNull;
    }
    final draft = CommunityPostDraft(
      caption: _caption.text,
      workoutId: _workoutId,
      workoutSource: _workoutSource,
      workout: _workout,
      includePrs: _includePrs,
      prs: widget.preselectedPrs,
      wearable: _wearable,
      photoUrl: photoUrl,
    );
    final result = await _repo.createPost(
      eventType: draft.eventType,
      payload: draft.toPayload(),
      visibility: _visibility,
      squadId: _visibility == 'squad' ? _squadId : null,
    );
    if (!mounted) return;
    if (result.isFailure) {
      _snack(result.failureOrNull?.message ?? l10n.comm_publish_error);
      setState(() => _publishing = false);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = _profile?.displayName ?? '';
    final username = _profile?.username;
    final visLabel = switch (_visibility) {
      'squad' => _squadTitle ?? l10n.comm_vis_squad,
      'private' => l10n.comm_vis_private,
      _ => l10n.comm_vis_public,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            BldrCommunityAvatar(
                name: name, imageUrl: _profile?.avatarUrl, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrCommunityTextV2.name),
                  if (username != null)
                    Text('@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrCommunityTextV2.meta),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _caption,
          minLines: 1,
          maxLines: 5,
          maxLength: 2000,
          cursorColor: BldrCommunityColorsV2.gold,
          style: BldrCommunityTextV2.composeInput,
          decoration: InputDecoration(
            hintText: l10n.comm_compose_prompt,
            hintStyle: BldrCommunityTextV2.composeHint,
            counterText: '',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _TypeTab(
              icon: TablerIcons.barbell,
              label: l10n.comm_compose_workout,
              active: _workoutId != null,
              onTap: _pickWorkout,
            ),
            _TypeTab(
              icon: TablerIcons.device_watch,
              label: l10n.comm_compose_wearable,
              active: _wearable != null,
              onTap: _pickWearable,
            ),
            _TypeTab(
              icon: TablerIcons.camera,
              label: l10n.comm_compose_photo,
              active: _photo != null,
              onTap: _pickPhoto,
            ),
          ],
        ),
        if (_workoutId != null || _wearable != null) ...[
          const SizedBox(height: 14),
          _selectedCard(l10n),
        ] else if (_photo != null) ...[
          const SizedBox(height: 14),
          _photoPreview(l10n),
        ],
        const SizedBox(height: 16),
        const BldrCommunitySheetDivider(),
        const SizedBox(height: 12),
        Text(l10n.comm_visibility, style: BldrCommunityTextV2.composeMeta),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _Pill(
                label: visLabel,
                trailing: TablerIcons.chevron_down,
                onTap: _pickVisibility,
              ),
            ),
            const SizedBox(width: 12),
            _Pill(
              label: l10n.comm_publish,
              primary: true,
              onTap: _canPublish && !_publishing ? _publish : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _selectedCard(AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    final wearable = _wearable;
    final String eyebrow;
    final String title;
    final String meta;
    String? stats;
    if (wearable != null) {
      final source =
          CommunityV2Format.providerLabel(wearable['provider']?.toString()) ??
              l10n.comm_compose_wearable.toUpperCase();
      final seconds = (wearable['duration_s'] as num?)?.toInt();
      final km = (wearable['distance_km'] as num?)?.toDouble();
      final hr = (wearable['average_heart_rate'] as num?)?.round();
      final kcal = (wearable['calories'] as num?)?.round();
      eyebrow = l10n.comm_wearable_selected(source);
      title = CommunityV2Format.activityName(
          wearable['activity_type']?.toString() ?? l10n.comm_activity_default);
      meta = [
        if (km != null) '${CommunityV2Format.decimal(km, locale)} km',
        if (seconds != null) CommunityV2Format.clock(seconds),
        if (hr != null) '$hr bpm',
      ].join(' · ');
      stats = [
        if (CommunityV2Format.pace(seconds, km) case final pace?) '$pace/km',
        if (kcal != null) '$kcal kcal',
      ].join('  ·  ');
    } else {
      final w = _workout;
      eyebrow = l10n.comm_workout_selected;
      title = (w?.name ?? l10n.comm_workout_fallback).toUpperCase();
      meta = [
        if (w?.completedAt case final d?)
          CommunityV2Format.shortDate(d.toLocal(), locale),
        if (w?.durationSeconds case final s?) CommunityV2Format.duration(s),
      ].join(' · ');
      stats = [
        if (w?.volumeKg case final v? when v > 0)
          l10n.comm_metric_volume(CommunityV2Format.thousands(v, locale)),
        if (w?.completedSetCount case final s?) l10n.comm_metric_sets(s),
        if (_includePrs && widget.preselectedPrs.isNotEmpty)
          l10n.comm_metric_prs(widget.preselectedPrs.length),
      ].join('   ·   ');
    }
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: BldrCommunityColorsV2.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: BldrCommunityColorsV2.composeBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(eyebrow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrCommunityTextV2.composeEyebrow),
              ),
              _TextAction(
                label: l10n.comm_change,
                style: BldrCommunityTextV2.composeEyebrow,
                onTap: wearable != null ? _pickWearable : _pickWorkout,
              ),
            ],
          ),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BldrCommunityTextV2.postTitle),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrCommunityTextV2.composeMeta),
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(stats,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BldrCommunityTextV2.composeMeta),
          ],
          if (wearable == null && widget.preselectedPrs.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.comm_include_prs,
                      style: BldrCommunityTextV2.composeAction),
                ),
                Switch(
                  value: _includePrs,
                  activeThumbColor: BldrCommunityColorsV2.gold,
                  onChanged: (v) => setState(() => _includePrs = v),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const BldrCommunitySheetDivider(),
          const SizedBox(height: 12),
          if (_photo != null)
            _photoPreview(l10n)
          else
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pickPhoto,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: BldrCommunityColorsV2.photoActionBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: BldrCommunityColorsV2.photoBorder, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(TablerIcons.plus,
                          size: 17, color: BldrCommunityColorsV2.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l10n.comm_add_photo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BldrCommunityTextV2.composeAction),
                      ),
                      Text(l10n.comm_optional,
                          style: BldrCommunityTextV2.composeMeta),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoPreview(AppLocalizations l10n) {
    final photo = _photo!;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: BldrCommunityColorsV2.photoGradient,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: BldrCommunityColorsV2.photoBorder, width: 0.8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              photo,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const SizedBox(width: 64, height: 64),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.comm_photo_attached,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrCommunityTextV2.composeEyebrow),
                const SizedBox(height: 2),
                Text(l10n.comm_photo_one,
                    style: BldrCommunityTextV2.composeMeta),
                Wrap(
                  spacing: 16,
                  children: [
                    _TextAction(
                      label: l10n.comm_photo_swap,
                      style: BldrCommunityTextV2.composeEyebrow,
                      onTap: _pickPhoto,
                    ),
                    _TextAction(
                      label: l10n.comm_photo_remove,
                      style: BldrCommunityTextV2.composeRemove,
                      onTap: () => setState(() => _photo = null),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TypeTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 24,
                    color: active
                        ? BldrCommunityColorsV2.gold
                        : BldrCommunityColorsV2.composeMuted),
                const SizedBox(height: 3),
                Text(label,
                    maxLines: 1,
                    style: active
                        ? BldrCommunityTextV2.composeTabOn
                        : BldrCommunityTextV2.composeTab),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  const _TextAction(
      {required this.label, required this.style, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(label, maxLines: 1, style: style),
          ),
        ),
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final bool primary;
  final IconData? trailing;
  final VoidCallback? onTap;

  const _Pill({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 94),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: BldrCommunityColorsV2.pillBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primary
                    ? BldrCommunityColorsV2.gold
                    : BldrCommunityColorsV2.divider,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: primary
                          ? BldrCommunityTextV2.cta
                          : BldrCommunityTextV2.composeAction),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  Icon(trailing,
                      size: 14, color: BldrCommunityColorsV2.composeMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lista de treinos recentes (32:234).
class _WorkoutPicker extends StatelessWidget {
  final List<RecentWorkout> workouts;
  final bool loading;

  const _WorkoutPicker({required this.workouts, required this.loading});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
              color: BldrCommunityColorsV2.gold, strokeWidth: 2),
        ),
      );
    }
    if (workouts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.comm_pick_workout_empty,
            textAlign: TextAlign.center, style: BldrCommunityTextV2.sheetSub),
      );
    }
    return Column(
      children: [
        for (final w in workouts)
          _SourceRow(
            icon: TablerIcons.barbell,
            title: w.name,
            subtitle: [
              if (w.completedAt case final d?)
                CommunityV2Format.shortDate(d.toLocal(), locale),
              if (w.durationSeconds case final s?)
                CommunityV2Format.duration(s),
              if (w.volumeKg case final v? when v > 0)
                '${CommunityV2Format.thousands(v, locale)} kg',
            ].join(' · '),
            onTap: () => Navigator.pop(context, w),
          ),
      ],
    );
  }
}

/// Origens do wearable (32:343). Garmin ainda não existe: "Em breve".
class _WearableSourcePicker extends StatelessWidget {
  const _WearableSourcePicker();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SourceRow(
          icon: TablerIcons.device_watch,
          title: 'WHOOP',
          subtitle: l10n.comm_wearable_recent,
          onTap: () => Navigator.pop(context, 'whoop'),
        ),
        _SourceRow(
          icon: TablerIcons.device_watch,
          title: 'Apple Watch',
          subtitle: l10n.comm_wearable_recent,
          onTap: () => Navigator.pop(context, 'apple_watch'),
        ),
        _SourceRow(
          icon: TablerIcons.device_watch,
          title: 'Garmin Connect',
          subtitle: l10n.comm_wearable_soon,
        ),
        const SizedBox(height: 10),
        Text(l10n.comm_wearable_note, style: BldrCommunityTextV2.composeMeta),
      ],
    );
  }
}

class _SourceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SourceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: onTap != null,
        enabled: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.5 : 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: 70),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: BldrCommunityColorsV2.pillBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: BldrCommunityColorsV2.divider, width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 24, color: BldrCommunityColorsV2.gold),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BldrCommunityTextV2.rowTitle),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: BldrCommunityTextV2.composeMeta),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(TablerIcons.chevron_right,
                        size: 18, color: BldrCommunityColorsV2.composeMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Registros recentes do wearable (42:832): até 10, em grade.
class _WearableRecordPicker extends StatefulWidget {
  final String provider;
  const _WearableRecordPicker({required this.provider});

  @override
  State<_WearableRecordPicker> createState() => _WearableRecordPickerState();
}

class _WearableRecordPickerState extends State<_WearableRecordPicker> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await getIt<CommunityFeedRepository>()
        .fetchWearableActivities(widget.provider);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result.failureOrNull?.message;
      _records = (result.valueOrNull ?? const []).take(10).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(
              color: BldrCommunityColorsV2.gold, strokeWidth: 2),
        ),
      );
    }
    final error = _error;
    if (error != null || _records.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(error ?? l10n.comm_records_empty,
              textAlign: TextAlign.center, style: BldrCommunityTextV2.sheetSub),
          const SizedBox(height: 14),
          BldrV2SheetButton(label: l10n.comm_retry, onTap: _load),
        ],
      );
    }
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _records.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 262 * scale,
      ),
      itemBuilder: (context, index) => WearableActivityGridCard(
        data: _records[index],
        selected: false,
        onTap: () => Navigator.pop(context, _records[index]),
      ),
    );
  }
}
