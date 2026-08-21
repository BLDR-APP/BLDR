import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class SquadSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> arenaData;

  const SquadSettingsScreen({super.key, required this.arenaData});

  @override
  State<SquadSettingsScreen> createState() => _SquadSettingsScreenState();
}

class _SquadSettingsScreenState extends State<SquadSettingsScreen> {
  static const gold = Color(0xFFD4AF37);
  final String? _currentUserId = getIt<GetCurrentUser>()()?.id;

  // Estado local
  late String _title;
  late String _desc;
  late String _mission;
  late int _xpLimit;
  late bool _tribunalActive;
  late bool _isPrivate; // <--- NOVA VARIÁVEL

  @override
  void initState() {
    super.initState();
    _title = widget.arenaData['title'];
    _desc = widget.arenaData['description'] ?? '';
    _mission = widget.arenaData['daily_mission'] ?? '';
    _xpLimit = widget.arenaData['xp_limit_per_day'] ?? 0;
    _tribunalActive = widget.arenaData['tribunal_active'] ?? false;
    _isPrivate = widget.arenaData['is_private'] ?? true; // <--- INICIALIZAÇÃO
  }

  // --- HELPERS VISUAIS ---
  InputDecoration _darkInputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF121212),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gold),
      ),
    );
  }

  Future<void> _updateArenaField(Map<String, dynamic> updates) async {
    try {
      final result = await getIt<ArenaRepository>()
          .updateArena(widget.arenaData['id'].toString(), updates);
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Configurações salvas! ✅")));
    } catch (e) {
      print(e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao salvar."), backgroundColor: Colors.red));
    }
  }

  // --- 0. TOGGLE PRIVACIDADE (NOVO) ---
  Future<void> _togglePrivacy() async {
    final newVal = !_isPrivate;

    // Atualiza visualmente na hora (otimista)
    setState(() => _isPrivate = newVal);

    // Salva no banco
    await _updateArenaField({'is_private': newVal});

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars(); // Limpa anteriores para não empilhar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newVal ? "Squad agora é PRIVADO 🔒" : "Squad agora é PÚBLICO 🌍"),
        backgroundColor: newVal ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  // --- 1. EDITAR DADOS (GERAL) ---
  Future<void> _editDetails() async {
    final titleCtrl = TextEditingController(text: _title);
    final descCtrl = TextEditingController(text: _desc);

    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Editar Operação", style: TextStyle(color: gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: _darkInputDeco("Nome do Squad")),
            const SizedBox(height: 16),
            TextField(controller: descCtrl, style: const TextStyle(color: Colors.white), decoration: _darkInputDeco("Missão (Descrição)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("SALVAR"),
          ),
        ],
      ),
    );

    if (changed == true) {
      setState(() {
        _title = titleCtrl.text.trim();
        _desc = descCtrl.text.trim();
      });
      await _updateArenaField({'title': _title, 'description': _desc});
    }
  }

  // --- 2. EDITAR MISSÃO DIÁRIA ---
  Future<void> _editMission() async {
    final missionCtrl = TextEditingController(text: _mission);

    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Missão Diária", style: TextStyle(color: gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Defina um objetivo extra para hoje (ex: 'Fazer 100 flexões').", style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: missionCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _darkInputDeco("Desafio do Dia"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("DEFINIR"),
          ),
        ],
      ),
    );

    if (changed == true) {
      setState(() => _mission = missionCtrl.text.trim());
      await _updateArenaField({'daily_mission': _mission});
    }
  }

  // --- 3. EDITAR LIMITES XP ---
  Future<void> _editLimits() async {
    final limitCtrl = TextEditingController(text: _xpLimit > 0 ? _xpLimit.toString() : '');

    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Limites de Pontuação", style: TextStyle(color: gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Limite máximo de XP que um usuário pode ganhar por dia para evitar fraudes.", style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: limitCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _darkInputDeco("Máx XP por Dia (0 = Sem limite)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("SALVAR"),
          ),
        ],
      ),
    );

    if (changed == true) {
      final val = int.tryParse(limitCtrl.text) ?? 0;
      setState(() => _xpLimit = val);
      await _updateArenaField({'xp_limit_per_day': val});
    }
  }

  // --- 4. TOGGLE TRIBUNAL ---
  Future<void> _toggleTribunal() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("O Tribunal", style: TextStyle(color: gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_tribunalActive ? Icons.gavel : Icons.gavel_outlined, size: 40, color: _tribunalActive ? gold : Colors.grey),
            const SizedBox(height: 16),
            Text(
              _tribunalActive
                  ? "O Tribunal está ATIVO. As fotos precisam ser validadas pelos membros."
                  : "O Tribunal está DESATIVADO. Treinos contam automaticamente.",
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("VOLTAR", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _tribunalActive ? Colors.redAccent : Colors.green,
                foregroundColor: Colors.white
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_tribunalActive ? "DESATIVAR" : "ATIVAR"),
          ),
        ],
      ),
    );

    if (changed == true) {
      setState(() => _tribunalActive = !_tribunalActive);
      await _updateArenaField({'tribunal_active': _tribunalActive});
    }
  }

  // --- LISTA DE AGENTES ---
  void _showMembers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101010),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _MembersSheet(
        arenaId: widget.arenaData['id'],
        isCreator: widget.arenaData['creator_id'] == _currentUserId,
        currentUserId: _currentUserId!,
      ),
    );
  }

  // --- ZONA DE PERIGO ---
  Future<void> _leaveSquad() async {
    final confirm = await _showConfirmDialog("Abandonar Missão?", "Vai perder o progresso. Tem certeza?", isDanger: false);
    if (confirm && mounted) {
      await getIt<ArenaRepository>()
          .leaveArena(widget.arenaData['id'].toString());
      if(mounted) { Navigator.pop(context); Navigator.pop(context); }
    }
  }

  Future<void> _deleteSquad() async {
    final confirm = await _showConfirmDialog(
        "ENCERRAR OPERAÇÃO?",
        "Isso apaga TUDO: mensagens, histórico e o squad. Irreversível.",
        isDanger: true
    );

    if (confirm && mounted) {
      try {
        // Chama a função nuclear no banco (RPC)
        final delResult = await getIt<ArenaRepository>()
            .deleteArenaTotally(widget.arenaData['id'].toString());
        final delFailure = delResult.failureOrNull;
        if (delFailure != null) throw Exception(delFailure.message);

        if (mounted) {
          // Volta direto para a tela inicial (Home) para não dar erro
          Navigator.of(context).popUntil((route) => route.isFirst);

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Operação encerrada. Squad excluído."),
                backgroundColor: Colors.redAccent,
              )
          );
        }
      } catch (e) {
        print('Erro ao excluir: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erro ao excluir: $e"), backgroundColor: Colors.red)
          );
        }
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String msg, {required bool isDanger}) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDanger ? const Color(0xFF1A0000) : const Color(0xFF1A1A1A),
        title: Text(title, style: TextStyle(color: isDanger ? Colors.red : Colors.white)),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isDanger ? "DESTRUIR" : "CONFIRMAR", style: TextStyle(color: isDanger ? Colors.red : gold))),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isCreator = widget.arenaData['creator_id'] == _currentUserId;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("CENTRO DE COMANDO", style: TextStyle(color: gold, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle("GERAL"),
          _SettingTile(
            icon: Icons.edit_note,
            title: "Dados da Operação",
            subtitle: "Editar nome e missão.",
            onTap: isCreator ? _editDetails : () {},
            color: isCreator ? Colors.white : Colors.grey,
          ),

          // --- NOVO BOTÃO DE PRIVACIDADE ---
          _SettingTile(
            icon: _isPrivate ? Icons.lock : Icons.public,
            title: "Visibilidade",
            subtitle: _isPrivate ? "Privado (Só convite)" : "Público (Visível na busca)",
            onTap: isCreator ? _togglePrivacy : () {},
            color: _isPrivate ? Colors.redAccent : Colors.green,
          ),
          // ---------------------------------

          _SettingTile(
            icon: Icons.groups,
            title: "Agentes",
            subtitle: "Gerenciar pelotão.",
            onTap: _showMembers,
          ),

          const SizedBox(height: 24),
          const _SectionTitle("REGRAS DO JOGO"),
          /*
          _SettingTile(
            icon: Icons.gavel,
            title: "O Tribunal",
            subtitle: _tribunalActive ? "Ativo (Votação necessária)." : "Inativo (Aprovação auto).",
            isNew: true,
            color: _tribunalActive ? gold : Colors.white,
            onTap: isCreator ? _toggleTribunal : () {},
          ),
          */
          _SettingTile(
            icon: Icons.flag,
            title: "Missão Diária",
            subtitle: _mission.isNotEmpty ? "Ativa: $_mission" : "Nenhuma missão ativa.",
            onTap: isCreator ? _editMission : () {},
          ),
          _SettingTile(
            icon: Icons.scale,
            title: "Limites de Pontuação",
            subtitle: _xpLimit > 0 ? "Teto: $_xpLimit XP/dia" : "Sem limites.",
            onTap: isCreator ? _editLimits : () {},
          ),

          const SizedBox(height: 24),
          const _SectionTitle("ZONA DE PERIGO"),
          _SettingTile(
            icon: Icons.logout,
            title: "Abandonar Squad",
            subtitle: "Sair da competição.",
            color: Colors.redAccent,
            onTap: _leaveSquad,
          ),
          if (isCreator)
            _SettingTile(
              icon: Icons.delete_forever,
              title: "Encerrar Operação",
              subtitle: "Excluir squad permanentemente.",
              color: Colors.red,
              onTap: _deleteSquad,
            ),
        ],
      ),
    );
  }
}

// --- SHEET DE MEMBROS ---
class _MembersSheet extends StatelessWidget {
  final String arenaId;
  final bool isCreator;
  final String currentUserId;

  const _MembersSheet({required this.arenaId, required this.isCreator, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Agentes Ativos", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54))
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder(
              future: _fetchMembers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                final members = snapshot.data as List<Map<String, dynamic>>;

                return ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                  itemBuilder: (ctx, i) {
                    final m = members[i];
                    final bool isMe = m['user_id'] == currentUserId;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[800],
                        backgroundImage: m['avatar'] != null ? NetworkImage(m['avatar']) : null,
                        child: m['avatar'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      title: Text(m['name'] + (isMe ? " (Você)" : ""), style: const TextStyle(color: Colors.white)),
                      subtitle: Text(m['status'] == 'eliminated' ? 'Eliminado 💀' : 'Ativo 🟢',
                          style: TextStyle(color: m['status'] == 'eliminated' ? Colors.red : Colors.green, fontSize: 12)),
                      trailing: (isCreator && !isMe)
                          ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () => _kickMember(context, m['user_id'], m['name']),
                      )
                          : null,
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

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    final result = await getIt<ArenaRepository>().membersCombined(arenaId);
    return result.valueOrNull ?? [];
  }

  Future<void> _kickMember(BuildContext context, String userId, String name) async {
    await getIt<ArenaRepository>().kickMember(arenaId, userId);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name removido da operação.")));
  }
}

// --- WIDGETS AUXILIARES ---
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)));
}

class _SettingTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap; final Color color; final bool isNew;
  const _SettingTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.color = Colors.white, this.isNew = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: ListTile(
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        title: Row(children: [Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)), if (isNew) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(4)), child: const Text("NOVO", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)))]]),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
      ),
    );
  }
}