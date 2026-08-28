import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/tracker_storage.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/tracker_share_screen.dart';

const _gold = Color(0xFFD4AF37);
const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);

class PoolTrackerScreen extends StatefulWidget {
  const PoolTrackerScreen({super.key});

  @override
  State<PoolTrackerScreen> createState() => _PoolTrackerScreenState();
}

class _PoolTrackerScreenState extends State<PoolTrackerScreen> {
  // Config
  int _laneSize = 25;
  String _stroke = 'Livre';
  int _lapGoal = 40;
  bool _configDone = false;

  // Session
  int _laps = 0;
  bool _isRunning = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // Lap times
  List<int> _lapTimes = [];
  int _lapStartSeconds = 0;
  int? _bestLapSeconds;

  final _strokes = ['Livre', 'Costas', 'Peito', 'Borboleta', 'Variado'];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final cfg = await TrackerStorage.getPoolConfig();
    if (mounted) setState(() {
      _laneSize = cfg['laneSize'] as int;
      _stroke = cfg['stroke'] as String;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStop() {
    if (!_configDone) {
      TrackerStorage.savePoolConfig(_laneSize, _stroke);
      setState(() => _configDone = true);
    }
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsedSeconds++);
      });
    }
  }

  void _markLap() {
    if (!_isRunning) return;
    final lapTime = _elapsedSeconds - _lapStartSeconds;
    setState(() {
      _laps++;
      _lapTimes.add(lapTime);
      _lapStartSeconds = _elapsedSeconds;
      if (_bestLapSeconds == null || lapTime < _bestLapSeconds!) {
        _bestLapSeconds = lapTime;
      }
    });
  }

  void _endSession() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    _showPostSession();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _laps = 0;
      _elapsedSeconds = 0;
      _lapTimes = [];
      _lapStartSeconds = 0;
      _bestLapSeconds = null;
      _isRunning = false;
      _configDone = false;
    });
  }

  void _showPostSession() async {
    final totalDistance = _laps * _laneSize;
    final avgLapSec = _laps > 0 ? _elapsedSeconds ~/ _laps : 0;
    final isPR = await TrackerStorage.updatePRIfBetter(
        'pool', 'distance_m', totalDistance.toDouble());
    if (mounted) setState(() {});

    final sessionData = {
      'laneSize': _laneSize,
      'stroke': _stroke,
      'laps': _laps,
      'totalDistanceM': totalDistance,
      'elapsedSeconds': _elapsedSeconds,
      'avgLapSeconds': avgLapSec,
      'bestLapSeconds': _bestLapSeconds ?? 0,
      'isNewPR': isPR,
    };

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostSessionSheet(
        data: sessionData,
        onSave: () async {
          await TrackerStorage.saveSession('pool', sessionData);
          if (mounted) Navigator.of(context).pop();
        },
        onShare: () {
          Navigator.of(context).pop();
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => TrackerShareScreen(
              trackerType: 'pool',
              stats: _buildShareStats(sessionData),
              modality: 'Natação',
              showPR: isPR,
            ),
          ));
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  Map<String, String> _buildShareStats(Map<String, dynamic> d) {
    final avgMin = (d['avgLapSeconds'] as int) ~/ 60;
    final avgSec = (d['avgLapSeconds'] as int) % 60;
    final bestMin = (d['bestLapSeconds'] as int) ~/ 60;
    final bestSec = (d['bestLapSeconds'] as int) % 60;
    return {
      'Modalidade': 'Natação · ${d['stroke']}',
      'Distância': '${d['totalDistanceM']}m',
      'Voltas': '${d['laps']}',
      'Média/volta': '${avgMin}:${avgSec.toString().padLeft(2, '0')}',
      'Melhor volta': '${bestMin}:${bestSec.toString().padLeft(2, '0')}',
    };
  }

  String get _elapsed {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _totalDistanceM => _laps * _laneSize;

  String _formatSec(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('POOL TRACKER',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            if (!_configDone) ...[
              _buildConfig(),
              const SizedBox(height: 20),
            ],
            if (_configDone) ...[
              _buildTimer(),
              const SizedBox(height: 16),
              _buildMetrics(),
              const SizedBox(height: 16),
              _buildLapList(),
              const SizedBox(height: 24),
            ],
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfig() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONFIGURAÇÃO',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5)),
          const SizedBox(height: 20),

          // Lane size
          Text('Tamanho da raia',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 10),
          Row(
            children: [25, 50].map((size) {
              final sel = _laneSize == size;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _laneSize = size),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? _gold : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sel ? _gold : Colors.white.withOpacity(0.1)),
                    ),
                    child: Text('${size}m',
                        style: TextStyle(
                            color: sel ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Text('Estilo',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _strokes.map((s) {
              final sel = _stroke == s;
              return GestureDetector(
                onTap: () => setState(() => _stroke = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? _gold : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? _gold : Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(s,
                      style: TextStyle(
                          color: sel ? Colors.black : Colors.white70,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          // Lap goal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meta de voltas',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              Row(
                children: [
                  _iconBtn(Icons.remove, () { if (_lapGoal > 1) setState(() => _lapGoal--); }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$_lapGoal',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  _iconBtn(Icons.add, () => setState(() => _lapGoal++)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text('$_elapsed',
              style: const TextStyle(
                  color: Colors.white, fontSize: 60, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          // Progress towards goal
          if (_lapGoal > 0) ...[
            LinearProgressIndicator(
              value: (_laps / _lapGoal).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(_gold),
            ),
            const SizedBox(height: 8),
            Text('$_laps / $_lapGoal voltas',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    final avgSec = _laps > 0 ? _elapsedSeconds ~/ _laps : 0;
    return Row(
      children: [
        _metricCard('Distância', '${_totalDistanceM}m'),
        const SizedBox(width: 8),
        _metricCard('Média/volta', _formatSec(avgSec)),
        const SizedBox(width: 8),
        _metricCard('Melhor volta', _bestLapSeconds != null ? _formatSec(_bestLapSeconds!) : '--:--',
            highlight: true),
      ],
    );
  }

  Widget _metricCard(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: highlight ? _gold.withOpacity(0.1) : _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: highlight ? _gold.withOpacity(0.3) : Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: highlight ? _gold : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 9, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildLapList() {
    if (_lapTimes.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ÚLTIMAS VOLTAS',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          ..._lapTimes.reversed.take(8).toList().asMap().entries.map((e) {
            final idx = _lapTimes.length - e.key;
            final sec = e.value;
            final isBest = sec == _bestLapSeconds;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Volta $idx',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  Row(
                    children: [
                      if (isBest)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('PR',
                              style: TextStyle(color: _gold, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      Text(_formatSec(sec),
                          style: TextStyle(
                              color: isBest ? _gold : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Main lap button
        if (_configDone)
          GestureDetector(
            onTap: _markLap,
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: _isRunning ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Center(
                child: Text('+ MARCAR VOLTA',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 15)),
              ),
            ),
          ),
        if (_configDone) const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.white.withOpacity(0.1) : _gold,
                  foregroundColor: _isRunning ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 20),
                label: Text(_configDone
                    ? (_isRunning ? 'Pausar' : 'Retomar')
                    : 'Iniciar',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _startStop,
              ),
            ),
            if (_configDone) ...[
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _reset,
                child: const Icon(Icons.refresh, size: 20),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _endSession,
                child: const Text('Fim', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 16),
      ),
    );
  }
}

// ── Post-session ──────────────────────────────────────────────────────────────

class _PostSessionSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onClose;

  const _PostSessionSheet({
    required this.data,
    required this.onSave,
    required this.onShare,
    required this.onClose,
  });

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isPR = data['isNewPR'] as bool;
    final avgSec = data['avgLapSeconds'] as int;
    final bestSec = data['bestLapSeconds'] as int;
    final totalMin = (data['elapsedSeconds'] as int) ~/ 60;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('RESUMO DA SESSÃO',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
              if (isPR) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withOpacity(0.5)),
                  ),
                  child: const Text('NOVO PR', style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _row('Estilo', data['stroke']),
          _row('Distância total', '${data['totalDistanceM']}m'),
          _row('Voltas', '${data['laps']}'),
          _row('Tempo total', '${totalMin}min'),
          _row('Média por volta', _fmt(avgSec)),
          _row('Melhor volta', _fmt(bestSec)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onSave,
              child: const Text('SALVAR SESSÃO',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Compartilhar'),
              onPressed: onShare,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
