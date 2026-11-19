import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_details_screen.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

/// Entrar com código (Figma 107:917). Conteúdo do [BldrV2Sheet].
class JoinSquadSheet extends StatefulWidget {
  const JoinSquadSheet({super.key});

  static Future<void> show(BuildContext context) => BldrV2Sheet.show<void>(
        context,
        title: AppLocalizations.of(context).sq_join_title,
        child: const JoinSquadSheet(),
      );

  @override
  State<JoinSquadSheet> createState() => _JoinSquadSheetState();
}

class _JoinSquadSheetState extends State<JoinSquadSheet> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

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
      if (mounted)
        setState(() {
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
    final l10n = AppLocalizations.of(context);
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
        throw l10n.sq_join_not_found;
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
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ArenaDetailsScreen(arenaId: realArenaId)));
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.sq_join_already)));
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
                _joinedThisMonth =
                    (response['used'] as num?)?.toInt() ?? _joinedThisMonth;
              });
            }
            await ClubPaywallSheet.show(context);
            break;
          case 'already_member':
            if (mounted) {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ArenaDetailsScreen(arenaId: realArenaId)));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l10n.sq_join_already)));
            }
            break;
          case 'invalid_share_code':
            throw l10n.sq_join_not_found;
          case 'arena_not_found':
            throw l10n.sq_join_not_found;
          default:
            throw l10n.sq_join_error;
        }
        return;
      }

      final arenaTitle = (response['arena_title'] as String?) ??
          arena['title']?.toString() ??
          'Squad';
      // Update local quota display from server response.
      final used = (response['used'] as num?)?.toInt();
      if (mounted && used != null) setState(() => _joinedThisMonth = used);

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ArenaDetailsScreen(arenaId: realArenaId)));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.sq_join_welcome(arenaTitle))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception:', '').trim())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.sq_join_sub,
            textAlign: TextAlign.center, style: BldrCommunityTextV2.sheetSub),
        const SizedBox(height: 18),
        BldrSquadField(
          label: l10n.sq_join_label,
          hint: l10n.sq_join_hint,
          controller: _codeController,
          capitalization: TextCapitalization.characters,
        ),
        if (_quotaLoaded && !_isClub) ...[
          const SizedBox(height: 12),
          BldrSquadQuotaNote(
            text: _limitReached
                ? l10n.sq_quota_join_full(_freeJoinLimit)
                : l10n.sq_quota_join(
                    _freeJoinLimit - _joinedThisMonth, _freeJoinLimit),
            blocked: _limitReached,
          ),
        ],
        const SizedBox(height: 18),
        BldrV2SheetButton(
          label: _limitReached ? l10n.sq_subscribe : l10n.sq_join_cta,
          onTap: _isLoading ? null : _joinSquad,
        ),
      ],
    );
  }
}
