import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/community/domain/entities/recent_workout.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post_payload.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/widgets/wearable_activity_grid_card.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class CreatePostScreen extends StatefulWidget {
  final String? preselectedWorkoutId;
  final String? preselectedSource;

  const CreatePostScreen({
    super.key,
    this.preselectedWorkoutId,
    this.preselectedSource,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _repo = getIt<CommunityFeedRepository>();
  final _captionController = TextEditingController();

  // Perfil
  String _userFullName = '';
  String? _userUsername;

  int _activeIcon = 0; // 0=treino 1=atividade 2=wearable 3=foto 4=mais
  String _visibility = 'public';
  List<Map<String, dynamic>> _squads = [];
  String? _selectedSquadId;
  String? _selectedSquadTitle;
  bool _publishing = false;

  // Treino
  List<RecentWorkout> _recentWorkouts = [];
  bool _workoutsLoading = true;
  String? _selectedWorkoutId;
  String? _selectedSource;
  RecentWorkout? _selectedWorkout;
  bool _includePrs = true;

  // Atividade
  String? _selectedActivity;
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _caloriesActivityController = TextEditingController();

  // Wearable
  Map<String, dynamic>? _wearableData;
  List<Map<String, dynamic>> _wearableActivities = [];
  bool _wearableImported = false;
  bool _wearableLoading = false;
  String? _wearableError;
  String? _selectedWearableProvider;

  // Foto
  File? _photoFile;
  String? _photoError;

  bool get _canPublish =>
      _captionController.text.trim().isNotEmpty ||
      _selectedWorkoutId != null ||
      _selectedActivity != null ||
      _wearableImported ||
      _photoFile != null;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRecentWorkouts();
    _loadSquads();
    if (widget.preselectedWorkoutId != null) {
      _selectedWorkoutId = widget.preselectedWorkoutId;
      _selectedSource = widget.preselectedSource ?? 'free';
    }
    _captionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _captionController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _caloriesActivityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserService.instance.getCurrentUserProfile();
      if (!mounted || profile == null) return;
      setState(() {
        _userFullName = profile.fullName;
        _userUsername = profile.username;
      });
    } catch (_) {}
  }

  Future<void> _loadRecentWorkouts() async {
    final result = await _repo.fetchRecentWorkouts();
    if (!mounted) return;
    result.fold(
      onSuccess: (workouts) {
        setState(() {
          _recentWorkouts = workouts;
          _workoutsLoading = false;
          if (widget.preselectedWorkoutId != null) {
            final match = workouts
                .where((w) => w.id == widget.preselectedWorkoutId)
                .firstOrNull;
            if (match != null) {
              _selectedWorkoutId = match.id;
              _selectedSource = match.source;
              _selectedWorkout = match;
            }
          }
        });
      },
      onFailure: (failure) {
        debugPrint('[CreatePost] fetchRecentWorkouts: ${failure.message}');
        setState(() => _workoutsLoading = false);
      },
    );
  }

  Future<void> _loadSquads() async {
    final result = await getIt<ArenaRepository>().mySquads();
    if (!mounted) return;
    result.fold(
      onSuccess: (squads) => setState(() => _squads = squads),
      onFailure: (_) {},
    );
  }

  Future<void> _loadWearableActivities(String provider) async {
    setState(() {
      _selectedWearableProvider = provider;
      _wearableLoading = true;
      _wearableError = null;
      _wearableActivities = [];
      _wearableData = null;
      _wearableImported = false;
    });
    final result = await _repo.fetchWearableActivities(provider);
    if (!mounted) return;
    result.fold(
      onSuccess: (activities) => setState(() {
        _wearableActivities = activities;
        _wearableData = null;
        _wearableImported = false;
        _wearableError = null;
        _wearableLoading = false;
      }),
      onFailure: (failure) => setState(() {
        _wearableError = failure.message;
        _wearableLoading = false;
      }),
    );
  }

  Future<void> _showWearableProviderSheet() async {
    final provider = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WearableProviderSheet(
        selectedProvider: _selectedWearableProvider,
      ),
    );
    if (!mounted || provider == null) return;
    await _loadWearableActivities(provider);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() {
        _photoFile = File(picked.path);
        _photoError = null;
      });
    }
  }

  Future<void> _showPhotoSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _photoFile == null ? 'Adicionar foto' : 'Trocar foto',
                style: BldrText.sectionTitle,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  TablerIcons.photo,
                  color: BldrColors.goldBright,
                ),
                title: Text('Escolher da galeria', style: BldrText.body),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  TablerIcons.camera,
                  color: BldrColors.goldBright,
                ),
                title: Text('Tirar foto', style: BldrText.body),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || source == null) return;
    await _pickPhoto(source);
  }

  Future<String?> _uploadPhoto() async {
    if (_photoFile == null) return null;
    final result = await _repo.uploadCommunityPhoto(
      bytes: await _photoFile!.readAsBytes(),
      extension: _photoFile!.path.split('.').last,
    );
    _photoError = result.failureOrNull?.message;
    return result.valueOrNull;
  }

  Future<void> _publish() async {
    if (!_canPublish) return;
    setState(() => _publishing = true);

    try {
      final photoUrl = await _uploadPhoto();
      if (_photoFile != null && photoUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            _photoError ?? 'Não foi possível enviar a foto.',
          )),
        );
        return;
      }
      final payload = <String, dynamic>{};
      payload['version'] = CommunityPostPayload.currentVersion;
      payload['kind'] = _selectedWorkoutId != null
          ? CommunityPayloadKind.workout.name
          : _selectedActivity != null
              ? CommunityPayloadKind.activity.name
              : _wearableImported
                  ? CommunityPayloadKind.wearable.name
                  : CommunityPayloadKind.manual.name;

      final caption = _captionController.text.trim();
      if (caption.isNotEmpty) payload['caption'] = caption;
      if (photoUrl != null) payload['photo_url'] = photoUrl;

      if (_selectedWorkoutId != null) {
        payload['workout_id'] = _selectedWorkoutId;
        payload['source'] = _selectedSource ?? 'free';
        if (_selectedWorkout != null) {
          payload['workout_name'] = _selectedWorkout!.name;
          payload['volume_kg'] = _selectedWorkout!.volumeKg;
          payload['set_count'] = _selectedWorkout!.completedSetCount;
          payload['duration_s'] = _selectedWorkout!.durationSeconds;
          payload['muscle_groups'] = _selectedWorkout!.muscleGroups;
        }
        if (_includePrs) payload['include_prs'] = true;
      }

      if (_selectedActivity != null) {
        payload['activity_type'] = _selectedActivity;
        final dur = int.tryParse(_durationController.text);
        final dist = double.tryParse(_distanceController.text);
        final kcal = int.tryParse(_caloriesActivityController.text);
        if (dur != null) payload['duration_s'] = dur * 60;
        if (dist != null) payload['distance_km'] = dist;
        if (kcal != null) payload['calories'] = kcal;
      }

      if (_wearableImported && _wearableData != null) {
        payload['wearable'] = _wearableData;
      }

      final eventType = _selectedWorkoutId != null
          ? 'workout_completed'
          : _selectedActivity != null
              ? 'activity_completed'
              : _wearableImported
                  ? 'wearable_activity'
                  : 'manual';
      final result = await _repo.createPost(
        eventType: eventType,
        payload: payload,
        visibility: _visibility,
        squadId: _visibility == 'squad' ? _selectedSquadId : null,
      );
      if (result.isFailure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.failureOrNull!.message)),
        );
        return;
      }

      if (!mounted) return;
      _close();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao publicar: $e')),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _showVisibilitySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _VisibilitySheet(
        selected: _visibility,
        onSelect: (v) {
          Navigator.pop(context);
          if (v == 'squad') {
            _selectSquad();
          } else {
            setState(() {
              _visibility = v;
              _selectedSquadId = null;
              _selectedSquadTitle = null;
            });
          }
        },
      ),
    );
  }

  Future<void> _selectSquad() async {
    if (_squads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você não participa de nenhum squad.')),
      );
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            Text('Escolher squad', style: BldrText.sectionTitle),
            const SizedBox(height: 12),
            ..._squads.map(
              (squad) => ListTile(
                title: Text(
                  squad['title'] as String? ?? 'Squad',
                  style: BldrText.body,
                ),
                onTap: () => Navigator.pop(context, squad),
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _visibility = 'squad';
      _selectedSquadId = selected['id'] as String;
      _selectedSquadTitle = selected['title'] as String? ?? 'Squad';
    });
  }

  void _close() => ModalRoute.of(context)?.navigator?.pop();

  @override
  Widget build(BuildContext context) {
    return BldrBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(TablerIcons.x, color: BldrColors.textPrimary),
          onPressed: _close,
        ),
        title: Text('Criar post', style: BldrText.screenTitle),
        actions: [
          TextButton(
            onPressed: _canPublish && !_publishing ? _publish : null,
            child: Text(
              'Publicar',
              style: BldrText.buttonPrimary.copyWith(
                color: _canPublish
                    ? BldrColors.goldBright
                    : BldrColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    BldrSpacing.pageX, 12, BldrSpacing.pageX, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildComposer(),
                    const SizedBox(height: 16),
                    _buildIconBar(),
                    const SizedBox(height: 16),
                    _buildContentArea(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    ));
  }

  Widget _buildComposer() {
    final initial =
        _userFullName.isNotEmpty ? _userFullName[0].toUpperCase() : '?';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [BldrColors.goldSolid, BldrColors.goldBright],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: BldrText.cardTitle.copyWith(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _userUsername != null
                    ? '@$_userUsername'
                    : _userFullName.isNotEmpty
                        ? _userFullName
                        : '...',
                style: BldrText.cardTitle.copyWith(
                  color: _userUsername != null
                      ? BldrColors.goldBright
                      : BldrColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('create_post_caption'),
          controller: _captionController,
          autofocus: true,
          minLines: 2,
          maxLines: null,
          textInputAction: TextInputAction.newline,
          style: BldrText.body,
          decoration: InputDecoration(
            hintText: 'O que você quer compartilhar?',
            hintStyle: BldrText.body.copyWith(
              color: BldrColors.textTertiary,
              fontSize: 17,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildIconBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _iconTab(0, TablerIcons.barbell, 'Treino'),
          _iconTab(1, TablerIcons.run, 'Atividade'),
          _iconTab(2, TablerIcons.device_watch, 'Wearable'),
          _iconTab(3, TablerIcons.camera, 'Foto'),
          _iconTab(4, TablerIcons.dots, 'Mais'),
        ],
      ),
    );
  }

  Widget _iconTab(int index, IconData icon, String label) {
    final active = _activeIcon == index;
    return GestureDetector(
      onTap: () {
        setState(() => _activeIcon = index);
        if (index == 3) _showPhotoSourceSheet();
        if (index == 2) _showWearableProviderSheet();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? BldrColors.goldTint : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color:
                    active ? BldrColors.goldBright : BldrColors.textTertiary),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 9,
                  color:
                      active ? BldrColors.goldBright : BldrColors.textTertiary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    switch (_activeIcon) {
      case 0:
        return _buildWorkoutSelector();
      case 1:
        return _buildActivitySelector();
      case 2:
        return _buildWearableArea();
      case 4:
        return _buildMoreArea();
      default:
        return _buildPhotoPreview();
    }
  }

  // ── Treino ─────────────────────────────────────────────────────────────────

  Widget _buildWorkoutSelector() {
    if (_workoutsLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: BldrColors.goldBright, strokeWidth: 2),
      );
    }

    if (_selectedWorkout != null) {
      return _buildWorkoutPreview();
    }

    if (_recentWorkouts.isEmpty) {
      return Column(
        children: [
          const Icon(TablerIcons.barbell,
              size: 40, color: BldrColors.textTertiary),
          const SizedBox(height: 12),
          Text('Nenhum treino recente', style: BldrText.description),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Treinos recentes', style: BldrText.sectionTitle),
        const SizedBox(height: 12),
        ..._recentWorkouts.map(_buildWorkoutItem),
      ],
    );
  }

  Widget _buildWorkoutItem(RecentWorkout w) {
    final isSelected = _selectedWorkoutId == w.id;
    final volLabel = _formatVolume(w.volumeKg);
    final durLabel = _formatDuration(w.durationSeconds);
    final subtitle = [
      if (w.dateLabel.isNotEmpty) w.dateLabel,
      if (volLabel != '—') volLabel,
      if (durLabel != '—') durLabel,
    ].join(' · ');

    return GestureDetector(
      onTap: () => setState(() {
        _selectedWorkoutId = w.id;
        _selectedSource = w.source;
        _selectedWorkout = w;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? BldrColors.goldTint : BldrColors.surface,
          border: Border.all(
            color: isSelected ? BldrColors.goldBorder : BldrColors.border,
          ),
          borderRadius: BorderRadius.circular(BldrRadius.cardSm),
        ),
        child: Row(
          children: [
            Icon(TablerIcons.barbell,
                size: 16,
                color: isSelected
                    ? BldrColors.goldBright
                    : BldrColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.name, style: BldrText.cardTitle),
                  if (subtitle.isNotEmpty) Text(subtitle, style: BldrText.meta),
                ],
              ),
            ),
            if (isSelected)
              const Icon(TablerIcons.check,
                  size: 16, color: BldrColors.goldBright),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutPreview() {
    final w = _selectedWorkout!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BldrColors.goldTint,
        border: Border.all(color: BldrColors.goldBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ícone + nome + "Trocar"
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BldrColors.goldTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(TablerIcons.barbell,
                    size: 18, color: BldrColors.goldBright),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.name, style: BldrText.cardTitle),
                    if (w.dateLabel.isNotEmpty)
                      Text(w.dateLabel,
                          style: BldrText.meta
                              .copyWith(color: BldrColors.textSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedWorkoutId = null;
                  _selectedWorkout = null;
                }),
                child: Text('Trocar',
                    style:
                        BldrText.meta.copyWith(color: BldrColors.goldBright)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _previewStat(_formatDuration(w.durationSeconds), 'DURAÇÃO'),
              const SizedBox(width: 8),
              _previewStat(_formatVolume(w.volumeKg), 'VOLUME'),
              const SizedBox(width: 8),
              _previewStat(_formatSetCount(w.completedSetCount), 'SÉRIES'),
            ],
          ),
          if (w.muscleGroups.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final m in w.muscleGroups)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(m,
                        style: BldrText.meta
                            .copyWith(color: BldrColors.textSecondary)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          // Toggle PRs
          Row(
            children: [
              const Icon(TablerIcons.trophy,
                  size: 16, color: BldrColors.goldBright),
              const SizedBox(width: 8),
              Text('Incluir PRs no post',
                  style: BldrText.meta.copyWith(color: BldrColors.goldBright)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _includePrs = !_includePrs),
                child: Container(
                  width: 34,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _includePrs
                        ? BldrColors.goldBright
                        : BldrColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 150),
                    alignment: _includePrs
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _includePrs
                            ? Colors.black
                            : BldrColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPostPhotoAttachment(),
        ],
      ),
    );
  }

  // ── Helpers de formatação ───────────────────────────────────────────────────

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '—';
    final m = seconds ~/ 60;
    return '$m MIN';
  }

  String _formatVolume(dynamic kg) {
    if (kg == null) return '—';
    final v = (kg as num).toDouble();
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} T';
    return '${v.toStringAsFixed(0)} KG';
  }

  String _formatSetCount(int? count) {
    if (count == null || count == 0) return '—';
    return count.toString();
  }

  Widget _previewStat(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(value,
                  style: BldrText.cardTitle
                      .copyWith(color: BldrColors.goldBright, fontSize: 14)),
              const SizedBox(height: 2),
              Text(label,
                  style: BldrText.metaSm.copyWith(
                      color: BldrColors.textTertiary, letterSpacing: .5)),
            ],
          ),
        ),
      );

  // ── Atividade ──────────────────────────────────────────────────────────────

  static const _activities = <(IconData, String)>[
    (TablerIcons.barbell, 'Musculação'),
    (TablerIcons.run, 'Corrida'),
    (TablerIcons.bike, 'Ciclismo'),
    (TablerIcons.gymnastics, 'Calistenia'),
    (TablerIcons.bolt, 'HIIT'),
    (TablerIcons.karate, 'Boxe'),
    (TablerIcons.karate, 'Jiu-Jitsu'),
    (TablerIcons.swimming, 'Natação'),
    (TablerIcons.yoga, 'Yoga'),
    (TablerIcons.ball_basketball, 'Basquete'),
    (TablerIcons.ball_tennis, 'Tênis'),
    (TablerIcons.waves_electricity, 'Surf'),
    (TablerIcons.ball_football, 'Futebol'),
    (TablerIcons.walk, 'Caminhada'),
    (TablerIcons.flame, 'Crossfit'),
    (TablerIcons.stretching, 'Pilates'),
    (TablerIcons.gymnastics, 'Funcional'),
    (TablerIcons.ball_volleyball, 'Vôlei'),
    (TablerIcons.ball_tennis, 'Padel'),
    (TablerIcons.mountain, 'Trilha'),
    (TablerIcons.mountain, 'Escalada'),
    (TablerIcons.run, 'Hyrox'),
    (TablerIcons.karate, 'Muay Thai'),
    (TablerIcons.karate, 'Kickboxing'),
  ];

  Widget _buildActivitySelector() {
    if (_selectedActivity != null) {
      final act = _activities.firstWhere(
        (a) => a.$2 == _selectedActivity,
        orElse: () => (TablerIcons.barbell, _selectedActivity!),
      );
      final isCardio = ['Corrida', 'Ciclismo', 'Natação', 'Caminhada', 'Trilha']
          .contains(_selectedActivity);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BldrGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      act.$1,
                      size: 24,
                      color: BldrColors.goldBright,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(act.$2, style: BldrText.cardTitleLg),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedActivity = null),
                      child: Text('Trocar',
                          style: BldrText.body
                              .copyWith(color: BldrColors.goldBright)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _textField(
                    'Duração (min)', _durationController, TextInputType.number),
                if (isCardio) ...[
                  const SizedBox(height: 10),
                  _textField('Distância (km)', _distanceController,
                      const TextInputType.numberWithOptions(decimal: true)),
                ],
                const SizedBox(height: 10),
                _textField('Calorias', _caloriesActivityController,
                    TextInputType.number),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selecione a atividade', style: BldrText.sectionTitle),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _activities.length,
          itemBuilder: (_, i) {
            final (icon, name) = _activities[i];
            return GestureDetector(
              onTap: () => setState(() => _selectedActivity = name),
              child: Container(
                decoration: BoxDecoration(
                  color: BldrColors.surface,
                  border: Border.all(color: BldrColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: BldrColors.goldBright,
                    ),
                    const SizedBox(height: 4),
                    Text(name,
                        style: BldrText.metaSm, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _textField(
      String label, TextEditingController ctrl, TextInputType keyboard) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: BldrText.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: BldrText.meta.copyWith(color: BldrColors.textSecondary),
        filled: true,
        fillColor: const Color(0x08FFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: BldrColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: BldrColors.border),
        ),
      ),
    );
  }

  // ── Wearable ───────────────────────────────────────────────────────────────

  Widget _buildWearableArea() {
    if (_selectedWearableProvider == null) {
      return _wearableEmptyState(
        icon: TablerIcons.device_watch,
        title: 'Escolha seu wearable',
        description: 'Importe uma atividade registrada no seu dispositivo.',
        actionLabel: 'Selecionar dispositivo',
        onAction: _showWearableProviderSheet,
      );
    }

    if (_wearableLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(
              color: BldrColors.goldBright, strokeWidth: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedWearableProvider == 'whoop'
                    ? 'Atividades da WHOOP'
                    : _selectedWearableProvider == 'apple_watch'
                        ? 'Atividades do Apple Watch'
                        : 'Atividades do wearable',
                style: BldrText.sectionTitle,
              ),
            ),
            TextButton(
              onPressed: _showWearableProviderSheet,
              child: const Text('Trocar dispositivo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_wearableError != null) ...[
          _wearableEmptyState(
            icon: TablerIcons.alert_circle,
            title: 'Não foi possível carregar',
            description: _wearableError!,
            actionLabel: 'Tentar novamente',
            onAction: () => _loadWearableActivities(
              _selectedWearableProvider!,
            ),
          ),
        ] else if (_wearableActivities.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _wearableActivities.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.70,
            ),
            itemBuilder: (context, index) {
              final activity = _wearableActivities[index];
              final selected = identical(_wearableData, activity);
              return WearableActivityGridCard(
                data: activity,
                selected: selected,
                onTap: () => setState(() {
                  _wearableData = selected ? null : activity;
                  _wearableImported = !selected;
                }),
              );
            },
          ),
        ] else ...[
          _wearableEmptyState(
            icon: TablerIcons.activity,
            title: 'Nenhuma atividade recente',
            description: _selectedWearableProvider == 'apple_watch'
                ? 'Os treinos recentes do Apple Watch aparecerão aqui. Confira o acesso do BLDR em Saúde > Apps.'
                : 'Quando a WHOOP processar um treino, ele aparecerá aqui.',
            actionLabel: 'Atualizar',
            onAction: () => _loadWearableActivities(
              _selectedWearableProvider!,
            ),
          ),
        ],
      ],
    );
  }

  Widget _wearableEmptyState({
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BldrColors.surface,
        border: Border.all(color: BldrColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: BldrColors.textSecondary),
          const SizedBox(height: 10),
          Text(title, style: BldrText.cardTitle),
          const SizedBox(height: 4),
          Text(description,
              style: BldrText.description, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }

  // ── Foto ───────────────────────────────────────────────────────────────────

  Widget _buildPhotoPreview() {
    return _buildPostPhotoAttachment();
  }

  Widget _buildPostPhotoAttachment() {
    if (_photoFile == null) {
      return InkWell(
        key: const ValueKey('create_post_add_photo'),
        onTap: _showPhotoSourceSheet,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: BldrColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                TablerIcons.photo_plus,
                size: 19,
                color: BldrColors.goldBright,
              ),
              const SizedBox(width: 8),
              Text(
                'Adicionar foto ao post',
                style: BldrText.body.copyWith(color: BldrColors.goldBright),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_photoFile!,
              width: double.infinity, height: 200, fit: BoxFit.cover),
        ),
        Positioned(
          top: 8,
          right: 44,
          child: _photoAction(
            key: const ValueKey('create_post_replace_photo'),
            icon: TablerIcons.replace,
            onTap: _showPhotoSourceSheet,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _photoAction(
            key: const ValueKey('create_post_remove_photo'),
            icon: TablerIcons.x,
            onTap: () => setState(() {
              _photoFile = null;
              _photoError = null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _photoAction({
    required Key key,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      child: InkWell(
        key: key,
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreArea() {
    return Column(
      children: [
        _moreRow(TablerIcons.map_pin, 'Local', 'Em breve'),
        const SizedBox(height: 8),
        _moreRow(TablerIcons.calendar, 'Data', 'Em breve'),
      ],
    );
  }

  Widget _moreRow(IconData icon, String label, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BldrColors.surface,
        border: Border.all(color: BldrColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: BldrColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: BldrText.cardTitle),
              Text(sub, style: BldrText.meta),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    final visLabel = switch (_visibility) {
      'squad' => _selectedSquadTitle ?? 'Só meu squad',
      'private' => 'Só eu',
      _ => 'Todos',
    };
    return Container(
      padding: EdgeInsets.fromLTRB(
        BldrSpacing.pageX,
        12,
        BldrSpacing.pageX,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: BldrColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showVisibilitySheet,
            child: Row(
              children: [
                const Icon(TablerIcons.world,
                    size: 16, color: BldrColors.textSecondary),
                const SizedBox(width: 6),
                Text(visLabel, style: BldrText.body),
                const SizedBox(width: 4),
                const Icon(TablerIcons.chevron_down,
                    size: 14, color: BldrColors.textSecondary),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _canPublish && !_publishing ? _publish : null,
            style: TextButton.styleFrom(
              backgroundColor: _canPublish && !_publishing
                  ? BldrColors.goldSolid
                  : BldrColors.surface,
              foregroundColor: BldrColors.bgBase,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BldrRadius.button)),
              minimumSize: const Size(0, 40),
            ),
            child: Text(
              _publishing ? 'Publicando…' : 'Publicar',
              style: BldrText.buttonPrimary.copyWith(
                color: _canPublish && !_publishing
                    ? BldrColors.bgBase
                    : BldrColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WearableProviderSheet extends StatelessWidget {
  final String? selectedProvider;

  const _WearableProviderSheet({required this.selectedProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BldrColors.sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: BldrColors.border),
          left: BorderSide(color: BldrColors.border),
          right: BorderSide(color: BldrColors.border),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: BldrColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Importar de wearable', style: BldrText.screenTitle),
          const SizedBox(height: 6),
          Text(
            'Escolha onde sua atividade foi registrada.',
            style: BldrText.description,
          ),
          const SizedBox(height: 18),
          _WearableProviderRow(
            name: 'WHOOP',
            subtitle: 'Treinos e atividades recentes',
            badge: 'Disponível',
            selected: selectedProvider == 'whoop',
            logo: Image.asset(
              'assets/images/whoop/whoop_puck_white.png',
              width: 30,
              height: 30,
            ),
            onTap: () => Navigator.pop(context, 'whoop'),
          ),
          _WearableProviderRow(
            name: 'Apple Watch',
            subtitle: 'Treinos recentes do Apple Health',
            badge: 'Disponível',
            selected: selectedProvider == 'apple_watch',
            logo: const Icon(
              TablerIcons.brand_apple,
              size: 26,
              color: BldrColors.textPrimary,
            ),
            onTap: () => Navigator.pop(context, 'apple_watch'),
          ),
          const _WearableProviderRow(
            name: 'Garmin Connect',
            subtitle: 'Aguardando integração oficial',
            badge: 'Em breve',
            logo: Icon(
              TablerIcons.run,
              size: 26,
              color: Color(0xFF00AEEF),
            ),
          ),
        ],
      ),
    );
  }
}

class _WearableProviderRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final String badge;
  final Widget logo;
  final bool selected;
  final VoidCallback? onTap;

  const _WearableProviderRow({
    required this.name,
    required this.subtitle,
    required this.badge,
    required this.logo,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: BldrColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BldrColors.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? BldrColors.goldBorder : BldrColors.border,
                ),
              ),
              child: logo,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: BldrText.cardTitle.copyWith(
                      color: enabled
                          ? BldrColors.textPrimary
                          : BldrColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: BldrText.meta),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: enabled ? BldrColors.goldTint : BldrColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: BldrText.metaSm.copyWith(
                  color:
                      enabled ? BldrColors.goldBright : BldrColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              enabled ? TablerIcons.chevron_right : TablerIcons.lock,
              size: 18,
              color: BldrColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Visibility sheet ───────────────────────────────────────────────────────

class _VisibilitySheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _VisibilitySheet({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      ('public', TablerIcons.world, 'Todos', 'Qualquer pessoa pode ver'),
      (
        'squad',
        TablerIcons.users,
        'Um squad',
        'Escolha um squad do qual você participa'
      ),
      ('private', TablerIcons.lock, 'Só eu', 'Visível apenas para você'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: BldrColors.sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: BldrColors.border),
          left: BorderSide(color: BldrColors.border),
          right: BorderSide(color: BldrColors.border),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: BldrColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Quem pode ver?', style: BldrText.screenTitle),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final (value, icon, name, sub) = opt;
            final isSelected = selected == value;
            return GestureDetector(
              onTap: () => onSelect(value),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: BldrColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: BldrColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(icon, size: 20, color: BldrColors.textSecondary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: BldrText.cardTitle),
                          Text(sub, style: BldrText.description),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? BldrColors.goldBright
                              : BldrColors.border,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: BldrColors.goldBright,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
