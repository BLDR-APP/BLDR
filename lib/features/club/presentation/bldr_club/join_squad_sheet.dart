import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_details_screen.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';
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

  // Quota state (client-side best-effort; server enforcement pending migration 00028)
  static const _freeJoinLimit = 5;
  bool _isClub = false;
  int _joinedThisMonth = 0;
  bool _quotaLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    try {
      final clubResult = await getIt<ResolveClubAccess>().call();
      final isClub = clubResult.valueOrNull ?? false;
      int joined = 0;
      if (!isClub) {
        final squadsResult = await getIt<ArenaRepository>().mySquads();
        final squads = squadsResult.valueOrNull ?? [];
        final now = DateTime.now().toUtc();
        final monthStart = DateTime(now.year, now.month, 1);
        joined = squads.where((s) {
          final raw = s['created_at'] as String?;
          if (raw == null) return false;
          final dt = DateTime.tryParse(raw)?.toUtc();
          if (dt == null) return false;
          return !dt.isBefore(monthStart);
        }).length;
      }
      if (mounted) setState(() {
        _isClub = isClub;
        _joinedThisMonth = joined;
        _quotaLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _quotaLoaded = true);
    }
  }

  bool get _limitReached => !_isClub && _joinedThisMonth >= _freeJoinLimit;

  Future<void> _joinSquad() async {
    if (_limitReached) {
      await ClubPaywallSheet.show(context);
      return;
    }

    // 1. Sanitização
    final codeInput = _codeController.text.trim().toUpperCase();
    if (codeInput.isEmpty) return;

    // Fecha o teclado
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      // 2. Resolve the arena ID from the share code so we can check if the
      //    user is already a member before consuming a quota slot, and to
      //    navigate to the details screen on success.
      final findResult =
          await getIt<ArenaRepository>().findArenaByCode(codeInput);
      final arena = findResult.valueOrNull;

      if (arena == null) {
        throw "Nenhum Squad encontrado com este código.";
      }

      final String realArenaId = arena['id'];

      // 3. Already a member? Navigate directly without consuming quota.
      final existing =
          (await getIt<ArenaRepository>().isParticipant(realArenaId))
                  .valueOrNull ??
              false;

      if (existing) {
        if (mounted) {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ArenaDetailsScreen(arenaId: realArenaId)));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Você já é membro deste Squad!")));
        }
        return;
      }

      // 4. Use the atomic server-side RPC which enforces quota and inserts
      //    the participant + ledger event in a single transaction.
      //    If the INSERT fails, the ledger rolls back — quota is never
      //    consumed without a successful join.
      final rpcResult = await getIt<ArenaRepository>()
          .joinSquadWithQuota(realArenaId, codeInput);
      final rpcFailure = rpcResult.failureOrNull;
      if (rpcFailure != null) throw rpcFailure.message;

      final response = rpcResult.valueOrNull!;

      if (response['allowed'] == false) {
        final reason = response['reason'] as String? ?? '';
        switch (reason) {
          case 'monthly_join_limit':
            // Update local quota state and show paywall.
            if (mounted) {
              setState(() {
                _joinedThisMonth = (response['used'] as num?)?.toInt() ?? _joinedThisMonth;
              });
            }
            await ClubPaywallSheet.show(context);
            break;
          case 'already_member':
            if (mounted) {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ArenaDetailsScreen(arenaId: realArenaId)));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("Você já é membro deste Squad!")));
            }
            break;
          case 'invalid_share_code':
            throw "Código de convite inválido.";
          case 'arena_not_found':
            throw "Nenhum Squad encontrado com este código.";
          default:
            throw "Não foi possível entrar no Squad: $reason";
        }
        return;
      }

      final arenaTitle = (response['arena_title'] as String?) ?? arena['title']?.toString() ?? 'Squad';
      // Update local quota display from server response.
      final used = (response['used'] as num?)?.toInt();
      if (mounted && used != null) setState(() => _joinedThisMonth = used);

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ArenaDetailsScreen(arenaId: realArenaId)));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Bem-vindo ao Squad $arenaTitle! 👊"),
          backgroundColor: const Color(0xFFD4AF37),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception:', '')),
              backgroundColor: Colors.red),
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
          const SizedBox(height: 12),
          // Quota indicator (only for Free users, after loading)
          if (_quotaLoaded && !_isClub) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _limitReached
                    ? Colors.redAccent.withOpacity(0.08)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _limitReached
                      ? Colors.redAccent.withOpacity(0.3)
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _limitReached ? Icons.lock_outline : Icons.info_outline,
                    color: _limitReached ? Colors.redAccent : Colors.white38,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _limitReached
                          ? "Limite de $_freeJoinLimit participações este mês atingido. Assine o BLDR Club para continuar."
                          : "Você tem ${_freeJoinLimit - _joinedThisMonth} de $_freeJoinLimit participações restantes este mês",
                      style: TextStyle(
                        color: _limitReached ? Colors.redAccent : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 12),

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