import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/tracker_storage.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/tracker_share_screen.dart';

const _gold = Color(0xFFD4AF37);
const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);

class RoundTimerScreen extends StatefulWidget {
  final String? initialModality;
  const RoundTimerScreen({super.key, this.initialModality});

  @override
  State<RoundTimerScreen> createState() => _RoundTimerScreenState();
}

class _RoundTimerScreenState extends State<RoundTimerScreen> {
  final List<String> _modalities = ['Boxe', 'MMA', 'Jiu Jitsu', 'Muay Thai'];
  late String _modality;

  int _roundMins = 3;
  int _restMins = 1;
  int _numRounds = 6;

  int _currentRound = 1;
  bool _isRoundPhase = true;
  bool _isRunning = false;
  bool _isFinished = false;
  int _secondsLeft = 0;
  Timer? _timer;

  List<Map<String, dynamic>> _history = [];

  // Stats for post-session
  int _completedRounds = 0;
  int _totalWorkSeconds = 0;
  int _totalRestSeconds = 0;

  @override
  void initState() {
    super.initState();
    _modality = widget.initialModality ?? 'Boxe';
    _loadSettings();
    _loadHistory();
  }

  Future<void> _loadSettings() async {
    final s = await TrackerStorage.getRoundSettings(_modality);
    if (mounted) {
      setState(() {
        _roundMins = s['roundMins'] as int;
        _restMins = s['restMins'] as int;
        _numRounds = s['numRounds'] as int;
        _secondsLeft = _roundMins * 60;
      });
    }
  }

  Future<void> _loadHistory() async {
    final h = await TrackerStorage.getHistory('round_$_modality');
    if (mounted) setState(() => _history = h);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStop() {
    if (_isFinished) return;
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_secondsLeft == 0) _secondsLeft = _roundMins * 60;
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void _tick(Timer t) {
    if (!mounted) { t.cancel(); return; }
    setState(() {
      if (_secondsLeft > 1) {
        _secondsLeft--;
        if (_isRoundPhase) _totalWorkSeconds++;
        else _totalRestSeconds++;
      } else {
        // Phase ends
        if (_isRoundPhase) _totalWorkSeconds++;
        else _totalRestSeconds++;
        _vibrate(strong: _isRoundPhase);

        if (_isRoundPhase) {
          // Round done
          _completedRounds++;
          if (_currentRound >= _numRounds) {
            // Session done
            _timer?.cancel();
            _isRunning = false;
            _isFinished = true;
            _showPostSession();
            return;
          }
          // Start rest
          _isRoundPhase = false;
          _secondsLeft = _restMins * 60;
        } else {
          // Rest done — next round
          _currentRound++;
          _isRoundPhase = true;
          _secondsLeft = _roundMins * 60;
        }
      }
    });
  }

  void _skipPhase() {
    if (!_isRunning && _secondsLeft == _roundMins * 60) return;
    _timer?.cancel();
    setState(() {
      if (_isRoundPhase) {
        _completedRounds++;
        if (_currentRound >= _numRounds) {
          _isRunning = false;
          _isFinished = true;
          _showPostSession();
          return;
        }
        _isRoundPhase = false;
        _secondsLeft = _restMins * 60;
      } else {
        _currentRound++;
        _isRoundPhase = true;
        _secondsLeft = _roundMins * 60;
      }
    });
    if (_isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void _reset() {
    _timer?.cancel();
    _loadSettings().then((_) {
      setState(() {
        _currentRound = 1;
        _isRoundPhase = true;
        _isRunning = false;
        _isFinished = false;
        _completedRounds = 0;
        _totalWorkSeconds = 0;
        _totalRestSeconds = 0;
        _secondsLeft = _roundMins * 60;
      });
    });
  }

  void _vibrate({required bool strong}) async {
    final hasVibrator = (await Vibration.hasVibrator()) == true;
    if (hasVibrator) {
      Vibration.vibrate(duration: strong ? 400 : 200);
    }
  }

  void _showPostSession() {
    final sessionData = {
      'modality': _modality,
      'completedRounds': _completedRounds,
      'numRounds': _numRounds,
      'totalWorkSeconds': _totalWorkSeconds,
      'totalRestSeconds': _totalRestSeconds,
      'totalSeconds': _totalWorkSeconds + _totalRestSeconds,
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostSessionSheet(
        data: sessionData,
        onSave: () async {
          await TrackerStorage.saveSession('round_$_modality', sessionData);
          _loadHistory();
          if (mounted) Navigator.of(context).pop();
        },
        onShare: () {
          Navigator.of(context).pop();
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => TrackerShareScreen(
              trackerType: 'round',
              stats: _buildShareStats(sessionData),
              modality: _modality,
            ),
          ));
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  Map<String, String> _buildShareStats(Map<String, dynamic> d) {
    final workMin = (d['totalWorkSeconds'] as int) ~/ 60;
    final workSec = (d['totalWorkSeconds'] as int) % 60;
    final total = (d['totalSeconds'] as int);
    final totalMin = total ~/ 60;
    return {
      'Modalidade': d['modality'],
      'Rounds': '${d['completedRounds']} de ${d['numRounds']}',
      'Tempo de trabalho': '${workMin}m ${workSec}s',
      'Sessão total': '${totalMin}min',
    };
  }

  void _onModalityChanged(String m) async {
    _timer?.cancel();
    setState(() {
      _modality = m;
      _isRunning = false;
      _isFinished = false;
      _currentRound = 1;
      _isRoundPhase = true;
      _completedRounds = 0;
      _totalWorkSeconds = 0;
      _totalRestSeconds = 0;
    });
    await _loadSettings();
    _loadHistory();
  }

  String get _timeDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('ROUND TIMER',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildModalitySelector(),
            const SizedBox(height: 20),
            _buildTimerDisplay(),
            const SizedBox(height: 20),
            _buildRoundIndicators(),
            const SizedBox(height: 24),
            if (!_isRunning) _buildConfigCards(),
            if (!_isRunning) const SizedBox(height: 24),
            _buildControls(),
            const SizedBox(height: 32),
            _buildHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildModalitySelector() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _modalities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = _modalities[i];
          final sel = m == _modality;
          return GestureDetector(
            onTap: () => _onModalityChanged(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _gold : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? _gold : Colors.white.withOpacity(0.12)),
              ),
              child: Text(m,
                  style: TextStyle(
                      color: sel ? Colors.black : Colors.white70,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerDisplay() {
    final phaseLabel =
        _isRoundPhase ? 'ROUND EM ANDAMENTO' : 'DESCANSO';
    final phaseColor = _isRoundPhase ? _gold : Colors.blueAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: phaseColor.withOpacity(0.4)),
            ),
            child: Text(phaseLabel,
                style: TextStyle(
                    color: phaseColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(height: 20),
          Text(_timeDisplay,
              style: TextStyle(
                  color: _isFinished ? Colors.grey : Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontFeatures: [const ui.FontFeature.tabularFigures()])),
          const SizedBox(height: 12),
          Text('Round $_currentRound de $_numRounds',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRoundIndicators() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(_numRounds, (i) {
        final roundNum = i + 1;
        final isDone = roundNum < _currentRound ||
            (roundNum == _currentRound && _isFinished);
        final isCurrent = roundNum == _currentRound && !_isFinished;

        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? _gold
                : isCurrent
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.1),
            border: Border.all(
              color: isCurrent ? _gold : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text('$roundNum',
                style: TextStyle(
                    color: isDone
                        ? Colors.black
                        : isCurrent
                            ? _gold
                            : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        );
      }),
    );
  }

  Widget _buildConfigCards() {
    return Row(
      children: [
        _configCard('Round', _roundMins, 'min', 1, 10, (v) {
          setState(() { _roundMins = v; if (!_isRunning) _secondsLeft = v * 60; });
          TrackerStorage.saveRoundSettings(_modality, v, _restMins, _numRounds);
        }),
        const SizedBox(width: 8),
        _configCard('Descanso', _restMins, 'min', 1, 5, (v) {
          setState(() => _restMins = v);
          TrackerStorage.saveRoundSettings(_modality, _roundMins, v, _numRounds);
        }),
        const SizedBox(width: 8),
        _configCard('Rounds', _numRounds, '', 1, 20, (v) {
          setState(() => _numRounds = v);
          TrackerStorage.saveRoundSettings(_modality, _roundMins, _restMins, v);
        }),
      ],
    );
  }

  Widget _configCard(String label, int value, String unit, int min, int max,
      ValueChanged<int> onChange) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('$value$unit',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _iconBtn(Icons.remove, () {
                  if (value > min) onChange(value - 1);
                }),
                const SizedBox(width: 8),
                _iconBtn(Icons.add, () {
                  if (value < max) onChange(value + 1);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 16),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset
        GestureDetector(
          onTap: _reset,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _card,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child:
                const Icon(Icons.refresh, color: Colors.white60, size: 24),
          ),
        ),
        const SizedBox(width: 24),
        // Play/Pause
        GestureDetector(
          onTap: _isFinished ? null : _startStop,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _isFinished ? Colors.grey.withOpacity(0.3) : _gold,
              shape: BoxShape.circle,
              boxShadow: [
                if (!_isFinished)
                  BoxShadow(color: _gold.withOpacity(0.4), blurRadius: 16),
              ],
            ),
            child: Icon(
              _isRunning ? Icons.pause : Icons.play_arrow,
              color: _isFinished ? Colors.grey : Colors.black,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Skip
        GestureDetector(
          onTap: _skipPhase,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _card,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.skip_next, color: Colors.white60, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ÚLTIMAS SESSÕES',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._history.take(5).map((s) {
          final date = _formatDate(s['savedAt']);
          final rounds = '${s['completedRounds']}/${s['numRounds']}';
          final totalMin = ((s['totalSeconds'] as int? ?? 0) ~/ 60);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12)),
                Text('$rounds rounds · ${totalMin}min',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '--';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    } catch (_) { return '--'; }
  }
}

// ── Post-session bottom sheet ──────────────────────────────────────────────

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
    final workMin = (data['totalWorkSeconds'] as int) ~/ 60;
    final workSec = (data['totalWorkSeconds'] as int) % 60;
    final restMin = (data['totalRestSeconds'] as int) ~/ 60;
    final restSec = (data['totalRestSeconds'] as int) % 60;
    final totalSec = data['totalSeconds'] as int;
    final totalMin = totalSec ~/ 60;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: _gold, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('SESSÃO CONCLUÍDA',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _statTile('Rounds', '${data['completedRounds']}/${data['numRounds']}'),
              const SizedBox(width: 12),
              _statTile('Trabalho', '${workMin}m ${workSec}s'),
              const SizedBox(width: 12),
              _statTile('Descanso', '${restMin}m ${restSec}s'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sessão total',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 13)),
                Text('${totalMin} min',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onSave,
              child: const Text('SALVAR SESSÃO',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
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

  Widget _statTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}

