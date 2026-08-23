import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart'
    as subUc;
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/features/workouts/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/routes/app_routes.dart';
import 'package:bldr_fitness/services/workout_photo_service.dart';
import 'package:bldr_fitness/theme/app_theme.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/widgets/continue_workout_card.dart';
import 'package:bldr_fitness/widgets/custom_error_widget.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/club_active_workout_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_sheet.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/widgets/current_week_card_widget.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/active_workout_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/create_workout_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/weekly_plan_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workout_photo_review_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen>
    with SingleTickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _myWorkouts = [];
  List<Map<String, dynamic>> _bldrWorkouts = [];
  List<Map<String, dynamic>> _pausedWorkouts = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasActiveWorkout = false;
  bool _isPro = false;
  bool _analyzingPhoto = false;

  // T3 — rótulo dinâmico do ciclo de hoje ("Legs", "Push"…), vindo do
  // CurrentWeekCardWidget (mesma derivação de onboarding_data, sem duplicar
  // a regra). `null` = dia de descanso ou dado ainda não carregado.
  String? _todayLabel;

  // T1 — busca local sobre as listas já carregadas (sem nova consulta).
  bool _searchOpen = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // T9 — "Ver tudo" expande o carrossel da Biblioteca BLDR para grade cheia,
  // usando o mesmo dado já carregado.
  bool _bldrExpanded = false;

  late TabController _myWorkoutsTabCtrl;

  /// Key that lets us call reload() on the card after editing the plan.
  final _weekCardKey = GlobalKey<CurrentWeekCardWidgetState>();

  @override
  void initState() {
    super.initState();
    _myWorkoutsTabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _myWorkoutsTabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── data ──────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      if (!_isLoading) setState(() => _isLoading = true);

      final templatesResult = await getIt<GetWorkoutTemplates>()();
      final activeResult = await getIt<HasActiveWorkout>()();
      final pausedResult = await getIt<GetPausedWorkouts>()(limit: 2);

      if (!mounted) return;

      final templates = templatesResult.valueOrNull;
      if (templates == null) {
        throw Exception(templatesResult.failureOrNull?.message);
      }
      final all = templates.map(templateToLegacyMap).toList();
      final isActive = activeResult.valueOrNull ?? false;
      final paused = (pausedResult.valueOrNull ?? [])
          .where((w) => w.source == 'free')
          .map(pausedToLegacyMap)
          .toList();

      // Load subscription in parallel (non-blocking for main list)
      getIt<subUc.GetCurrentSubscription>()().then((r) {
        final sub = r.valueOrNull;
        if (mounted) {
          setState(() => _isPro = sub != null &&
              (sub.status == 'active' || sub.status == 'trialing'));
        }
      });

      setState(() {
        _bldrWorkouts   = all.where((w) => w['is_public'] == true).toList();
        _myWorkouts     = all.where((w) => w['is_public'] != true).toList();
        _pausedWorkouts = paused;
        _hasActiveWorkout = isActive;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> source) {
    if (_searchQuery.trim().isEmpty) return source;
    final q = _searchQuery.trim().toLowerCase();
    return source
        .where((w) => (w['name'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  // ── navigation ─────────────────────────────────────────────────────────────

  void _startWorkout(Map<String, dynamic> template) async {
    try {
      final startResult = await getIt<StartWorkout>()(
        name: template['name'],
        templateId: template['id'],
      );
      final session = startResult.valueOrNull;
      if (session == null) {
        throw Exception(startResult.failureOrNull?.message);
      }

      if (!mounted) return;
      setState(() => _hasActiveWorkout = true);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveWorkoutScreen(
            workoutId: session.id!,
            workoutName: template['name'],
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() => _hasActiveWorkout = false);
          _loadData();
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).workouts_start_error),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _viewWorkoutDetails(Map<String, dynamic> template) {
    // Only user-created workouts (not public BLDR) can be edited/deleted
    final isOwned = template['is_public'] != true;

    // Buscado uma única vez por abertura do sheet — reaproveitado pelo
    // subtítulo de grupos musculares (item 1), pela contagem (item 3) e
    // pela lista de exercícios (item 4), evitando 3 consultas.
    final exercisesFuture = getIt<GetTemplateWithExercises>()(template['id'])
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
          final exercises = ((snap.data ?? {})['workout_template_exercises']
                  as List?) ??
              [];

          // Grupos musculares únicos entre os exercícios do treino.
          final muscleGroups = <String>{};
          int totalSets = 0;
          for (final row in exercises) {
            final r = (row as Map).cast<String, dynamic>();
            final ex =
                (r['exercises'] as Map?)?.cast<String, dynamic>() ?? {};
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

                      // Item 1 — título = nome curto; subtítulo = grupos
                      // musculares (nada de repetir o nome como subtítulo).
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(template['name'],
                                    style: BldrText.cardTitleLg),
                                if (muscleGroups.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(muscleGroups.join(' · '),
                                      style: BldrText.meta),
                                ],
                              ],
                            ),
                          ),
                          if (isOwned) ...[
                            const SizedBox(width: 8),
                            // Edit button
                            GestureDetector(
                              onTap: () async {
                                // Load full template data (with exercises) then open edit screen
                                Navigator.pop(ctx);
                                final fullResult = await getIt<
                                    GetTemplateWithExercises>()(
                                    template['id']);
                                final full = fullResult.valueOrNull;
                                if (!mounted || full == null) return;
                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateWorkoutScreen(
                                      editTemplate: full,
                                    ),
                                  ),
                                );
                                if (updated == true && mounted) _loadData();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: BldrColors.goldTintChip,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: BldrColors.goldBorderChip),
                                ),
                                child: const Icon(Icons.edit_outlined,
                                    color: BldrColors.goldBright, size: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete button
                            GestureDetector(
                              onTap: () => _confirmDelete(ctx, template),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0x1FC84040),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0x40C84040)),
                                ),
                                child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFC84040),
                                    size: 16),
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (template['description'] != null) ...[
                        const SizedBox(height: 8),
                        Text(template['description'],
                            style: BldrText.description),
                      ],

                      // Item 2 — chips de metadados, ícone dourado.
                      const SizedBox(height: 14),
                      Row(children: [
                        BldrChip(
                          label:
                              '${template['estimated_duration_minutes'] ?? 30} min',
                          icon: Icons.schedule,
                          active: true,
                        ),
                        const SizedBox(width: 8),
                        BldrChip(
                          label: 'Nível ${template['difficulty_level'] ?? 1}',
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              child: Text(AppLocalizations.of(ctx).workouts_no_exercises,
                                  style: BldrText.description),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 0, 20, 20),
                              itemCount: exercises.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                // Item 3 — cabeçalho "Exercícios" com contagem.
                                if (i == 0) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(AppLocalizations.of(ctx).workouts_exercises_header,
                                            style: BldrText.sectionTitle),
                                        Text(
                                            AppLocalizations.of(ctx).workouts_exercises_count(exercises.length, totalSets),
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
                                final notes =
                                    (row['notes'] as String?)?.trim();

                                // Item 4 — "3 séries · 12 reps" + variação
                                // (notes) quando houver.
                                final detailParts = [
                                  if (row['sets'] != null)
                                    AppLocalizations.of(ctx).workouts_sets(row['sets'] as int),
                                  if (row['reps'] != null)
                                    AppLocalizations.of(ctx).workouts_reps(row['reps'] as int),
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
                                  subtitle:
                                      subtitle.isEmpty ? null : subtitle,
                                  trailing: const Icon(Icons.chevron_right,
                                      color: BldrColors.textMuted, size: 18),
                                  onTap: () => _showExerciseTechnique(ex),
                                );
                              },
                            ),
                ),

                // ── footer (fixo) — item 5 ──────────────────────────────
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: BldrBlur.sheet, sigmaY: BldrBlur.sheet),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      decoration: BoxDecoration(
                        color: BldrColors.sheetBg,
                        border: Border(
                          top: BorderSide(color: BldrColors.border),
                        ),
                      ),
                      child: BldrPrimaryButton(
                        label: AppLocalizations.of(ctx).workouts_start_workout_btn,
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          Navigator.pop(ctx);
                          _startWorkout(template);
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
              Text(exercise['name'] ?? 'Exercício',
                  style: BldrText.cardTitleLg),
              if (_muscleGroupText(exercise['primary_muscle_group']) != null) ...[
                const SizedBox(height: 4),
                Text(_muscleGroupText(exercise['primary_muscle_group'])!,
                    style: BldrText.meta),
              ],
              const SizedBox(height: 16),
              if (instructions.isEmpty)
                Text(AppLocalizations.of(context).workouts_technique_unavailable,
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
                            child:
                                Text(instructions[i], style: BldrText.body)),
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

  /// Confirmation dialog before permanently deleting a template.
  void _confirmDelete(BuildContext sheetCtx, Map<String, dynamic> template) {
    showDialog(
      context: sheetCtx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: BldrColors.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(dCtx).workouts_delete_title, style: BldrText.cardTitleLg),
        content: Text(
          AppLocalizations.of(dCtx).workouts_delete_body(template['name']),
          style: BldrText.description,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text(AppLocalizations.of(dCtx).common_cancel,
                style: BldrText.buttonSecondary
                    .copyWith(color: BldrColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dCtx);       // close dialog
              Navigator.pop(sheetCtx);  // close detail sheet
              try {
                final result = await getIt<DeleteWorkoutTemplate>()(
                    template['id'] as String);
                final failure = result.failureOrNull;
                if (failure != null) throw Exception(failure.message);
                if (mounted) {
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context).workouts_deleted_snackbar(template['name'])),
                      backgroundColor: BldrColors.surface,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context).workouts_delete_error(e.toString())),
                      backgroundColor: const Color(0xFFC84040),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(dCtx).common_delete,
                style: const TextStyle(
                    color: Color(0xFFC84040), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _fmtType(String? t) {
    if (t == null || t.isEmpty) return 'Custom';
    return t
        .split('_')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: Center(
            child: CircularProgressIndicator(color: BldrColors.goldBright)),
      );
    }

    if (_hasError) {
      return const Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: Center(child: CustomErrorWidget()),
      );
    }

    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      body: BldrBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: BldrColors.goldBright,
            backgroundColor: BldrColors.surface,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // ── T1. Header: título + busca ──────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      BldrSpacing.pageX, 16, BldrSpacing.pageX, 0),
                  sliver: SliverToBoxAdapter(child: _buildHeader()),
                ),

                // ── T3. Hero do treino de hoje ──────────────────────────
                if (_todayLabel != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        BldrSpacing.pageX, 16, BldrSpacing.pageX, 0),
                    sliver: SliverToBoxAdapter(child: _buildTodayHero()),
                  ),

                // ── Card Semana Atual ────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      BldrSpacing.pageX, 16, BldrSpacing.pageX, 0),
                  sliver: SliverToBoxAdapter(
                    child: CurrentWeekCardWidget(
                      key: _weekCardKey,
                      onTodayLabel: (label) {
                        if (mounted) setState(() => _todayLabel = label);
                      },
                      onViewPlan: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WeeklyPlanScreen()),
                        );
                        // Refresh card to reflect any plan changes
                        _weekCardKey.currentState?.reload();
                      },
                    ),
                  ),
                ),

                // ── Continuar treinos pausados ──────────────────────────
                if (_pausedWorkouts.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        BldrSpacing.pageX, 16, BldrSpacing.pageX, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildContinueSection(),
                    ),
                  ),

                // ── Banner treino ativo (legado) — oculto temporariamente ──
                // if (_hasActiveWorkout)
                //   SliverPadding(
                //     padding: const EdgeInsets.fromLTRB(
                //         BldrSpacing.pageX, 16, BldrSpacing.pageX, 0),
                //     sliver: SliverToBoxAdapter(
                //       child: _buildActiveWorkoutBanner(),
                //     ),
                //   ),

                // ── T6. Meus Treinos (abas + carrossel) ─────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      BldrSpacing.pageX, 20, BldrSpacing.pageX, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildMyWorkoutsSection(),
                  ),
                ),

                // ── T4/T9. Biblioteca BLDR ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: _buildBldrSection(),
                  ),
                ),

                SliverToBoxAdapter(
                    child: const SizedBox(height: BldrSpacing.navClearance)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── T1: header ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: _searchOpen
              ? TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: BldrText.screenTitle,
                  cursorColor: BldrColors.goldBright,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: AppLocalizations.of(context).workouts_search_hint,
                    hintStyle:
                        BldrText.screenTitle.copyWith(color: BldrColors.textMuted),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                )
              : Text(AppLocalizations.of(context).workouts_title, style: BldrText.screenTitle),
        ),
        HavokEntryIcon(onTap: () => showHavokSheet(context, originScreen: 'workouts')),
        const SizedBox(width: 8),
        BldrCircleButton(
          icon: _searchOpen ? Icons.close_rounded : TablerIcons.search,
          size: 38,
          filled: false,
          onPressed: () {
            setState(() {
              _searchOpen = !_searchOpen;
              if (!_searchOpen) {
                _searchCtrl.clear();
                _searchQuery = '';
              }
            });
          },
        ),
      ],
    );
  }

  // ── T3: hero do treino de hoje ──────────────────────────────────────────

  Widget _buildTodayHero() {
    return BldrHeroCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WeeklyPlanScreen()),
        );
        _weekCardKey.currentState?.reload();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).workouts_today_hero_label, style: BldrText.label),
          const SizedBox(height: 6),
          // Dinâmico — deriva do plano ativo via CurrentWeekCardWidget.
          Text(AppLocalizations.of(context).workouts_today_with_label(_todayLabel ?? ''), style: BldrText.kpiMd),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context).workouts_today_hero_subtitle,
              style: BldrText.meta),
        ],
      ),
    );
  }

  // ── continue section ─────────────────────────────────────────────────────

  Widget _buildContinueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).workouts_continue_title, style: BldrText.sectionTitle),
        const SizedBox(height: 12),
        ..._pausedWorkouts.map((summary) {
              final workoutId = summary['id'] as String;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey('paused_$workoutId'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: BldrColors.sheetBg,
                        title: Text(AppLocalizations.of(context).dashboard_delete_paused_title,
                            style: const TextStyle(color: Colors.white)),
                        content: Text(
                          AppLocalizations.of(context).dashboard_delete_paused_body,
                          style: TextStyle(color: Color(0xFF888070)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(AppLocalizations.of(context).common_cancel,
                                style: const TextStyle(color: Color(0xFF888070))),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(AppLocalizations.of(context).common_delete,
                                style: const TextStyle(color: Color(0xFFC84040))),
                          ),
                        ],
                      ),
                    ) ?? false;
                  },
                  onDismissed: (_) async {
                    setState(() => _pausedWorkouts
                        .removeWhere((w) => w['id'] == workoutId));
                    final result =
                        await getIt<DeletePausedWorkout>()(workoutId, 'free');
                    if (result.isFailure && mounted) _loadData();
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC84040),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 24),
                  ),
                  // ContinueWorkoutCard é compartilhado (Club + Dashboard) —
                  // mantido como está, não redesenhado nesta tarefa.
                  child: ContinueWorkoutCard(
                    summary: summary,
                    onResume: () => _resumeWorkout(summary),
                  ),
                ),
              );
            }),
      ],
    );
  }

  void _resumeWorkout(Map<String, dynamic> summary) {
    final id     = summary['id'] as String;
    final name   = (summary['name'] as String?) ?? 'Treino';
    final source = (summary['source'] as String?) ?? 'free';

    if (source == 'club') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubActiveWorkoutScreen(
            workoutId: id,
            workoutName: name,
          ),
        ),
      ).then((_) { if (mounted) _loadData(); });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveWorkoutScreen(
            workoutId: id,
            workoutName: name,
          ),
        ),
      ).then((_) { if (mounted) _loadData(); });
    }
  }

  // ── active workout banner ─────────────────────────────────────────────────

  Widget _buildActiveWorkoutBanner() {
    return BldrGlassCard(
      background: BldrColors.goldTintChip,
      borderColor: BldrColors.goldBorderChip,
      onTap: () async {
        final activeResult = await getIt<GetActiveWorkoutDetails>()();
        final active = activeResult.valueOrNull;
        if (active == null || active.id == null || !mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveWorkoutScreen(
              workoutId: active.id!,
              workoutName: active.name.isNotEmpty ? active.name : 'Treino',
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() => _hasActiveWorkout = false);
            _loadData();
          }
        });
      },
      child: Row(
        children: [
          const Icon(Icons.circle, color: BldrColors.goldBright, size: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Text(AppLocalizations.of(context).workouts_active_banner_text,
                style: BldrText.body.copyWith(
                    color: BldrColors.goldBright, fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.chevron_right,
              color: BldrColors.goldBright, size: 18),
        ],
      ),
    );
  }

  // ── T6: meus treinos section ──────────────────────────────────────────────

  Widget _buildMyWorkoutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).workouts_my_workouts, style: BldrText.sectionTitle),
        const SizedBox(height: 12),
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: BldrColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _myWorkoutsTabCtrl,
            indicator: BoxDecoration(
              color: BldrColors.goldTintChip,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BldrColors.goldBorderChip),
            ),
            indicatorPadding: const EdgeInsets.all(4),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: BldrColors.goldBright,
            unselectedLabelColor: BldrColors.textSecondary,
            labelStyle: const TextStyle(
                fontFamily: BldrText.family,
                fontWeight: FontWeight.w600,
                fontSize: 13),
            unselectedLabelStyle: const TextStyle(
                fontFamily: BldrText.family,
                fontWeight: FontWeight.w400,
                fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: AppLocalizations.of(context).workouts_created_by_me),
              Tab(text: AppLocalizations.of(context).workouts_from_my_trainer),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildTabContent(),
      ],
    );
  }

  Widget _buildTabContent() {
    return AnimatedBuilder(
      animation: _myWorkoutsTabCtrl,
      builder: (_, __) {
        if (_myWorkoutsTabCtrl.index == 0) {
          return _buildCreatedByMeTab();
        }
        return _buildPersonalTab();
      },
    );
  }

  Widget _buildCreatedByMeTab() {
    final list = _filtered(_myWorkouts);
    if (_myWorkouts.isEmpty) {
      return Column(
        children: [
          // T7 — empty state com borda tracejada.
          BldrEmptyState(
            icon: Icons.fitness_center_outlined,
            title: AppLocalizations.of(context).workouts_empty_state,
            instruction: AppLocalizations.of(context).workouts_empty_subtitle,
          ),
          const SizedBox(height: 12),
          _buildCreateCta(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BldrCarousel(
          itemWidth: 154,
          height: 258,
          children: list
              .map((w) => BldrWorkoutCard(
                    title: w['name'] as String? ?? 'Treino',
                    subtitle: w['description'] as String?,
                    metaLeft: '${w['estimated_duration_minutes'] ?? 30} min',
                    metaRight: AppLocalizations.of(context).workouts_difficulty_label(((w['difficulty_level'] as int?) ?? 1)),
                    onTap: () => _viewWorkoutDetails(w),
                    onStart: () => _startWorkout(w),
                  ))
              .toList(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildCreateCta(),
        ),
      ],
    );
  }

  // ── T8: criar treino / a partir de foto ──────────────────────────────────

  Widget _buildCreateCta() {
    return Row(
      children: [
        Expanded(
          child: BldrSquareActionButton(
            icon: Icons.add_rounded,
            label: AppLocalizations.of(context).workouts_create_btn,
            emphasized: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateWorkoutScreen()),
            ).then((created) {
              if (created == true && mounted) _loadData();
            }),
          ),
        ),
        const SizedBox(width: BldrSpacing.gapCard),
        Expanded(
          child: BldrSquareActionButton(
            icon: Icons.camera_alt_outlined,
            label: AppLocalizations.of(context).workouts_from_photo_btn,
            loading: _analyzingPhoto,
            onPressed: _onCreateFromPhoto,
          ),
        ),
      ],
    );
  }

  Future<void> _onCreateFromPhoto() async {
    // Free user → upsell
    if (!_isPro) {
      Navigator.pushNamed(context, AppRoutes.checkoutScreen);
      return;
    }

    // PRO user → choose source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppTheme.accentGold),
                title: Text(AppLocalizations.of(ctx).workouts_photo_camera,
                    style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.accentGold),
                title: Text(AppLocalizations.of(ctx).workouts_photo_gallery,
                    style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
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
      final matches = await WorkoutPhotoService.instance
          .analyzeImage(File(picked.path));

      if (!mounted) return;
      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).workouts_photo_no_exercises),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              WorkoutPhotoReviewScreen(matches: matches),
        ),
      );
      if (mounted) _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).workouts_photo_error(e.toString())),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _analyzingPhoto = false);
    }
  }

  Widget _buildPersonalTab() {
    return BldrEmptyState(
      icon: Icons.person_outline,
      title: AppLocalizations.of(context).workouts_trainer_empty_state,
      instruction: AppLocalizations.of(context).workouts_trainer_empty_subtitle,
    );
  }

  // ── T4/T9: biblioteca bldr ──────────────────────────────────────────────

  Widget _buildBldrSection() {
    final list = _filtered(_bldrWorkouts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BldrSectionHeader(
          title: AppLocalizations.of(context).workouts_bldr_library,
          trailingLabel: list.isEmpty
              ? null
              : (_bldrExpanded ? AppLocalizations.of(context).workouts_see_less : AppLocalizations.of(context).workouts_see_all),
          onTrailingTap: () => setState(() => _bldrExpanded = !_bldrExpanded),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: BldrSpacing.pageInsets,
            child: BldrEmptyState(
              icon: Icons.auto_awesome_outlined,
              title: AppLocalizations.of(context).workouts_bldr_empty,
            ),
          )
        else if (_bldrExpanded)
          Padding(
            padding: BldrSpacing.pageInsets,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: BldrSpacing.gapCard,
                crossAxisSpacing: BldrSpacing.gapCard,
                childAspectRatio: 0.60,
              ),
              itemBuilder: (_, i) {
                final w = list[i];
                return BldrWorkoutCard(
                  title: w['name'] as String? ?? 'Treino',
                  subtitle: w['description'] as String?,
                  metaLeft: '${w['estimated_duration_minutes'] ?? 30} min',
                  metaRight: 'Nível ${w['difficulty_level'] ?? 1}',
                  onTap: () => _viewWorkoutDetails(w),
                  onStart: () => _startWorkout(w),
                );
              },
            ),
          )
        else
          BldrCarousel(
            itemWidth: 154,
            height: 258,
            children: list
                .map((w) => BldrWorkoutCard(
                      title: w['name'] as String? ?? 'Treino',
                      subtitle: w['description'] as String?,
                      metaLeft:
                          '${w['estimated_duration_minutes'] ?? 30} min',
                      metaRight: AppLocalizations.of(context).workouts_difficulty_label(((w['difficulty_level'] as int?) ?? 1)),
                      onTap: () => _viewWorkoutDetails(w),
                      onStart: () => _startWorkout(w),
                    ))
                .toList(),
          ),
      ],
    );
  }
}

/// `Exercise.primaryMuscleGroup` é `dynamic` por design: `String` nos
/// exercícios da base interna, `List` nos vindos do ExerciseDB (ver
/// lib/features/workouts/domain/entities/exercise.dart). Cast direto para
/// `String?` quebra em runtime para exercícios do ExerciseDB — esta função
/// normaliza os dois formatos para exibição.
String? _muscleGroupText(dynamic value) {
  if (value is String) return value.isEmpty ? null : value;
  if (value is List) {
    final parts = value.whereType<String>().where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
  return null;
}
