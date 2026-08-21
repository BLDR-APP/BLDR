import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:latlong2/latlong.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/corrida/run_tracker_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/corrida/summary_share_screen.dart';

const _gold = Color(0xFFD4AF37);

// Modalities for BLDR RUN dropdown
enum RunModality { corrida, ciclismo, caminhada }

extension RunModalityExt on RunModality {
  String get label {
    switch (this) {
      case RunModality.corrida: return 'Corrida';
      case RunModality.ciclismo: return 'Ciclismo';
      case RunModality.caminhada: return 'Caminhada';
    }
  }

  IconData get icon {
    switch (this) {
      case RunModality.corrida: return Icons.directions_run;
      case RunModality.ciclismo: return Icons.directions_bike;
      case RunModality.caminhada: return Icons.directions_walk;
    }
  }

  String get startLabel {
    switch (this) {
      case RunModality.corrida: return 'INICIAR CORRIDA';
      case RunModality.ciclismo: return 'INICIAR PEDALADA';
      case RunModality.caminhada: return 'INICIAR CAMINHADA';
    }
  }

  String get metricsLabel {
    switch (this) {
      case RunModality.corrida: return 'GPS · Pace · Distância · Elevação';
      case RunModality.ciclismo: return 'GPS · Velocidade · Distância · Elevação';
      case RunModality.caminhada: return 'GPS · Passos · Distância · Pace';
    }
  }

  String get storageKey => 'run_modality_${name}';
}

class RunCardWidget extends StatefulWidget {
  const RunCardWidget({super.key});

  @override
  State<RunCardWidget> createState() => _RunCardWidgetState();
}

class _RunCardWidgetState extends State<RunCardWidget> {
  List<Map<String, dynamic>> _lastActivities = [];
  bool _isLoading = true;
  RunModality _modality = RunModality.corrida;

  @override
  void initState() {
    super.initState();
    _loadModality();
    _fetchLastRuns();
  }

  Future<void> _loadModality() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('bldr_run_modality') ?? 'corrida';
    final m = RunModality.values.firstWhere(
        (e) => e.name == saved, orElse: () => RunModality.corrida);
    if (mounted) setState(() => _modality = m);
  }

  Future<void> _saveModality(RunModality m) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bldr_run_modality', m.name);
  }

  Future<void> _fetchLastRuns() async {
    try {
      final result = await getIt<GetRunActivities>()(limit: 5);
      final activities = result.valueOrNull;
      if (activities == null) return;

      if (mounted) {
        setState(() {
          _lastActivities = activities.map(_runToMap).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar últimos treinos: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openActivityDetails(Map<String, dynamic> activity) {
    try {
      List<LatLng> routePoints = [];
      if (activity['route_data'] != null) {
        final List<dynamic> rawList = activity['route_data'];
        routePoints = rawList.map((p) => LatLng(p['lat'], p['lng'])).toList();
      }

      final double distanceMeters = (activity['distance_meters'] as num? ?? 0).toDouble();
      final int durationSeconds = (activity['duration_seconds'] as num? ?? 0).toInt();
      final String paceStr = activity['pace_text'] ?? "--:--";

      final duration = Duration(seconds: durationSeconds);
      String timeStr;
      if (duration.inHours > 0) {
        timeStr = "${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
      } else {
        timeStr = "${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SummaryShareScreen(
            routePoints: routePoints,
            distanceMeters: distanceMeters,
            timeStr: timeStr,
            paceStr: paceStr,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Erro ao abrir detalhes: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao carregar os detalhes desta atividade.")),
      );
    }
  }

  void _showModalityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Modalidade',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...RunModality.values.map((m) {
              final sel = m == _modality;
              return ListTile(
                leading: Icon(m.icon, color: sel ? _gold : Colors.white54),
                title: Text(m.label,
                    style: TextStyle(
                        color: sel ? _gold : Colors.white,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                trailing: sel ? const Icon(Icons.check, color: _gold) : null,
                onTap: () {
                  setState(() => _modality = m);
                  _saveModality(m);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _runToMap(dynamic a) => {
      'id': a.id,
      'title': a.title,
      'distance_meters': a.distanceMeters,
      'duration_seconds': a.durationSeconds,
      'pace_text': a.paceText,
      'earned_xp': a.earnedXp,
      'created_at': a.createdAt?.toIso8601String(),
      'route_data': a.routeData,
    };

  /// Parse pace string "M:SS" → seconds. Returns null if unparseable.
  int? _parsePaceSec(String? paceText) {
    if (paceText == null || paceText == '--:--') return null;
    final parts = paceText.split(':');
    if (parts.length != 2) return null;
    final m = int.tryParse(parts[0]);
    final s = int.tryParse(parts[1]);
    if (m == null || s == null) return null;
    return m * 60 + s;
  }

  String _formatPaceSec(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}/km';
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inDays >= 7) return 'há ${diff.inDays ~/ 7} sem';
      if (diff.inDays >= 1) return 'há ${diff.inDays}d';
      if (diff.inHours >= 1) return 'há ${diff.inHours}h';
      return 'hoje';
    } catch (_) {
      return '';
    }
  }

  Widget _buildStatsRow() {
    if (_lastActivities.isEmpty) return const SizedBox.shrink();

    final last = _lastActivities.first;
    final now = DateTime.now();
    final thisMonthCount = _lastActivities.where((a) {
      try {
        final d = DateTime.parse(a['created_at'] as String? ?? '').toLocal();
        return d.year == now.year && d.month == now.month;
      } catch (_) {
        return false;
      }
    }).length;

    // Avg pace from all activities that have parseable pace_text
    final paceSecs = _lastActivities
        .map((a) => _parsePaceSec(a['pace_text'] as String?))
        .whereType<int>()
        .toList();
    final avgPace = paceSecs.isEmpty
        ? null
        : (paceSecs.reduce((a, b) => a + b) / paceSecs.length).round();

    final lastDist = ((last['distance_meters'] as num?) ?? 0) / 1000;
    final lastTitle = (last['title'] as String?) ?? 'Corrida';
    final lastDate = _timeAgo(last['created_at'] as String?);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$lastTitle · ${lastDist.toStringAsFixed(2)} km · $lastDate',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (avgPace != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Pace médio: ${_formatPaceSec(avgPace)} · $thisMonthCount ${thisMonthCount == 1 ? "corrida" : "corridas"} este mês',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABEÇALHO — mesmo visual, adicionado dropdown pill à direita
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_modality.icon, color: _gold, size: 24),
                  const SizedBox(width: 10),
                  const Text("BLDR RUN",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
              // Dropdown pill (novo)
              GestureDetector(
                onTap: _showModalityPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_modality.label,
                          style: TextStyle(
                              color: _gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: _gold, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // BOTÃO INICIAR — mesma aparência, texto muda com modalidade
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RunTrackerScreen()),
              ).then((_) => _fetchLastRuns());
            },
            child: Container(
              height: 75,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, _gold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: _gold.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                  const SizedBox(width: 15),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_modality.startLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18)),
                          Text(_modality.metricsLabel,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // F19 — stats inline: última corrida + pace médio + count mensal
          if (!_isLoading && _lastActivities.isNotEmpty) ...[
            _buildStatsRow(),
            const SizedBox(height: 16),
          ],

          // LISTA DE TREINOS — inalterada
          const Text("ÚLTIMOS TREINOS",
              style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),

          if (_isLoading)
            const Center(child: LinearProgressIndicator(color: _gold))
          else if (_lastActivities.isNotEmpty)
            Column(
              children: _lastActivities.map((activity) {
                final distance = (activity['distance_meters'] as num? ?? 0) / 1000;
                final dateStr = activity['created_at'];
                final pace = activity['pace_text'] ?? "--:--";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _openActivityDetails(activity),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                      color: Colors.grey[900],
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.history,
                                      color: Colors.grey, size: 14),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(_formatDate(dateStr),
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text("${distance.toStringAsFixed(2)} km",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  const SizedBox(width: 10),
                                  Text(pace,
                                      style: TextStyle(
                                          color: Colors.grey[400], fontSize: 12)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Nenhuma atividade registrada ainda.",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "--/--";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
    } catch (e) {
      return "--/--";
    }
  }
}
