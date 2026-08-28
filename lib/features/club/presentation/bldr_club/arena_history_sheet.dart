import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';

class ArenaHistorySheet extends StatelessWidget {
  final String arenaId;
  final String gameMode;

  const ArenaHistorySheet({super.key, required this.arenaId, this.gameMode = 'alpha'});

  // Função para buscar os dados dos posts + perfil do usuário
  Future<List<dynamic>> _fetchHistory() async {
      try {
      // 1. Busca os posts no schema 'bldr_club' (Sem tentar fazer o Join direto)
      final result = await getIt<ArenaRepository>().arenaHistory(arenaId);
      final combined = result.valueOrNull ?? <Map<String, dynamic>>[];

      return combined;
    } catch (e) {
      print("Erro ao buscar histórico: $e");
      throw e;
    }
  }

  // Função simples para deixar a data amigável ("Hoje, 14:30")
  String _formatTime(String isoString) {
    final date = DateTime.parse(isoString).toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);

    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (diff.inDays == 0 && now.day == date.day) return 'Hoje, $timeStr';
    if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day)) return 'Ontem, $timeStr';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} às $timeStr';
  }

  // Define um ícone baseado no tipo de atividade
  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'run': return Icons.directions_run;
      case 'cycle': return Icons.directions_bike;
      case 'swim': return Icons.pool;
      case 'crossfit': return Icons.local_fire_department;
      case 'sport': return Icons.sports_soccer;
      default: return Icons.fitness_center; // gym
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: gold),
                  SizedBox(width: 8),
                  Text(
                    "REGISTROS DA OPERAÇÃO",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const Divider(color: Colors.white24, height: 30),

          // Lista de Eventos (Timeline)
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _fetchHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: gold));
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text("Erro ao carregar: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,)
                  );
                }

                final posts = snapshot.data;
                if (posts == null || posts.isEmpty) {
                  return const Center(
                      child: Text("Nenhuma atividade registrada ainda.\nSeja o primeiro!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54)
                      )
                  );
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];

                    // --- EXTRAINDO OS DADOS ---
                    final title = post['activity_title'] ?? 'Treino concluído';
                    final type = post['activity_type'] ?? 'gym';
                    final dateStr = _formatTime(post['created_at']);

                    // Puxando do Join da tabela user_profiles
                    final userProfile = post['user_profiles'];
                    final userName = userProfile != null ? (userProfile['full_name'] ?? 'Atleta') : 'Atleta BLDR';
                    final avatarUrl = userProfile != null ? userProfile['avatar_url'] : null;

                    // Monta a string de detalhes (ex: "40 min • 300 kcal • 5 km")
                    List<String> details = [];
                    if (post['duration_minutes'] != null && post['duration_minutes'] > 0) details.add('${post['duration_minutes']} min');
                    if (post['calories'] != null && post['calories'] > 0) details.add('${post['calories']} kcal');
                    if (post['distance_km'] != null && post['distance_km'] > 0) details.add('${post['distance_km']} km');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12)
                      ),
                      child: Row(
                        children: [
                          // Foto do Usuário (ou ícone da atividade se não tiver foto)
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: gold.withOpacity(0.1),
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl == null
                                ? Icon(_getActivityIcon(type), color: gold, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 16),

                          // Dados do Post
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userName, style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(details.isNotEmpty ? details.join(' • ') : 'Atividade concluída',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12)
                                ),
                                const SizedBox(height: 4),
                                Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                              ],
                            ),
                          ),

                          _ScoreBadge(post: post, gameMode: gameMode),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final Map<String, dynamic> post;
  final String gameMode;
  const _ScoreBadge({required this.post, required this.gameMode});

  @override
  Widget build(BuildContext context) {
    switch (gameMode) {
      case 'roadrunner':
        final double km = (post['distance_km'] as num?)?.toDouble() ?? 0;
        if (km <= 0) return const SizedBox.shrink();
        return _badge('+${km.toStringAsFixed(1)} KM', Colors.cyanAccent);
      case 'hustle':
        return _badge('+1 DIA', Colors.orangeAccent);
      case 'survivor':
        return const SizedBox.shrink();
      default: // alpha
        final int xp = (post['xp_earned'] as num?)?.toInt() ?? 0;
        return _badge('+$xp XP', const Color(0xFFD4AF37));
    }
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}