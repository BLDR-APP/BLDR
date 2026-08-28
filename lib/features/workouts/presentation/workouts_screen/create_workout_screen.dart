import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart' as subUc;
import 'package:bldr_fitness/features/workouts/domain/entities/exercise.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart' as uc;
import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _ExSet {
  double? weight;
  int reps;
  int rest;

  _ExSet({this.weight, this.reps = 10, this.rest = 90});

  _ExSet copyWith({double? weight, bool clearWeight = false, int? reps, int? rest}) =>
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
        if (!_useFallback && widget.fallbackUrl.isNotEmpty && widget.fallbackUrl != widget.primaryUrl) {
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
  static const _bg = Color(0xFF111110);
  static const _surface = Color(0xFF1A1916);
  static const _card = Color(0xFF1E1C18);
  static const _muted = Color(0xFF888070);
  static const _red = Color(0xFFC84040);

  // ── form state ─────────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  String _category = 'Força';
  int _difficulty = 1;
  int _duration = 45;
  bool _saving = false;

  static const _categories = ['Força', 'HIIT', 'Cardio', 'Mobilidade', 'Misto'];
  // Maps PT label → DB enum value (workout_type column — enum is in Portuguese)
  static const _categoryToDbValue = {
    'Força':      'força',
    'HIIT':       'hiit',
    'Cardio':     'cardio',
    'Mobilidade': 'mobilidade',
    'Misto':      'misto',
  };
  static const _difficulties = [1, 2, 3, 4, 5];
  static const _durations = [30, 45, 60, 75, 90];

  // ── exercise list ──────────────────────────────────────────────────────────
  final List<_WorkoutEx> _exercises = [];

  // ── subscription ──────────────────────────────────────────────────────────
  bool _isPro = false;

  // ── reverse mapping: DB enum value → display label ────────────────────────
  static const _dbValueToCategory = {
    'força':      'Força',
    'hiit':       'HIIT',
    'cardio':     'Cardio',
    'mobilidade': 'Mobilidade',
    'misto':      'Misto',
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

    _difficulty = t.difficultyLevel ?? 1;
    _duration   = t.estimatedDurationMinutes ?? 45;
  }

  Future<void> _loadSubscription() async {
    try {
      final sub = (await getIt<subUc.GetCurrentSubscription>()()).valueOrNull;
      if (mounted) {
        final active = sub != null &&
            (sub.status == 'active' || sub.status == 'trialing');
        debugPrint('[CreateWorkout] isPro=$active  sub=${sub?.status}');
        setState(() => _isPro = active);
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
      final builtSets = List.generate(
        row.sets,
        (_) => _ExSet(
            weight: row.weightKg, reps: row.reps ?? 10, rest: row.restSeconds ?? 90),
      );

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
          exerciseDbId: e.exDbId.isNotEmpty ? e.exDbId : null,
          exercise: e.exDbId.isEmpty && e.id.isNotEmpty
              ? Exercise(id: e.id, name: e.name)
              : null,
        );
      }).toList();

      // isEditing = editTemplate exists AND has a real id (not the photo flow)
      final templateId = widget.editTemplate?.id;
      final isEditing  = widget.editTemplate != null && templateId != null;
      final template = WorkoutTemplate(
        id: templateId,
        name: name,
        workoutType: _categoryToDbValue[_category] ?? _category.toLowerCase(),
        estimatedDurationMinutes: _duration,
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

  void _openPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ExercisePickerSheet(
        addedIds: _exercises.map((e) => e.exDbId).toSet(),
        isPro: _isPro,
        onAdd: (ex) {
          setState(() {
            _exercises.add(_WorkoutEx(
              id: ex.exerciseId,
              exDbId: ex.exerciseId,
              name: ex.name,
              imageUrl: ex.displayUrl,
              muscle: ex.targetMuscles.isNotEmpty
                  ? ex.targetMuscles.first
                  : (ex.bodyParts.isNotEmpty ? ex.bodyParts.first : ''),
            ));
          });
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
              Text('Descanso',
                  style: TextStyle(color: _muted, fontSize: 13)),
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
                        border:
                            Border.all(color: sel ? _borderGold : Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text('${s}s',
                          style: TextStyle(
                              color: sel ? _gold : Colors.white,
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
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
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
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
          keyboardType:
              decimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
          inputFormatters: decimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),
                    _buildNameInput(),
                    SizedBox(height: 1.5.h),
                    _buildMetaRow(),
                    SizedBox(height: 2.5.h),
                    if (_exercises.isNotEmpty) ...[
                      Text('Exercícios',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      SizedBox(height: 1.5.h),
                      ..._exercises.asMap().entries.map((e) =>
                          _buildExerciseCard(e.key, e.value)),
                    ],
                    _buildAddButton(),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
            _buildSaveFooter(),
          ],
        ),
      ),
    );
  }

  // ── header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: const Icon(Icons.chevron_left,
                  color: Colors.white, size: 22),
            ),
          ),
          Expanded(
            child: Text(
                (widget.editTemplate != null &&
                        widget.editTemplate!.id != null)
                    ? 'Editar treino'
                    : 'Novo treino',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
                textAlign: TextAlign.center),
          ),
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: _saving ? _muted : _gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _saving ? 'Salvando…' : 'Salvar',
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── name input ─────────────────────────────────────────────────────────────

  Widget _buildNameInput() {
    return TextField(
      controller: _nameCtrl,
      style: const TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: 'Nome do treino',
        hintStyle: TextStyle(
            color: _muted, fontSize: 20, fontWeight: FontWeight.w700),
        filled: true,
        fillColor: Colors.transparent,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _gold.withValues(alpha: 0.5), width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0.5.h),
      ),
    );
  }

  // ── meta row ───────────────────────────────────────────────────────────────

  Widget _buildMetaRow() {
    return Row(
      children: [
        Expanded(child: _buildSelect('Categoria', _categories, _category,
            (v) => setState(() => _category = v!))),
        SizedBox(width: 2.w),
        Expanded(
            child: _buildSelect(
                'Nível',
                _difficulties.map((d) => 'Nível $d').toList(),
                'Nível $_difficulty',
                (v) => setState(() =>
                    _difficulty = int.parse(v!.replaceAll('Nível ', ''))))),
        SizedBox(width: 2.w),
        Expanded(
            child: _buildSelect(
                'Duração',
                _durations.map((d) => '${d}min').toList(),
                '${_duration}min',
                (v) => setState(
                    () => _duration = int.parse(v!.replaceAll('min', ''))))),
      ],
    );
  }

  Widget _buildSelect(String label, List<String> options, String value,
      void Function(String?) onChange) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _surface,
          icon: Icon(Icons.keyboard_arrow_down,
              color: _muted, size: 16),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500),
          items: options
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChange,
        ),
      ),
    );
  }

  // ── exercise card ──────────────────────────────────────────────────────────

  Widget _buildExerciseCard(int idx, _WorkoutEx ex) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Exercise header ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(3.w, 2.h, 3.w, 1.5.h),
            child: Row(
              children: [
                // GIF thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: ex.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ex.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: _surface,
                              child: Icon(Icons.fitness_center,
                                  color: _muted, size: 22),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: _surface,
                              child: Icon(Icons.fitness_center,
                                  color: _muted, size: 22),
                            ),
                          )
                        : Container(
                            color: _surface,
                            child: Icon(Icons.fitness_center,
                                color: _muted, size: 22),
                          ),
                  ),
                ),
                SizedBox(width: 2.5.w),
                // Name + muscle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      if (ex.muscle.isNotEmpty) ...[
                        SizedBox(height: 0.3.h),
                        Text(ex.muscle,
                            style:
                                TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                // Delete exercise
                GestureDetector(
                  onTap: () => setState(() => _exercises.removeAt(idx)),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: _red, size: 15),
                  ),
                ),
              ],
            ),
          ),

          // ── Sets table ───────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Column(
              children: [
                // Header row
                _setTableHeader(),
                SizedBox(height: 0.5.h),
                ...ex.sets.asMap().entries.map(
                  (e) => _setRow(idx, e.key, e.value, ex.sets.length > 1),
                ),
              ],
            ),
          ),

          // ── Add set button ───────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(3.w, 1.h, 3.w, 1.5.h),
            child: GestureDetector(
              onTap: () => setState(() => ex.sets.add(_ExSet(
                    reps: ex.sets.isNotEmpty
                        ? ex.sets.last.reps
                        : 10,
                    rest: ex.sets.isNotEmpty
                        ? ex.sets.last.rest
                        : 90,
                    weight: ex.sets.isNotEmpty
                        ? ex.sets.last.weight
                        : null,
                  ))),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      color: _gold, size: 16),
                  SizedBox(width: 1.5.w),
                  Text('Adicionar série',
                      style: TextStyle(
                          color: _gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setTableHeader() {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text('SÉRIE',
              style:
                  TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text('KG',
              style:
                  TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text('REPS',
              style:
                  TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ),
        SizedBox(width: 2.w),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _setRow(int exIdx, int setIdx, _ExSet set, bool canDelete) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.6.h),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 32,
            child: Text('${setIdx + 1}',
                style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ),
          SizedBox(width: 2.w),
          // Weight
          Expanded(
            child: GestureDetector(
              onTap: () => _editSet(exIdx, setIdx, set),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 0.9.h),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  set.weight != null ? '${set.weight}' : '—',
                  style: TextStyle(
                      color: set.weight != null
                          ? Colors.white
                          : _muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          // Reps
          Expanded(
            child: GestureDetector(
              onTap: () => _editSet(exIdx, setIdx, set),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 0.9.h),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${set.reps}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          // Delete set
          SizedBox(
            width: 24,
            child: canDelete
                ? GestureDetector(
                    onTap: () => setState(
                        () => _exercises[exIdx].sets.removeAt(setIdx)),
                    child: Icon(Icons.remove_circle_outline,
                        color: _muted, size: 18),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  // ── add button ─────────────────────────────────────────────────────────────

  Widget _buildAddButton() {
    return Padding(
      padding: EdgeInsets.only(top: _exercises.isNotEmpty ? 0 : 0),
      child: GestureDetector(
        onTap: _openPicker,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          decoration: BoxDecoration(
            color: _goldBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderGold),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: _gold, size: 20),
              SizedBox(width: 2.w),
              Text('Adicionar exercício',
                  style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ── save footer ───────────────────────────────────────────────────────────

  Widget _buildSaveFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 2.h),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 1.8.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _saving
                ? 'Salvando…'
                : (widget.editTemplate != null
                    ? 'Salvar alterações'
                    : 'Salvar treino'),
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

// ── Exercise Picker Bottom Sheet ──────────────────────────────────────────────

class _ExercisePickerSheet extends StatefulWidget {
  final Set<String> addedIds;
  final void Function(ExDbExercise ex) onAdd;
  final bool isPro;

  const _ExercisePickerSheet({
    required this.addedIds,
    required this.onAdd,
    this.isPro = false,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  static const _gold = Color(0xFFD4AF37);
  static const _goldBg = Color(0x1FD4AF37);
  static const _borderGold = Color(0x40D4AF37);
  static const _card = Color(0xFF1E1C18);
  static const _muted = Color(0xFF888070);

  /// Max exercises visible to free users before the paywall card.
  static const _freeLimit = 250;

  // ── filter maps (oss.exercisedb.dev field values) ────────────────────────────
  // bodyParts values: chest | back | upper arms | lower arms | upper legs |
  //                   lower legs | shoulders | waist | cardio | neck
  // targetMuscles values: pectorals | lats | quads | glutes | triceps | biceps |
  //                       abs | delts | calves | hamstrings | …
  static const _bodyParts = ['Peito', 'Costas', 'Pernas', 'Ombros', 'Braços', 'Core'];
  static const _bodyPartMap = {
    'Peito':  'chest',
    'Costas': 'back',
    'Pernas': 'upper legs,lower legs',
    'Ombros': 'shoulders',
    'Braços': 'upper arms,lower arms',
    'Core':   'waist',
  };

  static const _targets = [
    'Peitoral', 'Dorsais', 'Quadríceps', 'Glúteos',
    'Tríceps', 'Bíceps', 'Abdômen', 'Ombros', 'Panturrilhas', 'Posteriores',
  ];
  static const _targetMap = {
    'Peitoral':    'pectorals',
    'Dorsais':     'lats',
    'Quadríceps':  'quads',
    'Glúteos':     'glutes',
    'Tríceps':     'triceps',
    'Bíceps':      'biceps',
    'Abdômen':     'abs',
    'Ombros':      'delts',
    'Panturrilhas':'calves',
    'Posteriores': 'hamstrings',
  };

  final TextEditingController _searchCtrl = TextEditingController();
  String? _bodyPart;
  String? _target;
  String _searchQuery = '';

  List<ExDbExercise> _allExercises = [];
  List<ExDbExercise> _filteredExercises = [];
  bool _loading = true;
  final Set<String> _adding = {}; // kept for spinner UI; unused since add is now synchronous

  late Set<String> _addedIds;

  @override
  void initState() {
    super.initState();
    _addedIds = Set.from(widget.addedIds);
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
    final seen = <String>{};
    setState(() {
      _filteredExercises = _allExercises.where((ex) {
        // Deduplicate by exerciseId
        if (!seen.add(ex.exerciseId)) return false;

        final matchQ = q.isEmpty ||
            ex.name.toLowerCase().contains(q) ||
            ex.targetMuscles.any((m) => m.contains(q)) ||
            ex.bodyParts.any((b) => b.contains(q));

        // Body-part filter: match against bodyParts field (OSS API)
        bool matchBody = true;
        if (_bodyPart != null) {
          final keywords = (_bodyPartMap[_bodyPart!] ?? '')
              .toLowerCase()
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          matchBody = keywords
              .any((kw) => ex.bodyParts.any((b) => b == kw));
        }

        // Target-muscle filter: match against targetMuscles field (OSS API)
        bool matchTarget = true;
        if (_target != null) {
          final kw = (_targetMap[_target!] ?? '').toLowerCase().trim();
          matchTarget = kw.isEmpty ||
              ex.targetMuscles.any((m) => m.contains(kw));
        }

        return matchQ && matchBody && matchTarget;
      }).toList();
    });
  }

  void _addExercise(ExDbExercise ex) {
    setState(() => _addedIds.add(ex.exerciseId));
    widget.onAdd(ex);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          // Handle
          Padding(
            padding: EdgeInsets.only(top: 1.5.h, bottom: 0.5.h),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _muted, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Adicionar exercício',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    if (!_loading)
                      widget.isPro
                          ? Text('${_filteredExercises.length} exercícios',
                              style: TextStyle(color: _muted, fontSize: 13))
                          : RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 13),
                                children: [
                                  TextSpan(
                                    text:
                                        '${_filteredExercises.length.clamp(0, _freeLimit)}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  TextSpan(
                                    text:
                                        '/${_filteredExercises.length}',
                                    style: TextStyle(color: _muted),
                                  ),
                                  TextSpan(
                                    text: '  🔒',
                                    style: TextStyle(color: _muted),
                                  ),
                                ],
                              ),
                            ),
                  ],
                ),
                SizedBox(height: 1.5.h),

                // Search bar
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    _searchQuery = v;
                    _applyFilter();
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou músculo…',
                    hintStyle: TextStyle(color: _muted, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: _muted, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              _searchQuery = '';
                              _applyFilter();
                            },
                            child: Icon(Icons.close, color: _muted, size: 16),
                          )
                        : null,
                    filled: true,
                    fillColor: _card,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 3.w, vertical: 1.2.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _gold, width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: 1.h),

                // Body part chips
                _filterChips(
                  _bodyParts,
                  _bodyPart,
                  (v) {
                    _bodyPart = v;
                    _applyFilter();
                  },
                ),
                SizedBox(height: 0.6.h),

                // Target muscle chips
                _filterChips(
                  _targets,
                  _target,
                  (v) {
                    _target = v;
                    _applyFilter();
                  },
                ),
                SizedBox(height: 0.8.h),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _gold))
                : _filteredExercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, color: _muted, size: 40),
                            SizedBox(height: 1.h),
                            Text('Nenhum exercício encontrado',
                                style:
                                    TextStyle(color: _muted, fontSize: 14)),
                          ],
                        ),
                      )
                    : _buildExerciseList(sc),
          ),
        ],
      ),
    );
  }

  // ── exercise list with optional paywall ───────────────────────────────────

  Widget _buildExerciseList(ScrollController sc) {
    final visibleCount = widget.isPro
        ? _filteredExercises.length
        : _filteredExercises.length.clamp(0, _freeLimit);
    final showPaywall =
        !widget.isPro && _filteredExercises.length > _freeLimit;
    // Total items = visible exercises + 1 paywall card (if applicable)
    final itemCount = visibleCount + (showPaywall ? 1 : 0);

    return ListView.separated(
      controller: sc,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      itemCount: itemCount,
      separatorBuilder: (_, i) => i < visibleCount - 1
          ? Divider(color: Colors.white.withValues(alpha: 0.05), height: 1)
          : const SizedBox.shrink(),
      itemBuilder: (_, i) {
        if (i < visibleCount) return _exerciseRow(_filteredExercises[i]);
        // Paywall card
        return _buildPaywallCard(_filteredExercises.length - _freeLimit);
      },
    );
  }

  Widget _buildPaywallCard(int hiddenCount) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderGold),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1C18),
            _goldBg,
          ],
        ),
      ),
      child: Column(
        children: [
          // Lock icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _goldBg,
              shape: BoxShape.circle,
              border: Border.all(color: _borderGold),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: _gold, size: 22),
          ),
          SizedBox(height: 1.2.h),
          Text(
            '+$hiddenCount exercícios bloqueados',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Assine o BLDR PRO para acessar todos os\nexercícios com GIFs animados.',
            style: TextStyle(color: _muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.8.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close picker
                // TODO: navigate to paywall/checkout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 1.4.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ver planos PRO',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips(
      List<String> options, String? selected, void Function(String?) onSelect) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => SizedBox(width: 1.5.w),
        itemBuilder: (_, i) {
          final opt = options[i];
          final sel = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(sel ? null : opt),
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: sel ? _goldBg : _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel
                        ? _borderGold
                        : Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(opt,
                  style: TextStyle(
                      color: sel ? _gold : Colors.white,
                      fontSize: 12,
                      fontWeight:
                          sel ? FontWeight.w600 : FontWeight.w400)),
            ),
          );
        },
      ),
    );
  }

  Widget _exerciseRow(ExDbExercise ex) {
    final isAdded = _addedIds.contains(ex.exerciseId);
    final isAdding = _adding.contains(ex.exerciseId);
    final muscle = ex.targetMuscles.isNotEmpty
        ? ex.targetMuscles.first
        : (ex.bodyParts.isNotEmpty ? ex.bodyParts.first : '');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _ExerciseThumbnail(
                primaryUrl: ex.displayUrl,
                fallbackUrl: ex.exerciseId.isNotEmpty
                    ? 'https://v2.exercisedb.io/image/${ex.exerciseId}'
                    : '',
                cardColor: _card,
                mutedColor: _muted,
              ),
            ),
          ),
          SizedBox(width: 3.w),

          // Name + muscle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ex.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (muscle.isNotEmpty) ...[
                  SizedBox(height: 0.3.h),
                  Text(muscle,
                      style: TextStyle(color: _muted, fontSize: 12)),
                ],
              ],
            ),
          ),
          SizedBox(width: 2.w),

          // Add button
          GestureDetector(
            onTap: (isAdded || isAdding) ? null : () => _addExercise(ex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isAdded
                    ? _muted.withValues(alpha: 0.15)
                    : _goldBg,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isAdded ? _muted.withValues(alpha: 0.3) : _borderGold),
              ),
              child: isAdding
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          color: _gold, strokeWidth: 2),
                    )
                  : Icon(
                      isAdded ? Icons.check : Icons.add,
                      color: isAdded ? _muted : _gold,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
