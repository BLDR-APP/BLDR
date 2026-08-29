import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/community/domain/entities/recent_workout.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/widgets/wearable_import_card.dart';
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
  // Supabase direto apenas para upload de foto (operação de storage, não de dados)
  final _storage = Supabase.instance.client.storage;
  final _auth = Supabase.instance.client.auth;
  final _captionController = TextEditingController();

  // Perfil
  String _userFullName = '';
  String? _userUsername;

  int _activeIcon = 0; // 0=treino 1=atividade 2=wearable 3=foto 4=mais
  String _visibility = 'public';
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
  bool _wearableLoading = true;

  // Foto
  File? _photoFile;

  bool get _canPublish =>
      _captionController.text.trim().isNotEmpty ||
      _selectedWorkoutId != null ||
      _selectedActivity != null ||
      _photoFile != null;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRecentWorkouts();
    _detectWearable();
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

  Future<void> _detectWearable() async {
    final data = await WearableImportCard.detectRecentActivity();
    if (!mounted) return;
    setState(() {
      _wearableData = data;
      _wearableLoading = false;
    });
  }

  Future<void> _pickPhoto() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  Future<String?> _uploadPhoto() async {
    if (_photoFile == null) return null;
    try {
      final uid = _auth.currentUser?.id ?? 'anon';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '$uid/$ts.jpg';
      final bytes = await _photoFile!.readAsBytes();
      await _storage.from('community-posts').uploadBinary(path, bytes);
      return _storage.from('community-posts').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _publish() async {
    if (!_canPublish) return;
    setState(() => _publishing = true);

    try {
      final photoUrl = await _uploadPhoto();
      final payload = <String, dynamic>{};

      final caption = _captionController.text.trim();
      if (caption.isNotEmpty) payload['caption'] = caption;
      if (photoUrl != null) payload['photo_url'] = photoUrl;

      if (_selectedWorkoutId != null) {
        payload['workout_id'] = _selectedWorkoutId;
        payload['source'] = _selectedSource ?? 'free';
        if (_selectedWorkout != null) {
          payload['workout_name'] = _selectedWorkout!.name;
          payload['volume_kg'] = _selectedWorkout!.volumeKg;
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

      if (_wearableData != null) payload.addAll(_wearableData!);

      await _repo.createPost(
        eventType: 'manual',
        payload: payload,
        visibility: _visibility,
      );

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
          setState(() => _visibility = v);
          Navigator.pop(context);
        },
      ),
    );
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
    final initial = _userFullName.isNotEmpty
        ? _userFullName[0].toUpperCase()
        : '?';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
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
              const SizedBox(height: 6),
              TextField(
                controller: _captionController,
                maxLines: null,
                style: BldrText.body,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'O que você quer compartilhar?',
                  hintStyle: BldrText.body.copyWith(
                      color: BldrColors.textTertiary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: const BoxDecoration(
        color: BldrColors.surface,
        border: Border(
          top: BorderSide(color: BldrColors.border),
          bottom: BorderSide(color: BldrColors.border),
        ),
      ),
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
        if (index == 3) _pickPhoto();
        setState(() => _activeIcon = index);
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
                  color: active
                      ? BldrColors.goldBright
                      : BldrColors.textTertiary,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
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
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: BldrText.meta),
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
                          style: BldrText.meta.copyWith(
                              color: BldrColors.textSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedWorkoutId = null;
                  _selectedWorkout = null;
                }),
                child: Text('Trocar',
                    style: BldrText.meta.copyWith(
                        color: BldrColors.goldBright)),
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
              _previewStat('—', 'SÉRIES'),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(m,
                        style: BldrText.meta.copyWith(
                            color: BldrColors.textSecondary)),
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
                  style: BldrText.meta.copyWith(
                      color: BldrColors.goldBright)),
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
                      margin:
                          const EdgeInsets.symmetric(horizontal: 3),
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
                  style: BldrText.cardTitle.copyWith(
                      color: BldrColors.goldBright, fontSize: 14)),
              const SizedBox(height: 2),
              Text(label,
                  style: BldrText.metaSm.copyWith(
                      color: BldrColors.textTertiary,
                      letterSpacing: .5)),
            ],
          ),
        ),
      );

  // ── Atividade ──────────────────────────────────────────────────────────────

  static const _activities = [
    ('🏋️', 'Musculação'), ('🏃', 'Corrida'), ('🚴', 'Ciclismo'),
    ('🤸', 'Calistenia'), ('⚡', 'HIIT'), ('🥊', 'Boxe'),
    ('🤼', 'Jiu-Jitsu'), ('🏊', 'Natação'), ('🧘', 'Yoga'),
    ('🏀', 'Basquete'), ('🎾', 'Tênis'), ('🏄', 'Surf'),
    ('⚽', 'Futebol'), ('🚶', 'Caminhada'), ('🔥', 'Crossfit'),
    ('🧩', 'Pilates'), ('💪', 'Funcional'), ('🏐', 'Vôlei'),
    ('🏓', 'Padel'), ('🏔️', 'Trilha'), ('🧗', 'Escalada'),
  ];

  Widget _buildActivitySelector() {
    if (_selectedActivity != null) {
      final act = _activities.firstWhere(
        (a) => a.$2 == _selectedActivity,
        orElse: () => ('🏋️', _selectedActivity!),
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
                    Text(act.$1, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(act.$2, style: BldrText.cardTitleLg),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedActivity = null),
                      child: Text('Trocar', style: BldrText.body.copyWith(
                          color: BldrColors.goldBright)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _textField('Duração (min)', _durationController,
                    TextInputType.number),
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
            final (emoji, name) = _activities[i];
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
                    Text(emoji,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(name,
                        style: BldrText.metaSm,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _textField(String label, TextEditingController ctrl,
      TextInputType keyboard) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: BldrText.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            BldrText.meta.copyWith(color: BldrColors.textSecondary),
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
    if (_wearableLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: BldrColors.goldBright, strokeWidth: 2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_wearableData != null)
          WearableImportCard(
            data: _wearableData!,
            onImport: () {
              final dur = _wearableData!['duration_min'];
              final kcal = _wearableData!['calorias'];
              if (dur != null)
                _durationController.text = dur.toString();
              if (kcal != null)
                _caloriesActivityController.text = kcal.toString();
              setState(() {
                _wearableData = null;
                _activeIcon = 1; // vai para atividade
              });
            },
            onDismiss: () => setState(() => _wearableData = null),
          )
        else ...[
          _buildWearableRow('Whoop', TablerIcons.device_watch,
              const Color(0xFFFF0000), 'Sem dados recentes'),
          const SizedBox(height: 8),
          _buildWearableRow('Apple Health', TablerIcons.heart,
              BldrColors.goldBright, 'Sem dados recentes'),
          const SizedBox(height: 8),
          _buildWearableRow('Garmin', TablerIcons.device_watch,
              BldrColors.textSecondary, 'Em breve',
              soon: true),
        ],
      ],
    );
  }

  Widget _buildWearableRow(String name, IconData icon, Color iconColor,
      String subtitle, {bool soon = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BldrColors.surface,
        border: Border.all(color: BldrColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: BldrText.cardTitle),
                Text(subtitle, style: BldrText.meta),
              ],
            ),
          ),
          if (soon)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: BldrColors.surface,
                border: Border.all(color: BldrColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Em breve', style: BldrText.metaSm),
            ),
        ],
      ),
    );
  }

  // ── Foto ───────────────────────────────────────────────────────────────────

  Widget _buildPhotoPreview() {
    if (_photoFile == null) return const SizedBox.shrink();
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_photoFile!,
              width: double.infinity, height: 200, fit: BoxFit.cover),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _photoFile = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(TablerIcons.x,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
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
      'squad' => 'Só meu squad',
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
                const Icon(TablerIcons.world, size: 16,
                    color: BldrColors.textSecondary),
                const SizedBox(width: 6),
                Text(visLabel, style: BldrText.body),
                const SizedBox(width: 4),
                const Icon(TablerIcons.chevron_down, size: 14,
                    color: BldrColors.textSecondary),
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
      ('squad', TablerIcons.users, 'Só meu squad',
          'Apenas membros do seu squad'),
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
                      child: Icon(icon, size: 20,
                          color: BldrColors.textSecondary),
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
