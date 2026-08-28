import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart' as wt;
import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';

// ── Internal models ───────────────────────────────────────────────────────────

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
  final String exDbId;
  final String name;
  final String imageUrl;
  final String muscle;
  final List<_ExSet> sets;

  _WorkoutEx({
    required this.exDbId,
    required this.name,
    required this.imageUrl,
    required this.muscle,
    List<_ExSet>? sets,
  }) : sets = sets ?? [_ExSet()];
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ClubCreateWorkoutScreen extends StatefulWidget {
  /// Quando não-nulo, a tela entra em modo de edição.
  /// Deve ser o retorno de [ClubWorkoutsService.getClubWorkoutTemplateWithExercises].
  final Map<String, dynamic>? editTemplate;

  const ClubCreateWorkoutScreen({super.key, this.editTemplate});

  @override
  State<ClubCreateWorkoutScreen> createState() => _ClubCreateWorkoutScreenState();
}

class _ClubCreateWorkoutScreenState extends State<ClubCreateWorkoutScreen> {
  // BLDR CLUB colours
  static const _gold      = Color(0xFFD4AF37);
  static const _goldBg    = Color(0x1FD4AF37);
  static const _borderGold = Color(0x40D4AF37);
  static const _bg        = Color(0xFF111110);
  static const _surface   = Color(0xFF1A1916);
  static const _card      = Color(0xFF1E1C18);
  static const _muted     = Color(0xFF888070);
  static const _red       = Color(0xFFC84040);

  bool get _isEditing =>
      widget.editTemplate != null && widget.editTemplate!['id'] != null;

  // form state
  final _nameCtrl = TextEditingController();
  String _category = 'Força';
  int _difficulty = 1;
  int _duration = 45;
  bool _saving = false;

  // Apenas os dois valores válidos no enum club_workout_templates.workout_type
  static const _categories = ['Força', 'HIIT'];
  static const _categoryToDbValue = {
    'Força': 'força',
    'HIIT':  'hiit',
  };
  static const _difficulties = [1, 2, 3, 4];
  static const _durations = [30, 45, 60, 75, 90];

  final List<_WorkoutEx> _exercises = [];

  @override
  void initState() {
    super.initState();
    _prefillIfEditing();
  }

  void _prefillIfEditing() {
    final t = widget.editTemplate;
    if (t == null) return;

    _nameCtrl.text = (t['name'] as String?) ?? '';

    // workout_type → category label
    final dbType = (t['workout_type'] as String? ?? '').toLowerCase();
    _category = dbType == 'hiit' ? 'HIIT' : 'Força';

    _difficulty = (t['difficulty_level'] as int?) ?? 1;
    _duration   = (t['estimated_duration_minutes'] as int?) ?? 45;

    // Reconstrói a lista de exercícios a partir dos template_exercises.
    // Dois chamadores, duas convenções de chave: club_workout_screen.dart
    // passa a saída de `templateToLegacyMap` ('workout_template_exercises',
    // sem prefixo — mesma chave que WorkoutModels.templateFromMap espera);
    // club_workout_photo_review_screen.dart monta o mapa à mão com
    // 'club_workout_template_exercises' (prefixado). Aceita as duas para não
    // quebrar nenhum dos dois fluxos (RELATORIO_TREINOS_CLUB.md, bug 1).
    final rawEx = (t['workout_template_exercises'] as List?) ??
        (t['club_workout_template_exercises'] as List?) ??
        [];
    for (final row in rawEx) {
      final exMap = (row['exercises'] as Map?)?.cast<String, dynamic>() ?? {};
      final dbId  = (exMap['exercise_db_id'] as String?) ?? '';
      final name  = (exMap['name'] as String?) ?? 'Exercício';
      final muscle = (exMap['primary_muscle_group'] as String?) ?? '';

      final imageUrl = dbId.isNotEmpty
          ? 'https://static.exercisedb.dev/media/$dbId.gif'
          : '';

      final sets    = (row['sets'] as int?) ?? 1;
      final reps    = (row['reps'] as int?) ?? 10;
      final rest    = (row['rest_seconds'] as int?) ?? 90;
      final weightRaw = row['weight_kg'];
      final weight = weightRaw != null
          ? (weightRaw as num).toDouble()
          : null;

      _exercises.add(_WorkoutEx(
        exDbId:   dbId,
        name:     name,
        imageUrl: imageUrl,
        muscle:   muscle,
        sets: List.generate(
          sets,
          (_) => _ExSet(reps: reps, rest: rest, weight: weight),
        ),
      ));
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
      final exercisePayload = _exercises.map((e) {
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
        return wt.TemplateExercise(
          orderIndex: 0, // ordem final é definida pelo repositório/insert
          sets: e.sets.length,
          reps: avgReps,
          restSeconds: e.sets.isNotEmpty ? e.sets.first.rest : 90,
          weightKg: avgWeight,
          exerciseDbId: e.exDbId,
        );
      }).toList();

      final template = wt.WorkoutTemplate(
        id: _isEditing ? widget.editTemplate!['id'].toString() : null,
        name: name,
        workoutType: _categoryToDbValue[_category] ?? 'força',
        estimatedDurationMinutes: _duration,
        difficultyLevel: _difficulty,
        exercises: exercisePayload,
      );

      final result = _isEditing
          ? await getIt<UpdateClubTemplate>()(template)
          : await getIt<CreateClubTemplate>()(template);
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
      builder: (_) => _ClubExercisePickerSheet(
        addedIds: _exercises.map((e) => e.exDbId).toSet(),
        onAdd: (ex) {
          setState(() {
            _exercises.add(_WorkoutEx(
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
                        border: Border.all(
                            color: sel
                                ? _borderGold
                                : Colors.white.withValues(alpha: 0.1)),
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
                      const Text('Exercícios',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      SizedBox(height: 1.5.h),
                      ..._exercises.asMap().entries.map(
                          (e) => _buildExerciseCard(e.key, e.value)),
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
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: const Icon(Icons.chevron_left,
                  color: Colors.white, size: 22),
            ),
          ),
          Expanded(
            child: Text(_isEditing ? 'Editar treino CLUB' : 'Novo treino CLUB',
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
          borderSide:
              BorderSide(color: _gold.withValues(alpha: 0.5), width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 0.5.h),
      ),
    );
  }

  Widget _buildMetaRow() {
    return Row(
      children: [
        Expanded(
            child: _buildSelect('Categoria', _categories, _category,
                (v) => setState(() => _category = v!))),
        SizedBox(width: 2.w),
        Expanded(
            child: _buildSelect(
                'Nível',
                _difficulties.map((d) => 'Nível $d').toList(),
                'Nível $_difficulty',
                (v) => setState(() =>
                    _difficulty =
                        int.parse(v!.replaceAll('Nível ', ''))))),
        SizedBox(width: 2.w),
        Expanded(
            child: _buildSelect(
                'Duração',
                _durations.map((d) => '${d}min').toList(),
                '${_duration}min',
                (v) => setState(
                    () => _duration =
                        int.parse(v!.replaceAll('min', ''))))),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _surface,
          icon: Icon(Icons.keyboard_arrow_down, color: _muted, size: 16),
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
          Padding(
            padding: EdgeInsets.fromLTRB(3.w, 2.h, 3.w, 1.5.h),
            child: Row(
              children: [
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
                            style: TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _exercises.removeAt(idx)),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded, color: _red, size: 15),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Column(
              children: [
                _setTableHeader(),
                SizedBox(height: 0.5.h),
                ...ex.sets.asMap().entries.map(
                  (e) => _setRow(idx, e.key, e.value, ex.sets.length > 1),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(3.w, 1.h, 3.w, 1.5.h),
            child: GestureDetector(
              onTap: () => setState(() => ex.sets.add(_ExSet(
                    reps: ex.sets.isNotEmpty ? ex.sets.last.reps : 10,
                    rest: ex.sets.isNotEmpty ? ex.sets.last.rest : 90,
                    weight: ex.sets.isNotEmpty ? ex.sets.last.weight : null,
                  ))),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: _gold, size: 16),
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
          width: 44,
          child: Text('SÉRIE',
              style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text('KG',
              style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text('REPS',
              style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
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
          SizedBox(
            width: 44,
            child: Text('${setIdx + 1}',
                style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ),
          SizedBox(width: 2.w),
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
                      color: set.weight != null ? Colors.white : _muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
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
          SizedBox(
            width: 24,
            child: canDelete
                ? GestureDetector(
                    onTap: () => setState(
                        () => _exercises[exIdx].sets.removeAt(setIdx)),
                    child:
                        Icon(Icons.remove_circle_outline, color: _muted, size: 18),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
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
            const Icon(Icons.add_rounded, color: _gold, size: 20),
            SizedBox(width: 2.w),
            const Text('Adicionar exercício',
                style: TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

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
            _saving ? 'Salvando…' : 'Salvar treino',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

// ── Exercise Picker (reutiliza o ExerciseDbRapidService) ──────────────────────

class _ClubExercisePickerSheet extends StatefulWidget {
  final Set<String> addedIds;
  final void Function(ExDbExercise ex) onAdd;

  const _ClubExercisePickerSheet({
    required this.addedIds,
    required this.onAdd,
  });

  @override
  State<_ClubExercisePickerSheet> createState() =>
      _ClubExercisePickerSheetState();
}

class _ClubExercisePickerSheetState extends State<_ClubExercisePickerSheet> {
  static const _gold      = Color(0xFFD4AF37);
  static const _goldBg    = Color(0x1FD4AF37);
  static const _borderGold = Color(0x40D4AF37);
  static const _card      = Color(0xFF1E1C18);
  static const _muted     = Color(0xFF888070);

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
  bool _hasErrors = false;
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

  Future<void> _loadExercises({bool forceReload = false}) async {
    if (forceReload) {
      ExerciseDbRapidService.instance.clearCache();
      setState(() {
        _loading = true;
        _hasErrors = false;
      });
    }
    try {
      final list = await ExerciseDbRapidService.instance.listAllExercises();
      if (mounted) {
        setState(() {
          _allExercises = list;
          _loading = false;
          _hasErrors = ExerciseDbRapidService.instance.hasLoadErrors;
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
        if (!seen.add(ex.exerciseId)) return false;
        final matchQ = q.isEmpty ||
            ex.name.toLowerCase().contains(q) ||
            ex.targetMuscles.any((m) => m.contains(q)) ||
            ex.bodyParts.any((b) => b.contains(q));
        bool matchBody = true;
        if (_bodyPart != null) {
          final keywords = (_bodyPartMap[_bodyPart!] ?? '')
              .toLowerCase()
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          matchBody = keywords.any((kw) => ex.bodyParts.any((b) => b == kw));
        }
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (_, sc) => Column(
        children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Adicionar exercício',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    if (!_loading)
                      Text('${_filteredExercises.length} exercícios',
                          style: TextStyle(color: _muted, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 1.5.h),
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
                    prefixIcon:
                        Icon(Icons.search, color: _muted, size: 18),
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
                      borderSide: const BorderSide(color: _gold, width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                _filterChips(_bodyParts, _bodyPart, (v) {
                  _bodyPart = v;
                  _applyFilter();
                }),
                SizedBox(height: 0.6.h),
                _filterChips(_targets, _target, (v) {
                  _target = v;
                  _applyFilter();
                }),
                SizedBox(height: 0.8.h),
                if (_hasErrors && !_loading)
                  GestureDetector(
                    onTap: () => _loadExercises(forceReload: true),
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 1.h),
                      padding: EdgeInsets.symmetric(
                          horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: const Color(0x1FFFB800),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0x55FFB800)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFFFB800), size: 16),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              'Carregamento parcial (${_allExercises.length} exercícios). Toque para recarregar.',
                              style: const TextStyle(
                                  color: Color(0xFFFFB800),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          const Icon(Icons.refresh_rounded,
                              color: Color(0xFFFFB800), size: 16),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                    : ListView.separated(
                        controller: sc,
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 0.5.h),
                        itemCount: _filteredExercises.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1,
                        ),
                        itemBuilder: (_, i) =>
                            _exerciseRow(_filteredExercises[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips(List<String> options, String? selected,
      void Function(String?) onSelect) {
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
    final muscle = ex.targetMuscles.isNotEmpty
        ? ex.targetMuscles.first
        : (ex.bodyParts.isNotEmpty ? ex.bodyParts.first : '');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: ex.displayUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ex.displayUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: _card,
                        child: Icon(Icons.fitness_center,
                            color: _muted, size: 20),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: _card,
                        child: Icon(Icons.fitness_center,
                            color: _muted, size: 20),
                      ),
                    )
                  : Container(
                      color: _card,
                      child:
                          Icon(Icons.fitness_center, color: _muted, size: 20),
                    ),
            ),
          ),
          SizedBox(width: 3.w),
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
          GestureDetector(
            onTap: isAdded
                ? null
                : () {
                    setState(() => _addedIds.add(ex.exerciseId));
                    widget.onAdd(ex);
                  },
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
                    color: isAdded
                        ? _muted.withValues(alpha: 0.3)
                        : _borderGold),
              ),
              child: Icon(
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
