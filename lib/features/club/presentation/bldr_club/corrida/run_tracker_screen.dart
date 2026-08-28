// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/corrida/summary_share_screen.dart';
import 'package:bldr_fitness/features/integrations/data/run_live_activity_service.dart';
import 'package:bldr_fitness/features/integrations/data/watch_service.dart';

class RunTrackerScreen extends StatefulWidget {
  const RunTrackerScreen({super.key});

  @override
  State<RunTrackerScreen> createState() => _RunTrackerScreenState();
}

class _RunTrackerScreenState extends State<RunTrackerScreen> {
  final MapController _mapController = MapController();

  List<LatLng> _routePoints = [];
  bool _isTracking = false;
  bool _isPaused = false;

  double _totalDistance = 0.0;
  String _currentPace = "0:00";
  double _currentPaceSec = 0; // segundos/km para LiveActivity

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<Map<String, dynamic>>? _watchSub;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;

  LatLng _initialLocation = const LatLng(-23.5505, -46.6333);
  bool _hasUserLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationForMap();
    _listenWatchActions();
  }

  void _listenWatchActions() {
    _watchSub = getIt<WatchService>().watchActions.listen((msg) {
      final acao = msg['acao_corrida'] as String?;
      if (acao == null) return;
      if (acao == 'pausar' && _isTracking && !_isPaused) _pauseTracking();
      if (acao == 'retomar' && _isPaused) _resumeTracking();
      if (acao == 'finalizar' && _isTracking) _stopAndSave();
    });
  }

  Future<void> _getCurrentLocationForMap() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _initialLocation = LatLng(pos.latitude, pos.longitude);
          _hasUserLocation = true;
        });
        _mapController.move(_initialLocation, 16.0);
      }
    } catch (e) {
      debugPrint("Erro ao pegar localização inicial: $e");
    }
  }

  Future<void> _startTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() {
      _isTracking = true;
      _isPaused = false;
      _routePoints.clear();
      _totalDistance = 0.0;
      _currentPace = "0:00";
      _currentPaceSec = 0;
      _stopwatch.reset();
      _stopwatch.start();
    });

    unawaited(getIt<RunLiveActivityService>().start());
    unawaited(getIt<WatchService>().sendRunState(distanceMeters: 0, paceSecPerKm: 0));

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });

    late LocationSettings locationSettings;

    if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      );
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _processNewPosition(position);
    });
  }

  void _pauseTracking() {
    setState(() {
      _isPaused = true;
      _stopwatch.stop();
    });
    unawaited(getIt<RunLiveActivityService>().pause());
    unawaited(getIt<WatchService>().sendRunState(
        distanceMeters: _totalDistance, paceSecPerKm: _currentPaceSec, isActive: false));
  }

  void _resumeTracking() {
    setState(() {
      _isPaused = false;
      _stopwatch.start();
    });
    unawaited(getIt<RunLiveActivityService>().resume());
    unawaited(getIt<WatchService>().sendRunState(
        distanceMeters: _totalDistance, paceSecPerKm: _currentPaceSec));
  }

  void _processNewPosition(Position pos) {
    if (_isPaused) return;

    final newPoint = LatLng(pos.latitude, pos.longitude);

    setState(() {
      // Se for o primeiro ponto, apenas adiciona
      if (_routePoints.isEmpty) {
        _routePoints.add(newPoint);
        return;
      }

      // Calcula distância do último ponto
      final previous = _routePoints.last;
      final distanceGap = Geolocator.distanceBetween(
        previous.latitude, previous.longitude,
        newPoint.latitude, newPoint.longitude,
      );

      // Filtro de ruído
      if (distanceGap > 2.0) {
        _routePoints.add(newPoint);
        _totalDistance += distanceGap;
        _updatePace();
      }

      _mapController.move(newPoint, 17.0);
    });
  }

  void _updatePace() {
    if (_totalDistance > 50) {
      final km = _totalDistance / 1000;
      final minutes = _stopwatch.elapsed.inMinutes.toDouble() +
          (_stopwatch.elapsed.inSeconds % 60) / 60;

      if (km > 0) {
        final paceVal = minutes / km;
        if (paceVal < 30) {
          _currentPaceSec = paceVal * 60; // segundos/km
          final paceMin = paceVal.floor();
          final paceSec = ((paceVal - paceMin) * 60).round();
          _currentPace = "$paceMin:${paceSec.toString().padLeft(2, '0')}";
        }
      }
    }
    // Atualiza LiveActivity e Watch a cada ponto GPS
    unawaited(getIt<RunLiveActivityService>().update(
      distanceMeters: _totalDistance,
      paceSecPerKm: _currentPaceSec,
      isActive: true,
    ));
    unawaited(getIt<WatchService>().sendRunState(
      distanceMeters: _totalDistance,
      paceSecPerKm: _currentPaceSec,
    ));
  }

  Future<void> _stopAndSave() async {
    _positionStream?.cancel();
    _stopwatch.stop();
    _uiTimer?.cancel();
    unawaited(getIt<RunLiveActivityService>().end());
    unawaited(getIt<WatchService>().sendRunState(
        distanceMeters: _totalDistance, paceSecPerKm: _currentPaceSec, finished: true));

    // Recálculo de segurança
    if (_totalDistance == 0 && _routePoints.length > 1) {
      double recalculated = 0;
      for (int i = 0; i < _routePoints.length - 1; i++) {
        recalculated += Geolocator.distanceBetween(
            _routePoints[i].latitude, _routePoints[i].longitude,
            _routePoints[i+1].latitude, _routePoints[i+1].longitude
        );
      }
      _totalDistance = recalculated;
    }

    const int xpDaCorrida = 500;
    final double finalDistance = _totalDistance;
    final String finalTimeStr = _formatTime(_stopwatch.elapsed);
    final String finalPace = _currentPace;
    final List<LatLng> finalRoute = List.from(_routePoints);

    setState(() {
      _isTracking = false;
      _isPaused = false;
    });

    final userId = getIt<GetCurrentUser>()()?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro: Usuário não logado")));
      return;
    }

    final routeJson = finalRoute.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();

    try {
      final result = await getIt<SaveRunActivity>()(
        distanceMeters: finalDistance,
        durationSeconds: _stopwatch.elapsed.inSeconds,
        paceText: finalPace,
        routeData: routeJson,
        earnedXp: xpDaCorrida,
      );
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);
      unawaited(getIt<TryIncrementOperation>()(
          'run_distance', (finalDistance / 1000).floor()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Corrida salva! +500 XP conquistados!'), backgroundColor: Color(0xFFD4AF37)),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SummaryShareScreen(
              routePoints: finalRoute,
              distanceMeters: finalDistance,
              timeStr: finalTimeStr,
              paceStr: finalPace,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao salvar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e")));
      }
    }
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours > 0 ? "${d.inHours}:" : "";
    return "$hours$minutes:$seconds";
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _watchSub?.cancel();
    _uiTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialLocation,
              initialZoom: 16.0,
              maxZoom: 18.0,
            ),
            children: [
              // --- MUDANÇA AQUI: CARTO DB DARK MATTER ---
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.bldr.app',
              ),
              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.0,
                      color: const Color(0xFFD4AF37), // Dourado do BLDR
                    ),
                  ],
                ),
              if (_isTracking && _routePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _routePoints.last,
                      width: 24,
                      height: 24,
                      child: Icon(
                        Icons.circle,
                        color: _isPaused ? Colors.grey : const Color(0xFFD4AF37),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              if (!_isTracking && _hasUserLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _initialLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // OVERLAY DE PAUSA
          if (_isPaused)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Text("PAUSADO",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 2)),
              ),
            ),

          // PAINEL DE CONTROLE INFERIOR
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black, // Fundo preto puro para contraste
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: _infoCard("DISTÂNCIA", "${(_totalDistance / 1000).toStringAsFixed(2)}", "km")),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(child: _infoCard("PACE", _currentPace, "/km")),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(child: _infoCard("TEMPO", _formatTime(_stopwatch.elapsed), "")),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!_isTracking)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        onPressed: _startTracking,
                        child: const Text("INICIAR CORRIDA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else if (!_isPaused)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        onPressed: _pauseTracking,
                        icon: const Icon(Icons.pause),
                        label: const Text("PAUSAR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                              onPressed: _resumeTracking,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text("RETOMAR", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                              onPressed: _stopAndSave,
                              icon: const Icon(Icons.stop),
                              label: const Text("FINALIZAR", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, String unit) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if(unit.isNotEmpty)
                Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              if(unit.isNotEmpty) const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}