import 'dart:math';
import 'package:flutter/material.dart';

class LevelUpModal extends StatefulWidget {
  final int fromLevel;
  final int toLevel;

  const LevelUpModal({
    super.key,
    required this.fromLevel,
    required this.toLevel,
  });

  static Future<void> show(
    BuildContext context, {
    required int fromLevel,
    required int toLevel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => LevelUpModal(fromLevel: fromLevel, toLevel: toLevel),
    );
  }

  @override
  State<LevelUpModal> createState() => _LevelUpModalState();
}

class _LevelUpModalState extends State<LevelUpModal>
    with TickerProviderStateMixin {
  static const _gold = Color(0xFFD4AF37);
  static const _goldBright = Color(0xFFFFD700);

  late final AnimationController _modalCtrl;
  late final AnimationController _particleCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  final _rand = Random();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _modalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnim = CurvedAnimation(
      parent: _modalCtrl,
      curve: Curves.elasticOut,
    );

    _fadeAnim = CurvedAnimation(
      parent: _modalCtrl,
      curve: Curves.easeOut,
    );

    _particles = List.generate(26, (_) {
      final angle = _rand.nextDouble() * 2 * pi;
      final dist = 60.0 + _rand.nextDouble() * 110;
      return _Particle(
        color: [
          _goldBright,
          Colors.orange,
          Colors.white,
          const Color(0xFFFFB700),
          _gold,
        ][_rand.nextInt(5)],
        angle: angle,
        distance: dist,
        size: 4.0 + _rand.nextDouble() * 4,
        isCircle: _rand.nextBool(),
      );
    });

    _modalCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _particleCtrl.forward();
    });
  }

  @override
  void dispose() {
    _modalCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Modal card (abaixo das partículas)
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF2f2f2f)),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTop(),
                      _buildBody(context),
                    ],
                  ),
                ),
              ),

              // Partículas sobre o modal
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) {
                  final t = _particleCtrl.value;
                  return SizedBox(
                    height: 200,
                    child: Stack(
                      children: _particles.map((p) {
                        final x = cos(p.angle) * p.distance * t;
                        final y = sin(p.angle) * p.distance * t;
                        final opacity = (1.0 - t * 1.2).clamp(0.0, 1.0);
                        return Positioned(
                          top: 60 + y,
                          left: 150 + x,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: p.size,
                              height: p.size,
                              decoration: BoxDecoration(
                                color: p.color,
                                shape: p.isCircle
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                                borderRadius: p.isCircle
                                    ? null
                                    : BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTop() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFb8860b),
            Color(0xFFFFD700),
            Color(0xFFFFA500),
            Color(0xFFb8860b),
          ],
        ),
      ),
      child: Column(
        children: const [
          Text('🏆', style: TextStyle(fontSize: 52)),
          SizedBox(height: 8),
          Text(
            'BLDR CLUB',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: Color(0x99000000),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Level Up!',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        children: [
          // Transição de nível
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _levelCircle(widget.fromLevel, isNew: false),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.arrow_forward,
                    color: Color(0xFFFFD700), size: 22),
              ),
              _levelCircle(widget.toLevel, isNew: true),
            ],
          ),
          const SizedBox(height: 20),

          // Mensagem
          Text(
            'Você alcançou o Nível ${widget.toLevel}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Sua consistência está pagando.\nContinue assim e domine o ranking.',
            style: TextStyle(
                color: Colors.grey[500], fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Tag XP
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.08),
              border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⚡', style: TextStyle(fontSize: 15)),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '+500 XP desbloqueados no próximo nível',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Botão
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelCircle(int level, {required bool isNew}) {
    return Container(
      width: isNew ? 72 : 64,
      height: isNew ? 72 : 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isNew ? const Color(0xFF2a2000) : const Color(0xFF1a1a1a),
        border: Border.all(
          color: isNew ? const Color(0xFFFFD700) : const Color(0xFF333333),
          width: isNew ? 2.5 : 2,
        ),
        boxShadow: isNew
            ? [
                BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 20),
                BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    blurRadius: 40),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            color: isNew ? const Color(0xFFFFD700) : Colors.grey[600],
            fontSize: isNew ? 24 : 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final Color color;
  final double angle;
  final double distance;
  final double size;
  final bool isCircle;

  const _Particle({
    required this.color,
    required this.angle,
    required this.distance,
    required this.size,
    required this.isCircle,
  });
}
