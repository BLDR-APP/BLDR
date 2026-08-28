import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/tracker_storage.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/tracker_share_screen.dart';

const _gold = Color(0xFFD4AF37);
const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);

enum WodMode { amrap, forTime, emom, tabata }

class WodTimerScreen extends StatefulWidget {
  const WodTimerScreen({super.key});

  @override
  State<WodTimerScreen> createState() => _WodTimerScreenState();
}

class _WodTimerScreenState extends State<WodTimerScreen> {
  WodMode _mode = WodMode.amrap;
  bool _isRunning = false;
  bool _isFinished = false;
  Timer? _timer;

  // AMRAP config
  int _amrapMins = 20;
  int _amrapRounds = 0;
  int _amrapRepsExtra = 0;

  // For Time config
  int _forTimeRounds = 5;
  int _forTimeCompleted = 0;

  // EMOM config
  int _emomMins = 10;
  int _emomCurrentMin = 1;

  // Tabata config
  int _tabataRounds = 8;
  int _tabataWorkSec = 20;
  int _tabataRestSec = 10;
  int _tabataCurrentRound = 1;
  bool _tabataWorkPhase = true;

  // Shared timer
  int _secondsLeft = 0;
  int _elapsedSeconds = 0;


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initTimer() {
    switch (_mode) {
      case WodMode.amrap:
        _secondsLeft = _amrapMins * 60;
        break;
      case WodMode.forTime:
        _secondsLeft = 0;
        break;
      case WodMode.emom:
        _secondsLeft = 60;
        _emomCurrentMin = 1;
        break;
      case WodMode.tabata:
        _secondsLeft = _tabataWorkSec;
        _tabataCurrentRound = 1;
        _tabataWorkPhase = true;
        break;
    }
  }

  void _startStop() {
    if (_isFinished) return;
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (!_isRunning && _elapsedSeconds == 0 && _secondsLeft == 0) {
        _initTimer();
      }
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void _tick(Timer t) {
    if (!mounted) { t.cancel(); return; }
    setState(() {
      _elapsedSeconds++;
      switch (_mode) {
        case WodMode.amrap:
          if (_secondsLeft > 0) {
            _secondsLeft--;
            if (_secondsLeft == 0) {
              _timer?.cancel();
              _isRunning = false;
              _isFinished = true;
              _showPostSession();
            }
          }
          break;
        case WodMode.forTime:
          _secondsLeft++;
          if (_forTimeCompleted >= _forTimeRounds) {
            _timer?.cancel();
            _isRunning = false;
            _isFinished = true;
            _showPostSession();
          }
          break;
        case WodMode.emom:
          _secondsLeft--;
          if (_secondsLeft <= 0) {
            _vibrate();
            if (_emomCurrentMin >= _emomMins) {
              _timer?.cancel();
              _isRunning = false;
              _isFinished = true;
              _showPostSession();
            } else {
              _emomCurrentMin++;
              _secondsLeft = 60;
            }
          }
          break;
        case WodMode.tabata:
          _secondsLeft--;
          if (_secondsLeft <= 0) {
            _vibrate();
            if (_tabataWorkPhase) {
              _tabataWorkPhase = false;
              _secondsLeft = _tabataRestSec;
            } else {
              if (_tabataCurrentRound >= _tabataRounds) {
                _timer?.cancel();
                _isRunning = false;
                _isFinished = true;
                _showPostSession();
              } else {
                _tabataCurrentRound++;
                _tabataWorkPhase = true;
                _secondsLeft = _tabataWorkSec;
              }
            }
          }
          break;
      }
    });
  }

  void _vibrate() async {
    final has = (await Vibration.hasVibrator()) == true;
    if (has) Vibration.vibrate(duration: 300);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isFinished = false;
      _elapsedSeconds = 0;
      _secondsLeft = 0;
      _amrapRounds = 0;
      _amrapRepsExtra = 0;
      _forTimeCompleted = 0;
      _emomCurrentMin = 1;
      _tabataCurrentRound = 1;
      _tabataWorkPhase = true;
    });
  }

  void _showPostSession() async {
    final result = _buildResult();
    final prKey = '${_mode.name}_result';

    double prValue = 0;
    bool isPR = false;
    switch (_mode) {
      case WodMode.amrap:
        prValue = (_amrapRounds * 100 + _amrapRepsExtra).toDouble();
        isPR = await TrackerStorage.updatePRIfBetter('wod_$_amrapMins', prKey, prValue);
        break;
      case WodMode.forTime:
        prValue = _elapsedSeconds.toDouble();
        isPR = await TrackerStorage.updatePRIfBetter(
            'wod_ft_$_forTimeRounds', prKey, prValue, lowerIsBetter: true);
        break;
      case WodMode.emom:
        prValue = _emomCurrentMin.toDouble();
        isPR = await TrackerStorage.updatePRIfBetter('wod_emom_$_emomMins', prKey, prValue);
        break;
      case WodMode.tabata:
        prValue = _tabataCurrentRound.toDouble();
        isPR = await TrackerStorage.updatePRIfBetter('wod_tabata', prKey, prValue);
        break;
    }

    if (mounted) setState(() {});

    final sessionData = {
      'mode': _mode.name,
      'result': result,
      'elapsedSeconds': _elapsedSeconds,
      'isNewPR': isPR,
    };

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostSessionSheet(
        data: sessionData,
        isPR: isPR,
        onSave: () async {
          await TrackerStorage.saveSession('wod', sessionData);
          if (mounted) Navigator.of(context).pop();
        },
        onShare: () {
          Navigator.of(context).pop();
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => TrackerShareScreen(
              trackerType: 'wod',
              stats: {
                'Modalidade': 'Crossfit',
                'Modo': _modeLabel(_mode),
                'Resultado': result,
              },
              modality: 'Crossfit',
              showPR: isPR,
            ),
          ));
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  String _buildResult() {
    switch (_mode) {
      case WodMode.amrap:
        return '$_amrapRounds rounds + $_amrapRepsExtra reps';
      case WodMode.forTime:
        final m = _elapsedSeconds ~/ 60;
        final s = _elapsedSeconds % 60;
        return '${m}:${s.toString().padLeft(2, '0')}';
      case WodMode.emom:
        return '$_emomCurrentMin / $_emomMins min';
      case WodMode.tabata:
        return '$_tabataCurrentRound / $_tabataRounds rounds';
    }
  }

  String _modeLabel(WodMode m) {
    switch (m) {
      case WodMode.amrap: return 'AMRAP';
      case WodMode.forTime: return 'For Time';
      case WodMode.emom: return 'EMOM';
      case WodMode.tabata: return 'Tabata';
    }
  }

  String get _timerDisplay {
    int sec;
    switch (_mode) {
      case WodMode.forTime:
        sec = _elapsedSeconds;
        break;
      default:
        sec = _secondsLeft;
    }
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
        title: const Text('WOD TIMER',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildModeSelector(),
            const SizedBox(height: 20),
            _buildTimerDisplay(),
            const SizedBox(height: 20),
            if (!_isRunning && !_isFinished) _buildConfig(),
            if (!_isRunning && !_isFinished) const SizedBox(height: 20),
            _buildInSessionControls(),
            const SizedBox(height: 24),
            _buildPlayControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    final modes = [WodMode.amrap, WodMode.forTime, WodMode.emom, WodMode.tabata];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3,
      children: modes.map((m) {
        final sel = m == _mode;
        return GestureDetector(
          onTap: () { if (!_isRunning) { setState(() { _mode = m; _reset(); }); } },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: sel ? _gold : _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel ? _gold : Colors.white.withOpacity(0.08)),
            ),
            child: Center(
              child: Text(_modeLabel(m),
                  style: TextStyle(
                      color: sel ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimerDisplay() {
    String phaseLabel = '';
    Color phaseColor = _gold;
    switch (_mode) {
      case WodMode.emom:
        phaseLabel = 'Minuto $_emomCurrentMin de $_emomMins';
        break;
      case WodMode.tabata:
        phaseLabel = _tabataWorkPhase ? 'TRABALHO' : 'DESCANSO';
        phaseColor = _tabataWorkPhase ? _gold : Colors.blueAccent;
        break;
      default:
        phaseLabel = _modeLabel(_mode).toUpperCase();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: phaseColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: phaseColor.withOpacity(0.3)),
            ),
            child: Text(phaseLabel,
                style: TextStyle(
                    color: phaseColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(height: 20),
          Text(_timerDisplay,
              style: const TextStyle(
                  color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          if (_mode == WodMode.amrap) ...[
            Text('$_amrapRounds rounds completos',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ],
          if (_mode == WodMode.forTime) ...[
            Text('$_forTimeCompleted / $_forTimeRounds rounds',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _buildConfig() {
    switch (_mode) {
      case WodMode.amrap:
        return _configRow('Duração (min)', _amrapMins, 5, 90,
            (v) => setState(() => _amrapMins = v));
      case WodMode.forTime:
        return _configRow('Número de rounds', _forTimeRounds, 1, 50,
            (v) => setState(() => _forTimeRounds = v));
      case WodMode.emom:
        return _configRow('Duração (min)', _emomMins, 5, 60,
            (v) => setState(() => _emomMins = v));
      case WodMode.tabata:
        return Column(
          children: [
            _configRow('Rounds', _tabataRounds, 4, 20,
                (v) => setState(() => _tabataRounds = v)),
            const SizedBox(height: 8),
            _configRow('Trabalho (seg)', _tabataWorkSec, 10, 60,
                (v) => setState(() => _tabataWorkSec = v)),
            const SizedBox(height: 8),
            _configRow('Descanso (seg)', _tabataRestSec, 5, 30,
                (v) => setState(() => _tabataRestSec = v)),
          ],
        );
    }
  }

  Widget _configRow(
      String label, int value, int min, int max, ValueChanged<int> onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          Row(
            children: [
              _iconBtn(Icons.remove, () { if (value > min) onChange(value - 1); }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$value',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              _iconBtn(Icons.add, () { if (value < max) onChange(value + 1); }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInSessionControls() {
    if (!_isRunning) return const SizedBox.shrink();
    switch (_mode) {
      case WodMode.amrap:
        return Row(
          children: [
            Expanded(
              child: _inSessionBtn('+ ROUND', () => setState(() => _amrapRounds++)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _inSessionBtn('+ REP', () => setState(() => _amrapRepsExtra++)),
            ),
          ],
        );
      case WodMode.forTime:
        return _inSessionBtn(
          '+ ROUND COMPLETO',
          () {
            setState(() => _forTimeCompleted++);
            if (_forTimeCompleted >= _forTimeRounds) {
              _timer?.cancel();
              setState(() { _isRunning = false; _isFinished = true; });
              _showPostSession();
            }
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _inSessionBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildPlayControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
            child: const Icon(Icons.refresh, color: Colors.white60, size: 24),
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: _isFinished ? null : _startStop,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _isFinished ? Colors.grey.withOpacity(0.3) : _gold,
              shape: BoxShape.circle,
              boxShadow: [
                if (!_isFinished) BoxShadow(color: _gold.withOpacity(0.4), blurRadius: 16),
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
        const SizedBox(width: 56),
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
  final bool isPR;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onClose;

  const _PostSessionSheet({
    required this.data,
    required this.isPR,
    required this.onSave,
    required this.onShare,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final min = (data['elapsedSeconds'] as int) ~/ 60;
    final modeLabels = {
      'amrap': 'AMRAP',
      'forTime': 'For Time',
      'emom': 'EMOM',
      'tabata': 'Tabata',
    };

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
              const Text('WOD CONCLUÍDO',
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
                  child: const Text('PR', style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _row('Modo', modeLabels[data['mode']] ?? data['mode']),
          _row('Resultado', data['result']),
          _row('Tempo total', '${min}min'),
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
