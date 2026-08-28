import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/features/club/club_service.dart';
import 'package:bldr_fitness/features/club/models.dart';
import 'package:bldr_fitness/features/club/program_detail_page.dart';
import 'package:bldr_fitness/features/club/programs_page.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/features/club/domain/entities/club_community.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_sheet.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/weekly_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart' as wt;
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart' as wuc;
import 'package:bldr_fitness/features/workouts/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/services/supabase_service.dart';
import 'package:bldr_fitness/services/workout_photo_service.dart';
import 'package:bldr_fitness/widgets/continue_workout_card.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/weekly_plan_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/club_active_workout_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/club_cardio_session_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/club_create_workout_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/club_workout_photo_review_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class WorkoutCardData {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String imageUrl;
  final bool isClubExclusive;

  const WorkoutCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.imageUrl = '',
    this.isClubExclusive = false,
  });
}

class TemplateExercise {
  final String id;
  final String? exerciseId;
  final String name;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final int? restSeconds;
  final int? orderIndex;

  const TemplateExercise({
    required this.id,
    required this.name,
    this.exerciseId,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.restSeconds,
    this.orderIndex,
  });
}

class _CardioOption {
  final String label;
  final IconData icon;
  final String activityType;
  final int? targetMinutes;
  const _CardioOption({
    required this.label,
    required this.icon,
    required this.activityType,
    this.targetMinutes,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ClubWorkoutsScreen extends StatefulWidget {
  const ClubWorkoutsScreen({super.key});

  @override
  State<ClubWorkoutsScreen> createState() => _ClubWorkoutsScreenState();
}

class _ClubWorkoutsScreenState extends State<ClubWorkoutsScreen>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFD4AF37);
  static const _goldBg = Color(0x1FD4AF37);
  static const _borderGold = Color(0x40D4AF37);
  static const _bg = Color(0xFF111110);
  static const _surface = Color(0xFF1A1916);
  static const _card = Color(0xFF1E1C18);
  static const _muted = Color(0xFF888070);

  late TabController _myWorkoutsTabCtrl;

  // Continuar treino
  List<Map<String, dynamic>> _pausedClubWorkouts = [];

  // Foto → ficha
  bool _analyzingPhoto = false;

  // Meus Treinos
  List<Map<String, dynamic>> _myWorkouts = [];
  bool _myWorkoutsLoading = true;

  // Library
  bool _loadingLibrary = true;
  List<WorkoutCardData> _library = const [];

  // Programs
  List<ClubProgram> _programs = const [];
  bool _programsLoading = true;

  // Workout start
  final Map<String, List<TemplateExercise>> _exCache = {};
  bool _startingWorkout = false;

  // Week card key for reload
  final _weekCardKey = GlobalKey<_ClubCurrentWeekCardState>();

  @override
  void initState() {
    super.initState();
    _myWorkoutsTabCtrl = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _myWorkoutsTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadMyWorkouts(),
      _loadLibrary(),
      _loadPrograms(),
      _loadPausedWorkouts(),
    ]);
  }

  Future<void> _loadPausedWorkouts() async {
    try {
      final result = await getIt<GetPausedClubWorkouts>()(limit: 2);
      final paused =
          (result.valueOrNull ?? []).map(pausedToLegacyMap).toList();
      if (!mounted) return;
      setState(() => _pausedClubWorkouts = paused);
    } catch (_) {
      if (mounted) setState(() => _pausedClubWorkouts = []);
    }
  }

  Future<void> _loadMyWorkouts() async {
    try {
      final result = await getIt<GetMyClubTemplates>()();
      final all = (result.valueOrNull ?? []).map(templateToLegacyMap).toList();
      if (!mounted) return;
      setState(() {
        _myWorkouts = all;
        _myWorkoutsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _myWorkoutsLoading = false);
    }
  }

  Future<void> _loadLibrary() async {
    try {
      final result = await getIt<GetClubPublicTemplates>()(limit: 50);
      final templates = result.valueOrNull;
      if (templates == null) throw Exception(result.failureOrNull?.message);
      if (!mounted) return;
      setState(() {
        _library = templates.map(_templateToCard).toList();
        _loadingLibrary = false;
      });
    } catch (e, st) {
      debugPrint('_loadLibrary error: $e\n$st');
      if (mounted) setState(() => _loadingLibrary = false);
    }
  }

  Future<void> _loadPrograms() async {
    try {
      final svc = BldrClubProgramsService(SupabaseService.instance.client);
      final programs = await svc.listPrograms(from: 0, to: 9);
      if (!mounted) return;
      setState(() {
        _programs = programs;
        _programsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _programsLoading = false);
    }
  }

  WorkoutCardData _templateToCard(wt.WorkoutTemplate t) {
    final minutes = t.estimatedDurationMinutes ?? 30;
    final typeLabel =
        (t.workoutType ?? '').toLowerCase() == 'hiit' ? 'HIIT' : 'Força';
    return WorkoutCardData(
      id: t.id ?? '',
      title: t.name,
      subtitle: '$typeLabel · $minutes min',
      badge: _levelLabel(t.difficultyLevel),
      isClubExclusive: false,
    );
  }

  String _levelLabel(dynamic raw) {
    if (raw is int) {
      switch (raw) {
        case 1:
          return 'Iniciante';
        case 2:
          return 'Intermediário';
        case 3:
          return 'Avançado';
        case 4:
          return 'Experiente';
      }
    }
    final s = raw?.toString().toLowerCase() ?? '';
    if (s.contains('inic')) return 'Iniciante';
    if (s.contains('inter')) return 'Intermediário';
    if (s.contains('avan')) return 'Avançado';
    if (s.contains('exp')) return 'Experiente';
    return s.isEmpty ? 'Todos os níveis' : s;
  }

  // ── workout actions ──────────────────────────────────────────────────────

  void _handleOpenWorkout(WorkoutCardData data) =>
      _openWorkoutSheet(context, data);

  Future<void> _startClubWorkout(
      WorkoutCardData data, BuildContext sheetCtx) async {
    if (_startingWorkout) return;
    setState(() => _startingWorkout = true);
    try {
      final startResult = await getIt<StartClubWorkout>()(
        name: data.title,
        templateId: data.id,
      );
      final workout = startResult.valueOrNull;
      if (workout == null) throw Exception(startResult.failureOrNull?.message);
      if (!mounted) return;
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubActiveWorkoutScreen(
            workoutId:   workout.id ?? '',
            workoutName: data.title,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).club_fail_start),
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _startingWorkout = false);
    }
  }

  Future<void> _openWorkoutSheet(
      BuildContext ctx, WorkoutCardData data) async {
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F10),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99)),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18)),
                            const SizedBox(height: 4),
                            Row(children: [
                              if (data.isClubExclusive) ...[
                                const _ClubBadge(),
                                const SizedBox(width: 8),
                              ],
                              Text(data.subtitle,
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 13)),
                            ]),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<TemplateExercise>>(
                    future: _fetchExercises(data.id),
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(
                            child: CircularProgressIndicator(color: _gold));
                      }
                      final list = snap.data ?? [];
                      if (list.isEmpty) {
                        return const Center(
                            child: Text('Sem exercícios.',
                                style: TextStyle(color: Colors.white70)));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white12, height: 18),
                        itemBuilder: (_, i) {
                          final e = list[i];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: _gold.withOpacity(0.14),
                              child: Text('${i + 1}',
                                  style:
                                      const TextStyle(color: Colors.white)),
                            ),
                            title: Text(e.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(_exerciseSubtitle(e),
                                style:
                                    const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.white38),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startingWorkout
                          ? null
                          : () => _startClubWorkout(data, sheetCtx),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                          _startingWorkout ? 'Iniciando...' : AppLocalizations.of(context).club_start_workout_btn,
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _exerciseSubtitle(TemplateExercise e) {
    final parts = <String>[];
    if (e.sets != null) {
      parts.add(
          e.reps != null ? '${e.sets} x ${e.reps}' : '${e.sets} séries');
    } else if (e.reps != null) {
      parts.add('${e.reps} reps');
    }
    if ((e.durationSeconds ?? 0) > 0) parts.add('${e.durationSeconds}s');
    if ((e.restSeconds ?? 0) > 0) parts.add('descanso ${e.restSeconds}s');
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  Future<List<TemplateExercise>> _fetchExercises(String templateId) async {
    if (_exCache.containsKey(templateId)) return _exCache[templateId]!;
    final result = await getIt<GetClubTemplateExercises>()(templateId);
    final rows = result.valueOrNull;
    if (rows == null) throw Exception(result.failureOrNull?.message);
    final list = rows
        .map((e) => TemplateExercise(
              id: e.id ?? '',
              exerciseId: e.exercise?.id ?? '',
              name: e.exercise?.name ?? 'Exercício',
              sets: e.sets,
              reps: e.reps,
              durationSeconds: e.durationSeconds,
              restSeconds: e.restSeconds,
              orderIndex: e.orderIndex,
            ))
        .toList();
    _exCache[templateId] = list;
    return list;
  }

  // ── personal workout details ──────────────────────────────────────────────

  // Mesmo design do sheet de detalhe do treino grátis
  // (workouts_screen.dart:_viewWorkoutDetails) — header fixo com
  // título/subtítulo de grupos musculares, chips BldrChip, lista de
  // exercícios via BldrListRow+BldrIndexBox, rodapé fixo com blur e
  // BldrPrimaryButton.
  void _viewMyWorkoutDetails(Map<String, dynamic> template) {
    final exercisesFuture = getIt<GetClubTemplateWithExercises>()(
            template['id'].toString())
        .then((r) =>
            r.valueOrNull == null ? null : templateToLegacyMap(r.valueOrNull!));

    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FutureBuilder<Map<String, dynamic>?>(
        future: exercisesFuture,
        builder: (_, snap) {
          final loading = snap.connectionState == ConnectionState.waiting;
          // `snap.data` é sempre saída de `templateToLegacyMap`, que grava
          // sob 'workout_template_exercises' (sem prefixo) — RELATORIO_TREINOS_CLUB.md, bug 1.
          final exercises =
              ((snap.data ?? {})['workout_template_exercises'] as List?) ??
                  [];

          final muscleGroups = <String>{};
          int totalSets = 0;
          for (final row in exercises) {
            final r = (row as Map).cast<String, dynamic>();
            final ex = (r['exercises'] as Map?)?.cast<String, dynamic>() ?? {};
            final group = _muscleGroupText(ex['primary_muscle_group']);
            if (group != null && group.isNotEmpty) muscleGroups.add(group);
            totalSets += (r['sets'] as int?) ?? 0;
          }

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                // ── header (fixo) ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                              color: BldrColors.textMuted,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text((template['name'] as String?) ?? 'Treino',
                                    style: BldrText.cardTitleLg),
                                if (muscleGroups.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(muscleGroups.join(' · '),
                                      style: BldrText.meta),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              Navigator.pop(ctx);
                              final fullResult =
                                  await getIt<GetClubTemplateWithExercises>()(
                                      template['id'].toString());
                              final full = fullResult.valueOrNull == null
                                  ? null
                                  : templateToLegacyMap(fullResult.valueOrNull!);
                              if (!mounted) return;
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ClubCreateWorkoutScreen(editTemplate: full),
                                ),
                              );
                              if (updated == true && mounted) _loadMyWorkouts();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: BldrColors.goldTintChip,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: BldrColors.goldBorderChip),
                              ),
                              child: const Icon(Icons.edit_outlined,
                                  color: BldrColors.goldBright, size: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _confirmDelete(ctx, template),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0x1FC84040),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0x40C84040)),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: Color(0xFFC84040), size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        BldrChip(
                          label:
                              '${(template['estimated_duration_minutes'] as int?) ?? 30} min',
                          icon: Icons.schedule,
                          active: true,
                        ),
                        const SizedBox(width: 8),
                        BldrChip(
                          label:
                              'Nível ${(template['difficulty_level'] as int?) ?? 1}',
                          icon: Icons.bar_chart,
                          active: true,
                        ),
                        const SizedBox(width: 8),
                        BldrChip(
                          label: _fmtType(template['workout_type']),
                          icon: Icons.category,
                          active: true,
                        ),
                      ]),
                    ],
                  ),
                ),

                // ── conteúdo (rolável) ──────────────────────────────────
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: BldrColors.goldBright))
                      : exercises.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text('Nenhum exercício',
                                  style: BldrText.description),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: exercises.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                if (i == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Exercícios',
                                            style: BldrText.sectionTitle),
                                        Text('${exercises.length} · $totalSets séries',
                                            style: BldrText.meta),
                                      ],
                                    ),
                                  );
                                }
                                final row = (exercises[i - 1] as Map)
                                    .cast<String, dynamic>();
                                final ex = (row['exercises'] as Map?)
                                        ?.cast<String, dynamic>() ??
                                    {};
                                final notes = (row['notes'] as String?)?.trim();

                                final detailParts = [
                                  if (row['sets'] != null) '${row['sets']} séries',
                                  if (row['reps'] != null) '${row['reps']} reps',
                                ];
                                var subtitle = detailParts.join(' · ');
                                if (notes != null && notes.isNotEmpty) {
                                  subtitle = subtitle.isEmpty
                                      ? notes
                                      : '$subtitle · $notes';
                                }

                                return BldrListRow(
                                  icon: Icons.fitness_center,
                                  leading: BldrIndexBox(index: i),
                                  title: ex['name'] ?? 'Exercício',
                                  subtitle: subtitle.isEmpty ? null : subtitle,
                                  trailing: const Icon(Icons.chevron_right,
                                      color: BldrColors.textMuted, size: 18),
                                  onTap: () => _showExerciseTechnique(ex),
                                );
                              },
                            ),
                ),

                // ── footer (fixo) ────────────────────────────────────────
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: BldrBlur.sheet, sigmaY: BldrBlur.sheet),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      decoration: BoxDecoration(
                        color: BldrColors.sheetBg,
                        border: Border(top: BorderSide(color: BldrColors.border)),
                      ),
                      child: BldrPrimaryButton(
                        label: AppLocalizations.of(context).club_start_workout_btn,
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          Navigator.pop(ctx);
                          _startPersonalWorkout(template);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Abre a técnica do exercício — sheet de leitura, sem alterar dados.
  /// Mesmo design de workouts_screen.dart:_showExerciseTechnique.
  void _showExerciseTechnique(Map<String, dynamic> exercise) {
    final instructions =
        (exercise['instructions'] as List?)?.cast<String>() ?? const [];

    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: BldrColors.textMuted,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(exercise['name'] ?? 'Exercício', style: BldrText.cardTitleLg),
              if (_muscleGroupText(exercise['primary_muscle_group']) != null) ...[
                const SizedBox(height: 4),
                Text(_muscleGroupText(exercise['primary_muscle_group'])!,
                    style: BldrText.meta),
              ],
              const SizedBox(height: 16),
              if (instructions.isEmpty)
                Text('Técnica não disponível para este exercício.',
                    style: BldrText.description)
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: instructions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}.',
                            style: BldrText.body.copyWith(
                                color: BldrColors.goldBright,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(instructions[i], style: BldrText.body)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext sheetCtx, Map<String, dynamic> template) {
    showDialog(
      context: sheetCtx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: BldrColors.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Excluir treino', style: BldrText.cardTitleLg),
        content: Text(
          'Tem certeza que deseja excluir "${template['name']}"?\nEsta ação não pode ser desfeita.',
          style: BldrText.description,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Cancelar',
                style: BldrText.buttonSecondary
                    .copyWith(color: BldrColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              Navigator.pop(sheetCtx);
              try {
                final delResult = await getIt<DeleteClubTemplate>()(
                    template['id'].toString());
                final delFailure = delResult.failureOrNull;
                if (delFailure != null) throw Exception(delFailure.message);
                if (mounted) {
                  _loadMyWorkouts();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('"${template['name']}" excluído'),
                    backgroundColor: BldrColors.surface,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erro ao excluir: $e'),
                    backgroundColor: const Color(0xFFC84040),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: const Text('Excluir',
                style:
                    TextStyle(color: Color(0xFFC84040), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _fmtType(dynamic t) {
    final s = (t as String? ?? '').toLowerCase();
    if (s == 'força' || s == 'forca') return 'Força';
    if (s == 'hiit') return 'HIIT';
    if (s.isEmpty) return 'Custom';
    return s[0].toUpperCase() + s.substring(1);
  }

  // ── personal workout ─────────────────────────────────────────────────────

  void _startPersonalWorkout(Map<String, dynamic> template) async {
    try {
      final startResult = await getIt<StartClubWorkout>()(
        name: (template['name'] as String?) ?? 'Treino',
        templateId: template['id'].toString(),
      );
      final workout = startResult.valueOrNull;
      if (workout == null) throw Exception(startResult.failureOrNull?.message);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubActiveWorkoutScreen(
            workoutId:   workout.id ?? '',
            workoutName: (template['name'] as String?) ?? 'Treino',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).club_fail_start),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ── foto → ficha ────────────────────────────────────────────────────────

  Future<void> _pickAndAnalyzePhoto() async {
    // Direto ao picker — sem modal de upsell (BLDR Club tem acesso completo)
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _muted, borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _gold),
              title: Text(AppLocalizations.of(context).club_camera,
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _gold),
              title: Text(AppLocalizations.of(context).club_gallery,
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    setState(() => _analyzingPhoto = true);
    try {
      final matches =
          await WorkoutPhotoService.instance.analyzeImage(File(picked.path));
      if (!mounted) return;
      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context).club_no_exercise_in_photo),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ClubWorkoutPhotoReviewScreen(matches: matches),
        ),
      );
      if (mounted) _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao analisar foto: $e'),
          backgroundColor: const Color(0xFFC84040),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _analyzingPhoto = false);
    }
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final items = _library;

    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      // C1-equivalente (G1) — fundo decorativo virou BldrBackground.
      body: BldrBackground(
        child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              color: BldrColors.goldBright,
              backgroundColor: BldrColors.surface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  // ── 1. Hero compacto ──────────────────────────────────
                  const SliverToBoxAdapter(child: _ClubHeroHeader()),

                  // ── 1b. Continuar treino (quando há pausados) — oculto, mini-player global assume ──
                  // if (_pausedClubWorkouts.isNotEmpty)
                  //   SliverPadding(
                  //     padding:
                  //         const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  //     sliver: SliverToBoxAdapter(
                  //       child: _buildContinueSection(),
                  //     ),
                  //   ),

                  // ── 2. Card Semana Atual BLDR CLUB ────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ClubCurrentWeekCard(
                        key: _weekCardKey,
                        onViewPlan: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WeeklyPlanScreen(isClub: true)),
                          );
                          _weekCardKey.currentState?.reload();
                        },
                      ),
                    ),
                  ),

                  // ── 3. Meus Treinos ───────────────────────────────────
                  // Sem padding horizontal aqui: a seção controla o próprio
                  // padding (título/segmented em pageInsets, carrossel
                  // edge-to-edge com seu padding interno).
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    sliver: SliverToBoxAdapter(
                        child: _buildMyWorkoutsSection()),
                  ),

                  // ── 4. Cardio ─────────────────────────────────────────
                  // Sem padding horizontal aqui: BldrCarousel já traz seu
                  // próprio padding de borda (BldrSpacing.pageInsets).
                  // Comentado a pedido — seção fica fora do ar por enquanto,
                  // sem remover o código (_buildCardioSection permanece).
                  // SliverPadding(
                  //   padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                  //   sliver: SliverToBoxAdapter(child: _buildCardioSection()),
                  // ),

                  // ── 5. Yoga & Pilates ─────────────────────────────────
                  // Comentado a pedido — mesmo tratamento do Cardio acima.
                  // SliverPadding(
                  //   padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                  //   sliver: SliverToBoxAdapter(child: _buildYogaSection()),
                  // ),

                  // ── 6. Biblioteca BLDR ────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildGoldDivider()),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: Image.asset(
                          'assets/images/BLDR_CLUB.png',
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // Library carousel
                  SliverToBoxAdapter(
                    child: _loadingLibrary
                        ? const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: _gold)),
                          )
                        : items.isEmpty
                            ? Padding(
                                padding: EdgeInsets.only(top: 24),
                                child: Center(
                                    child: Text(
                                        AppLocalizations.of(context).club_no_workout_found,
                                        style: TextStyle(
                                            color: Colors.white70))),
                              )
                            : SizedBox(
                                height: 212,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 0),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (_, i) => SizedBox(
                                    width: 158,
                                    child: _LibraryTile(
                                      data: items[i],
                                      onOpen: () =>
                                          _handleOpenWorkout(items[i]),
                                    ),
                                  ),
                                ),
                              ),
                  ),

                  // ── 5. Programas Club ─────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildGoldDivider()),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                    sliver: SliverToBoxAdapter(
                        child: _buildProgramsSection()),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ),
            ),
        ),
      ),
    );
  }

  // ── Cardio ───────────────────────────────────────────────────────────────

  static const _cardioOptions = [
    _CardioOption(
        label: 'Corrida Leve',
        icon: Icons.directions_run_rounded,
        activityType: 'corrida',
        targetMinutes: 20),
    _CardioOption(
        label: 'HIIT Cardio',
        icon: Icons.bolt_rounded,
        activityType: 'hiit',
        targetMinutes: 30),
    _CardioOption(
        label: 'Ciclismo',
        icon: Icons.directions_bike_rounded,
        activityType: 'ciclismo',
        targetMinutes: 45),
    _CardioOption(
        label: 'Cardio Livre',
        icon: Icons.timer_rounded,
        activityType: 'cardio',
        targetMinutes: null),
  ];

  void _startCardio(_CardioOption option) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClubCardioSessionScreen(
          label: option.label,
          activityType: option.activityType,
          targetMinutes: option.targetMinutes,
        ),
      ),
    ).then((completed) {
      if (completed == true && mounted) {
        _weekCardKey.currentState?.reload();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).club_cardio_saved),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF1E1C18),
          ),
        );
      }
    });
  }

  Widget _buildCardioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: BldrSpacing.pageInsets,
          child: Row(children: [
            const Icon(Icons.favorite_rounded, color: BldrColors.goldBright, size: 18),
            const SizedBox(width: 8),
            Text('Cardio', style: BldrText.sectionTitle),
            const SizedBox(width: 8),
            const BldrBadge(label: 'CLUB'),
          ]),
        ),
        const SizedBox(height: 12),
        // CT6 — carrossel via BldrCarousel (componente 7.10).
        BldrCarousel(
          height: 128,
          itemWidth: 126,
          children: [
            for (final opt in _cardioOptions)
              _CardioCard(option: opt, onStart: () => _startCardio(opt)),
          ],
        ),
      ],
    );
  }

  // ── Yoga & Pilates ───────────────────────────────────────────────────────

  static const _yogaOptions = [
    _CardioOption(
        label: 'Yoga Relaxamento',
        icon: Icons.self_improvement_rounded,
        activityType: 'yoga',
        targetMinutes: 20),
    _CardioOption(
        label: 'Pilates Core',
        icon: Icons.accessibility_new_rounded,
        activityType: 'pilates',
        targetMinutes: 30),
    _CardioOption(
        label: 'Yoga Flexibilidade',
        icon: Icons.self_improvement_rounded,
        activityType: 'yoga',
        targetMinutes: 45),
    _CardioOption(
        label: 'Sessão Livre',
        icon: Icons.timer_rounded,
        activityType: 'yoga',
        targetMinutes: null),
  ];

  Widget _buildYogaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: BldrSpacing.pageInsets,
          child: Row(children: [
            const Icon(Icons.self_improvement_rounded,
                color: BldrColors.goldBright, size: 18),
            const SizedBox(width: 8),
            Text('Yoga & Pilates', style: BldrText.sectionTitle),
            const SizedBox(width: 8),
            const BldrBadge(label: 'CLUB'),
          ]),
        ),
        const SizedBox(height: 12),
        // CT6 — carrossel via BldrCarousel (componente 7.10).
        BldrCarousel(
          height: 128,
          itemWidth: 126,
          children: [
            for (final opt in _yogaOptions)
              _CardioCard(option: opt, onStart: () => _startCardio(opt)),
          ],
        ),
      ],
    );
  }

  // ── section helpers ──────────────────────────────────────────────────────

  Widget _buildGoldDivider() => Container(
        height: 1,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, _gold, Colors.transparent],
          ),
        ),
      );

  // ── Meus Treinos ─────────────────────────────────────────────────────────

  Widget _buildMyWorkoutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: BldrSpacing.pageInsets,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).club_my_workouts, style: BldrText.sectionTitle),
              const SizedBox(height: 12),
              BldrSegmentedControl(
                segments: [AppLocalizations.of(context).club_created_by_me, AppLocalizations.of(context).club_from_trainer],
                selectedIndex: _myWorkoutsTabCtrl.index,
                onChanged: (i) => setState(() => _myWorkoutsTabCtrl.index = i),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _myWorkoutsTabCtrl,
          builder: (_, __) => _myWorkoutsTabCtrl.index == 0
              ? _buildCreatedByMeTab()
              : _buildPersonalTab(),
        ),
      ],
    );
  }

  Widget _buildCreatedByMeTab() {
    if (_myWorkoutsLoading) {
      return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: BldrColors.goldBright)));
    }
    if (_myWorkouts.isEmpty) {
      return Padding(
        padding: BldrSpacing.pageInsets,
        child: Column(children: [
          _buildEmptyMyWorkouts(),
          const SizedBox(height: 12),
          _buildCreateCta(),
        ]),
      );
    }
    // CT4 — "Meus treinos" em carrossel horizontal (era lista vertical).
    return Column(children: [
      BldrCarousel(
        // Mesmo tamanho já usado por BldrWorkoutCard em workouts_screen.dart
        // (título + subtítulo + meta + botão "Iniciar" cabem sem overflow).
        height: 258,
        itemWidth: 154,
        children: [
          for (final w in _myWorkouts)
            _PersonalWorkoutTile(
                workout: w,
                onTap: () => _viewMyWorkoutDetails(w),
                onStart: () => _startPersonalWorkout(w)),
        ],
      ),
      const SizedBox(height: 12),
      Padding(padding: BldrSpacing.pageInsets, child: _buildCreateCta()),
    ]);
  }

  Widget _buildEmptyMyWorkouts() {
    return BldrEmptyState(
      icon: Icons.fitness_center_outlined,
      title: AppLocalizations.of(context).club_no_workout_created,
      instruction: AppLocalizations.of(context).club_create_first_workout,
    );
  }

  // ── Continuar treino ──────────────────────────────────────────────────────

  Widget _buildContinueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTINUAR',
          style: TextStyle(
              color: Color(0xFF888070),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        ..._pausedClubWorkouts.map((summary) {
              final workoutId = summary['id'] as String;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey(workoutId),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1C18),
                        title: const Text('Excluir treino pausado',
                            style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Deseja excluir este treino pausado? O progresso não será recuperado.',
                          style: TextStyle(color: Color(0xFF888070)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar',
                                style:
                                    TextStyle(color: Color(0xFF888070))),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Excluir',
                                style:
                                    TextStyle(color: Color(0xFFC84040))),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) async {
                    try {
                      final delResult =
                          await getIt<DeletePausedClubWorkout>()(workoutId);
                      final delFailure = delResult.failureOrNull;
                      if (delFailure != null) {
                        throw Exception(delFailure.message);
                      }
                      if (mounted) _loadPausedWorkouts();
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Erro ao excluir treino.')),
                        );
                        _loadPausedWorkouts();
                      }
                    }
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC84040),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 22),
                  ),
                  child: ContinueWorkoutCard(
                    summary: summary,
                    onResume: () {
                      final name = (summary['name'] as String?) ?? 'Treino';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClubActiveWorkoutScreen(
                            workoutId: workoutId,
                            workoutName: name,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) _loadAll();
                      });
                    },
                  ),
                ),
              );
            }),
      ],
    );
  }

  // T8 — dois botões quadrados lado a lado (mockup: mesmo estilo neutro
  // para os dois, ícone dourado + label branco, sem destaque diferenciado).
  Widget _buildCreateCta() {
    return Row(
      children: [
        Expanded(
          child: _createCtaButton(
            icon: TablerIcons.plus,
            label: AppLocalizations.of(context).club_create_workout,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClubCreateWorkoutScreen()),
            ).then((created) {
              if (created == true && mounted) _loadMyWorkouts();
            }),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _createCtaButton(
            icon: TablerIcons.camera,
            label: AppLocalizations.of(context).club_from_photo,
            loading: _analyzingPhoto,
            onTap: _analyzingPhoto ? null : _pickAndAnalyzePhoto,
          ),
        ),
      ],
    );
  }

  Widget _createCtaButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: BldrGlassCard(
        radius: BldrRadius.cardSm,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: BldrColors.goldBright, strokeWidth: 2),
                  )
                : Icon(icon, size: 16, color: BldrColors.goldBright),
            const SizedBox(height: 7),
            Text(
              loading ? AppLocalizations.of(context).club_analyzing_photo : label,
              textAlign: TextAlign.center,
              style: BldrText.cardTitle.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTab() {
    return Padding(
      padding: BldrSpacing.pageInsets,
      child: BldrDashedContainer(
        radius: BldrRadius.cardLg,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, color: BldrColors.textMuted, size: 28),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(AppLocalizations.of(context).club_trainer_workouts, style: BldrText.cardTitle),
              const SizedBox(width: 8),
              const BldrBadge(label: 'Em breve', gold: false),
            ]),
            const SizedBox(height: 4),
            Text(
                AppLocalizations.of(context).club_trainer_programs_soon_desc,
                style: BldrText.metaSm,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Programas Club ───────────────────────────────────────────────────────

  Widget _buildProgramsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: BldrSpacing.pageInsets,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).club_programs_title, style: BldrText.sectionTitle),
                    const SizedBox(height: 2),
                    Text(AppLocalizations.of(context).club_programs_subtitle,
                        style: BldrText.meta),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClubProgramsPage()),
                ),
                child: Text(AppLocalizations.of(context).club_see_all_arrow, style: BldrText.buttonSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_programsLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: CircularProgressIndicator(color: BldrColors.goldBright)),
          )
        else if (_programs.isEmpty)
          Padding(
            padding: BldrSpacing.pageInsets,
            child: BldrEmptyState(
              icon: Icons.auto_awesome_outlined,
              title: AppLocalizations.of(context).club_programs_soon,
            ),
          )
        else
          // CT6-adjacent — carrossel via BldrCarousel (mesmo padrão).
          BldrCarousel(
            height: 200,
            itemWidth: 158,
            children: [
              for (final p in _programs)
                _ProgramCard(
                  program: p,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProgramDetailPage(programId: p.id)),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  1. HERO HEADER — logo original
// ─────────────────────────────────────────────────────────────────────────────

class _ClubHeroHeader extends StatelessWidget {
  const _ClubHeroHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        height: 188,
        child: Stack(
          children: [
            Center(
              child: Image.asset(
                'assets/images/BLDR CLUB_TREINOS.png',
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: HavokEntryIcon(
                onTap: () => showHavokSheet(context, originScreen: 'club_treinos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  2. CARD SEMANA ATUAL — BLDR CLUB VERSION
// ─────────────────────────────────────────────────────────────────────────────

enum _DayStatus { done, today, pending, rest, lost }

enum _ActivityType { workout, running, sport, yoga, none }

class _ClubWeekDay {
  final String abbrev;
  final int dayNumber;
  final _DayStatus status;
  final _ActivityType activityType;
  final String? workoutLabel;
  final String? workoutId;   // ID do club_user_workouts para exclusão
  final String? activityId;  // ID do bldr_club.user_activities (corrida GPS)

  const _ClubWeekDay({
    required this.abbrev,
    required this.dayNumber,
    required this.status,
    required this.activityType,
    this.workoutLabel,
    this.workoutId,
    this.activityId,
  });
}

class _ClubCurrentWeekCard extends StatefulWidget {
  const _ClubCurrentWeekCard({super.key, required this.onViewPlan});
  final VoidCallback onViewPlan;

  @override
  State<_ClubCurrentWeekCard> createState() => _ClubCurrentWeekCardState();
}

class _ClubCurrentWeekCardState extends State<_ClubCurrentWeekCard> {
  static const _gold = Color(0xFFD4AF37);
  static const _goldBg = Color(0x1FD4AF37);
  static const _borderGold = Color(0x40D4AF37);
  static const _card = Color(0xFF1E1C18);
  static const _muted = Color(0xFF888070);
  static const _red = Color(0xFFC84040);

  List<_ClubWeekDay> _days = [];
  bool _loading = true;
  String _splitChip = '';
  int _gymWorkoutsCount = 0;
  int _extraActivitiesCount = 0;
  int _weekXp = 0;

  Future<void> reload() => _load();

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _monday(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  List<String> _splitLabels(String pref) {
    if (pref.contains('Full Body')) return ['Full Body'];
    if (pref.contains('Upper/Lower')) return ['Upper', 'Lower'];
    if (pref.contains('Push/Pull/Legs')) return ['Push', 'Pull', 'Legs'];
    if (pref.contains('ABCDE')) return ['A', 'B', 'C', 'D', 'E'];
    return ['Treino'];
  }

  String _splitChipLabel(String pref) {
    if (pref.contains('Full Body')) return 'Full Body';
    if (pref.contains('Upper/Lower')) return 'Upper · Lower';
    if (pref.contains('Push/Pull/Legs')) return 'Push · Pull · Legs';
    if (pref.contains('ABCDE')) return 'A · B · C · D · E';
    if (pref.contains('HAVOK') || pref.isEmpty) return 'HAVOK Decide';
    return pref.split('(').first.trim();
  }

  List<int> _trainingIndices(int n) {
    n = n.clamp(1, 7);
    if (n >= 7) return List.generate(7, (i) => i);
    return {
          for (int i = 0; i < n; i++) (i * 7 / n).round() % 7,
        }.toList()
        ..sort();
  }

  List<int> _trainingFromRestDays(List<int> restDays) =>
      List.generate(7, (i) => i).where((i) => !restDays.contains(i)).toList();

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final config = (await getIt<wuc.GetWeeklyPlanConfig>()()).valueOrNull;
      if (config == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final splitPref = config.splitPreference;
      final freqDays = config.frequencyDays;
      final restDaysRaw = config.restDays;
      final labels = _splitLabels(splitPref);
      final indices = restDaysRaw.isNotEmpty
          ? _trainingFromRestDays(restDaysRaw)
          : _trainingIndices(freqDays);
      final effectiveFreq = indices.length;

      final now = DateTime.now();
      final weekStart = _monday(now);
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Treinos pessoais da semana (mesma janela do plano semanal)
      final week = (await getIt<wuc.GetWeekCompletedWorkouts>()(
                  weekStart, weekEnd))
              .valueOrNull ??
          const WeekCompletedWorkouts();
      final personalSessions = week.personal;

      // Treinos do Club (inclui não concluídos, p/ tipo de atividade do dia)
      final clubSessions =
          (await getIt<GetClubWorkoutsBetween>()(weekStart, weekEnd))
                  .valueOrNull ??
              <WorkoutSession>[];

      // Atividades avulsas (corridas, esportes)
      final activities =
          (await getIt<GetClubActivitiesBetween>()(weekStart, weekEnd))
                  .valueOrNull ??
              <ClubActivity>[];

      // XP da semana
      final weekXp =
          (await getIt<GetClubXpBetween>()(weekStart, weekEnd)).valueOrNull ??
              0;

      // Build dayIndex → activity type map
      final Map<int, _ActivityType> activityByDay = {};
      // dayIndex → workout data (id, source). Declarado aqui para incluir club workouts.
      final Map<int, Map<String, dynamic>> completedByDay = {};
      // Contador separado do "1 por dia" de completedByDay — completedByDay
      // serve aos quadrados do calendário semanal (:1819-1838, onde um dia só
      // pode ter um estado), mas o card "Treinos" precisa somar TODOS os
      // treinos concluídos na semana, mesmo vários no mesmo dia
      // (RELATORIO_TREINOS_CLUB.md, bug 2). Não mexe no que já usa
      // completedByDay corretamente.
      int gymWorkoutsTotal = 0;

      // Club workouts → activity type + marca como concluído quando completed_at != null
      for (final w in clubSessions) {
        final rawDate = w.completedAt ?? w.startedAt;
        if (rawDate != null) {
          final dt = rawDate.toLocal();
          final idx = dt.weekday - 1;
          // tipo vem de notes (cardio/yoga) ou do name como fallback
          final type = (w.notes ?? w.name).toLowerCase();
          if (type.contains('corrida') || type.contains('run')) {
            activityByDay[idx] = _ActivityType.running;
          } else if (type.contains('yoga') || type.contains('pilates')) {
            activityByDay[idx] = _ActivityType.yoga;
          } else if (type.contains('hiit') ||
              type.contains('ciclismo') ||
              type.contains('cardio')) {
            activityByDay[idx] = _ActivityType.sport;
          } else {
            activityByDay[idx] = _ActivityType.workout;
          }
          // Marca o dia como concluído (necessário para o dot "Feito" e para exclusão)
          if (w.completedAt != null) {
            completedByDay.putIfAbsent(
                idx, () => {'id': w.id ?? '', 'source': 'club'});
            gymWorkoutsTotal++;
          }
        }
      }

      // Personal workouts → override ou adiciona ao completedByDay
      for (final w in personalSessions) {
        if (w.completedAt != null && w.startedAt != null) {
          final idx = w.startedAt!.toLocal().weekday - 1;
          // Personal workout tem prioridade sobre club (sobrescreve se existir)
          completedByDay[idx] = {'id': w.id ?? '', 'source': 'personal'};
          activityByDay.putIfAbsent(idx, () => _ActivityType.workout);
          gymWorkoutsTotal++;
        }
      }

      // Extra activities → mark their days
      final Map<int, _ActivityType> extraByDay = {};
      final Map<int, String> activityIdByDay = {}; // corridas GPS por dia
      for (final a in activities) {
        final dt = (a.createdAt ?? DateTime.now()).toLocal();
        final idx = dt.weekday - 1;
        final type = a.activityType.toLowerCase();
        if (type.contains('run') || type.contains('corrida')) {
          extraByDay[idx] = _ActivityType.running;
        } else if (type.contains('sport') || type.contains('esporte')) {
          extraByDay[idx] = _ActivityType.sport;
        } else {
          extraByDay[idx] = _ActivityType.running; // fallback: corrida GPS
        }
        activityIdByDay[idx] = a.id ?? ''; // rastreia ID para exclusão
        // Mark as done if not already a workout day
        completedByDay.putIfAbsent(idx, () => {'id': a.id});
      }

      // Merge: extra activities override only if no workout on that day
      for (final entry in extraByDay.entries) {
        activityByDay.putIfAbsent(entry.key, () => entry.value);
      }

      // Build days
      const abbrevs = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      final todayIdx = now.weekday - 1;
      final List<_ClubWeekDay> days = [];

      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final isTraining = indices.contains(i);
        final labelIdx = indices.indexOf(i);

        _DayStatus status;
        if (!isTraining) {
          status = _DayStatus.rest;
        } else if (completedByDay.containsKey(i)) {
          status = _DayStatus.done;
        } else if (i == todayIdx) {
          status = _DayStatus.today;
        } else if (i < todayIdx) {
          status = _DayStatus.lost;
        } else {
          status = _DayStatus.pending;
        }

        days.add(_ClubWeekDay(
          abbrev: abbrevs[i],
          dayNumber: date.day,
          status: status,
          activityType: activityByDay[i] ?? _ActivityType.none,
          workoutLabel: isTraining && labelIdx >= 0
              ? labels[labelIdx % labels.length]
              : null,
          workoutId: completedByDay[i]?['source'] == 'club'
              ? completedByDay[i]!['id']?.toString()
              : null,
          activityId: activityIdByDay[i],
        ));
      }

      // Counts for stats pills
      // "Treinos" soma todos os treinos concluídos na semana (gymWorkoutsTotal,
      // não deduplicado por dia — bug 2). "Extras" continua vindo de
      // `activities` direto, sem relação com completedByDay.
      final gymCount = gymWorkoutsTotal;
      final extraCount = activities.length;

      if (mounted) {
        setState(() {
          _days = days;
          _splitChip =
              '${_splitChipLabel(splitPref)} — ${effectiveFreq}x/semana';
          _gymWorkoutsCount = gymCount.clamp(0, effectiveFreq);
          _extraActivitiesCount = extraCount;
          _weekXp = weekXp;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDaySheet(_ClubWeekDay day) {
    final isDone = day.status == _DayStatus.done;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1916),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _muted,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDone ? _gold : _red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDone ? 'Treino Realizado' : 'Treino Perdido',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 17),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isDone
                    ? '${day.abbrev} · ${day.workoutLabel ?? "Treino"} — concluído!'
                    : 'Você não registrou o treino de ${day.abbrev}.',
                style: const TextStyle(color: _muted, fontSize: 14),
              ),
              if (!isDone) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Fazer agora',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
              if (isDone &&
                  (day.workoutId != null || day.activityId != null)) ...[
                const SizedBox(height: 12),
                // ── Seletor de exclusão ────────────────────────────────────
                if (day.workoutId != null && day.activityId != null) ...[
                  // Ambos presentes → mostrar dois botões com label dinâmico
                  const Center(
                    child: Text('Excluir:',
                        style: TextStyle(
                            color: Color(0xFF888070), fontSize: 12)),
                  ),
                  const SizedBox(height: 4),
                  Builder(builder: (_) {
                    // Label/ícone do chip de treino baseado no tipo do dia
                    final IconData workoutIcon;
                    final String workoutLabel;
                    final String workoutTitle;
                    final String workoutMsg;
                    switch (day.activityType) {
                      case _ActivityType.yoga:
                        workoutIcon = Icons.self_improvement_outlined;
                        workoutLabel = 'Yoga/Pilates';
                        workoutTitle = 'Excluir sessão';
                        workoutMsg =
                            'Deseja excluir o registro de Yoga/Pilates? Esta ação não pode ser desfeita.';
                      case _ActivityType.running:
                        workoutIcon = Icons.directions_run_outlined;
                        workoutLabel = 'Cardio (corrida)';
                        workoutTitle = 'Excluir sessão de cardio';
                        workoutMsg =
                            'Deseja excluir o registro de cardio? Esta ação não pode ser desfeita.';
                      case _ActivityType.sport:
                        workoutIcon = Icons.local_fire_department_outlined;
                        workoutLabel = 'Cardio (HIIT)';
                        workoutTitle = 'Excluir sessão de cardio';
                        workoutMsg =
                            'Deseja excluir o registro de cardio? Esta ação não pode ser desfeita.';
                      default:
                        workoutIcon = Icons.fitness_center_outlined;
                        workoutLabel = 'Treino';
                        workoutTitle = 'Excluir treino';
                        workoutMsg =
                            'Deseja excluir o registro do treino? Esta ação não pode ser desfeita.';
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DeleteChipButton(
                          icon: workoutIcon,
                          label: workoutLabel,
                          onTap: () => _confirmDelete(
                            context: context,
                            title: workoutTitle,
                            message: workoutMsg,
                            onConfirmed: () async {
                              await getIt<DeleteClubWorkoutRecord>()(
                                  day.workoutId!);
                            },
                            onDone: () {
                              if (mounted) {
                                Navigator.pop(context);
                                reload();
                              }
                            },
                            onError: () {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Erro ao excluir registro.')),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        _DeleteChipButton(
                          icon: Icons.gps_fixed,
                          label: 'Corrida GPS',
                          onTap: () => _confirmDelete(
                            context: context,
                            title: 'Excluir corrida GPS',
                            message:
                                'Deseja excluir o registro da corrida GPS? Esta ação não pode ser desfeita.',
                            onConfirmed: () async {
                              await getIt<DeleteClubActivityRecord>()(
                                  day.activityId!);
                            },
                            onDone: () {
                              if (mounted) {
                                Navigator.pop(context);
                                reload();
                              }
                            },
                            onError: () {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Erro ao excluir corrida.')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ] else ...[
                  // Apenas um → botão único
                  Builder(builder: (_) {
                    // Label/título dinâmico para o botão único
                    final String singleLabel;
                    final String singleTitle;
                    final String singleMsg;
                    if (day.activityId != null && day.workoutId == null) {
                      singleLabel = 'Excluir corrida GPS';
                      singleTitle = 'Excluir corrida GPS';
                      singleMsg =
                          'Deseja excluir o registro da corrida GPS? Esta ação não pode ser desfeita.';
                    } else {
                      switch (day.activityType) {
                        case _ActivityType.yoga:
                          singleLabel = 'Excluir Yoga/Pilates';
                          singleTitle = 'Excluir sessão';
                          singleMsg =
                              'Deseja excluir o registro de Yoga/Pilates? Esta ação não pode ser desfeita.';
                        case _ActivityType.running:
                        case _ActivityType.sport:
                          singleLabel = 'Excluir sessão de cardio';
                          singleTitle = 'Excluir cardio';
                          singleMsg =
                              'Deseja excluir o registro de cardio? Esta ação não pode ser desfeita.';
                        default:
                          singleLabel = 'Excluir registro';
                          singleTitle = 'Excluir registro';
                          singleMsg =
                              'Deseja excluir este registro? Esta ação não pode ser desfeita.';
                      }
                    }
                    return Center(
                      child: TextButton.icon(
                        onPressed: () => _confirmDelete(
                          context: context,
                          title: singleTitle,
                          message: singleMsg,
                          onConfirmed: () async {
                            if (day.workoutId != null) {
                              await getIt<DeleteClubWorkoutRecord>()(
                                  day.workoutId!);
                            } else {
                              await getIt<DeleteClubActivityRecord>()(
                                  day.activityId!);
                            }
                          },
                          onDone: () {
                            if (mounted) {
                              Navigator.pop(context);
                              reload();
                            }
                          },
                          onError: () {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Erro ao excluir registro.')),
                              );
                            }
                          },
                        ),
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Color(0xFFC84040)),
                        label: Text(singleLabel,
                            style: const TextStyle(
                                color: Color(0xFFC84040), fontSize: 13)),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6)),
                      ),
                    );
                  }),
                ],
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Exibe AlertDialog de confirmação e executa [onConfirmed] se aceito.
  Future<void> _confirmDelete({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() onConfirmed,
    required VoidCallback onDone,
    required VoidCallback onError,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1C18),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message,
            style: const TextStyle(color: Color(0xFF888070))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF888070))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir',
                style: TextStyle(color: Color(0xFFC84040))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await onConfirmed();
      onDone();
    } catch (_) {
      onError();
    }
  }

  @override
  Widget build(BuildContext context) {
    // CT2 — legenda só aparece quando há mais de um tipo de ícone em uso
    // (regra do componente 7.13). Ícone reflete a atividade já inferida
    // hoje pelo club_service (heurística de string sobre notes/name) —
    // dado existente, nada novo inventado aqui.
    final activityTypesInUse = _days
        .where((d) => d.status == _DayStatus.done || d.status == _DayStatus.today)
        .map((d) => d.activityType)
        .where((t) => t != _ActivityType.none)
        .toSet();

    return BldrGlassCard(
      radius: BldrRadius.cardLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Semana atual', style: BldrText.cardTitleLg),
              GestureDetector(
                onTap: widget.onViewPlan,
                child: Text('Ver plano →', style: BldrText.buttonSecondary),
              ),
            ],
          ),
          if (_splitChip.isNotEmpty) ...[
            const SizedBox(height: 8),
            BldrBadge(label: _splitChip),
          ],
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(
                      color: BldrColors.goldBright, strokeWidth: 2),
                ),
              ),
            )
          else ...[
            Row(
              children: _days.map(_buildDayCol).toList(),
            ),
            if (activityTypesInUse.length > 1) ...[
              const SizedBox(height: 10),
              _buildActivityLegend(activityTypesInUse),
            ],
          ],
          if (!_loading) ...[
            const SizedBox(height: 16),
            BldrStatDividerRow(items: [
              BldrStatItem(value: '$_gymWorkoutsCount', label: 'Treinos'),
              BldrStatItem(value: '$_extraActivitiesCount', label: 'Extras'),
              BldrStatItem(value: '$_weekXp', label: 'XP'),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCol(_ClubWeekDay day) {
    final isToday = day.status == _DayStatus.today;
    final tappable =
        day.status == _DayStatus.done || day.status == _DayStatus.lost;

    // "Perdido" não existe mais como estado visual distinto — mesma regra
    // neutra já aplicada em Meu Plano (P1): sem dado, o quadrado fica
    // pendente, nunca vermelho.
    final BldrDayState state = switch (day.status) {
      _DayStatus.done => BldrDayState.done,
      _DayStatus.today => BldrDayState.today,
      _DayStatus.rest => BldrDayState.rest,
      _DayStatus.pending || _DayStatus.lost => BldrDayState.pending,
    };
    final icon =
        (day.status == _DayStatus.done || day.status == _DayStatus.today)
            ? _activityIcon(day.activityType)
            : null;

    return Expanded(
      child: GestureDetector(
        onTap: tappable ? () => _showDaySheet(day) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            children: [
              Text(
                day.abbrev,
                style: isToday
                    ? BldrText.label.copyWith(color: BldrColors.goldBright)
                    : BldrText.meta,
              ),
              const SizedBox(height: 6),
              BldrDaySquare(state: state, icon: icon),
              const SizedBox(height: 6),
              Text(
                '${day.dayNumber}',
                style: isToday
                    ? BldrText.metaSm.copyWith(
                        color: BldrColors.textPrimary, fontWeight: FontWeight.w600)
                    : BldrText.meta,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityLegend(Set<_ActivityType> types) {
    String labelFor(_ActivityType t) => switch (t) {
          _ActivityType.running => 'Corrida',
          _ActivityType.sport => 'Esporte',
          _ActivityType.yoga => 'Yoga',
          _ActivityType.workout => 'Musculação',
          _ActivityType.none => '',
        };
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final t in types)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_activityIcon(t), size: 12, color: BldrColors.goldBright),
              const SizedBox(width: 4),
              Text(labelFor(t), style: BldrText.metaSm),
            ],
          ),
      ],
    );
  }

  IconData _activityIcon(_ActivityType type) {
    switch (type) {
      case _ActivityType.running:
        return Icons.directions_run;
      case _ActivityType.sport:
        return Icons.bolt;
      case _ActivityType.yoga:
        return Icons.self_improvement;
      case _ActivityType.workout:
      case _ActivityType.none:
        return TablerIcons.barbell;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LIBRARY WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// Mesmo padrão visual do `_ProgramCard` (capa com badges em blur no topo +
// bloco de conteúdo sólido abaixo) — consistente com o mockup de referência
// "Programas Club".
class _LibraryTile extends StatelessWidget {
  const _LibraryTile({required this.data, required this.onOpen});
  final WorkoutCardData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return BldrGlassCard(
      radius: BldrRadius.cardLg,
      padding: EdgeInsets.zero,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(BldrRadius.cardLg)),
            child: SizedBox(
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: BldrColors.surfaceInset,
                    child: const Center(
                      child: Icon(TablerIcons.barbell,
                          color: BldrColors.textMuted, size: 26),
                    ),
                  ),
                  if (data.isClubExclusive || data.badge.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Row(children: [
                        if (data.isClubExclusive) ...[
                          const BldrBadge(label: 'CLUB', blur: true),
                          const SizedBox(width: 6),
                        ],
                        if (data.badge.isNotEmpty)
                          Flexible(child: BldrBadge(label: data.badge, blur: true)),
                      ]),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BldrText.cardTitle),
                const SizedBox(height: 3),
                Text(data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrText.meta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROGRAM CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program, required this.onTap});
  final ClubProgram program;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final equipLabel = program.equipment.isEmpty
        ? 'Sem equipamentos'
        : program.equipment.first.toLowerCase().contains('no equipment') ||
                program.equipment.first.toLowerCase().contains('sem')
            ? 'Sem equipamentos'
            : 'Com equipamentos';

    final meta =
        '$equipLabel · ${program.minutesPerDay} min · ${program.durationWeeks} semanas';

    // CT7 — capa fixa com badges em blur no topo + bloco de conteúdo sólido
    // abaixo (não mais texto sobreposto com gradiente na imagem inteira).
    return BldrGlassCard(
      radius: BldrRadius.cardLg,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(BldrRadius.cardLg)),
            child: SizedBox(
              height: 106,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (program.coverImage != null && program.coverImage!.isNotEmpty)
                    Image.network(
                      program.coverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ProgramCardFallback(),
                    )
                  else
                    const _ProgramCardFallback(),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(children: [
                      const BldrBadge(label: 'CLUB', blur: true),
                      const SizedBox(width: 6),
                      BldrBadge(label: levelLabel(program.level), blur: true),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(program.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BldrText.cardTitle),
                const SizedBox(height: 3),
                Text(meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrText.meta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCardFallback extends StatelessWidget {
  const _ProgramCardFallback();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DiagonalLinePainter(),
      child: const Center(
        child: Icon(Icons.star_border_rounded,
            color: Color(0x88D4AF37), size: 36),
      ),
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0F0F10);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const spacing = 10.0;
    for (double i = -size.height; i <= size.width + size.height; i += spacing) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  CARDIO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CardioCard extends StatelessWidget {
  const _CardioCard({required this.option, required this.onStart});
  final _CardioOption option;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return BldrGlassCard(
      radius: BldrRadius.cardSm,
      onTap: onStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BldrIconBox(icon: option.icon, size: 32),
          const Spacer(),
          Text(
            option.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BldrText.cardTitle,
          ),
          const SizedBox(height: 4),
          Text(
            option.targetMinutes != null ? '${option.targetMinutes} min' : 'Livre',
            style: BldrText.meta,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PERSONAL WORKOUT TILE
// ─────────────────────────────────────────────────────────────────────────────

// CT4 (carrossel) + CT5 (botão "Iniciar" outline dentro do card) + G10
// (título curto + subtítulo) — os três resolvidos de uma vez ao compor a
// partir de `BldrWorkoutCard` em vez de uma linha de lista com botão
// dourado sólido.
class _PersonalWorkoutTile extends StatelessWidget {
  const _PersonalWorkoutTile(
      {required this.workout, required this.onStart, this.onTap});
  final Map<String, dynamic> workout;
  final VoidCallback onStart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = (workout['name'] as String?) ?? 'Treino';
    final minutes = (workout['estimated_duration_minutes'] as int?) ?? 30;
    final type = (workout['workout_type'] as String?) ?? '';

    return BldrWorkoutCard(
      title: name,
      subtitle: type.isNotEmpty ? type : null,
      metaLeft: '$minutes min',
      onTap: onTap,
      onStart: onStart,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DELETE CHIP BUTTON (usado no seletor de exclusão do day sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteChipButton extends StatelessWidget {
  const _DeleteChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x14C84040),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x40C84040)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFC84040), size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFC84040),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED BADGE + SECTION HEADER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ClubBadge extends StatelessWidget {
  const _ClubBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text('CLUB',
          style: TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5)),
    );
  }
}



/// `primary_muscle_group` vem ora como String, ora como List<String> —
/// mesmo helper duplicado em workouts_screen.dart e active_workout_screen.dart
/// (dynamic tipado incorretamente no domínio; já causou crash de cast antes).
String? _muscleGroupText(dynamic value) {
  if (value is String) return value.isEmpty ? null : value;
  if (value is List) {
    final parts = value.whereType<String>().where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
  return null;
}
