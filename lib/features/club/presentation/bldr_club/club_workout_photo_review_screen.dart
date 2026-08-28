// lib/presentation/bldr_club/club_workout_photo_review_screen.dart
//
// Tela de revisão dos exercícios extraídos da foto para o BLDR Club.
// Mesmo fluxo de WorkoutPhotoReviewScreen, mas redireciona para
// ClubCreateWorkoutScreen no formato que ela espera.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';
import 'package:bldr_fitness/services/workout_photo_service.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/club_create_workout_screen.dart';

class ClubWorkoutPhotoReviewScreen extends StatefulWidget {
  final List<MatchedExercise> matches;

  const ClubWorkoutPhotoReviewScreen({Key? key, required this.matches})
      : super(key: key);

  @override
  State<ClubWorkoutPhotoReviewScreen> createState() =>
      _ClubWorkoutPhotoReviewScreenState();
}

class _ClubWorkoutPhotoReviewScreenState
    extends State<ClubWorkoutPhotoReviewScreen> {
  static const _gold       = Color(0xFFD4AF37);
  static const _goldBg     = Color(0x1FD4AF37);
  static const _borderGold = Color(0x40D4AF37);
  static const _bg         = Color(0xFF111110);
  static const _surface    = Color(0xFF1A1916);
  static const _card       = Color(0xFF1E1C18);
  static const _muted      = Color(0xFF888070);
  static const _red        = Color(0xFFC84040);
  static const _green      = Color(0xFF4CAF50);

  late List<_ReviewItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.matches
        .map((m) => _ReviewItem(match: m, selected: m.match != null))
        .toList();
  }

  // ── Continue ───────────────────────────────────────────────────────────────

  void _proceed() {
    final confirmed =
        _items.where((i) => i.selected && i.match.match != null).toList();
    if (confirmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecione ao menos um exercício para continuar'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Build payload compatible with ClubCreateWorkoutScreen._prefillIfEditing
    final exerciseRows = confirmed.map((item) {
      final ex   = item.match.match!;
      final info = item.match.extracted;
      return {
        'exercises': {
          'exercise_db_id':       ex.exerciseId,
          'name':                 ex.name,
          'primary_muscle_group': ex.targetMuscles.isNotEmpty
              ? ex.targetMuscles.first
              : '',
        },
        'sets':         info.sets,
        'reps':         info.reps,
        'rest_seconds': info.rest,
        'weight_kg':    null,
      };
    }).toList();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ClubCreateWorkoutScreen(
          editTemplate: {
            'id':                               null, // null = create mode
            'name':                             '',
            'workout_type':                     'força',
            'estimated_duration_minutes':       45,
            'difficulty_level':                 1,
            'club_workout_template_exercises':  exerciseRows,
          },
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.separated(
                padding:
                    EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                itemCount: _items.length,
                separatorBuilder: (_, __) => SizedBox(height: 1.2.h),
                itemBuilder: (_, i) => _buildItem(i),
              ),
            ),
            _buildFooter(),
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
            bottom:
                BorderSide(color: Colors.white.withOpacity(0.07))),
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
                    color: Colors.white.withOpacity(0.07)),
              ),
              child: const Icon(Icons.chevron_left,
                  color: Colors.white, size: 22),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Confirmar exercícios',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
                Text(
                  'Revise os exercícios identificados na ficha',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          // CLUB badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'CLUB',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int i) {
    final item  = _items[i];
    final match = item.match;
    final ex    = match.match;
    final info  = match.extracted;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (match.matchType) {
      case MatchType.exact:
        statusColor = _green;
        statusLabel = 'Correspondência exata';
        statusIcon  = Icons.check_circle_rounded;
        break;
      case MatchType.fuzzy:
        statusColor = _gold;
        statusLabel = 'Correspondência aproximada — confirme';
        statusIcon  = Icons.info_outline_rounded;
        break;
      case MatchType.notFound:
        statusColor = _red;
        statusLabel = 'Não encontrado';
        statusIcon  = Icons.error_outline_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.selected
              ? statusColor.withOpacity(0.4)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── top row ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(3.w, 2.h, 3.w, 1.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: ex != null
                      ? () =>
                          setState(() => item.selected = !item.selected)
                      : null,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: item.selected && ex != null
                          ? _gold
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: item.selected && ex != null
                              ? _gold
                              : _muted),
                    ),
                    child: item.selected && ex != null
                        ? const Icon(Icons.check_rounded,
                            color: Colors.black, size: 14)
                        : null,
                  ),
                ),
                SizedBox(width: 3.w),

                // Exercise GIF
                if (ex != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CachedNetworkImage(
                        imageUrl: ex.displayUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: _surface),
                        errorWidget: (_, __, ___) => Container(
                            color: _surface,
                            child: Icon(Icons.fitness_center,
                                color: _muted, size: 18)),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.5.w),
                ],

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex?.name ?? info.nameEN,
                        style: TextStyle(
                          color: ex != null ? Colors.white : _muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (ex != null &&
                          ex.name.toLowerCase() !=
                              info.nameEN.toLowerCase()) ...[
                        SizedBox(height: 0.2.h),
                        Text('IA: "${info.nameEN}"',
                            style:
                                TextStyle(color: _muted, fontSize: 11)),
                      ],
                      SizedBox(height: 0.4.h),
                      Row(
                        children: [
                          Icon(statusIcon,
                              color: statusColor, size: 12),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(statusLabel,
                                style: TextStyle(
                                    color: statusColor, fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── chips ─────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(3.w, 0, 3.w, 1.5.h),
            child: Wrap(
              spacing: 2.w,
              children: [
                _paramChip('${info.sets} séries',
                    Icons.repeat_rounded),
                _paramChip(
                    '${info.reps} reps', Icons.fitness_center_rounded),
                _paramChip('${info.rest}s descanso',
                    Icons.timer_outlined),
              ],
            ),
          ),

          // ── busca manual (fuzzy / not found) ──────────────────────────
          if (match.matchType != MatchType.exact)
            Padding(
              padding: EdgeInsets.fromLTRB(3.w, 0, 3.w, 1.5.h),
              child: GestureDetector(
                onTap: () => _openSearchForItem(i),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 3.w, vertical: 0.8.h),
                  decoration: BoxDecoration(
                    color: _goldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _borderGold),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_rounded,
                          color: _gold, size: 14),
                      SizedBox(width: 1.5.w),
                      Text('Buscar manualmente',
                          style: TextStyle(
                              color: _gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paramChip(String label, IconData icon) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _muted, size: 11),
          SizedBox(width: 1.w),
          Text(label, style: TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final count =
        _items.where((i) => i.selected && i.match.match != null).length;
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 2.h),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
            top:
                BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: count > 0 ? _proceed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            disabledBackgroundColor: _muted,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 1.8.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            count > 0
                ? 'Montar treino com $count exercício${count != 1 ? "s" : ""}'
                : 'Selecione ao menos um exercício',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }

  // ── Manual search ──────────────────────────────────────────────────────────

  void _openSearchForItem(int itemIndex) async {
    ExDbExercise? picked;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ClubExerciseSearchSheet(
        initialQuery: _items[itemIndex].match.extracted.nameEN,
        onPick: (ex) {
          picked = ex;
          Navigator.pop(context);
        },
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        final old = _items[itemIndex].match;
        _items[itemIndex] = _ReviewItem(
          match: MatchedExercise(
            extracted: old.extracted,
            match:     picked,
            matchType: MatchType.exact,
          ),
          selected: true,
        );
      });
    }
  }
}

// ── Review item model ──────────────────────────────────────────────────────────

class _ReviewItem {
  MatchedExercise match;
  bool selected;
  _ReviewItem({required this.match, required this.selected});
}

// ── Exercise search bottom sheet ───────────────────────────────────────────────

class _ClubExerciseSearchSheet extends StatefulWidget {
  final String initialQuery;
  final void Function(ExDbExercise) onPick;

  const _ClubExerciseSearchSheet(
      {required this.initialQuery, required this.onPick});

  @override
  State<_ClubExerciseSearchSheet> createState() =>
      _ClubExerciseSearchSheetState();
}

class _ClubExerciseSearchSheetState
    extends State<_ClubExerciseSearchSheet> {
  static const _gold  = Color(0xFFD4AF37);
  static const _card  = Color(0xFF1E1C18);
  static const _muted = Color(0xFF888070);

  final _ctrl = TextEditingController();
  List<ExDbExercise> _results = [];
  bool _loading = true;
  List<ExDbExercise> _all = [];

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialQuery;
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _all = await ExerciseDbRapidService.instance.listAllExercises();
    if (mounted) {
      setState(() => _loading = false);
      _filter();
    }
  }

  void _filter() {
    final q = _ctrl.text.trim().toLowerCase();
    setState(() {
      _results = q.isEmpty
          ? _all.take(50).toList()
          : _all
              .where((e) => e.name.toLowerCase().contains(q))
              .take(50)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          Padding(
            padding:
                EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0.5.h),
            child: Column(
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
                SizedBox(height: 1.5.h),
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  onChanged: (_) => _filter(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar exercício…',
                    hintStyle: TextStyle(color: _muted),
                    prefixIcon:
                        Icon(Icons.search, color: _muted, size: 18),
                    filled: true,
                    fillColor: _card,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 3.w, vertical: 1.2.h),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: _gold, width: 1.5)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: _gold))
                : ListView.builder(
                    controller: sc,
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 0.5.h),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final ex = _results[i];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(8),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: CachedNetworkImage(
                              imageUrl: ex.displayUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Container(color: _card),
                            ),
                          ),
                        ),
                        title: Text(ex.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        subtitle: ex.targetMuscles.isNotEmpty
                            ? Text(ex.targetMuscles.first,
                                style: TextStyle(
                                    color: _muted, fontSize: 11))
                            : null,
                        onTap: () => widget.onPick(ex),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
