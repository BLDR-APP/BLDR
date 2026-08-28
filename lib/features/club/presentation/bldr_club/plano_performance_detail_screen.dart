import 'package:flutter/material.dart';
// Certifique-se de que o caminho para esportes_screen.dart está correto
import 'package:bldr_fitness/features/club/presentation/bldr_club/esportes_screen.dart';

class PlanoPerformanceDetailScreen extends StatefulWidget {
  final PerformancePlan plan;

  const PlanoPerformanceDetailScreen({
    super.key,
    required this.plan,
  });

  @override
  State<PlanoPerformanceDetailScreen> createState() =>
      _PlanoPerformanceDetailScreenState();
}

class _PlanoPerformanceDetailScreenState
    extends State<PlanoPerformanceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _planJson;

  // F8: estado local de check por exercício — Map<'dia_N:index', bool>
  final Map<String, bool> _checked = {};

  // Cores do BLDR
  static const Color bldrGold = Color(0xFFD4AF37);
  static const Color bldrBlack = Color(0xFF000000);
  static const Color cardBg = Color(0xFF111111);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _planJson = widget.plan.planJson;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _checkKey(String dayKey, int index) => '$dayKey:$index';

  bool _isDayComplete(String dayKey) {
    final exercicios = (_planJson[dayKey] as Map<String, dynamic>?)?['exercicios'] as List? ?? [];
    if (exercicios.isEmpty) return false;
    return List.generate(exercicios.length, (i) => _checked[_checkKey(dayKey, i)] == true)
        .every((v) => v);
  }

  int _doneCount(String dayKey) {
    final exercicios = (_planJson[dayKey] as Map<String, dynamic>?)?['exercicios'] as List? ?? [];
    return List.generate(exercicios.length, (i) => _checked[_checkKey(dayKey, i)] == true)
        .where((v) => v)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bldrBlack,
      body: Stack(
        children: [
          // Fundo Radial Sutil
          const _GoldRadialBackground(),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDayWorkoutList('dia_1'),
                      _buildDayWorkoutList('dia_2'),
                      _buildDayWorkoutList('dia_3'),
                      _buildDayWorkoutList('dia_4'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. HEADER CINEMÁTICO
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Botão Voltar Estilizado
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          // Título do Esporte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PROTOCOLO",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.plan.sport.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // Ícone Decorativo
          Icon(Icons.fitness_center, color: bldrGold.withOpacity(0.5), size: 28),
        ],
      ),
    );
  }

  // 2. TAB BAR MODERNA
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: bldrGold,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'DIA 01'),
          Tab(text: 'DIA 02'),
          Tab(text: 'DIA 03'),
          Tab(text: 'DIA 04'),
        ],
      ),
    );
  }

  Widget _buildDayWorkoutList(String dayKey) {
    final dayData = _planJson[dayKey] as Map<String, dynamic>?;

    if (dayData == null || dayData.isEmpty) {
      return const Center(child: Text('Descanso ou Dados ausentes.', style: TextStyle(color: Colors.white54)));
    }

    final String foco = dayData['foco'] ?? 'Geral';
    final List exercicios = dayData['exercicios'] as List? ?? [];
    final total = exercicios.length;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          physics: const BouncingScrollPhysics(),
          children: [
            // F8: contador de progresso do dia
            if (total > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      '${_doneCount(dayKey)} de $total exercícios',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: total > 0 ? _doneCount(dayKey) / total : 0.0,
                          backgroundColor: Colors.white12,
                          color: bldrGold,
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Badge de foco
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: bldrGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bldrGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.track_changes, color: bldrGold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "FOCO: ${foco.toUpperCase()}",
                      style: const TextStyle(
                        color: bldrGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // F8: cards com checkbox
            ...List.generate(exercicios.length, (i) {
              final key = _checkKey(dayKey, i);
              final done = _checked[key] == true;
              return _buildExerciseCard(
                exercicios[i] as Map<String, dynamic>,
                checkKey: key,
                done: done,
                onToggle: () => setState(() => _checked[key] = !done),
              );
            }),

            const SizedBox(height: 40),
          ],
        ),

        // F8: botão fixo no rodapé
        if (total > 0)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _isDayComplete(dayKey)
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Dia concluído!',
                            style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      // Marca todos os exercícios do dia como concluídos
                      setState(() {
                        for (int i = 0; i < total; i++) {
                          _checked[_checkKey(dayKey, i)] = true;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: bldrGold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _doneCount(dayKey) > 0
                                ? 'Continuar — ${total - _doneCount(dayKey)} restantes'
                                : 'Iniciar dia',
                            style: const TextStyle(
                                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  // 4. CARD DE EXERCÍCIO com F8 checkbox
  Widget _buildExerciseCard(
    Map<String, dynamic> exercicio, {
    required String checkKey,
    required bool done,
    required VoidCallback onToggle,
  }) {
    final String nome = exercicio['nome'] ?? 'Exercício';
    final String series = exercicio['series'] ?? '-';
    final String reps = exercicio['reps'] ?? '-';
    final String descanso = exercicio['descanso'] ?? '-';
    final String observacoes = exercicio['observacoes'] ?? '';

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedOpacity(
        opacity: done ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? bldrGold.withOpacity(0.4) : Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // F8: linha de título com checkbox
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    done ? '$nome ✓' : nome,
                    style: TextStyle(
                      color: done ? bldrGold : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: bldrGold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? bldrGold : Colors.transparent,
                      border: Border.all(
                        color: done ? bldrGold : Colors.white38,
                        width: 2,
                      ),
                    ),
                    child: done
                        ? const Icon(Icons.check, color: Colors.black, size: 16)
                        : null,
                  ),
                ),
              ],
            ),
          ),

          // GRID DE STATS (SÉRIES | REPS | DESCANSOS)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              // EXPANDED resolve o overflow dividindo o espaço igualmente
              children: [
                Expanded(child: _buildStatItem(Icons.repeat, "SÉRIES", series)),
                Container(
                    width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                Expanded(child: _buildStatItem(Icons.fitness_center, "REPS", reps)),
                Container(
                    width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                Expanded(child: _buildStatItem(Icons.timer_outlined, "PAUSA", descanso)),
              ],
            ),
          ),

          // Instruções / Observações
          if (observacoes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.white.withOpacity(0.4), size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      observacoes,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ), // Container
      ), // AnimatedOpacity
    ); // GestureDetector
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: bldrGold, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: bldrGold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center, // Centraliza texto longo
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} // <--- A CHAVE QUE FALTAVA ESTÁ AQUI

// ==========================================
// CLASSES AUXILIARES (FORA DA CLASSE DE STATE)
// ==========================================

class _GoldRadialBackground extends StatelessWidget {
  const _GoldRadialBackground();
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(children: [
          _RadialBlob(top: -100, right: -100, opacity: 0.25),
          _RadialBlob(bottom: -100, left: -50, opacity: 0.15),
        ]),
      ),
    );
  }
}

class _RadialBlob extends StatelessWidget {
  final double? top, bottom, left, right;
  final double opacity;
  const _RadialBlob({this.top, this.bottom, this.left, this.right, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 300, height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [const Color(0xFFD4AF37).withOpacity(opacity), Colors.transparent],
          ),
        ),
      ),
    );
  }
}