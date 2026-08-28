import 'dart:io';
import 'package:bldr_fitness/l10n/app_localizations.dart';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <--- Import do Supabase

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_provider.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class PhotoProgressWidget extends StatefulWidget {
  const PhotoProgressWidget({Key? key}) : super(key: key);

  @override
  State<PhotoProgressWidget> createState() => _PhotoProgressWidgetState();
}

class _PhotoProgressWidgetState extends State<PhotoProgressWidget> {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client; // <--- Cliente do Banco

  List<Map<String, dynamic>> _progressPhotos = [];
  bool _isLoading = true;
  bool _isUploading = false; // Novo estado para feedback de upload

  @override
  void initState() {
    super.initState();
    _loadProgressPhotos();
  }

  // --- CARREGAR FOTOS DO SUPABASE ---
  Future<void> _loadProgressPhotos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Busca no banco (ordenado pela data da foto)
      final response = await _supabase
          .from('progress_photos')
          .select()
          .eq('user_id', userId)
          .order('taken_at', ascending: false);

      if (mounted) {
        setState(() {
          // Converte para Lista de Maps segura
          _progressPhotos = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        // print('Erro ao carregar: $error'); // Opcional para debug
      }
    }
  }

  // --- MENU DE SELEÇÃO ---
  void _showAddPhotoDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: BldrColors.sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: BldrColors.textMuted,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(l10n.photo_add_sheet_title, style: BldrText.cardTitleLg),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoOption(l10n.photo_option_camera, Icons.photo_camera_outlined, _takePhoto),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPhotoOption(l10n.photo_option_gallery, Icons.image_outlined, _selectFromGallery),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
      },
    );
  }

  Widget _buildPhotoOption(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BldrColors.surface,
          borderRadius: BldrRadius.all(BldrRadius.cardSm),
          border: Border.all(color: BldrColors.border),
        ),
        child: Column(
          children: [
            BldrIconBox(icon: icon),
            const SizedBox(height: 8),
            Text(title, style: BldrText.body.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS DE CAPTURA E PERMISSÃO (LÓGICA MANTIDA EXATAMENTE IGUAL) ---

  Future<void> _takePhoto() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        final XFile? shot = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 95,
        );
        if (shot == null) return;
        final file = await _saveCompressed(File(shot.path));

        // AQUI MUDOU O DESTINO (Supabase), MAS A LÓGICA ANTES É IGUAL
        _uploadAndSavePhoto(file, notes: 'Foto tirada com câmera');
      } else if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog(AppLocalizations.of(context)!.photo_camera_permission_body);
      } else {
        // Usuário negou na hora
        // _toast('Permissão de câmera necessária.');
      }
    } catch (e) {
      _toast('Erro ao abrir câmera: $e', isError: true);
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final status = await Permission.photos.request();

      // Nota: Mantida a lógica para iOS e Androids novos/velhos
      if (status.isGranted || status.isLimited) {
        final XFile? picked = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 95,
        );
        if (picked == null) return;
        final file = await _saveCompressed(File(picked.path));

        // AQUI MUDOU O DESTINO (Supabase), MAS A LÓGICA ANTES É IGUAL
        _uploadAndSavePhoto(file, notes: 'Importada da galeria');
      } else if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog(AppLocalizations.of(context)!.photo_gallery_permission_body);
      }
    } catch (e) {
      _toast('Erro ao abrir galeria: $e', isError: true);
    }
  }

  void _showPermissionDeniedDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BldrColors.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BldrRadius.all(BldrRadius.card)),
        title: Text(AppLocalizations.of(context)!.photo_permission_title, style: BldrText.cardTitleLg),
        content: Text(message, style: BldrText.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.common_cancel, style: BldrText.description),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(AppLocalizations.of(context)!.profile_open_settings_btn, style: BldrText.buttonSecondary),
          ),
        ],
      ),
    );
  }

  Future<File> _saveCompressed(File original) async {
    final dir = await getApplicationDocumentsDirectory();
    final outPath =
        '${dir.path}/bldr_progress_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      original.path,
      outPath,
      quality: 80,
      minWidth: 1080,
      minHeight: 1440,
      format: CompressFormat.jpeg,
    );
    return File(result!.path);
  }

  // --- LÓGICA DE UPLOAD E SALVAMENTO (MANTIDA) ---

  Future<void> _uploadAndSavePhoto(File file, {String? notes}) async {
    setState(() => _isUploading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Faça login novamente.');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'progress_photos/$userId/$fileName';

      // 1. Upload para o Storage (Bucket 'Images')
      await _supabase.storage.from('Images').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // 2. Obter URL Pública
      final publicUrl = _supabase.storage.from('Images').getPublicUrl(storagePath);

      // 3. Salvar no Banco (Tabela 'progress_photos')
      final newRecord = await _supabase.from('progress_photos').insert({
        'user_id': userId,
        'photo_url': publicUrl,
        'taken_at': DateTime.now().toUtc().toIso8601String(),
        'notes': notes,
        'photo_type': 'front',
      }).select().single();

      // 4. Atualizar lista local
      if (mounted) {
        setState(() {
          _progressPhotos.insert(0, newRecord);
        });
        _toast(AppLocalizations.of(context)!.photo_saved);
        context.read<AchievementProvider>().checkAchievements('photo');
      }

      // 5. §12.4 — Emite evento no feed da comunidade (aparece como 📷 no feed)
      try {
        await _supabase.schema('bldr_club').from('xp_events').insert({
          'user_id': userId,
          'delta': 10, // +10 XP por compartilhar progresso
          'reason': 'progress_photo',
        });
      } catch (_) {
        // Feed event is non-critical — silently ignore if xp_events table unavailable
      }

    } catch (e) {
      _toast('Erro ao salvar foto: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Método Toast melhorado para suportar erro visual
  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? BldrColors.danger : BldrColors.goldSolid,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- VISUALIZAÇÃO E UTILS ---

  // PC6 — comparar fotos com seleção livre de data em cada lado.
  void _showPhotoComparison() {
    if (_progressPhotos.length < 2) {
      _toast(AppLocalizations.of(context)!.photo_need_two, isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _PhotoComparisonDialog(
        photos: _progressPhotos,
        imageProviderFor: _imageProviderFor,
        formatDate: _formatDate,
      ),
    );
  }

  Widget _buildCompareFrame(String label, Map<String, dynamic> photo) {
    return Column(
      children: [
        Text(label, style: BldrText.label),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BldrRadius.all(BldrRadius.cardSm),
              image: DecorationImage(
                image: _imageProviderFor(photo),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(_formatDate(photo['taken_at'] ?? photo['date']), style: BldrText.meta),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      return DateFormat('d/M/y').format(d);
    } catch (_) {
      return '';
    }
  }

  ImageProvider _imageProviderFor(Map<String, dynamic> photo) {
    // Prioriza 'photo_url' (Supabase), fallback para 'url' (legado ou local)
    final url = photo['photo_url'] ?? photo['url'];

    // Verificação de segurança
    if (url == null || url.isEmpty) {
      return const AssetImage('assets/images/placeholder.png'); // Imagem segura se falhar
    }

    // Se for arquivo local (File)
    if (Uri.tryParse(url)?.isScheme('file') == true) {
      return FileImage(File(url));
    }

    // Se for URL da web (Supabase)
    return NetworkImage(url);
  }

  Future<void> _confirmDelete(Map<String, dynamic> photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BldrColors.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BldrRadius.all(BldrRadius.card)),
        title: Text(AppLocalizations.of(context)!.photo_delete_title, style: BldrText.cardTitleLg),
        content: Text(AppLocalizations.of(context)!.photo_delete_message, style: BldrText.description),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.common_cancel, style: BldrText.description)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.photo_delete_btn, style: TextStyle(
                  fontFamily: BldrText.family, color: BldrColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _supabase.from('progress_photos').delete().eq('id', photo['id']);
        setState(() => _progressPhotos.removeWhere((p) => p['id'] == photo['id']));
        _toast(AppLocalizations.of(context)!.photo_deleted);
      } catch (e) {
        _toast('Erro ao remover: $e', isError: true);
      }
    }
  }

  void _viewPhoto(Map<String, dynamic> photo) {
    final provider = _imageProviderFor(photo);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: BldrColors.sheetBg,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BldrRadius.all(BldrRadius.card),
          child: InteractiveViewer(
            child: Image(image: provider, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  // PC1 — glass neutro no lugar de fundo/botão verdes.
  @override
  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context)!;
        return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BldrIconBox(icon: Icons.photo_camera_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.photo_progress_title, style: BldrText.cardTitleLg)),
              if (_isUploading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: BldrColors.goldBright, strokeWidth: 2),
                )
              else
                Semantics(
                  label: l10n.photo_add_semantics,
                  button: true,
                  child: BldrCircleButton(
                    icon: Icons.add,
                    size: 36,
                    filled: false,
                    onPressed: _showAddPhotoDialog,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: BldrColors.goldBright))
          else if (_progressPhotos.isEmpty)
            _buildEmptyState()
          else
            _buildPhotoGallery(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {

    final l10n = AppLocalizations.of(context)!;
        return BldrEmptyState(
      icon: Icons.photo_camera_outlined,
      title: l10n.photo_empty_title,
      instruction: l10n.photo_empty_instruction,
    );
  }

  // PC5 — carrossel horizontal com data em cada foto.
  Widget _buildPhotoGallery() {

    final l10n = AppLocalizations.of(context)!;
        return Column(
      children: [
        if (_progressPhotos.length >= 2) ...[
          BldrSecondaryButton(
            label: l10n.photo_compare_btn,
            icon: Icons.compare_arrows,
            onPressed: _showPhotoComparison,
          ),
          const SizedBox(height: 16),
        ],
        BldrCarousel(
          height: 240,
          itemWidth: 150,
          children: [
            for (int i = 0; i < _progressPhotos.length; i++)
              _buildPhotoCard(_progressPhotos[i], i),
          ],
        ),
        const SizedBox(height: 16),
        _buildPhotoTips(),
      ],
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> photo, int index) {
    final notes = photo['notes'] ?? '';

    return GestureDetector(
      onTap: () => _viewPhoto(photo),
      onLongPress: () => _confirmDelete(photo),
      child: ClipRRect(
        borderRadius: BldrRadius.all(BldrRadius.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: _imageProviderFor(photo), fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xBF000000)],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: BldrBadge(label: '#${index + 1}', gold: false),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(photo['taken_at'] ?? photo['date']),
                    style: BldrText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(notes, style: BldrText.metaSm, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTips() {

    final l10n = AppLocalizations.of(context)!;
        return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BldrColors.surfaceInset,
        borderRadius: BldrRadius.all(BldrRadius.cardSm),
        border: Border.all(color: BldrColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: BldrColors.goldBright, size: 16),
              const SizedBox(width: 8),
              Text(l10n.photo_tips_title, style: BldrText.cardTitle),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.photo_tips_content,
            style: BldrText.description.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PhotoComparisonDialog extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final ImageProvider Function(Map<String, dynamic>) imageProviderFor;
  final String Function(String?) formatDate;

  const _PhotoComparisonDialog({
    required this.photos,
    required this.imageProviderFor,
    required this.formatDate,
  });

  @override
  State<_PhotoComparisonDialog> createState() => _PhotoComparisonDialogState();
}

class _PhotoComparisonDialogState extends State<_PhotoComparisonDialog> {
  late int _beforeIndex;
  late int _afterIndex;

  @override
  void initState() {
    super.initState();
    _beforeIndex = widget.photos.length - 1; // oldest
    _afterIndex = 0; // newest
  }

  void _pickPhoto(bool isBefore) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: widget.photos.length,
        itemBuilder: (context, i) {
          final photo = widget.photos[i];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Image(image: widget.imageProviderFor(photo), fit: BoxFit.cover),
              ),
            ),
            title: Text(
              widget.formatDate(photo['taken_at'] ?? photo['date']),
              style: BldrText.body,
            ),
            onTap: () {
              setState(() {
                if (isBefore) {
                  _beforeIndex = i;
                } else {
                  _afterIndex = i;
                }
              });
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final before = widget.photos[_beforeIndex];
    final after = widget.photos[_afterIndex];

    return Dialog(
      backgroundColor: BldrColors.sheetBg,
      shape: RoundedRectangleBorder(borderRadius: BldrRadius.all(BldrRadius.card)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.photo_comparison_title, style: BldrText.cardTitleLg),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _buildSide(AppLocalizations.of(context)!.photo_comparison_before, before, true)),
                const SizedBox(width: 12),
                Expanded(child: _buildSide(AppLocalizations.of(context)!.photo_comparison_after, after, false)),
              ],
            ),
            const SizedBox(height: 18),
            BldrPrimaryButton(
              label: AppLocalizations.of(context)!.photo_close_btn,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSide(String label, Map<String, dynamic> photo, bool isBefore) {
    return Column(
      children: [
        Text(label, style: BldrText.label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickPhoto(isBefore),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BldrRadius.all(BldrRadius.cardSm),
                    image: DecorationImage(
                      image: widget.imageProviderFor(photo),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.swap_horiz, color: Colors.white70, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.formatDate(photo['taken_at'] ?? photo['date']),
          style: BldrText.meta,
        ),
        TextButton(
          onPressed: () => _pickPhoto(isBefore),
          child: Text(AppLocalizations.of(context)!.photo_swap_btn, style: BldrText.metaSm.copyWith(color: BldrColors.goldBright)),
        ),
      ],
    );
  }
}
