import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bldr_fitness/features/workouts/domain/entities/workout_share_data.dart';
import 'package:bldr_fitness/features/workouts/presentation/share/workout_share_exporter.dart';
import 'package:bldr_fitness/features/workouts/presentation/share/workout_share_templates.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_map.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

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
  WorkoutShareStyle _style = WorkoutShareStyle.performance;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _exporter = WorkoutShareExporter(prepareAssets: BldrMuscleMap.precache);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) BldrMuscleMap.precache(context);
    });
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final file = await _exporter.exportPng(
        context: context,
        boundaryKey: _boundaryKey,
      );
      if (file == null || !mounted) return;
      final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: 'Treino concluído no BLDR',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível gerar a imagem. Tente novamente.'),
        ));
      }
      debugPrint('[WorkoutShare] $error');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BldrColors.bgBase,
        appBar: AppBar(
          backgroundColor: BldrColors.bgBase,
          foregroundColor: BldrColors.textPrimary,
          title: const Text('Compartilhar treino'),
        ),
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: WorkoutShareTemplate(
                        data: widget.data,
                        style: _style,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(children: [
                SegmentedButton<WorkoutShareStyle>(
                  segments: const [
                    ButtonSegment(
                        value: WorkoutShareStyle.performance,
                        label: Text('Performance')),
                    ButtonSegment(
                        value: WorkoutShareStyle.muscleMap,
                        label: Text('Muscle Map')),
                    ButtonSegment(
                        value: WorkoutShareStyle.minimal,
                        label: Text('Minimal')),
                  ],
                  selected: {_style},
                  onSelectionChanged: _sharing
                      ? null
                      : (value) => setState(() => _style = value.first),
                  style: SegmentedButton.styleFrom(
                    foregroundColor: BldrColors.textSecondary,
                    selectedForegroundColor: BldrColors.bgBase,
                    selectedBackgroundColor: BldrColors.goldBright,
                    backgroundColor: BldrColors.surface,
                    side: const BorderSide(color: BldrColors.border),
                    textStyle: BldrText.metaSm,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  key: _buttonKey,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    style: FilledButton.styleFrom(
                      backgroundColor: BldrColors.goldSolid,
                      foregroundColor: BldrColors.bgBase,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _sharing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.ios_share_rounded),
                    label:
                        Text(_sharing ? 'Gerando imagem...' : 'Compartilhar'),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      );
}
