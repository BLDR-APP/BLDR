import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _gold = Color(0xFFD4AF37);
const _darkBg = Color(0xFF161208);

class TrackerShareScreen extends StatefulWidget {
  final String trackerType;
  final Map<String, String> stats;
  final String modality;
  final bool showPR;
  final String? result;
  // AJUSTE 4 — per-set score lines on share card
  final List<Map<String, int>>? sets;

  const TrackerShareScreen({
    super.key,
    required this.trackerType,
    required this.stats,
    required this.modality,
    this.showPR = false,
    this.result,
    this.sets,
  });

  @override
  State<TrackerShareScreen> createState() => _TrackerShareScreenState();
}

class _TrackerShareScreenState extends State<TrackerShareScreen> {
  final GlobalKey _captureKey = GlobalKey();

  // Format: 0=story(9:16), 1=square(1:1), 2=wide(16:9)
  int _format = 0;

  // Background: 0=dark, 1=transparent, 2+=gallery photo
  int _bgMode = 0;
  double _overlayOpacity = 0.65;

  String? _selectedPhotoPath;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadRecentPhotos();
  }

  Future<void> _loadRecentPhotos() async {
    // We don't pre-load the gallery automatically; just show a button
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedPhotoPath = picked.path;
        _bgMode = 2;
      });
    }
  }

  Future<void> _captureAndShare({bool saveToGallery = false, String? platform}) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Capture error');

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final format = _bgMode == 1 ? ui.ImageByteFormat.png : ui.ImageByteFormat.png;
      final ByteData? byteData = await image.toByteData(format: format);
      if (byteData == null) throw Exception('PNG error');

      final Uint8List bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/bldr_tracker_${widget.trackerType}.png');
      await file.writeAsBytes(bytes);

      if (saveToGallery) {
        // Save using share_plus (best we can do without gallery_saver)
        await Share.shareXFiles([XFile(file.path)],
            text: '⚡️ BLDR Club · ${widget.modality}');
      } else {
        await Share.shareXFiles([XFile(file.path)],
            text: '⚡️ BLDR Club · ${widget.modality}');
      }
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao gerar card.')));
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // AJUSTE 5 — preview capped at ~38% of screen height; selectors always visible
    final screenH = MediaQuery.of(context).size.height;
    final previewMaxH = screenH * 0.38;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Compartilhar',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // ── FIXED PREVIEW ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: previewMaxH),
                child: RepaintBoundary(
                  key: _captureKey,
                  child: _buildCard(maxHeight: previewMaxH),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── SCROLLABLE SELECTORS ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Format selector
                  _sectionLabel('FORMATO'),
                  const SizedBox(height: 10),
                  _buildFormatSelector(),
                  const SizedBox(height: 20),

                  // Background selector
                  _sectionLabel('FUNDO'),
                  const SizedBox(height: 10),
                  _buildBgSelector(),
                  const SizedBox(height: 16),

                  // Opacity slider (only when photo selected)
                  if (_bgMode == 2 && _selectedPhotoPath != null) ...[
                    _buildOpacitySlider(),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildCard({double? maxHeight}) {
    final aspectRatio = _format == 0
        ? 9 / 16.0
        : _format == 1
            ? 1.0
            : 16 / 9.0;

    final isTransparent = _bgMode == 1;
    final hasPhoto = _bgMode == 2 && _selectedPhotoPath != null;

    // AJUSTE 6 — for Wide (16:9) use maxHeight to compute width so it never
    // exceeds the available screen width; for Story/Square use fixed 260px width.
    Widget card;
    if (_format == 2 && maxHeight != null) {
      // Wide: height = min(maxHeight, screenWidth / aspectRatio)
      final wideH = maxHeight;
      final wideW = wideH * aspectRatio;
      card = SizedBox(
        width: wideW,
        height: wideH,
        child: _buildCardInner(isTransparent, hasPhoto),
      );
    } else {
      // Story / Square — fixed 260px wide, height derived from aspect ratio
      const cardW = 260.0;
      final cardH = cardW / aspectRatio;
      card = SizedBox(
        width: cardW,
        height: cardH,
        child: _buildCardInner(isTransparent, hasPhoto),
      );
    }

    return card;
  }

  Widget _buildCardInner(bool isTransparent, bool hasPhoto) {
    final hasSets = widget.sets != null && widget.sets!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isTransparent ? Colors.transparent : _darkBg,
        borderRadius: BorderRadius.circular(16),
        border: isTransparent
            ? null
            : Border.all(color: _gold.withOpacity(0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background photo
            if (hasPhoto)
              Image.file(File(_selectedPhotoPath!), fit: BoxFit.cover),

            // Overlay (for photo bg)
            if (hasPhoto)
              Container(color: Colors.black.withOpacity(_overlayOpacity)),

            // Gold accent line (dark & photo modes only — not transparent)
            if (!isTransparent)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  color: _gold,
                ),
              ),

            // Card content
            Padding(
              // AJUSTE 3 — reduced top gap so logo is closer to metrics
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo — centered
                  Center(
                    child: Image.asset(
                      'assets/images/BLDR_CLUB.png',
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        'BLDR CLUB',
                        style: TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Modality + PR badge
                  Text(widget.modality.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: _gold,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                  if (widget.showPR) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('NOVO PR 🏆',
                          style: TextStyle(
                              color: _gold,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Stats chips — Wrap
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: widget.stats.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isTransparent
                              ? Colors.black.withOpacity(0.55)
                              : Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.value,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            Text(e.key,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 8,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  // AJUSTE 4 — per-set score lines (only for match tracker)
                  if (hasSets) ...[
                    const SizedBox(height: 10),
                    ...List.generate(widget.sets!.length, (i) {
                      final sv = widget.sets![i];
                      final me = sv['me'] as int;
                      final opp = sv['opp'] as int;
                      final meWinsSet = me > opp;
                      final oppWinsSet = opp > me;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Set ${i + 1}  ',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 9)),
                            Text('$me',
                                style: TextStyle(
                                    color: meWinsSet ? _gold : Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900)),
                            Text('  ×  ',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.25),
                                    fontSize: 11)),
                            Text('$opp',
                                style: TextStyle(
                                    color: oppWinsSet ? _gold : Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      );
                    }),
                  ],

                  const Spacer(),

                  // Footer
                  Center(
                    child: Text('bldrapp.com.br',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 8,
                            letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFormatSelector() {
    final formats = [
      (0, 'Story\n9:16', Icons.smartphone),
      (1, 'Quadrado\n1:1', Icons.crop_square),
      (2, 'Wide\n16:9', Icons.crop_landscape),
    ];
    return Row(
      children: formats.map((f) {
        final sel = _format == f.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: f.$1 < 2 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _format = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? _gold.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: sel ? _gold : Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Icon(f.$3,
                        color: sel ? _gold : Colors.white38, size: 22),
                    const SizedBox(height: 6),
                    Text(f.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: sel ? _gold : Colors.white38,
                            fontSize: 10,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBgSelector() {
    return Row(
      children: [
        _bgOption(0, 'Escuro', Icons.dark_mode),
        const SizedBox(width: 8),
        _bgOption(1, 'Transparente', Icons.layers_clear),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 72,
              decoration: BoxDecoration(
                color: _bgMode == 2
                    ? _gold.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _bgMode == 2
                        ? _gold
                        : Colors.white.withOpacity(0.1)),
              ),
              child: _selectedPhotoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.file(File(_selectedPhotoPath!),
                          fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library,
                            color: _bgMode == 2 ? _gold : Colors.white38, size: 22),
                        const SizedBox(height: 4),
                        Text('Galeria',
                            style: TextStyle(
                                color: _bgMode == 2 ? _gold : Colors.white38,
                                fontSize: 10)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bgOption(int mode, String label, IconData icon) {
    final sel = _bgMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _bgMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 72,
          decoration: BoxDecoration(
            color: sel ? _gold.withOpacity(0.15) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: sel ? _gold : Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: sel ? _gold : Colors.white38, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: sel ? _gold : Colors.white38,
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpacitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Opacidade do overlay',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12)),
            Text('${(_overlayOpacity * 100).round()}%',
                style: const TextStyle(
                    color: _gold, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbColor: _gold,
            activeTrackColor: _gold,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            overlayColor: _gold.withOpacity(0.2),
          ),
          child: Slider(
            value: _overlayOpacity,
            min: 0.4,
            max: 0.85,
            onChanged: (v) => setState(() => _overlayOpacity = v),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.save_alt, size: 20),
              label: _isSharing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('SALVAR NA GALERIA',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
              onPressed: _isSharing
                  ? null
                  : () => _captureAndShare(saveToGallery: true),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Instagram',
                      style: TextStyle(fontSize: 12)),
                  onPressed: _isSharing
                      ? null
                      : () => _captureAndShare(platform: 'instagram'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('WhatsApp',
                      style: TextStyle(fontSize: 12)),
                  onPressed: _isSharing
                      ? null
                      : () => _captureAndShare(platform: 'whatsapp'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.more_horiz, size: 18),
                  label: const Text('Outros',
                      style: TextStyle(fontSize: 12)),
                  onPressed: _isSharing ? null : () => _captureAndShare(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
