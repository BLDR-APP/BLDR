import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> activityData;

  const ActivityDetailScreen({super.key, required this.activityData});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  List<LatLng> _routePoints = [];
  final GlobalKey _printKey = GlobalKey();
  final GlobalKey _shareBtnKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _parseRoute();
  }

  void _parseRoute() {
    try {
      final rawRoute = widget.activityData['route_data'];

      if (rawRoute != null && rawRoute is List) {
        setState(() {
          _routePoints = rawRoute.map((point) {
            return LatLng(
              (point['lat'] as num).toDouble(),
              (point['lng'] as num).toDouble(),
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Erro ao ler rota: $e");
      // Se der erro, mantém a lista vazia, mas não cracha o app
    }
  }

  LatLngBounds _getBounds() {
    if (_routePoints.isEmpty) {
      // Retorna uma coordenada padrão (São Paulo) para não quebrar o mapa
      return LatLngBounds(
        const LatLng(-23.55, -46.63),
        const LatLng(-23.56, -46.64),
      );
    }
    return LatLngBounds.fromPoints(_routePoints);
  }

  Future<void> _shareActivity() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final boundary = _printKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Erro de captura");

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Falha imagem");

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/bldr_share.png');
      await file.writeAsBytes(pngBytes);

      Rect sharePositionOrigin = const Rect.fromLTWH(0, 0, 1, 1);
      final RenderBox? buttonBox = _shareBtnKey.currentContext?.findRenderObject() as RenderBox?;
      if (buttonBox != null && buttonBox.hasSize) {
        sharePositionOrigin = buttonBox.localToGlobal(Offset.zero) & buttonBox.size;
      }

      final distanceKm = (widget.activityData['distance_meters'] as num? ?? 0) / 1000;
      final durationSec = (widget.activityData['duration_seconds'] as num? ?? 0).toInt();
      final duration = Duration(seconds: durationSec);
      final timeStr = _formatDuration(duration);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Treino BLDR Club!\n$distanceKm km em $timeStr',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      debugPrint("Erro share: $e");
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _formatDuration(Duration d) {
    return d.inHours > 0
        ? '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}'
        : '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // PROTEÇÃO CONTRA NULOS AQUI TAMBÉM
    final distanceVal = (widget.activityData['distance_meters'] as num?) ?? 0;
    final distanceKm = (distanceVal / 1000).toStringAsFixed(2);
    final pace = widget.activityData['pace_text'] ?? "--:--";
    final durationSeconds = (widget.activityData['duration_seconds'] as num?)?.toInt() ?? 0;
    final duration = Duration(seconds: durationSeconds);
    final timeStr = _formatDuration(duration);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityData['title'] ?? 'Treino'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: _shareBtnKey,
            icon: _isSharing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.share),
            onPressed: _shareActivity,
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _printKey,
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: _getBounds(),
                    padding: const EdgeInsets.all(50),
                  ),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bldr.app',
                  ),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5.0,
                          color: const Color(0xFFFC4C02),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                width: double.infinity,
                child: Column(
                  children: [
                    const Text("Resumo BLDR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem("km", "$distanceKm km"),
                        _statItem("Tempo", timeStr),
                        _statItem("Pace", pace),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}