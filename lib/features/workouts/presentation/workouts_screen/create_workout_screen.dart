import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_workout_v2_components.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_duration_estimator.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/exercise.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart'
    as uc;
import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _ExSet {
  double? weight;
  int reps;
  int rest;

  _ExSet({this.weight, this.reps = 10, this.rest = 90});

  _ExSet copyWith(
          {double? weight, bool clearWeight = false, int? reps, int? rest}) =>
      _ExSet(
        weight: clearWeight ? null : (weight ?? this.weight),
        reps: reps ?? this.reps,
        rest: rest ?? this.rest,
      );
}

class _WorkoutEx {
  final String id; // Supabase UUID
  final String exDbId; // ExerciseDB ID
  final String name;
  final String imageUrl;
  final String muscle;
  final List<_ExSet> sets;

  _WorkoutEx({
    required this.id,
    required this.exDbId,
    required this.name,
    required this.imageUrl,
    required this.muscle,
    List<_ExSet>? sets,
  }) : sets = sets ?? [_ExSet()];
}

// ── Thumbnail with two-URL fallback ──────────────────────────────────────────

class _ExerciseThumbnail extends StatefulWidget {
  final String primaryUrl;
  final String fallbackUrl;
  final Color cardColor;
  final Color mutedColor;

  const _ExerciseThumbnail({
    required this.primaryUrl,
    required this.fallbackUrl,
    required this.cardColor,
    required this.mutedColor,
  });

  @override
  State<_ExerciseThumbnail> createState() => _ExerciseThumbnailState();
}

class _ExerciseThumbnailState extends State<_ExerciseThumbnail> {
  bool _useFallback = false;

  @override
  Widget build(BuildContext context) {
    final url = _useFallback ? widget.fallbackUrl : widget.primaryUrl;

    if (url.isEmpty) {
      return _placeholder();
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) {
        // If primary failed and we have a fallback, retry once
        if (!_useFallback &&
            widget.fallbackUrl.isNotEmpty &&
            widget.fallbackUrl != widget.primaryUrl) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _useFallback = true);
          });
          return _placeholder();
        }
        return _placeholder();
      },
    );
  }

  Widget _placeholder() => Container(
        color: widget.cardColor,
        child: Icon(Icons.fitness_center, color: widget.mutedColor, size: 20),
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CreateWorkoutScreen extends StatefulWidget {
  /// When provided the screen opens in edit mode, pre-filling all fields and
  /// calling [WorkoutService.updateWorkoutTemplate] on save.
  /// Expected keys: id, name, workout_type, estimated_duration_minutes,
  /// difficulty_level, workout_template_exercises (list with exercise data).
  final WorkoutTemplate? editTemplate;

  const CreateWorkoutScreen({super.key, this.editTemplate});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  // ── colours ────────────────────────────────────────────────────────────────
  static const _gold = Color(0xFFD4AF37);
  static const _goldBg = Color(0x1FD4AF37);
  static const _borderGold = Color(0x40D4AF37);
  static const _surface = Color(0xFF1A1916);
  static const _card = Color(0xFF1E1C18);
  static const _muted = Color(0xFF888070);

  // ── form state ─────────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  String _category = 'Força';

  /// Nível só é mantido para treinos já existentes (decisão aprovada):
  /// treinos novos do usuário salvam difficulty_level NULL.
  int? _difficulty;
  bool _saving = false;

  // ── Treinos v2 (Figma 179:981 / 179:1015) ─────────────────────────────────
  /// 0 = "Monte seu treino" (nome + tipo); 1 = "Montar treino".
  int _step = 0;

  /// Exercícios com "Personalizar séries" aberto.
  final Set<int> _expanded = {};

  bool get _isEditing =>
      widget.editTemplate != null && widget.editTemplate!.id != null;

  static const _categories = ['Força', 'HIIT', 'Cardio', 'Mobilidade', 'Misto'];
  // Maps PT label → DB enum value (workout_type column — enum is in Portuguese)
  static const _categoryToDbValue = {
    'Força': 'força',
    'HIIT': 'hiit',
    'Cardio': 'cardio',
    'Mobilidade': 'mobilidade',
    'Misto': 'misto',
  };

  // ── exercise list ──────────────────────────────────────────────────────────
  final List<_WorkoutEx> _exercises = [];

  // ── subscription ──────────────────────────────────────────────────────────
  bool _isPro = false;

  // ── reverse mapping: DB enum value → display label ────────────────────────
  static const _dbValueToCategory = {
    'força': 'Força',
    'hiit': 'HIIT',
    'cardio': 'Cardio',
    'mobilidade': 'Mobilidade',
    'misto': 'Misto',
  };

  @override
  void initState() {
    super.initState();
    _loadSubscription();
    _prefillIfEditing();
  }

  /// Pre-populate form fields when editing an existing template.
  void _prefillIfEditing() {
    final t = widget.editTemplate;
    if (t == null) return;

    _nameCtrl.text = t.name;

    _category = _dbValueToCategory[t.workoutType ?? ''] ?? 'Força';

    // Edição: mantém o nível salvo (pode ser NULL). Fluxo da foto (sem id)
    // é um treino novo: nível NULL e começa direto no passo "Montar".
    _difficulty = t.id != null ? t.difficultyLevel : null;
    if (t.id == null) _step = 1;
  }

  Future<void> _loadSubscription() async {
    try {
      final access = (await getIt<ResolveClubAccess>()()).valueOrNull ?? false;
      if (mounted) {
        debugPrint('[CreateWorkout] isPro=$access');
        setState(() => _isPro = access);
      }
      // After subscription is loaded, resolve edit exercises (needs ExerciseDB)
      if (widget.editTemplate != null) await _loadEditExercises();
    } catch (e) {
      // On error, stay free (default _isPro = false)
      debugPrint('[CreateWorkout] subscription check failed: $e');
      if (widget.editTemplate != null) await _loadEditExercises();
    }
  }

  /// Resolves exercise rows from the edit template into [_WorkoutEx] objects.
  Future<void> _loadEditExercises() async {
    final t = widget.editTemplate;
    if (t == null) return;

    final rows = t.exercises;
    if (rows.isEmpty) return;

    // Load ExerciseDB cache once (returns immediately if already cached)
    List<ExDbExercise> allEx = [];
    try {
      allEx = await ExerciseDbRapidService.instance.listAllExercises();
    } catch (_) {}
    final exDbById = {for (final e in allEx) e.exerciseId: e};

    final resolved = <_WorkoutEx>[];
    for (final row in rows) {
      // Séries salvas uma a uma (set_details); templates antigos caem nos
      // valores agregados (TREINOS_V2.md, P2).
      final builtSets = row.resolvedSets
          .map((d) => _ExSet(
              weight: d.weightKg,
              reps: d.reps ?? 10,
              rest: d.restSeconds ?? 90))
          .toList();

      final exDbId = row.exerciseDbId ?? '';
      if (exDbId.isNotEmpty) {
        final found = exDbById[exDbId];
        if (found != null) {
          resolved.add(_WorkoutEx(
            id: found.exerciseId,
            exDbId: found.exerciseId,
            name: found.name,
            imageUrl: found.displayUrl,
            muscle: found.targetMuscles.isNotEmpty
                ? found.targetMuscles.first
                : (found.bodyParts.isNotEmpty ? found.bodyParts.first : ''),
            sets: builtSets,
          ));
          continue;
        }
      }

      // Fallback: exercício da biblioteca interna
      final internal = row.exercise;
      resolved.add(_WorkoutEx(
        id: internal?.id ?? '',
        exDbId: exDbId,
        name: internal?.name ?? 'Exercício',
        imageUrl: '',
        muscle: internal?.primaryMuscleGroup?.toString() ?? '',
        sets: builtSets,
      ));
    }

    if (mounted) {
      setState(() => _exercises
        ..clear()
        ..addAll(resolved));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ── save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dê um nome ao treino'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Adicione ao menos um exercício'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      final exercisePayload = _exercises.asMap().entries.map((entry) {
        final e = entry.value;
        final avgReps = e.sets.isEmpty
            ? 10
            : (e.sets.map((s) => s.reps).reduce((a, b) => a + b) /
                    e.sets.length)
                .round();
        final avgWeight = e.sets.any((s) => s.weight != null)
            ? e.sets
                    .where((s) => s.weight != null)
                    .map((s) => s.weight!)
                    .reduce((a, b) => a + b) /
                e.sets.where((s) => s.weight != null).length
            : null;
        // Prefere exercise_db_id; cai para exercise (biblioteca BLDR)
        return TemplateExercise(
          orderIndex: entry.key + 1,
          sets: e.sets.length,
          reps: avgReps,
          restSeconds: e.sets.isNotEmpty ? e.sets.first.rest : 90,
          weightKg: avgWeight,
          // Carga/reps/descanso de cada série (antes se perdiam na média).
          setDetails: [
            for (final set in e.sets)
              TemplateSetDetail(
                  weightKg: set.weight, reps: set.reps, restSeconds: set.rest),
          ],
          exerciseDbId: e.exDbId.isNotEmpty ? e.exDbId : null,
          exercise: e.exDbId.isEmpty && e.id.isNotEmpty
              ? Exercise(id: e.id, name: e.name)
              : null,
        );
      }).toList();

      // isEditing = editTemplate exists AND has a real id (not the photo flow)
      final templateId = widget.editTemplate?.id;
      final isEditing = widget.editTemplate != null && templateId != null;
      final template = WorkoutTemplate(
        id: templateId,
        name: name,
        workoutType: _categoryToDbValue[_category] ?? _category.toLowerCase(),
        // Duração estimada (P1), na criação e na edição.
        estimatedDurationMinutes:
            WorkoutDurationEstimator.estimateTemplate(exercisePayload),
        difficultyLevel: _difficulty,
        isPublic: false,
        exercises: exercisePayload,
      );

      final result = isEditing
          ? await getIt<uc.UpdateWorkoutTemplate>()(template)
          : await getIt<uc.CreateWorkoutTemplate>()(template);
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── picker ────────────────────────────────────────────────────────────────

  void _openPicker({VoidCallback? afterConfirm}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => _ExercisePickerSheet(
        addedIds: _exercises.map((e) => e.exDbId).toSet(),
        isPro: _isPro,
        onConfirm: (list) {
          setState(() {
            for (final ex in list) {
              _exercises.add(_WorkoutEx(
                id: ex.exerciseId,
                exDbId: ex.exerciseId,
                name: ex.name,
                imageUrl: ex.displayUrl,
                muscle: ex.targetMuscles.isNotEmpty
                    ? ex.targetMuscles.first
                    : (ex.bodyParts.isNotEmpty ? ex.bodyParts.first : ''),
              ));
            }
          });
          if (list.isNotEmpty) afterConfirm?.call();
        },
      ),
    );
  }

  // ── set editing ───────────────────────────────────────────────────────────

  void _editSet(int exIdx, int setIdx, _ExSet current) {
    double? weight = current.weight;
    int reps = current.reps;
    int rest = current.rest;

    final weightCtrl =
        TextEditingController(text: weight != null ? weight.toString() : '');
    final repsCtrl = TextEditingController(text: reps.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 4.w,
            right: 4.w,
            top: 2.h),
        child: StatefulBuilder(
          builder: (ctx, setModal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _muted, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: 2.h),
              Text('Série ${setIdx + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              SizedBox(height: 2.h),
              Row(children: [
                Expanded(
                  child: _numField(
                    label: 'Carga (kg)',
                    controller: weightCtrl,
                    hint: '—',
                    decimal: true,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _numField(
                    label: 'Repetições',
                    controller: repsCtrl,
                    hint: '10',
                    decimal: false,
                  ),
                ),
              ]),
              SizedBox(height: 1.5.h),
              Text('Descanso', style: TextStyle(color: _muted, fontSize: 13)),
              SizedBox(height: 0.8.h),
              Wrap(
                spacing: 2.w,
                children: [30, 60, 90, 120, 180].map((s) {
                  final sel = rest == s;
                  return GestureDetector(
                    onTap: () => setModal(() => rest = s),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 3.w, vertical: 0.6.h),
                      decoration: BoxDecoration(
                        color: sel ? _goldBg : _card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel
                                ? _borderGold
                                : Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text('${s}s',
                          style: TextStyle(
                              color: sel ? _gold : Colors.white,
                              fontSize: 13,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 2.5.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final w = double.tryParse(weightCtrl.text);
                    final r = int.tryParse(repsCtrl.text) ?? 10;
                    setState(() {
                      _exercises[exIdx].sets[setIdx] = current.copyWith(
                        weight: w,
                        clearWeight: weightCtrl.text.isEmpty,
                        reps: r,
                        rest: rest,
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 1.6.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirmar',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool decimal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: _muted, fontSize: 13)),
        SizedBox(height: 0.5.h),
        TextField(
          controller: controller,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: decimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _muted, fontSize: 18),
            filled: true,
            fillColor: _card,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.07)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.07)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _gold, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) =>
      _isEditing ? _buildEditorV2() : _buildV2();

  // ══ Treinos v2 — editor (179:1590) ═══════════════════════════════════════

  final _nameFocus = FocusNode();

  static const _categoryKeys = {
    'Força': 'strength',
    'HIIT': 'hiit',
    'Cardio': 'cardio',
    'Mobilidade': 'mobility',
    'Misto': 'mixed',
  };

  String _categoryLabel(AppLocalizations l10n, String c) =>
      switch (_categoryKeys[c]) {
        'strength' => l10n.ed_cat_strength,
        'hiit' => l10n.ed_cat_hiit,
        'cardio' => l10n.ed_cat_cardio,
        'mobility' => l10n.ed_cat_mobility,
        'mixed' => l10n.ed_cat_mixed,
        _ => c,
      };

  Widget _buildEditorV2() {
    final l10n = AppLocalizations.of(context);
    final allSets = [for (final e in _exercises) ...e.sets];
    final avgRest = allSets.isEmpty
        ? 0
        : (allSets.map((st) => st.rest).reduce((a, b) => a + b) /
                allSets.length)
            .round();
    final minutes =
        WorkoutDurationEstimator.estimateTemplate(_payloadForEstimate);
    final name = _nameCtrl.text.trim();
    final groups = <String>{
      for (final e in _exercises)
        if (e.muscle.trim().isNotEmpty) e.muscle.trim()
    }.join(' · ');

    return Scaffold(
      backgroundColor: BldrColorsV2.bg,
      body: BldrBackground(
        v2: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(_px, 4, _px, 40),
            children: [
              BldrWorkoutHeader(
                eyebrow: l10n.ed_eyebrow,
                eyebrowStyle: BldrWorkoutTextV2.eyebrowSm,
                title: name.isEmpty ? l10n.cw_name_hint : name,
                onBack: () => Navigator.pop(context),
                trailing: BldrCompactGoldButton(
                  label: _saving ? '…' : l10n.ed_save,
                  width: 82,
                  height: 38,
                  onTap: _saving ? null : _save,
                ),
              ),
              const SizedBox(height: 10),
              _editorIdentityCard(l10n, groups),
              const SizedBox(height: 12),
              BldrHudStats(
                valueStyle: BldrWorkoutTextV2.edHudValue,
                accentStyle: BldrWorkoutTextV2.edHudAccent,
                items: [
                  (value: '${_exercises.length}', label: l10n.cw_hud_exercises),
                  (value: '${allSets.length}', label: l10n.cw_hud_sets),
                  (value: '~$minutes', label: l10n.cw_hud_minutes),
                  (value: '${avgRest}s', label: l10n.cw_hud_avg_rest),
                ],
              ),
              const SizedBox(height: 20),
              // "Segure para reordenar" oculto: reordenar não existe ([F]).
              Text(l10n.ed_section,
                  maxLines: 1, style: BldrWorkoutTextV2.sectionLabel),
              const SizedBox(height: 10),
              for (var i = 0; i < _exercises.length; i++) ...[
                _editorExerciseCard(l10n, i, _exercises[i]),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 6),
              BldrGoldRowCta(
                label: l10n.cw_add_exercise,
                height: 58,
                radius: 22,
                labelStyle: BldrWorkoutTextV2.cta,
                // N/M: não há limite de exercícios por treino → só N.
                trailing: Text('${_exercises.length}',
                    style: BldrWorkoutTextV2.edAddCount),
                onTap: () => _openPicker(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editorIdentityCard(AppLocalizations l10n, String groups) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 15, 12, 14),
      decoration: BoxDecoration(
        color: BldrWorkoutColorsV2.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BldrWorkoutColorsV2.editorIdentityBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.ed_name_label, style: BldrWorkoutTextV2.edLabel),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  maxLines: 1,
                  style: BldrWorkoutTextV2.edName,
                  cursorColor: BldrWorkoutColorsV2.gold,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: l10n.cw_name_hint,
                    hintStyle: BldrWorkoutTextV2.edName
                        .copyWith(color: BldrWorkoutColorsV2.muted),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: l10n.ed_edit_name,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _nameFocus.requestFocus(),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(TablerIcons.pencil,
                        size: 18, color: BldrWorkoutColorsV2.gold),
                  ),
                ),
              ),
            ],
          ),
          if (groups.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(groups,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrWorkoutTextV2.edGroups),
          ],
          const SizedBox(height: 12),
          Text(l10n.ed_category_label, style: BldrWorkoutTextV2.edLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in _categories)
                BldrTypeChip(
                  label: _categoryLabel(l10n, c),
                  width: 92,
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editorChip(String text, TextStyle style, VoidCallback onTap) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 24, minWidth: 62),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: BldrWorkoutColorsV2.editorChipBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: style),
        ),
      );

  /// Card do exercício no editor (27:23 fechado / 27:35 expandido).
  Widget _editorExerciseCard(AppLocalizations l10n, int idx, _WorkoutEx ex) {
    final open = _expanded.contains(idx);
    final setsTxt = l10n.ed_chip_sets(ex.sets.length);
    final repsTxt = l10n.ed_chip_reps(_repsLabel(ex.sets));
    final restTxt = _restLabel(ex.sets);
    void toggle() =>
        setState(() => open ? _expanded.remove(idx) : _expanded.add(idx));

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 12, 8, 10),
      decoration: BoxDecoration(
        color: BldrWorkoutColorsV2.cardBg,
        borderRadius: BorderRadius.circular(open ? 24 : 22),
        border: Border.all(
            color: open
                ? BldrWorkoutColorsV2.editorExpandedBorder
                : BldrWorkoutColorsV2.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text((idx + 1).toString().padLeft(2, '0'),
                      style: BldrWorkoutTextV2.edOrder),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrWorkoutTextV2.edExName),
                    const SizedBox(height: 3),
                    Text(ex.muscle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrWorkoutTextV2.edMuscles),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.ed_options,
                padding: EdgeInsets.zero,
                color: BldrWorkoutColorsV2.sheetBg,
                onSelected: (_) => setState(() {
                  _exercises.removeAt(idx);
                  _expanded
                    ..remove(idx)
                    ..removeWhere((e) => e > idx);
                }),
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'remove',
                      child: Text(l10n.ed_remove_exercise,
                          style: BldrWorkoutTextV2.exName)),
                ],
                child: SizedBox(
                  width: 36,
                  height: 28,
                  child: Center(
                      child: Text('•••', style: BldrWorkoutTextV2.edMenu)),
                ),
              ),
            ],
          ),
          if (!open) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 6, right: 8),
              child: Wrap(spacing: 8, runSpacing: 6, children: [
                _editorChip(setsTxt, BldrWorkoutTextV2.edChipAccent,
                    () => _editSetCount(idx)),
                _editorChip(
                    repsTxt, BldrWorkoutTextV2.edChip, () => _editAllReps(idx)),
                _editorChip(
                    restTxt, BldrWorkoutTextV2.edChip, () => _editAllRest(idx)),
              ]),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: toggle,
              child: Padding(
                padding: const EdgeInsets.only(left: 36, top: 6),
                child: Row(children: [
                  Expanded(
                    child: Text(l10n.cw_personalize,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrWorkoutTextV2.edPersonalize),
                  ),
                  const SizedBox(
                    width: 36,
                    child: Icon(TablerIcons.chevron_right,
                        size: 16, color: BldrWorkoutColorsV2.muted),
                  ),
                ]),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(l10n.ed_default, style: BldrWorkoutTextV2.edLabel),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.only(left: 13),
                decoration: BoxDecoration(
                  color: BldrWorkoutColorsV2.cardBg,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: BldrWorkoutColorsV2.typeBoxBorder),
                ),
                child: Row(children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Wrap(
                        spacing: 22,
                        runSpacing: 6,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _editSetCount(idx),
                            child: Text(setsTxt,
                                style: BldrWorkoutTextV2.edDefaultAccent),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _editAllReps(idx),
                            child: Text(repsTxt,
                                style: BldrWorkoutTextV2.edDefault),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _editAllRest(idx),
                            child: Text(l10n.ed_default_rest(restTxt),
                                style: BldrWorkoutTextV2.edDefault),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: toggle,
                    child: const SizedBox(
                      width: 40,
                      height: 44,
                      child: Icon(TablerIcons.chevron_down,
                          size: 18, color: BldrWorkoutColorsV2.muted),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Text(l10n.ed_sets_header,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrWorkoutTextV2.edLabel),
            const SizedBox(height: 4),
            for (var j = 0; j < ex.sets.length; j++)
              SizedBox(
                height: 29,
                child: Row(children: [
                  SizedBox(
                    width: 36,
                    child: Text('${j + 1}',
                        textAlign: TextAlign.center,
                        style: j == 0
                            ? BldrWorkoutTextV2.edSetIndex
                                .copyWith(color: BldrWorkoutColorsV2.gold)
                            : BldrWorkoutTextV2.edSetIndex),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _editSet(idx, j, ex.sets[j]),
                      child: Text(_kg(ex.sets[j].weight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrWorkoutTextV2.edSetValue),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _editSet(idx, j, ex.sets[j]),
                      child: Text('${ex.sets[j].reps} reps',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrWorkoutTextV2.edSetValue),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    color: BldrWorkoutColorsV2.sheetBg,
                    onSelected: (v) {
                      if (v == 'edit') {
                        _editSet(idx, j, ex.sets[j]);
                      } else if (ex.sets.length > 1) {
                        setState(() => ex.sets.removeAt(j));
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'edit',
                          child: Text(l10n.cw_set_edit,
                              style: BldrWorkoutTextV2.exName)),
                      PopupMenuItem(
                          value: 'remove',
                          enabled: ex.sets.length > 1,
                          child: Text(l10n.cw_set_remove,
                              style: BldrWorkoutTextV2.exName)),
                    ],
                    child: SizedBox(
                      width: 44,
                      height: 29,
                      child: Center(
                          child: Text('•••', style: BldrWorkoutTextV2.more)),
                    ),
                  ),
                ]),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => ex.sets.add(
                  ex.sets.isNotEmpty ? ex.sets.last.copyWith() : _ExSet())),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(36, 6, 0, 4),
                child: Row(children: [
                  const Icon(TablerIcons.plus,
                      size: 12, color: BldrWorkoutColorsV2.gold),
                  const SizedBox(width: 6),
                  Text(l10n.cw_add_set, style: BldrWorkoutTextV2.edAddSet),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══ Treinos v2 — criação ═════════════════════════════════════════════════

  static const double _px = 18;

  Widget _buildV2() {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == 1) setState(() => _step = 0);
      },
      child: Scaffold(
        backgroundColor: BldrColorsV2.bg,
        body: BldrBackground(
          v2: true,
          child: SafeArea(
            bottom: false,
            child: _step == 0 ? _buildStepSetup() : _buildStepBuild(),
          ),
        ),
      ),
    );
  }

  void _back() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Passo 1: "Monte seu treino" (179:981) ─────────────────────────────────

  Widget _buildStepSetup() {
    final l10n = AppLocalizations.of(context);
    final types = <({String label, double width, bool enabled})>[
      (label: l10n.cw_type_strength, width: 116, enabled: true),
      (label: l10n.cw_type_hiit, width: 72, enabled: false),
      (label: l10n.cw_type_cardio, width: 82, enabled: false),
      (label: l10n.cw_type_yoga, width: 74, enabled: false),
      (label: l10n.cw_type_pilates, width: 92, enabled: false),
      (label: l10n.cw_type_hyrox, width: 88, enabled: false),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(_px, 6, _px, 40),
      children: [
        BldrWorkoutHeader(
          eyebrow: l10n.cw_eyebrow,
          title: l10n.cw_title,
          subtitle: l10n.cw_subtitle,
          onBack: _back,
        ),
        const SizedBox(height: 46),
        Container(
          height: 112,
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
          decoration: BoxDecoration(
            color: BldrWorkoutColorsV2.inputBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: BldrWorkoutColorsV2.inputBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cw_name_label, style: BldrWorkoutTextV2.sectionLabel),
              const SizedBox(height: 15),
              TextField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
                style: BldrWorkoutTextV2.inputValue,
                cursorColor: BldrWorkoutColorsV2.gold,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: l10n.cw_name_hint,
                  hintStyle: BldrWorkoutTextV2.inputValue
                      .copyWith(color: BldrWorkoutColorsV2.muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(l10n.cw_type_label, style: BldrWorkoutTextV2.sectionLabel),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: BldrWorkoutColorsV2.typeBoxBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BldrWorkoutColorsV2.typeBoxBorder),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 12,
            children: [
              for (final t in types)
                BldrTypeChip(
                  label: t.label,
                  width: t.width,
                  selected: t.enabled,
                  soonLabel: t.enabled ? null : l10n.cw_soon,
                ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        BldrGoldRowCta(
          label: l10n.cw_add_exercises,
          onTap: () => _openPicker(afterConfirm: () {
            if (mounted) setState(() => _step = 1);
          }),
        ),
        const SizedBox(height: 18),
        Text(l10n.cw_setup_hint,
            textAlign: TextAlign.center, style: BldrWorkoutTextV2.hint),
      ],
    );
  }

  // ── Passo 2: "Montar treino" (179:1015) ───────────────────────────────────

  List<TemplateExercise> get _payloadForEstimate => [
        for (final e in _exercises)
          TemplateExercise(
            orderIndex: 0,
            sets: e.sets.length,
            setDetails: [
              for (final st in e.sets)
                TemplateSetDetail(
                    weightKg: st.weight, reps: st.reps, restSeconds: st.rest),
            ],
          ),
      ];

  Widget _buildStepBuild() {
    final l10n = AppLocalizations.of(context);
    final allSets = [for (final e in _exercises) ...e.sets];
    final avgRest = allSets.isEmpty
        ? 0
        : (allSets.map((st) => st.rest).reduce((a, b) => a + b) /
                allSets.length)
            .round();
    final minutes =
        WorkoutDurationEstimator.estimateTemplate(_payloadForEstimate);
    final name = _nameCtrl.text.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(_px, 4, _px, 60),
      children: [
        BldrWorkoutHeader(
          eyebrow: l10n.cw_build_eyebrow(name.isEmpty
              ? l10n.cw_name_hint.toUpperCase()
              : name.toUpperCase()),
          eyebrowStyle: BldrWorkoutTextV2.eyebrowSm,
          title: l10n.cw_build_title,
          onBack: _back,
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 4),
              Text(l10n.cw_selected_count(_exercises.length),
                  style: BldrWorkoutTextV2.count),
              const SizedBox(height: 6),
              BldrCompactGoldButton(
                label: _saving ? '…' : l10n.cw_create,
                onTap: _saving ? null : _save,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        BldrHudStats(items: [
          (value: '${_exercises.length}', label: l10n.cw_hud_exercises),
          (value: '${allSets.length}', label: l10n.cw_hud_sets),
          (value: '~$minutes', label: l10n.cw_hud_minutes),
          (value: '${avgRest}s', label: l10n.cw_hud_avg_rest),
        ]),
        const SizedBox(height: 7),
        Text(l10n.cw_hud_helper,
            textAlign: TextAlign.center, style: BldrWorkoutTextV2.hintSm),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(l10n.cw_selected_header,
                maxLines: 1, style: BldrWorkoutTextV2.sectionLabel),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.cw_selected_hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: BldrWorkoutTextV2.hintSm),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _exercises.length; i++) ...[
          _exerciseCardV2(i, _exercises[i]),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        BldrGoldRowCta(
          label: l10n.cw_add_exercise,
          height: 52,
          radius: 18,
          labelStyle: BldrWorkoutTextV2.ctaSm,
          onTap: () => _openPicker(),
        ),
        const SizedBox(height: 10),
        Text(l10n.cw_add_exercise_hint,
            textAlign: TextAlign.center, style: BldrWorkoutTextV2.hintSm),
      ],
    );
  }

  /// Reps exibidas: valor único ou "mín–máx" das séries (só exibição).
  static String _repsLabel(List<_ExSet> sets) {
    if (sets.isEmpty) return '—';
    final reps = sets.map((st) => st.reps).toList();
    final lo = reps.reduce((a, b) => a < b ? a : b);
    final hi = reps.reduce((a, b) => a > b ? a : b);
    return lo == hi ? '$lo' : '$lo–$hi';
  }

  static String _restLabel(List<_ExSet> sets) {
    if (sets.isEmpty) return '—';
    final rests = sets.map((st) => st.rest).toSet();
    if (rests.length == 1) return '${rests.first}s';
    final avg =
        (sets.map((st) => st.rest).reduce((a, b) => a + b) / sets.length)
            .round();
    return '~${avg}s';
  }

  static String _kg(double? w) {
    if (w == null) return '— kg';
    final txt = w == w.roundToDouble()
        ? w.toStringAsFixed(0)
        : w.toStringAsFixed(1).replaceAll('.', ',');
    return '$txt kg';
  }

  Widget _exerciseThumb(_WorkoutEx ex) => _ExerciseThumbnail(
        primaryUrl: ex.imageUrl,
        fallbackUrl: ex.exDbId.isNotEmpty
            ? 'https://v2.exercisedb.io/image/${ex.exDbId}'
            : '',
        cardColor: BldrWorkoutColorsV2.thumbBg,
        mutedColor: BldrWorkoutColorsV2.muted,
      );

  /// Card do exercício (34:23 fechado / 36:2 expandido).
  Widget _exerciseCardV2(int idx, _WorkoutEx ex) {
    final l10n = AppLocalizations.of(context);
    final open = _expanded.contains(idx);
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 11, 14, 11),
      decoration: BoxDecoration(
        color: open
            ? BldrWorkoutColorsV2.cardExpandedBg
            : BldrWorkoutColorsV2.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: open
                ? BldrWorkoutColorsV2.cardExpandedBorder
                : BldrWorkoutColorsV2.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BldrExerciseMediaFrame(size: 64, child: _exerciseThumb(ex)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrWorkoutTextV2.exName),
                    const SizedBox(height: 7),
                    Text(ex.muscle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrWorkoutTextV2.exMuscles),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        BldrValueBox(
                          value: '${ex.sets.length}',
                          label: l10n.cw_value_sets,
                          width: 76,
                          onTap: () => _editSetCount(idx),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: BldrValueBox(
                            value: _repsLabel(ex.sets),
                            label: l10n.cw_value_reps,
                            width: 92,
                            onTap: () => _editAllReps(idx),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: BldrValueBox(
                            value: _restLabel(ex.sets),
                            label: l10n.cw_value_rest,
                            width: 92,
                            onTap: () => _editAllRest(idx),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).deleteButtonTooltip,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    _exercises.removeAt(idx);
                    _expanded
                      ..remove(idx)
                      ..removeWhere((e) => e > idx);
                  }),
                  child: SizedBox(
                    width: 28,
                    height: 24,
                    child: Text('×',
                        textAlign: TextAlign.center,
                        style: BldrWorkoutTextV2.remove),
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(
                () => open ? _expanded.remove(idx) : _expanded.add(idx)),
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                        open
                            ? l10n.cw_personalize
                            : '${l10n.cw_personalize}  ›',
                        style: BldrWorkoutTextV2.personalize),
                  ),
                  if (open)
                    const Icon(TablerIcons.chevron_up,
                        size: 16, color: BldrWorkoutColorsV2.gold),
                ],
              ),
            ),
          ),
          if (open) ...[
            const SizedBox(height: 4),
            Text(l10n.cw_advanced_hint, style: BldrWorkoutTextV2.advancedHint),
            const SizedBox(height: 9),
            for (var j = 0; j < ex.sets.length; j++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text('${j + 1}',
                          textAlign: TextAlign.center,
                          style: BldrWorkoutTextV2.setIndex),
                    ),
                    Expanded(
                        child: _setBox(_kg(ex.sets[j].weight),
                            () => _editSet(idx, j, ex.sets[j]))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _setBox('${ex.sets[j].reps} reps',
                            () => _editSet(idx, j, ex.sets[j]))),
                    SizedBox(
                      width: 52,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        color: BldrWorkoutColorsV2.sheetBg,
                        onSelected: (v) {
                          if (v == 'edit') {
                            _editSet(idx, j, ex.sets[j]);
                          } else if (ex.sets.length > 1) {
                            setState(() => ex.sets.removeAt(j));
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.cw_set_edit,
                                  style: BldrWorkoutTextV2.exName)),
                          PopupMenuItem(
                              value: 'remove',
                              enabled: ex.sets.length > 1,
                              child: Text(l10n.cw_set_remove,
                                  style: BldrWorkoutTextV2.exName)),
                        ],
                        child: Center(
                            child: Text('•••', style: BldrWorkoutTextV2.more)),
                      ),
                    ),
                  ],
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => ex.sets.add(
                  ex.sets.isNotEmpty ? ex.sets.last.copyWith() : _ExSet())),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(34, 4, 0, 4),
                child: Row(
                  children: [
                    const Icon(TablerIcons.plus,
                        size: 9, color: BldrWorkoutColorsV2.muted),
                    const SizedBox(width: 6),
                    Text(l10n.cw_add_set, style: BldrWorkoutTextV2.addSet),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _setBox(String value, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BldrWorkoutColorsV2.setBoxBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BldrWorkoutColorsV2.setBoxBorder),
          ),
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrWorkoutTextV2.setValue),
        ),
      );

  // ── edição pelas caixas Séries / Reps / Desc. ─────────────────────────────

  Future<int?> _stepperSheet(String title, int initial,
      {int min = 1, int max = 99, int step = 1, String suffix = ''}) {
    final l10n = AppLocalizations.of(context);
    var value = initial;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: BldrWorkoutColorsV2.sheetBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(34))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_px, 20, _px, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: BldrWorkoutTextV2.sheetTitle),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: value - step < min
                          ? null
                          : () => setModal(() => value -= step),
                      icon: const Icon(TablerIcons.circle_minus,
                          color: BldrWorkoutColorsV2.gold),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text('$value$suffix',
                          textAlign: TextAlign.center,
                          style: BldrWorkoutTextV2.title),
                    ),
                    IconButton(
                      onPressed: value + step > max
                          ? null
                          : () => setModal(() => value += step),
                      icon: const Icon(TablerIcons.circle_plus,
                          color: BldrWorkoutColorsV2.gold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                BldrGoldRowCta(
                  label: l10n.cw_confirm,
                  height: 52,
                  radius: 18,
                  onTap: () => Navigator.pop(ctx, value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editSetCount(int idx) async {
    final ex = _exercises[idx];
    final v = await _stepperSheet(
        AppLocalizations.of(context).cw_edit_sets_title, ex.sets.length);
    if (v == null || !mounted) return;
    setState(() {
      while (ex.sets.length < v) {
        ex.sets.add(ex.sets.isNotEmpty ? ex.sets.last.copyWith() : _ExSet());
      }
      while (ex.sets.length > v) {
        ex.sets.removeLast();
      }
    });
  }

  /// Séries personalizadas com valores diferentes → pede confirmação antes
  /// de sobrescrever (decisão aprovada).
  Future<bool> _confirmOverwrite(bool differs) async {
    if (!differs) return true;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BldrWorkoutColorsV2.sheetBg,
        title: Text(l10n.cw_overwrite_title, style: BldrWorkoutTextV2.exName),
        content: Text(l10n.cw_overwrite_body, style: BldrWorkoutTextV2.hint),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cw_cancel, style: BldrWorkoutTextV2.hint)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.cw_overwrite_confirm,
                  style: BldrWorkoutTextV2.cta)),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _editAllReps(int idx) async {
    final ex = _exercises[idx];
    if (ex.sets.isEmpty) return;
    final v = await _stepperSheet(
        AppLocalizations.of(context).cw_edit_reps_title, ex.sets.first.reps,
        max: 100);
    if (v == null || !mounted) return;
    final differs = ex.sets.map((st) => st.reps).toSet().length > 1;
    if (!await _confirmOverwrite(differs) || !mounted) return;
    setState(() {
      for (var i = 0; i < ex.sets.length; i++) {
        ex.sets[i] = ex.sets[i].copyWith(reps: v);
      }
    });
  }

  Future<void> _editAllRest(int idx) async {
    final ex = _exercises[idx];
    if (ex.sets.isEmpty) return;
    final v = await _stepperSheet(
        AppLocalizations.of(context).cw_edit_rest_title, ex.sets.first.rest,
        min: 0, max: 600, step: 15, suffix: 's');
    if (v == null || !mounted) return;
    final differs = ex.sets.map((st) => st.rest).toSet().length > 1;
    if (!await _confirmOverwrite(differs) || !mounted) return;
    setState(() {
      for (var i = 0; i < ex.sets.length; i++) {
        ex.sets[i] = ex.sets[i].copyWith(rest: v);
      }
    });
  }
}

// ── Exercise Picker Bottom Sheet ──────────────────────────────────────────────

class _ExercisePickerSheet extends StatefulWidget {
  final Set<String> addedIds;
  final void Function(List<ExDbExercise> selected) onConfirm;
  final bool isPro;

  const _ExercisePickerSheet({
    required this.addedIds,
    required this.onConfirm,
    required this.isPro,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

/// Sheet "Adicionar exercícios" (Figma 179:1117): busca, uma fileira de
/// filtros, seleção múltipla e "ADICIONAR N EXERCÍCIOS". Mantém a base
/// ExerciseDB, o limite gratuito e o card de paywall de hoje.
class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  static const _freeLimit = 250;

  /// Fileira única de filtros (decisão aprovada), ligada aos filtros que já
  /// existiam: grupo (bodyParts) ou músculo-alvo (targetMuscles).
  static const _filters = <({String key, String? bodyParts, String? target})>[
    (key: 'all', bodyParts: null, target: null),
    (key: 'back', bodyParts: 'back', target: null),
    (key: 'biceps', bodyParts: null, target: 'biceps'),
    (key: 'chest', bodyParts: 'chest', target: null),
    (key: 'shoulders', bodyParts: 'shoulders', target: null),
    (key: 'legs', bodyParts: 'upper legs,lower legs', target: null),
    (key: 'triceps', bodyParts: null, target: 'triceps'),
    (key: 'core', bodyParts: 'waist', target: null),
    (key: 'glutes', bodyParts: null, target: 'glutes'),
  ];

  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = 'all';
  String _searchQuery = '';

  List<ExDbExercise> _allExercises = [];
  List<ExDbExercise> _filteredExercises = [];
  bool _loading = true;

  /// Selecionados nesta abertura do sheet, na ordem do toque.
  final List<ExDbExercise> _picked = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final list = await ExerciseDbRapidService.instance.listAllExercises();
      if (mounted) {
        setState(() {
          _allExercises = list;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchQuery.trim().toLowerCase();
    final f = _filters.firstWhere((e) => e.key == _filter);
    final seen = <String>{};
    setState(() {
      _filteredExercises = _allExercises.where((ex) {
        if (!seen.add(ex.exerciseId)) return false;
        final matchQ = q.isEmpty ||
            ex.name.toLowerCase().contains(q) ||
            ex.targetMuscles.any((m) => m.contains(q)) ||
            ex.bodyParts.any((b) => b.contains(q));
        var matchBody = true;
        if (f.bodyParts != null) {
          final kws = f.bodyParts!.split(',').map((e) => e.trim());
          matchBody = kws.any((kw) => ex.bodyParts.any((b) => b == kw));
        }
        var matchTarget = true;
        if (f.target != null) {
          matchTarget = ex.targetMuscles.any((m) => m.contains(f.target!));
        }
        return matchQ && matchBody && matchTarget;
      }).toList();
    });
  }

  String _filterLabel(AppLocalizations l10n, String key) => switch (key) {
        'back' => l10n.cw_filter_back,
        'biceps' => l10n.cw_filter_biceps,
        'chest' => l10n.cw_filter_chest,
        'shoulders' => l10n.cw_filter_shoulders,
        'legs' => l10n.cw_filter_legs,
        'triceps' => l10n.cw_filter_triceps,
        'core' => l10n.cw_filter_core,
        'glutes' => l10n.cw_filter_glutes,
        _ => l10n.cw_filter_all,
      };

  void _toggle(ExDbExercise ex) {
    setState(() {
      final i = _picked.indexWhere((e) => e.exerciseId == ex.exerciseId);
      if (i >= 0) {
        _picked.removeAt(i);
      } else {
        _picked.add(ex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, sc) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: BldrWorkoutColorsV2.sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          border: Border.all(color: BldrWorkoutColorsV2.sheetBorder),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 9),
                Container(
                  width: 54,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BldrWorkoutColorsV2.grabber,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 18, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(l10n.cw_sheet_title,
                                style: BldrWorkoutTextV2.sheetTitle),
                          ),
                          Text(l10n.cw_selected_count(_picked.length),
                              style: BldrWorkoutTextV2.count),
                        ],
                      ),
                      const SizedBox(height: 16),
                      BldrSearchFieldV2(
                        controller: _searchCtrl,
                        hint: l10n.cw_search_hint,
                        onChanged: (v) {
                          _searchQuery = v;
                          _applyFilter();
                        },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final key = _filters[i].key;
                            return BldrFilterChipV2(
                              label: _filterLabel(l10n, key),
                              selected: _filter == key,
                              onTap: () {
                                _filter = key;
                                _applyFilter();
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(l10n.cw_all_exercises,
                                style: BldrWorkoutTextV2.listLabel),
                          ),
                          if (!_loading) _countLabel(l10n),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: BldrWorkoutColorsV2.gold))
                      : _filteredExercises.isEmpty
                          ? Center(
                              child: Text('—', style: BldrWorkoutTextV2.hint),
                            )
                          : _buildExerciseList(sc),
                ),
              ],
            ),
            if (_picked.isNotEmpty)
              Positioned(
                left: 17,
                right: 17,
                bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
                child: BldrGoldRowCta(
                  label: l10n.cw_add_n(_picked.length),
                  height: 56,
                  radius: 20,
                  labelStyle: BldrWorkoutTextV2.sheetCta,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onConfirm(List.of(_picked));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// "N exercícios" — no plano gratuito mantém o indicador "N/total 🔒".
  Widget _countLabel(AppLocalizations l10n) {
    if (widget.isPro) {
      return Text(l10n.cw_exercise_count(_filteredExercises.length),
          style: BldrWorkoutTextV2.hintSm);
    }
    return Text(
      '${_filteredExercises.length.clamp(0, _freeLimit)}/${_filteredExercises.length}  🔒',
      style: BldrWorkoutTextV2.hintSm,
    );
  }

  Widget _buildExerciseList(ScrollController sc) {
    final visibleCount = widget.isPro
        ? _filteredExercises.length
        : _filteredExercises.length.clamp(0, _freeLimit);
    final showPaywall = !widget.isPro && _filteredExercises.length > _freeLimit;
    final itemCount = visibleCount + (showPaywall ? 1 : 0);
    return ListView.separated(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(17, 0, 18, 110),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i < visibleCount) return _exerciseRow(_filteredExercises[i]);
        return _buildPaywallCard(_filteredExercises.length - _freeLimit);
      },
    );
  }

  Widget _buildPaywallCard(int hiddenCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BldrWorkoutColorsV2.itemBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BldrWorkoutColorsV2.itemSelBorder),
      ),
      child: Column(
        children: [
          const Icon(TablerIcons.lock,
              color: BldrWorkoutColorsV2.gold, size: 22),
          const SizedBox(height: 10),
          Text('+$hiddenCount exercícios bloqueados',
              textAlign: TextAlign.center, style: BldrWorkoutTextV2.itemName),
          const SizedBox(height: 4),
          Text(
            'Assine o BLDR PRO para acessar todos os\nexercícios com GIFs animados.',
            textAlign: TextAlign.center,
            style: BldrWorkoutTextV2.hintSm,
          ),
        ],
      ),
    );
  }

  Widget _exerciseRow(ExDbExercise ex) {
    final already = widget.addedIds.contains(ex.exerciseId);
    final picked = _picked.any((e) => e.exerciseId == ex.exerciseId);
    final muscles = [
      if (ex.targetMuscles.isNotEmpty) ex.targetMuscles.first,
      if (ex.secondaryMuscles.isNotEmpty) ex.secondaryMuscles.first,
    ].join(' · ');
    return BldrLibraryExerciseTile(
      media: _ExerciseThumbnail(
        primaryUrl: ex.displayUrl,
        fallbackUrl: ex.exerciseId.isNotEmpty
            ? 'https://v2.exercisedb.io/image/${ex.exerciseId}'
            : '',
        cardColor: BldrWorkoutColorsV2.itemThumbBg,
        mutedColor: BldrWorkoutColorsV2.muted,
      ),
      name: ex.name,
      muscles: muscles.isEmpty
          ? (ex.bodyParts.isNotEmpty ? ex.bodyParts.first : '')
          : muscles,
      equipment: ex.equipments.isNotEmpty ? ex.equipments.first : null,
      selected: picked,
      alreadyAdded: already,
      onToggle: () => _toggle(ex),
    );
  }
}
