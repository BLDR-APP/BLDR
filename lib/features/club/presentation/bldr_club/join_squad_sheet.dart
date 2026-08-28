import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_details_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class JoinSquadSheet extends StatefulWidget {
  const JoinSquadSheet({super.key});

  @override
  State<JoinSquadSheet> createState() => _JoinSquadSheetState();
}

class _JoinSquadSheetState extends State<JoinSquadSheet> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  static const gold = Color(0xFFD4AF37);

  Future<void> _joinSquad() async {
    // 1. Sanitização
    final codeInput = _codeController.text.trim().toUpperCase();
    if (codeInput.isEmpty) return;

    // Fecha o teclado
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      print("🔍 Buscando Squad com código: $codeInput");

      Map<String, dynamic>? arena;

      final findResult =
          await getIt<ArenaRepository>().findArenaByCode(codeInput);
      arena = findResult.valueOrNull;

      if (arena == null) {
        throw "Nenhum Squad encontrado com este código.";
      }

      // IMPORTANTE: Pegamos o ID REAL (UUID) do banco para usar nas relações
      final String realArenaId = arena['id'];
      final String arenaTitle = arena['title'];

      print("✅ Squad encontrado: $arenaTitle ($realArenaId)");

      // 2. Verificar se já estou nela (Usando o ID Real)
      final existing =
          (await getIt<ArenaRepository>().isParticipant(realArenaId))
                  .valueOrNull ??
              false;

      if (existing) {
        if (mounted) {
          Navigator.pop(context); // Fecha o Sheet
          Navigator.push(context, MaterialPageRoute(builder: (_) => ArenaDetailsScreen(arenaId: realArenaId)));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Você já é membro deste Squad!")));
        }
        return;
      }

      // 3. Entrar no Squad
      final joinResult = await getIt<ArenaRepository>()
          .joinArena(realArenaId, gameMode: (arena['game_mode'] ?? '').toString());
      final joinFailure = joinResult.failureOrNull;
      if (joinFailure != null) throw joinFailure.message;

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => ArenaDetailsScreen(arenaId: realArenaId)));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Bem-vindo ao Squad $arenaTitle! 👊"),
          backgroundColor: const Color(0xFFD4AF37),
        ));
      }

    } catch (e) {
      print("❌ ERRO JOIN: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception:', '')), // Mensagem limpa
              backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Entrar em Operação", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Cole o código de convite (Ex: K9X-2M1).", style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),

          TextField(
            controller: _codeController,
            style: const TextStyle(color: Colors.white, letterSpacing: 1),
            // Força teclado maiúsculo para facilitar
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: "CÓDIGO DE ACESSO",
              labelStyle: const TextStyle(color: gold, fontSize: 12),
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gold)),
              prefixIcon: const Icon(Icons.vpn_key, color: Colors.white24),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _joinSquad,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text("JUNTAR-SE AGORA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}