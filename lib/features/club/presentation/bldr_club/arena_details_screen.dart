import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:flutter/services.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/squad_settings_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/tribunal_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/create_checkin_sheet.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_history_sheet.dart'; // <--- IMPORT DO FEED ADICIONADO

class ArenaDetailsScreen extends StatefulWidget {
  final String arenaId;

  const ArenaDetailsScreen({super.key, required this.arenaId});

  @override
  State<ArenaDetailsScreen> createState() => _ArenaDetailsScreenState();
}

class _ArenaDetailsScreenState extends State<ArenaDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _arenaData;
  List<Map<String, dynamic>> _participants = [];
  String? _myUserId;

  // Retorna dias restantes até o fim da arena.
  // Retorna -1 se is_active == false (encerrada manualmente).
  // Retorna null se end_date não estiver disponível.
  int? get _daysRemaining {
    if (_arenaData?['is_active'] == false) return -1;
    final endDateStr = _arenaData?['end_date'] as String?;
    if (endDateStr == null) return null;
    final endDate = DateTime.parse(endDateStr).toLocal();
    return endDate.difference(DateTime.now()).inDays;
  }

  // Controle de Status do Dia
  bool _hasPostedToday = false;
  String _todayStatus = 'pending'; // pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _myUserId = getIt<GetCurrentUser>()()?.id;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Dados da Arena
      final arenaResult =
          await getIt<ArenaRepository>().arenaById(widget.arenaId);
      final arena = arenaResult.valueOrNull;
      if (arena == null) throw Exception(arenaResult.failureOrNull?.message);

      // 2. Verifica se eu postei HOJE
      await _checkTodayStatus();

      // Define a ordem baseada no modo
      final String orderBy = (arena['game_mode'] == 'survivor') ? 'lives_count' : 'current_score';

      // 3. Participantes (com nome/avatar já combinados)
      final combinedResult = await getIt<ArenaRepository>()
          .participantsCombined(widget.arenaId, orderBy: orderBy);
      final List<Map<String, dynamic>> combined =
          combinedResult.valueOrNull ?? [];

      if (combined.isEmpty) {
        if (mounted) setState(() { _arenaData = arena; _isLoading = false; });
        return;
      }

      // Survivor: ordena por vidas DESC, desempate por check-in mais recente
      if (arena['game_mode'] == 'survivor') {
        combined.sort((a, b) {
          final livesA = (a['lives_count'] as num?)?.toInt() ?? 0;
          final livesB = (b['lives_count'] as num?)?.toInt() ?? 0;
          if (livesB != livesA) return livesB.compareTo(livesA);
          final dateA = a['updated_at'] as String? ?? '';
          final dateB = b['updated_at'] as String? ?? '';
          return dateB.compareTo(dateA);
        });
      }

      if (mounted) {
        setState(() {
          _arenaData = arena;
          _participants = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro Arena Details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkTodayStatus() async {
    final result =
        await getIt<ArenaRepository>().todayCheckinStatus(widget.arenaId);
    final status = result.valueOrNull;
    if (mounted) {
      setState(() {
        if (status != null) {
          _hasPostedToday = true;
          _todayStatus = status;
        } else {
          _hasPostedToday = false;
        }
      });
    }
  }

  // --- AÇÃO DE CHECK-IN ---
  void _handleMissionAction() {
    final validationType = _arenaData?['validation_type'] ?? 'photo';
    final int? xpLimit = _arenaData?['xp_limit_per_day'];
    final String gameMode = _arenaData?['game_mode'] ?? 'alpha';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateCheckinSheet(
        arenaId: widget.arenaId,
        validationType: validationType,
        xpLimitPerDay: xpLimit,
        gameMode: gameMode,
      ),
    ).then((posted) {
      if (posted == true) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Atividade registrada no Feed! 🚀"),
              backgroundColor: Color(0xFFD4AF37),
            )
        );
      }
    });
  }

  // --- DIRETRIZES DO HAVOK (Regras por modo) ---
  void _showXPRules(BuildContext context) {
    final String mode = _arenaData?['game_mode'] ?? 'alpha';
    final Color themeColor = _getModeColor(mode);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: themeColor),
                const SizedBox(width: 8),
                const Text("DIRETRIZES DO HAVOK", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ..._buildModeRules(mode),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("ENTENDIDO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildModeRules(String mode) {
    switch (mode) {
      case 'alpha':
        return [
          const Text("Como a IA calcula sua pontuação:", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          _buildRuleRow("Check-in Básico",              "+10 XP", Icons.check_circle),
          _buildRuleRow("Por Minuto de Treino",         "+1 XP",  Icons.timer),
          _buildRuleRow("Por Km (Corrida/Bike)",        "+10 XP", Icons.map),
          _buildRuleRow("Atividade diferente no dia",   "+15 XP", Icons.swap_horiz),
        ];
      case 'survivor':
        return [
          const Text("Sobreviva. É simples assim.", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          _buildRuleRow("Vidas iniciais",               "2 VIDAS",               Icons.favorite),
          _buildRuleRow("Check-in diário",              "Mantém você vivo",      Icons.check_circle),
          _buildRuleRow("Foto não aprovada",             "−1 VIDA",               Icons.gavel),
          _buildRuleRow("0 vidas",                      "ELIMINADO",             Icons.dangerous),
          _buildRuleRow("Desempate",                    "Check-in mais recente", Icons.access_time),
        ];
      case 'roadrunner':
        return [
          const Text("Quanto mais você corre, mais pontua.", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          _buildRuleRow("Cada check-in",  "Registra seus km",        Icons.directions_run),
          _buildRuleRow("Validação",      "Sistema de honra",        Icons.handshake),
          _buildRuleRow("Ranking",        "Maior km acumulado",      Icons.emoji_events),
          _buildRuleRow("Sem votação",    "Não há votação de fotos", Icons.no_photography),
        ];
      case 'hustle':
        return [
          const Text("Consistência é o único segredo.", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          _buildRuleRow("Cada dia treinado",           "+1 PONTO",           Icons.bolt),
          _buildRuleRow("Vários treinos no mesmo dia", "Ainda 1 ponto",      Icons.info_outline),
          _buildRuleRow("Validação",                   "Sistema de honra",   Icons.handshake),
          _buildRuleRow("Ranking",                     "Maior nº de dias",   Icons.emoji_events),
        ];
      default:
        return [_buildRuleRow("Check-in Básico", "+10 XP", Icons.check_circle)];
    }
  }

  Widget _buildRuleRow(String title, String points, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white)),
            ],
          ),
          Text(points, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- COMPARTILHAMENTO ---
  void _shareInvite() {
    final String title = _arenaData?['title'] ?? 'Arena';
    final String mode = _getModeTitle(_arenaData?['game_mode'] ?? 'survivor');
    final String code = _arenaData?['share_code'] ?? widget.arenaId;
    final String link = "bldr://invite/$code";

    final String inviteText =
        "CONVOCAÇÃO BLDR CLUB\n\n"
        "Missão: $title\n"
        "Modo: $mode\n\n"
        "🔗Acesso Rápido:\n$link\n\n"
        "Ou digite o código no app:\n"
        "👉 $code \n\n"
        "Não seja o último a entrar.";

    Clipboard.setData(ClipboardData(text: inviteText));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Convite copiado! Mande no grupo. 🫡'),
          backgroundColor: Color(0xFFD4AF37),
          behavior: SnackBarBehavior.floating,
        )
    );
  }

  // --- EDITAR MISSÃO ---
  void _editMission() {
    final TextEditingController missionController = TextEditingController(
        text: _arenaData?['daily_mission'] ?? ''
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Definir Missão 🚩", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: missionController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Ex: Correr 5km ou Treino Livre...",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            child: const Text("SALVAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final updateResult = await getIt<ArenaRepository>()
                    .updateArena(widget.arenaId,
                        {'daily_mission': missionController.text.trim()});
                final updateFailure = updateResult.failureOrNull;
                if (updateFailure != null) {
                  throw Exception(updateFailure.message);
                }

                await _loadData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Missão atualizada!")));
              } catch (e) {
                print("Erro ao atualizar missão: $e");
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  // --- HELPERS VISUAIS ---
  String _getModeTitle(String mode) {
    switch (mode) {
      case 'survivor':   return 'MODO SURVIVOR';
      case 'alpha':      return 'MODO ALFA';
      case 'hustle':     return 'MODO HUSTLE';
      case 'roadrunner': return 'MODO ROADRUNNER';
      default:           return 'SQUAD';
    }
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'survivor':   return Colors.redAccent;
      case 'alpha':      return const Color(0xFFD4AF37);
      case 'hustle':     return Colors.orangeAccent;
      case 'roadrunner': return Colors.cyanAccent;
      default:           return Colors.white;
    }
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'survivor':   return Icons.local_fire_department;
      case 'alpha':      return Icons.emoji_events;
      case 'hustle':     return Icons.bolt;
      case 'roadrunner': return Icons.directions_run;
      default:           return Icons.shield;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));

    final mode = _arenaData?['game_mode'] ?? 'survivor';
    final validation = _arenaData?['validation_type'] ?? 'photo';
    final themeColor = _getModeColor(mode);
    final isSurvivor = mode == 'survivor';
    final missionText = _arenaData?['daily_mission'] ?? '';

    final active = _participants.where((p) {
      if (isSurvivor) return (p['lives_count'] ?? 0) > 0;
      return true;
    }).toList();

    final double maxScore = active.isEmpty ? 1.0 : active
        .map((p) => (p['current_score'] as num?)?.toDouble() ?? 0.0)
        .fold(0.0, (a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    final eliminated = _participants.where((p) {
      if (isSurvivor) return (p['lives_count'] ?? 0) <= 0;
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,

      // --- BARRA DE AÇÃO INFERIOR ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // 1. Botão de CHAT/TRIBUNAL
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'chat_btn',
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white12)
                ),
                elevation: 4,
                icon: const Icon(Icons.forum, color: Colors.white),
                label: const Text("CHAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TribunalScreen(arenaId: widget.arenaId)),
                  ).then((_) => _loadData());
                },
              ),
            ),

            const SizedBox(width: 12),

            // 2. Botão de CHECK-IN (desabilitado se arena encerrada)
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'checkin_btn',
                backgroundColor: (_daysRemaining != null && _daysRemaining! < 0)
                    ? const Color(0xFF2A2A2A)
                    : themeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                icon: Icon(
                  (_daysRemaining != null && _daysRemaining! < 0)
                      ? Icons.lock_outline
                      : Icons.add_a_photo,
                  color: (_daysRemaining != null && _daysRemaining! < 0)
                      ? Colors.white38
                      : Colors.black,
                ),
                label: Text(
                  (_daysRemaining != null && _daysRemaining! < 0)
                      ? "ENCERRADO"
                      : "CHECK-IN",
                  style: TextStyle(
                    color: (_daysRemaining != null && _daysRemaining! < 0)
                        ? Colors.white38
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: (_daysRemaining != null && _daysRemaining! < 0)
                    ? null
                    : _handleMissionAction,
              ),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_getModeTitle(mode), style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share), onPressed: _shareInvite),
          if (_arenaData != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SquadSettingsScreen(arenaData: _arenaData!)));
                if (mounted) _loadData();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: _loadData,
        child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(_getModeIcon(mode), size: 48, color: themeColor),
                  const SizedBox(height: 16),
                  Text(
                    _arenaData?['title'] ?? 'Arena',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _arenaData?['description'] ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Banner de prazo (só aparece quando faltam ≤ 3 dias ou encerrada)
          if (_daysRemaining != null && _daysRemaining! <= 3)
            SliverToBoxAdapter(
              child: _DeadlineBanner(daysRemaining: _daysRemaining!),
            ),

          // Missão
          SliverToBoxAdapter(
            child: _MissionBoard(
              mission: missionText,
              hasPosted: _hasPostedToday,
              status: _todayStatus,
              color: themeColor,
              onEdit: _editMission,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSurvivor) ...[
                    _StatBadge(label: 'VIVOS', count: active.length, color: Colors.green),
                    const SizedBox(width: 16),
                    _StatBadge(label: 'BAIXAS', count: eliminated.length, color: Colors.red),
                  ] else ...[
                    _StatBadge(label: 'ATLETAS', count: active.length, color: themeColor),
                  ]
                ],
              ),
            ),
          ),

          if (active.isNotEmpty) ...[
            // --- NOVO CABEÇALHO COM BOTÕES DE INFO E FEED ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                            isSurvivor ? "SOBREVIVENTES" : "RANKING",
                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)
                        ),
                        IconButton(
                          icon: Icon(Icons.info_outline, color: themeColor, size: 18),
                          padding: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(),
                          onPressed: () => _showXPRules(context), // Abre regras
                        )
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => ArenaHistorySheet(arenaId: widget.arenaId, gameMode: mode), // Abre Feed
                        );
                      },
                      icon: const Icon(Icons.history, color: Colors.white70, size: 16),
                      label: const Text("Feed da Squad", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    )
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _ParticipantTile(
                  data: active[index],
                  isMe: active[index]['user_id'] == _myUserId,
                  mode: mode,
                  rank: index + 1,
                  maxScore: maxScore,
                ),
                childCount: active.length,
              ),
            ),
          ],

          if (eliminated.isNotEmpty) ...[
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text("CEMITÉRIO 💀", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5))
                )
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _EliminatedTile(data: eliminated[index]),
                childCount: eliminated.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      ),
    );
  }
}

class _DeadlineBanner extends StatelessWidget {
  final int daysRemaining;
  const _DeadlineBanner({required this.daysRemaining});

  @override
  Widget build(BuildContext context) {
    final bool isExpired = daysRemaining < 0;
    final bool isUrgent  = daysRemaining <= 1;

    final Color color = isExpired
        ? Colors.grey
        : isUrgent
            ? Colors.redAccent
            : Colors.amber;

    final IconData icon = isExpired
        ? Icons.lock_outline
        : isUrgent
            ? Icons.warning_amber_rounded
            : Icons.timer_outlined;

    final String text = isExpired
        ? 'Operação encerrada.'
        : daysRemaining == 0
            ? '🚨 Último dia! Encerra hoje.'
            : daysRemaining == 1
                ? '🚨 Encerra amanhã! Faça seu check-in.'
                : '⚡ Operação encerra em $daysRemaining dias.';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionBoard extends StatelessWidget {
  final String mission;
  final bool hasPosted;
  final String status;
  final Color color;
  final VoidCallback onEdit;

  const _MissionBoard({
    required this.mission,
    required this.hasPosted,
    required this.status,
    required this.color,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String statusText;
    Color statusColor;

    if (!hasPosted) {
      icon = Icons.radio_button_unchecked;
      statusText = "A FAZER";
      statusColor = Colors.grey;
    } else {
      if (status == 'approved') {
        icon = Icons.check_circle;
        statusText = "CUMPRIDA";
        statusColor = Colors.green;
      } else if (status == 'rejected') {
        icon = Icons.cancel;
        statusText = "REJEITADA";
        statusColor = Colors.red;
      } else {
        icon = Icons.hourglass_top;
        statusText = "EM ANÁLISE";
        statusColor = const Color(0xFFD4AF37);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: hasPosted ? statusColor.withOpacity(0.5) : color.withOpacity(0.3)
        ),
        boxShadow: [
          BoxShadow(
            color: (hasPosted ? statusColor : color).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                  "MISSÃO DO DIA",
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onEdit,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mission.isEmpty ? "Toque no lápis para definir..." : mission,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: mission.isEmpty ? Colors.white24 : Colors.white
            ),
          ),

          if (hasPosted && status == 'pending')
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                  "Sua prova foi enviada para análise.",
                  style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)
              ),
            ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label; final int count; final Color color;
  const _StatBadge({required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)), Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, letterSpacing: 1))]),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final String mode;
  final int rank;
  final double maxScore;

  const _ParticipantTile({
    required this.data,
    required this.isMe,
    required this.mode,
    required this.rank,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    final int lives = data['lives_count'] ?? 0;
    final String name = data['name'] ?? 'Atleta';
    final String? avatar = data['avatar'];
    final double score = (data['current_score'] as num?)?.toDouble() ?? 0.0;
    final double ratio = (score / maxScore).clamp(0.0, 1.0);

    final Color scoreColor = mode == 'roadrunner'
        ? Colors.cyanAccent
        : mode == 'hustle'
            ? Colors.orangeAccent
            : const Color(0xFFD4AF37);

    final String scoreLabel = mode == 'roadrunner'
        ? '${score.toStringAsFixed(1)} KM'
        : mode == 'hustle'
            ? '${score.toInt()} DIAS'
            : '${score.toInt()} PTS';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: isMe ? Border.all(color: Colors.green.withOpacity(0.4), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (mode != 'survivor')
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text('#$rank',
                      style: TextStyle(
                          color: isMe ? Colors.green : Colors.white38,
                          fontWeight: FontWeight.bold)),
                ),
              CircleAvatar(
                radius: 20,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                backgroundColor: Colors.grey[800],
                child: avatar == null
                    ? Text(name[0], style: const TextStyle(color: Colors.white))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name + (isMe ? ' (Você)' : ''),
                  style: TextStyle(
                      color: isMe ? Colors.green : Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (mode == 'survivor')
                Row(
                  children: List.generate(2, (index) {
                    if (index < lives) {
                      return const Icon(Icons.favorite, color: Colors.red, size: 18);
                    } else {
                      return const Icon(Icons.favorite_border, color: Colors.grey, size: 18);
                    }
                  }),
                )
              else
                Text(scoreLabel,
                    style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
            ],
          ),
          if (mode != 'survivor') ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 3,
                backgroundColor: Colors.white10,
                color: scoreColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EliminatedTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _EliminatedTile({required this.data});
  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? 'Atleta'; final String? avatar = data['avatar'];
    return Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(12)), child: Row(children: [ColorFiltered(colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation), child: CircleAvatar(radius: 20, backgroundImage: avatar != null ? NetworkImage(avatar) : null, backgroundColor: Colors.grey[900], child: avatar == null ? Text(name[0], style: const TextStyle(color: Colors.white38)) : null)), const SizedBox(width: 12), Expanded(child: Text(name, style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough))), const Icon(Icons.dangerous, color: Colors.grey, size: 18)]));
  }
}