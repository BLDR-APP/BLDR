import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/widgets/wearable_import_card.dart';
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
  final _client = Supabase.instance.client;
  final _captionController = TextEditingController();

  int _activeIcon = 0; // 0=treino 1=atividade 2=wearable 3=foto 4=mais
  String _visibility = 'public';
  bool _publishing = false;

  // Treino
  List<Map<String, dynamic>> _recentWorkouts = [];
  bool _workoutsLoading = true;
  String? _selectedWorkoutId;
  String? _selectedSource;
  Map<String, dynamic>? _selectedWorkoutData;
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

  Future<void> _loadRecentWorkouts() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;

      // Buscar das duas fontes em paralelo
      final results = await Future.wait([
        _client
            .from('user_workouts')
            .select('id, workout_template_id, completed_at, volume_kg')
            .eq('user_id', uid)
            .eq('is_completed', true)
            .order('completed_at', ascending: false)
            .limit(5),
        _client
            .from('club_user_workouts')
            .select('id, workout_template_id, completed_at, volume_kg')
            .eq('user_id', uid)
            .eq('is_completed', true)
            .order('completed_at', ascending: false)
            .limit(5),
      ]);

      // Unificar, marcar source e ordenar por completed_at desc, pegar top 5
      final combined = <Map<String, dynamic>>[];
      for (final row in results[0] as List) {
        combined.add({...row as Map<String, dynamic>, 'source': 'free'});
      }
      for (final row in results[1] as List) {
        combined.add({...row as Map<String, dynamic>, 'source': 'club'});
      }
      combined.sort((a, b) {
        final aTs = a['completed_at'] as String? ?? '';
        final bTs = b['completed_at'] as String? ?? '';
        return bTs.compareTo(aTs);
      });
      final top5 = combined.take(5).toList();

      // Buscar nomes dos templates
      final List<Map<String, dynamic>> workouts = [];
      for (final row in top5) {
        final templateId = row['workout_template_id'] as String?;
        String name = 'Treino';
        if (templateId != null) {
          final tmpl = await _client
              .from('workout_templates')
              .select('name')
              .eq('id', templateId)
              .maybeSingle();
          name = tmpl?['name'] as String? ?? 'Treino';
        }
        workouts.add({
          'id': row['id'],
          'name': name,
          'completed_at': row['completed_at'],
          'volume_kg': row['volume_kg'],
          'source': row['source'],
        });
      }

      if (!mounted) return;
      setState(() {
        _recentWorkouts = workouts;
        _workoutsLoading = false;

        // Pré-selecionar se veio da WorkoutSummaryScreen
        if (widget.preselectedWorkoutId != null) {
          final match = workouts.where(
              (w) => w['id'] == widget.preselectedWorkoutId).firstOrNull;
          if (match != null) _selectedWorkoutData = match;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _workoutsLoading = false);
    }
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
      final uid = _client.auth.currentUser?.id ?? 'anon';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '$uid/$ts.jpg';
      final bytes = await _photoFile!.readAsBytes();
      await _client.storage.from('community-posts').uploadBinary(path, bytes);
      return _client.storage.from('community-posts').getPublicUrl(path);
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
        if (_selectedWorkoutData != null) {
          payload['workout_name'] = _selectedWorkoutData!['name'];
          payload['volume_kg'] = _selectedWorkoutData!['volume_kg'];
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
      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return BldrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(TablerIcons.x,
                color: BldrColors.textPrimary),
            onPressed: () => Navigator.pop(context),
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
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    BldrSpacing.pageX, 0, BldrSpacing.pageX, 0),
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
    );
  }

  Widget _buildComposer() {
    final uid = _client.auth.currentUser?.id ?? '';
    final initial = uid.isNotEmpty ? uid[0].toUpperCase() : '?';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: BldrColors.goldTint,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(initial,
                style: BldrText.cardTitle.copyWith(
                    color: BldrColors.goldBright)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _captionController,
            maxLines: null,
            style: BldrText.body,
            decoration: const InputDecoration(
              hintText: 'O que você quer compartilhar?',
              hintStyle: TextStyle(color: BldrColors.textTertiary),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconBar() {
    final icons = [
      (TablerIcons.barbell, 'Treino'),
      (TablerIcons.run, 'Atividade'),
      (TablerIcons.device_watch, 'Wearable'),
      (TablerIcons.camera, 'Foto'),
      (TablerIcons.dots, 'Mais'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: icons.asMap().entries.map((e) {
          final i = e.key;
          final (icon, label) = e.value;
          final active = _activeIcon == i;
          return GestureDetector(
            onTap: () {
              if (i == 3) {
                _pickPhoto();
                return;
              }
              setState(() => _activeIcon = i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? BldrColors.goldTint
                    : BldrColors.surface,
                border: Border.all(
                  color: active
                      ? BldrColors.goldBorder
                      : BldrColors.border,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(icon,
                      size: 15,
                      color: active
                          ? BldrColors.goldBright
                          : BldrColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: BldrText.meta.copyWith(
                      color: active
                          ? BldrColors.goldBright
                          : BldrColors.textSecondary,
                      fontWeight: active
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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

    if (_selectedWorkoutData != null) {
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

  Widget _buildWorkoutItem(Map<String, dynamic> w) {
    final isSelected = _selectedWorkoutId == w['id'];
    final date = w['completed_at'] != null
        ? DateTime.tryParse(w['completed_at'].toString())
        : null;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '';
    final vol = w['volume_kg'];

    return GestureDetector(
      onTap: () => setState(() {
        _selectedWorkoutId = w['id'] as String;
        _selectedSource = w['source'] as String? ?? 'free';
        _selectedWorkoutData = w;
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
                  Text(w['name'] as String? ?? 'Treino',
                      style: BldrText.cardTitle),
                  if (dateStr.isNotEmpty || vol != null)
                    Text(
                      [
                        if (dateStr.isNotEmpty) dateStr,
                        if (vol != null)
                          '${(vol as num).toStringAsFixed(0)}kg',
                      ].join(' · '),
                      style: BldrText.meta,
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(TablerIcons.check, size: 16,
                  color: BldrColors.goldBright),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutPreview() {
    final w = _selectedWorkoutData!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BldrGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(w['name'] as String? ?? 'Treino',
                        style: BldrText.cardTitleLg),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedWorkoutId = null;
                      _selectedWorkoutData = null;
                    }),
                    child: Text('Trocar', style: BldrText.body.copyWith(
                        color: BldrColors.goldBright)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(TablerIcons.trophy, size: 14,
                      color: BldrColors.goldBright),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _includePrs = !_includePrs),
                    child: Text(
                      _includePrs ? 'Incluir PRs ✓' : 'Incluir PRs',
                      style: BldrText.body.copyWith(
                        color: _includePrs
                            ? BldrColors.goldBright
                            : BldrColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

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
          SizedBox(
            height: 40,
            child: BldrPrimaryButton(
              label: _publishing ? 'Publicando…' : 'Publicar',
              onPressed: _canPublish && !_publishing ? _publish : null,
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
