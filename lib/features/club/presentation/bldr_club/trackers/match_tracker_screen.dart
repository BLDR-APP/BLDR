import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/entities/club_community.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/tracker_storage.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/tracker_share_screen.dart';

const _gold = Color(0xFFD4AF37);
const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);

class MatchTrackerScreen extends StatefulWidget {
  final String? initialModality;
  const MatchTrackerScreen({super.key, this.initialModality});

  @override
  State<MatchTrackerScreen> createState() => _MatchTrackerScreenState();
}

class _MatchTrackerScreenState extends State<MatchTrackerScreen> {
  // AJUSTE 3 — chips expandidos + Beach Tennis
  final _modalities = ['Tênis', 'Padel', 'Beach Tennis'];
  late String _modality;

  // Stopwatch
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  Timer? _timer;

  // AJUSTE 1 — Sets: lista de sets, o último é sempre o ativo.
  // Cada entry: {'me': int, 'opp': int, 'closed': bool}
  List<Map<String, dynamic>> _sets = [
    {'me': 0, 'opp': 0, 'closed': false}
  ];

  // Intensity 1-10
  double _intensity = 5;

  // History
  List<MatchSession> _history = [];
  String? _historyFilter; // null = all

  @override
  void initState() {
    super.initState();
    _loadModality(widget.initialModality);
    _loadHistory();
  }

  Future<void> _loadModality(String? initial) async {
    if (initial != null && _modalities.contains(initial)) {
      setState(() => _modality = initial);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('match_tracker_modality') ?? 'Tênis';
    setState(() => _modality =
        _modalities.contains(saved) ? saved : 'Tênis');
  }

  Future<void> _saveModality(String m) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('match_tracker_modality', m);
  }

  Future<void> _loadHistory() async {
    try {
      final result = await getIt<GetMatchHistory>()();
      final sessions = result.valueOrNull;
      if (sessions != null && mounted) {
        setState(() => _history = sessions);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStop() {
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

  void _reset() {
    _timer?.cancel();
    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
      _sets = [{'me': 0, 'opp': 0, 'closed': false}];
      _intensity = 5;
    });
  }

  void _endSession() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    _showPostSession();
  }

  // AJUSTE 1 — fecha o set atual e abre um novo
  void _addSet() {
    setState(() {
      // fecha o set ativo (último)
      _sets[_sets.length - 1]['closed'] = true;
      // abre novo set
      _sets.add({'me': 0, 'opp': 0, 'closed': false});
    });
  }

  void _updateScore(int side, int delta) {
    // Só o último set (ativo) pode ser editado
    final i = _sets.length - 1;
    setState(() {
      final key = side == 0 ? 'me' : 'opp';
      final v = ((_sets[i][key] as int) + delta).clamp(0, 99);
      _sets[i][key] = v;
    });
  }

  // AJUSTE 2 — label dinâmico
  String get _stopwatchLabel {
    if (!_isRunning && _elapsedSeconds == 0) return 'AGUARDANDO INÍCIO';
    if (_isRunning) return 'SESSÃO EM ANDAMENTO';
    return 'PAUSADO';
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

  // AJUSTE 1 — apenas sets com pelo menos um ponto registrado
  List<Map<String, dynamic>> get _validSets =>
      _sets.where((s) => (s['me'] as int) > 0 || (s['opp'] as int) > 0).toList();

  String get _result {
    int meWon = 0, oppWon = 0;
    for (final s in _validSets) {
      final me = s['me'] as int;
      final opp = s['opp'] as int;
      if (me > opp) meWon++;
      else if (opp > me) oppWon++;
    }
    if (meWon > oppWon) return 'Vitória';
    if (oppWon > meWon) return 'Derrota';
    return 'Empate';
  }

  // AJUSTE 2 — subtítulo hero: "Tênis · Vitória · 2 sets a 1"
  String _buildHeroSubtitle(int meWon, int oppWon) {
    final result = _result;
    return '$_modality · $result · $meWon sets a $oppWon';
  }

  Future<void> _showPostSession() async {
    final valid = _validSets;
    int meWon = 0, oppWon = 0;
    for (final s in valid) {
      if ((s['me'] as int) > (s['opp'] as int)) meWon++;
      else if ((s['opp'] as int) > (s['me'] as int)) oppWon++;
    }

    // Check if there's already an active protocol for this sport
    final hasActiveProtocol =
        await TrackerStorage.hasActivePlanForSport(_modality);

    final sessionData = {
      'modality': _modality,
      'elapsedSeconds': _elapsedSeconds,
      'sets': valid.map((s) => {'me': s['me'], 'opp': s['opp']}).toList(),
      'result': _result,
      'intensity': _intensity.round(),
      'heroSubtitle': _buildHeroSubtitle(meWon, oppWon),
    };

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostSessionSheet(
        data: sessionData,
        hasActiveProtocol: hasActiveProtocol,
        onSave: () async {
          await TrackerStorage.saveSession('match_$_modality', sessionData);
          // F18: persistir também no Supabase
          unawaited(getIt<SaveMatchSession>()(
            modality: _modality,
            result: _result,
            sets: valid.map((s) => {'me': s['me'], 'opp': s['opp']}).toList(),
            intensity: _intensity.round(),
            durationSec: _elapsedSeconds,
          ).then((_) => _loadHistory()));
          if (mounted) Navigator.of(context).pop();
        },
        onShare: () {
          Navigator.of(context).pop();
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => TrackerShareScreen(
              trackerType: 'match',
              stats: _buildShareStats(sessionData),
              modality: _modality,
              result: _result,
              sets: (sessionData['sets'] as List)
                  .map((s) => {'me': s['me'] as int, 'opp': s['opp'] as int})
                  .toList(),
            ),
          ));
        },
        onOpenProtocol: () {
          // Pop the bottom sheet, then pop the tracker → lands on EsportesScreen
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  Map<String, String> _buildShareStats(Map<String, dynamic> d) {
    final min = (d['elapsedSeconds'] as int) ~/ 60;
    return {
      'Modalidade': d['modality'],
      'Duração': '${min}min',
      'Resultado': d['result'],
      'Intensidade': '${d['intensity']}/10',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('MATCH TRACKER',
            style: TextStyle(
                fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildModalitySelector(),
            const SizedBox(height: 20),
            _buildStopwatch(),
            const SizedBox(height: 20),
            _buildSetsScoreboard(),
            const SizedBox(height: 20),
            _buildIntensitySlider(),
            const SizedBox(height: 24),
            _buildControls(),
            const SizedBox(height: 32),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  // AJUSTE 3 — chips com persistência
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
            onTap: () {
              setState(() => _modality = m);
              _saveModality(m);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? _gold : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? _gold : Colors.white.withOpacity(0.12)),
              ),
              child: Text(m,
                  style: TextStyle(
                      color: sel ? Colors.black : Colors.white70,
                      fontWeight:
                          sel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  // AJUSTE 2 — label dinâmico
  Widget _buildStopwatch() {
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
          Text(_stopwatchLabel,
              style: TextStyle(
                  color: _isRunning
                      ? _gold.withOpacity(0.9)
                      : Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_elapsed,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
        ],
      ),
    );
  }

  // AJUSTE 1 — sets com histórico fixo + set ativo
  Widget _buildSetsScoreboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Expanded(
                  child: Text('VOCÊ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _gold,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold))),
              const SizedBox(width: 60),
              Expanded(
                  child: Text('ADVERSÁRIO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),

          // Sets list
          ...List.generate(_sets.length, (i) {
            final isClosed = _sets[i]['closed'] as bool;
            return isClosed
                ? _buildClosedSetRow(i)
                : _buildActiveSetRow(i);
          }),

          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addSet,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Adicionar set'),
            style: TextButton.styleFrom(foregroundColor: _gold),
          ),
        ],
      ),
    );
  }

  // Set fechado — linha de histórico fixa, sem controles
  Widget _buildClosedSetRow(int i) {
    final me = _sets[i]['me'] as int;
    final opp = _sets[i]['opp'] as int;
    final meWins = me > opp;
    final oppWins = opp > me;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text('Set ${i + 1}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11,
                    letterSpacing: 0.5)),
            const Spacer(),
            Text('$me',
                style: TextStyle(
                    color: meWins ? _gold : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('×',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 16)),
            ),
            Text('$opp',
                style: TextStyle(
                    color: oppWins ? _gold : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  // Set ativo — com controles +/-
  Widget _buildActiveSetRow(int i) {
    final me = _sets[i]['me'] as int;
    final opp = _sets[i]['opp'] as int;
    final meWins = me > opp;
    final oppWins = opp > me;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Label do set ativo
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _gold.withOpacity(0.3)),
                  ),
                  child: Text('SET ${i + 1} — EM ANDAMENTO',
                      style: const TextStyle(
                          color: _gold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Você
              Expanded(
                child: _scoreCellActive(
                  value: me,
                  isWinner: meWins,
                  onInc: () => _updateScore(0, 1),
                  onDec: () => _updateScore(0, -1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('×',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 20)),
              ),
              // Adversário
              Expanded(
                child: _scoreCellActive(
                  value: opp,
                  isWinner: oppWins,
                  onInc: () => _updateScore(1, 1),
                  onDec: () => _updateScore(1, -1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreCellActive({
    required int value,
    required bool isWinner,
    required VoidCallback onInc,
    required VoidCallback onDec,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _scoreBtn(Icons.remove, onDec),
        const SizedBox(width: 12),
        Text('$value',
            style: TextStyle(
                color: isWinner ? _gold : Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900)),
        const SizedBox(width: 12),
        _scoreBtn(Icons.add, onInc),
      ],
    );
  }

  Widget _scoreBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white54, size: 16),
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
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 13)),
              Text('${_intensity.round()}/10',
                  style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
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

  Widget _buildHistorySection() {
    final filtered = _historyFilter == null
        ? _history
        : _history.where((s) => s.modality == _historyFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('HISTÓRICO',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold)),
            Text('${_history.length} partidas',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 12),
        // Filter chips
        if (_history.isNotEmpty) ...[
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('Todas', null),
                ...<String>{for (final s in _history) s.modality}
                    .map((m) => _filterChip(m, m)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // List
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Nenhuma partida salva ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
            ),
          )
        else
          Column(
            children: filtered.take(20).map(_buildHistoryItem).toList(),
          ),
      ],
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _historyFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _historyFilter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _gold : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? _gold : Colors.white.withOpacity(0.1)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.black : Colors.white70,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12)),
      ),
    );
  }

  Widget _buildHistoryItem(MatchSession session) {
    final result = session.result == 'win'
        ? 'V'
        : session.result == 'loss'
            ? 'D'
            : 'E';
    final resultColor = session.result == 'win'
        ? const Color(0xFF4CAF50)
        : session.result == 'loss'
            ? const Color(0xFFEF5350)
            : Colors.white70;
    final setsLabel = session.sets
        .map((s) => '${s['me']}-${s['opp']}')
        .join(', ');
    final timeAgo = _timeAgo(session.playedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: resultColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(result,
                    style: TextStyle(
                        color: resultColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.modality,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (setsLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(setsLabel,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12)),
                  ],
                ],
              ),
            ),
            Text(timeAgo,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}sem atrás';
    if (diff.inDays >= 1) return 'há ${diff.inDays}d';
    if (diff.inHours >= 1) return 'há ${diff.inHours}h';
    return 'agora';
  }

  Widget _buildControls() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: Icon(
                _isRunning ? Icons.pause : Icons.play_arrow,
                size: 20),
            label: Text(_isRunning
                ? 'Pausar'
                : (_elapsedSeconds == 0 ? 'Iniciar' : 'Retomar')),
            onPressed: _startStop,
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white54,
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
            padding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _endSession,
            child: const Text('Finalizar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

// ── Post-session ──────────────────────────────────────────────────────────────

class _PostSessionSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool hasActiveProtocol;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onOpenProtocol;
  final VoidCallback onClose;

  const _PostSessionSheet({
    required this.data,
    required this.hasActiveProtocol,
    required this.onSave,
    required this.onShare,
    required this.onOpenProtocol,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final totalSec = data['elapsedSeconds'] as int;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    final durationLabel = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final sets = data['sets'] as List;
    final result = data['result'] as String;
    final heroSubtitle = data['heroSubtitle'] as String? ?? result;

    final resultColor = result == 'Vitória'
        ? const Color(0xFF4CAF50)
        : result == 'Derrota'
            ? const Color(0xFFEF5350)
            : Colors.white70;



    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),

            // ── HERO BLOCK ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Text(durationLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Text(heroSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 13,
                          letterSpacing: 0.3)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── STATS GRID 2×2 ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                    child: _statCard('Sets jogados', '${sets.length}')),
                const SizedBox(width: 10),
                Expanded(
                    child: _statCard('Resultado', result,
                        valueColor: resultColor)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _statCard('Duração', '${m}min')),
                const SizedBox(width: 10),
                Expanded(
                    child: _statCard(
                        'Intensidade', '${data['intensity']}/10')),
              ],
            ),
            const SizedBox(height: 20),

            // ── SET SCORE LINES ────────────────────────────────────────────
            if (sets.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('PLACAR POR SET',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              ...List.generate(sets.length, (i) {
                final sv = sets[i];
                final me = sv['me'] as int;
                final opp = sv['opp'] as int;
                final meWinsSet = me > opp;
                final oppWinsSet = opp > me;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text('Set ${i + 1}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 12)),
                        const Spacer(),
                        Text('$me',
                            style: TextStyle(
                                color: meWinsSet ? _gold : Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('×',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 16)),
                        ),
                        Text('$opp',
                            style: TextStyle(
                                color: oppWinsSet ? _gold : Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
            ],

            // ── PROTOCOL STRIP ───────────────────────────────────────────
            // HAVOK_SPEC.md §7.3 — a faixa "Gerar ficha de treino com Havok"
            // não gerava nada (só fechava a sheet/tela). Removida; só resta
            // a faixa quando existe protocolo ativo de verdade para ver.
            if (hasActiveProtocol) ...[
              GestureDetector(
                onTap: onOpenProtocol,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _gold.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: _gold.withOpacity(0.8), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Protocolo ativo para ${data['modality']} — Ver detalhes',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: _gold.withOpacity(0.4), size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── BUTTONS ────────────────────────────────────────────────────
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
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15)),
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
      ),
    );
  }

  Widget _statCard(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
