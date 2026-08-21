import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/tracker_storage.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/tracker_share_screen.dart';

const _gold = Color(0xFFD4AF37);
const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);

class YogaTrackerScreen extends StatefulWidget {
  const YogaTrackerScreen({super.key});

  @override
  State<YogaTrackerScreen> createState() => _YogaTrackerScreenState();
}

class _YogaTrackerScreenState extends State<YogaTrackerScreen>
    with WidgetsBindingObserver {
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  Timer? _timer;
  DateTime? _runSince; // wall-clock anchor when running started

  String? _selectedFocus;
  double _intensity = 5;

  final _focuses = ['Flexibilidade', 'Força', 'Respiração', 'Meditação', 'Equilíbrio'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning && _runSince != null && mounted) {
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_runSince!).inSeconds;
      });
    }
  }

  void _startStop() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _runSince = DateTime.now().subtract(Duration(seconds: _elapsedSeconds));
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _elapsedSeconds = DateTime.now().difference(_runSince!).inSeconds;
          });
        }
      });
    }
  }

  void _endSession() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    _showPostSession();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
    });
  }

  void _showPostSession() async {
    final sessionData = {
      'focus': _selectedFocus ?? 'Livre',
      'elapsedSeconds': _elapsedSeconds,
      'intensity': _intensity.round(),
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostSessionSheet(
        data: sessionData,
        onSave: () async {
          await TrackerStorage.saveSession('yoga', sessionData);
          if (mounted) Navigator.of(context).pop();
        },
        onShare: () {
          Navigator.of(context).pop();
          final min = _elapsedSeconds ~/ 60;
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => TrackerShareScreen(
              trackerType: 'yoga',
              stats: {
                'Modalidade': 'Yoga',
                'Duração': '${min}min',
                'Foco': _selectedFocus ?? 'Livre',
                'Intensidade': '${_intensity.round()}/10',
              },
              modality: 'Yoga',
            ),
          ));
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  String get _elapsed {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('YOGA',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildTimer(),
            const SizedBox(height: 20),
            _buildFocusSelector(),
            const SizedBox(height: 20),
            _buildIntensitySlider(),
            const SizedBox(height: 32),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.self_improvement, color: _gold.withOpacity(0.6), size: 36),
          const SizedBox(height: 16),
          Text(_elapsed,
              style: const TextStyle(
                  color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(
            _isRunning ? 'EM PRÁTICA' : _elapsedSeconds == 0 ? 'PRONTO PARA INICIAR' : 'PAUSADO',
            style: TextStyle(
                color: _isRunning ? _gold : Colors.white.withOpacity(0.3),
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foco da prática (opcional)',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _focuses.map((f) {
              final sel = _selectedFocus == f;
              return GestureDetector(
                onTap: () => setState(() => _selectedFocus = sel ? null : f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? _gold : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? _gold : Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(f,
                      style: TextStyle(
                          color: sel ? Colors.black : Colors.white70,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensitySlider() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Intensidade percebida',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
              Text('${_intensity.round()}/10',
                  style: const TextStyle(
                      color: _gold, fontWeight: FontWeight.bold, fontSize: 16)),
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
              value: _intensity,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _intensity = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 22),
            label: Text(_isRunning ? 'Pausar' : (_elapsedSeconds == 0 ? 'Iniciar' : 'Retomar'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _startStop,
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white54,
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _reset,
          child: const Icon(Icons.refresh, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _elapsedSeconds > 0 ? _endSession : null,
            child: const Text('Finalizar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final min = (data['elapsedSeconds'] as int) ~/ 60;
    final sec = (data['elapsedSeconds'] as int) % 60;

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
          const Text('PRÁTICA CONCLUÍDA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
          const SizedBox(height: 20),
          _row('Duração', '${min}min ${sec}s'),
          _row('Foco', data['focus']),
          _row('Intensidade', '${data['intensity']}/10'),
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
