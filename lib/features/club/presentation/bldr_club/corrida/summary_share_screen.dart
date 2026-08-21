import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SummaryShareScreen extends StatefulWidget {
  final List<LatLng> routePoints;
  final double distanceMeters;
  final String timeStr;
  final String paceStr;

  const SummaryShareScreen({
    super.key,
    required this.routePoints,
    required this.distanceMeters,
    required this.timeStr,
    required this.paceStr,
  });

  @override
  State<SummaryShareScreen> createState() => _SummaryShareScreenState();
}

class _SummaryShareScreenState extends State<SummaryShareScreen> {
  final GlobalKey _captureKey = GlobalKey();
  final GlobalKey _shareOriginKey = GlobalKey();

  // 0 = MAPA (Com fundo), 1 = STICKER (Transparente)
  int _selectedStyle = 0;
  bool _isSharing = false;

  Future<void> _shareCurrentView() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Erro de captura");

      final double ratio = _selectedStyle == 1 ? 2.0 : 3.0;

      final ui.Image image = await boundary.toImage(pixelRatio: ratio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Erro PNG");

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();

      String fileName = _selectedStyle == 1 ? 'bldr_sticker.png' : 'bldr_map.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      Rect sharePositionOrigin = const Rect.fromLTWH(0, 0, 1, 1);
      final RenderBox? box = _shareOriginKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
      }

      String distanceKm = (widget.distanceMeters / 1000).toStringAsFixed(2);
      String caption = '⚡️ BLDR Club: $distanceKm km';

      await Share.shareXFiles(
        [XFile(file.path)],
        text: _selectedStyle == 1 ? null : caption,
        sharePositionOrigin: sharePositionOrigin,
      );

    } catch (e) {
      debugPrint("Erro share: $e");
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Compartilhar", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: SizedBox(key: _shareOriginKey, width: 1, height: 1),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: RepaintBoundary(
                    key: _captureKey,
                    child: _selectedStyle == 0
                        ? _buildMapCard()
                        : _buildStickerCard(),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildOptionButton(0, "MAPA", Icons.map),
                    const SizedBox(width: 30),
                    _buildOptionButton(1, "TRAJETO", Icons.timeline),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSharing ? null : _shareCurrentView,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSharing
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text("COMPARTILHAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, String label, IconData icon) {
    final bool isSelected = _selectedStyle == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedStyle = index),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[900],
              borderRadius: BorderRadius.circular(18),
              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Icon(icon, color: isSelected ? Colors.black : Colors.white54, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAttribution() {
    return Positioned(
      right: 12,
      top: 12, // Coloquei no topo para não brigar com o gradiente/texto embaixo
      child: Text(
        "© OpenStreetMap, © CARTO",
        style: TextStyle(
          color: Colors.black.withOpacity(0.5), // Bem discreto
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // === OPÇÃO A: MAPA DARK ===
  Widget _buildMapCard() {
    final points = widget.routePoints.isNotEmpty ? widget.routePoints : [const LatLng(-23.55, -46.63)];

    return AspectRatio(
      aspectRatio: 4/5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(60),
                  ),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.bldr.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(points: points, strokeWidth: 5, color: const Color(0xFFD4AF37)),
                    ],
                  ),
                ],
              ),

              _buildAttribution(),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 30, left: 24, right: 24,
                child: _buildFooterStats(isTransparent: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === OPÇÃO B: STICKER ===
  Widget _buildStickerCard() {
    final points = widget.routePoints.isNotEmpty ? widget.routePoints : [const LatLng(-23.55, -46.63)];

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 380,
        height: 380,
        color: Colors.transparent,
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(50),
                  ),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  backgroundColor: Colors.transparent,
                ),
                children: [
                  PolylineLayer(
                    polylines: [
                      Polyline(points: points, strokeWidth: 3.5, color: const Color(0xFFD4AF37)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildFooterStats(isTransparent: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterStats({required bool isTransparent}) {
    final distanceKm = (widget.distanceMeters / 1000).toStringAsFixed(2);
    final List<Shadow> shadows = isTransparent
        ? [const Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))]
        : [];

    // Alinhamento: Centro se Sticker, Esquerda se Mapa
    final align = isTransparent ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final double mainFontSize = isTransparent ? 44 : 52;

    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$distanceKm km",
          style: TextStyle(
            color: Colors.white,
            fontSize: mainFontSize,
            fontWeight: FontWeight.w900,
            height: 1.0,
            shadows: shadows,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: isTransparent ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            _statItem(widget.timeStr, "TEMPO", shadows, isTransparent),
            const SizedBox(width: 24),
            _statItem(widget.paceStr, "PACE", shadows, isTransparent),
          ],
        ),

        const SizedBox(height: 12),

        // --- LOGO UNIFICADA ---
        // A logo é usada nos dois casos.
        // Se for Sticker, centraliza. Se for Mapa, alinha à esquerda.
        Align(
          alignment: isTransparent ? Alignment.center : Alignment.centerLeft,
          child: Image.asset(
            'assets/images/BLDR_CLUB.png',
            height: 50,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Text(
                  "BLDR CLUB",
                  style: TextStyle(
                      color: const Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      shadows: shadows,
                      letterSpacing: 1.5
                  )
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statItem(String value, String label, List<Shadow> shadows, bool isTransparent) {
    return Column(
      crossAxisAlignment: isTransparent ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: shadows)),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, shadows: shadows)),
      ],
    );
  }
}