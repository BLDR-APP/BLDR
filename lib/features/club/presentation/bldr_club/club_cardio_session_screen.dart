import 'dart:async';
import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CLUB CARDIO SESSION SCREEN
//  Full-screen timer for cardio sessions (running, HIIT, cycling, free).
//  On finish → saves to bldr_club.user_activities and pops with `true`.
// ─────────────────────────────────────────────────────────────────────────────

class ClubCardioSessionScreen extends StatefulWidget {
  const ClubCardioSessionScreen({
    super.key,
    required this.label,
    required this.activityType,
    this.targetMinutes,
  });

  final String label;
  final String activityType;
  final int? targetMinutes;

  @override
  State<ClubCardioSessionScreen> createState() =>
      _ClubCardioSessionScreenState();
}

class _ClubCardioSessionScreenState extends State<ClubCardioSessionScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── palette ────────────────────────────────────────────────────────────────
  static const _gold = Color(0xFFD4AF37);
  static const _goldBg = Color(0x1FD4AF37);
  static const _borderGold = Color(0x40D4AF37);
  static const _bg = Color(0xFF111110);
  static const _surface = Color(0xFF1A1916);
  static const _card = Color(0xFF1E1C18);
  static const _muted = Color(0xFF888070);

  // ── state ──────────────────────────────────────────────────────────────────
  Timer? _ticker;
  late DateTime _startTime;
  int _elapsed = 0; // seconds — recalculado pelo relógio real
  bool _saving = false;

  // ── animations ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTime = DateTime.now();
    _startTicker();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _elapsed = DateTime.now().difference(_startTime).inSeconds;
      });
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime).inSeconds;
        });
      }
    });
  }

  String _fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  IconData get _icon {
    switch (widget.activityType.toLowerCase()) {
      case 'corrida':
        return Icons.directions_run_rounded;
      case 'hiit':
        return Icons.bolt_rounded;
      case 'ciclismo':
        return Icons.directions_bike_rounded;
      case 'yoga':
        return Icons.self_improvement_rounded;
      case 'pilates':
        return Icons.accessibility_new_rounded;
      default:
        return Icons.timer_rounded;
    }
  }

  double? get _progress {
    if (widget.targetMinutes == null) return null;
    return (_elapsed / (widget.targetMinutes! * 60)).clamp(0.0, 1.0);
  }

  // ── actions ────────────────────────────────────────────────────────────────

  Future<void> _finish() async {
    if (_saving) return;

    // ── Minimum time guard (only when user is in an active challenge) ────────
    if (widget.targetMinutes != null &&
        _elapsed < widget.targetMinutes! * 60) {
      final inChallenge =
          (await getIt<IsUserInActiveChallenge>()()).valueOrNull ?? false;
      if (inChallenge) {
        if (!mounted) return;
        final remaining = widget.targetMinutes! * 60 - _elapsed;
        final remainingMin = (remaining / 60).ceil();
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Tempo mínimo não atingido',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
            content: Text(
              'Esta atividade requer pelo menos ${widget.targetMinutes} min '
              'para ser registrada no desafio. '
              'Faltam aproximadamente $remainingMin min.',
              style: const TextStyle(
                  color: _muted, fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Continuar sessão',
                    style: TextStyle(color: _gold)),
              ),
            ],
          ),
        );
        return; // timer keeps running
      }
    }

    _ticker?.cancel();
    setState(() => _saving = true);
    try {
      final result = await getIt<LogClubCardio>()(
        label: widget.label,
        activityType: widget.activityType,
        durationSeconds: _elapsed,
      );
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);
      if (!mounted) return;
      _showCompletionSheet();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _startTicker();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: const Color(0xFFC84040),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCompletionSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CardioCompletionSheet(
        activityLabel: widget.label,
        activityType: widget.activityType,
        timeLabel: _fmt(_elapsed),
        icon: _icon,
        onFinish: () {
          Navigator.pop(context); // fecha sheet
          Navigator.pop(context, true); // fecha tela de sessão
        },
      ),
    );
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sair da sessão?',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
        content: const Text(
          'A sessão não será salva se você sair agora.',
          style: TextStyle(color: _muted, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Continuar', style: TextStyle(color: _gold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sair',
              style: TextStyle(
                  color: Color(0xFFC84040),
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit() && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (await _confirmExit() && mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.08)),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Em andamento',
                            style: TextStyle(
                                color: _muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            widget.label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    // CLUB badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CLUB',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // ── main content ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pulsing icon ring
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _goldBg,
                          border: Border.all(color: _borderGold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withOpacity(0.18),
                              blurRadius: 36,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(_icon, color: _gold, size: 58),
                      ),
                    ),
                    const SizedBox(height: 44),

                    // Elapsed timer
                    Text(
                      _fmt(_elapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 58,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.targetMinutes != null
                          ? 'Meta: ${widget.targetMinutes} min'
                          : 'Sessão livre',
                      style: const TextStyle(color: _muted, fontSize: 14),
                    ),

                    // Progress bar (only when target is set)
                    if (progress != null) ...[
                      const SizedBox(height: 28),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 48),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: _card,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        _gold),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(progress * 100).toInt()}% concluído',
                              style: const TextStyle(
                                  color: _muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── placeholder para métricas futuras ────────────────
                    // TODO: distância, frequência cardíaca, calorias
                  ],
                ),
              ),

              // ── finish button ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          _gold.withOpacity(0.5),
                      padding:
                          const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Finalizar Sessão',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  COMPLETION SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CardioCompletionSheet extends StatefulWidget {
  const _CardioCompletionSheet({
    required this.activityLabel,
    required this.activityType,
    required this.timeLabel,
    required this.icon,
    required this.onFinish,
  });

  final String activityLabel;
  final String activityType;
  final String timeLabel;
  final IconData icon;
  final VoidCallback onFinish;

  @override
  State<_CardioCompletionSheet> createState() =>
      _CardioCompletionSheetState();
}

class _CardioCompletionSheetState extends State<_CardioCompletionSheet>
    with SingleTickerProviderStateMixin {
  static const _gold       = Color(0xFFD4AF37);
  static const _goldBg     = Color(0x1FD4AF37);
  static const _borderGold = Color(0x40D4AF37);
  static const _muted      = Color(0xFF888070);

  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _typeLabel() {
    switch (widget.activityType.toLowerCase()) {
      case 'corrida':   return 'Corrida';
      case 'hiit':      return 'HIIT';
      case 'ciclismo':  return 'Ciclismo';
      case 'yoga':      return 'Yoga';
      case 'pilates':   return 'Pilates';
      default:          return 'Livre';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle visual
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _muted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 28),

          // Ícone animado
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _goldBg,
                border: Border.all(color: _borderGold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.28),
                    blurRadius: 36,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: _gold, size: 42),
            ),
          ),
          const SizedBox(height: 20),

          // Título + nome
          FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                const Text(
                  'Sessão Concluída!',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.activityLabel,
                  style: const TextStyle(color: _muted, fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),

                // Stats
                Row(
                  children: [
                    _CardioStatCard(
                        label: 'Duração', value: widget.timeLabel),
                    const SizedBox(width: 12),
                    _CardioStatCard(
                        label: 'Modalidade', value: _typeLabel()),
                  ],
                ),
                const SizedBox(height: 28),

                // Botão
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onFinish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      padding:
                          const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Finalizar',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardioStatCard extends StatelessWidget {
  const _CardioStatCard({required this.label, required this.value});
  final String label;
  final String value;

  static const _gold       = Color(0xFFD4AF37);
  static const _goldBg     = Color(0x1FD4AF37);
  static const _borderGold = Color(0x40D4AF37);
  static const _muted      = Color(0xFF888070);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _goldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderGold),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
