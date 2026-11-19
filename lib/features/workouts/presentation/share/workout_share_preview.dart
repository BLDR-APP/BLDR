import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bldr_fitness/core/toast/bldr_toaster.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post_draft.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_create_post_sheet_v2.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_share_data.dart';
import 'package:bldr_fitness/features/workouts/presentation/share/workout_share_exporter.dart';
import 'package:bldr_fitness/features/workouts/presentation/share/workout_share_v2_templates.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Compartilhar v2 (Figma 241:12891 Overlay / 241:12890 Card).
class WorkoutSharePreview extends StatefulWidget {
  final WorkoutShareData data;
  const WorkoutSharePreview({super.key, required this.data});

  @override
  State<WorkoutSharePreview> createState() => _WorkoutSharePreviewState();
}

class _WorkoutSharePreviewState extends State<WorkoutSharePreview> {
  final _boundaryKey = GlobalKey();
  final _buttonKey = GlobalKey();
  late final WorkoutShareExporter _exporter;
  WorkoutShareFormatV2 _format = WorkoutShareFormatV2.overlay;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _exporter = WorkoutShareExporter(
      prepareAssets: (context) =>
          prepareWorkoutShareAssets(context, widget.data),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_prewarmShareAssets());
    });
  }

  Future<void> _prewarmShareAssets() async {
    try {
      await prepareWorkoutShareAssets(context, widget.data);
    } catch (error, stackTrace) {
      debugPrint(
          '[WorkoutShare][prepare-warmup] ${error.runtimeType}\n$stackTrace');
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _sharing = true);
    WorkoutShareStage stage = WorkoutShareStage.prepare;
    try {
      final file = await _exporter.exportPng(
        context: context,
        boundaryKey: _boundaryKey,
        onStage: (value) => stage = value,
      );
      if (file == null || !mounted) return;
      final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      try {
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: l10n.sh_share_text,
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ));
      } catch (error, stackTrace) {
        debugPrint('[WorkoutShare][share] ${error.runtimeType}\n$stackTrace');
        if (mounted) {
          context.toast.error(l10n.sh_share_error);
        }
      }
    } catch (error, stackTrace) {
      if (mounted) {
        context.toast.error(l10n.sh_export_error);
      }
      debugPrint(
          '[WorkoutShare][${stage.name}] ${error.runtimeType}\n$stackTrace');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// P5: mesmo fluxo que o resumo usava (treino, origem e PRs).
  void _publish() {
    final s = widget.data.summary;
    CommunityCreatePostSheetV2.show(
      context,
      preselectedWorkoutId: s.workoutId,
      preselectedSource: s.source,
      preselectedPrs: [
        for (final pr in s.newPRs)
          CommunityDraftPr(
            exerciseName: pr.exerciseName,
            weightKg: pr.newWeightKg,
            e1rm: pr.newE1rm,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overlay = _format == WorkoutShareFormatV2.overlay;
    final template = RepaintBoundary(
      key: _boundaryKey,
      child: overlay
          ? WorkoutShareOverlayV2(data: widget.data)
          : WorkoutShareCardV2(data: widget.data),
    );
    return Scaffold(
      backgroundColor: BldrColorsV2.bg,
      body: BldrBackground(
        v2: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              // Cabeçalho
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Stack(children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      button: true,
                      label:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.maybePop(context),
                        child: const SizedBox(
                          width: 40,
                          height: 44,
                          child: Icon(TablerIcons.chevron_left,
                              size: 26, color: BldrShareColorsV2.text),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.sh_title,
                            maxLines: 1, style: BldrShareTextV2.title),
                        const SizedBox(height: 4),
                        Text(l10n.sh_subtitle,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: BldrShareTextV2.subtitle),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              // Abas
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 324),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: BldrShareColorsV2.panelBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: BldrShareColorsV2.panelBorder),
                    ),
                    child: Row(children: [
                      for (final f in WorkoutShareFormatV2.values)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: f == _format,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _sharing
                                  ? null
                                  : () => setState(() => _format = f),
                              child: Container(
                                constraints:
                                    const BoxConstraints(minHeight: 36),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: f == _format
                                      ? Border.all(
                                          color: BldrShareColorsV2.gold)
                                      : null,
                                ),
                                child: Text(
                                    f == WorkoutShareFormatV2.overlay
                                        ? l10n.sh_tab_overlay
                                        : l10n.sh_tab_card,
                                    style: f == _format
                                        ? BldrShareTextV2.tabActive
                                        : BldrShareTextV2.tab),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Prévia
              Container(
                padding: const EdgeInsets.fromLTRB(19, 16, 19, 18),
                decoration: BoxDecoration(
                  color: BldrShareColorsV2.panelBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: BldrShareColorsV2.panelBorder),
                ),
                child: Column(children: [
                  Text(overlay ? l10n.sh_preview_overlay : l10n.sh_preview_card,
                      style: BldrShareTextV2.hint),
                  const SizedBox(height: 18),
                  if (overlay)
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
                      decoration: BoxDecoration(
                        color: BldrShareColorsV2.canvasBg,
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: BldrShareColorsV2.panelBorder),
                      ),
                      child: Column(children: [
                        Text(l10n.sh_transparent, style: BldrShareTextV2.hint),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: template,
                          ),
                        ),
                        Text(l10n.sh_transparent_note,
                            textAlign: TextAlign.center,
                            style: BldrShareTextV2.note),
                      ]),
                    )
                  else ...[
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 216),
                        child: template,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.sh_card_hint,
                        textAlign: TextAlign.center,
                        style: BldrShareTextV2.note),
                  ],
                ]),
              ),
              const SizedBox(height: 20),
              Text(overlay ? l10n.sh_overlay_title : l10n.sh_card_title,
                  textAlign: TextAlign.center,
                  style: BldrShareTextV2.infoTitle),
              const SizedBox(height: 8),
              Text(overlay ? l10n.sh_overlay_body : l10n.sh_card_body,
                  textAlign: TextAlign.center, style: BldrShareTextV2.infoBody),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                enabled: !_sharing,
                child: GestureDetector(
                  key: _buttonKey,
                  onTap: _sharing ? null : _share,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(29),
                      border: Border.all(color: BldrShareColorsV2.gold),
                    ),
                    child: Text(_sharing ? l10n.sh_sharing : l10n.sh_share,
                        style: BldrShareTextV2.cta),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _publish,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('${l10n.sh_publish}  ›',
                        textAlign: TextAlign.center,
                        style: BldrShareTextV2.publish),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.sh_note,
                  textAlign: TextAlign.center, style: BldrShareTextV2.note),
            ],
          ),
        ),
      ),
    );
  }
}
