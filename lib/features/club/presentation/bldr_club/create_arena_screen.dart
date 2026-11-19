// lib/features/club/presentation/bldr_club/create_arena_screen.dart
import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_details_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'dart:math';

class CreateArenaScreen extends StatefulWidget {
  const CreateArenaScreen({super.key});

  @override
  State<CreateArenaScreen> createState() => _CreateArenaScreenState();
}

class _CreateArenaScreenState extends State<CreateArenaScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _stakeController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingQuota = true;

  // Quota state (client-side best-effort; server-side RPC pending migration 00028)
  bool _isClub = false;
  int _createdThisMonth = 0;
  static const _freeCreateLimit = 2;

  // Configurações Padrão
  String _selectedMode = 'hustle';
  int _durationDays = 7;
  String _selectedValidation = 'manual';

  @override
  void initState() {
    super.initState();
    _loadQuota();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _stakeController.dispose();
    super.dispose();
  }

  /// Roadrunner e Hustle usam só check-in de honra (ranking objetivo).
  bool get _honorOnly =>
      _selectedMode == 'roadrunner' || _selectedMode == 'hustle';

  void _selectMode(String mode) => setState(() {
        _selectedMode = mode;
        _selectedValidation = mode == 'roadrunner' || mode == 'hustle'
            ? 'manual'
            : _selectedValidation == 'manual'
                ? 'photo'
                : _selectedValidation;
      });

  Future<void> _loadQuota() async {
    try {
      final clubResult = await getIt<ResolveClubAccess>().call();
      final isClub = clubResult.valueOrNull ?? false;

      int created = 0;
      if (!isClub) {
        // Use the server-side preflight RPC for an accurate count from the
        // arenas table (same source the create RPC enforces against).
        final repo = getIt<ArenaRepository>();
        final squadsResult = await repo.mySquads();
        final squads = squadsResult.valueOrNull ?? [];
        final now = DateTime.now().toUtc();
        // Use UTC month start for preflight display (server uses SP timezone
        // for enforcement, so this count is approximate — only the RPC is
        // authoritative on whether the action is allowed).
        final monthStart = DateTime.utc(now.year, now.month, 1);
        created = squads.where((s) {
          final raw = s['created_at'] as String?;
          if (raw == null) return false;
          final dt = DateTime.tryParse(raw)?.toUtc();
          if (dt == null) return false;
          return !dt.isBefore(monthStart);
        }).length;
      }

      if (mounted) {
        setState(() {
          _isClub = isClub;
          _createdThisMonth = created;
          _isCheckingQuota = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingQuota = false);
    }
  }

  bool get _limitReached => !_isClub && _createdThisMonth >= _freeCreateLimit;

  // --- FUNÇÃO PARA GERAR CÓDIGO CURTO ---
  String _generateSquadCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    String part1 = String.fromCharCodes(Iterable.generate(
        3, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    String part2 = String.fromCharCodes(Iterable.generate(
        3, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return "$part1-$part2";
  }

  Future<void> _createArena() async {
    final l10n = AppLocalizations.of(context);
    if (_limitReached) {
      await ClubPaywallSheet.show(context);
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.sq_name_required)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final shareCode = _generateSquadCode();

      // Use the atomic server-side RPC which enforces quota and inserts
      // the arena + creator participant in a single transaction.
      final rpcResult = await getIt<ArenaRepository>().createSquadWithQuota(
        name: title,
        description: _descController.text.trim(),
        gameMode: _selectedMode,
        durationDays: _durationDays,
        validationType: _selectedValidation,
        shareCode: shareCode,
      );

      final rpcFailure = rpcResult.failureOrNull;
      if (rpcFailure != null) throw Exception(rpcFailure.message);

      final response = rpcResult.valueOrNull!;

      if (response['allowed'] == false) {
        // Server-side quota enforcement denied the action.
        final reason = response['reason'] as String? ?? '';
        if (reason == 'monthly_create_limit') {
          // Update local quota state so the UI reflects the new count.
          if (mounted) {
            setState(() {
              _createdThisMonth =
                  (response['used'] as num?)?.toInt() ?? _createdThisMonth;
            });
          }
          await ClubPaywallSheet.show(context);
        } else {
          throw Exception(reason);
        }
        return;
      }

      final arenaJson = response['arena'] as Map?;
      final arenaId = arenaJson?['id']?.toString();

      if (mounted && arenaId != null) {
        // Update local quota display from server response.
        final used = (response['used'] as num?)?.toInt();
        if (used != null) setState(() => _createdThisMonth = used);

        // A aposta é gravada depois: o RPC de cota não recebe este campo.
        final stake = _stakeController.text.trim();
        if (stake.isNotEmpty) {
          await getIt<ArenaRepository>().updateArena(arenaId, {'stake': stake});
          if (!mounted) return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ArenaDetailsScreen(arenaId: arenaId),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sq_created)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sq_create_error)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _modeInfo(AppLocalizations l10n) => switch (_selectedMode) {
        'survivor' => l10n.sq_mode_survivor_info,
        'alpha' => l10n.sq_mode_alpha_info,
        'roadrunner' => l10n.sq_mode_roadrunner_info,
        _ => l10n.sq_mode_hustle_info,
      };

  String _modeName(AppLocalizations l10n) => switch (_selectedMode) {
        'survivor' => l10n.club_game_mode_survivor,
        'alpha' => l10n.club_game_mode_alfa,
        'roadrunner' => l10n.club_game_mode_roadrunner,
        _ => l10n.club_game_mode_hustle,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget mode(String id, String title, String sub) => Expanded(
          child: _OptionCard(
            title: title,
            subtitle: sub,
            selected: _selectedMode == id,
            onTap: () => _selectMode(id),
          ),
        );
    return BldrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    BldrCommunityBackButton(
                        onTap: () => Navigator.maybePop(context)),
                    Expanded(
                      child: Text(l10n.sq_new_title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrCommunityTextV2.sqTitle),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      BldrCommunityV2.pageX, 8, BldrCommunityV2.pageX, 32),
                  children: [
                    Text(l10n.sq_new_heading,
                        style: BldrCommunityTextV2.sqHeading),
                    const SizedBox(height: 4),
                    Text(l10n.sq_new_sub, style: BldrCommunityTextV2.sheetSub),
                    const SizedBox(height: 24),
                    BldrSquadField(
                      label: l10n.sq_field_name,
                      hint: l10n.sq_field_name_hint,
                      controller: _titleController,
                      maxLength: 60,
                    ),
                    const SizedBox(height: 20),
                    BldrSquadField(
                      label: l10n.sq_field_stake,
                      hint: l10n.sq_field_stake_hint,
                      controller: _stakeController,
                      maxLength: 120,
                    ),
                    const SizedBox(height: 20),
                    BldrSquadField(
                      label: l10n.sq_field_desc,
                      hint: l10n.sq_field_desc_hint,
                      controller: _descController,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 24),
                    Text(l10n.sq_field_mode,
                        style: BldrCommunityTextV2.sqLabel),
                    const SizedBox(height: 8),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          mode('survivor', l10n.club_game_mode_survivor,
                              l10n.sq_mode_survivor_sub),
                          const SizedBox(width: 8),
                          mode('alpha', l10n.club_game_mode_alfa,
                              l10n.sq_mode_alpha_sub),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          mode('roadrunner', l10n.club_game_mode_roadrunner,
                              l10n.sq_mode_roadrunner_sub),
                          const SizedBox(width: 8),
                          mode('hustle', l10n.club_game_mode_hustle,
                              l10n.sq_mode_hustle_sub),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BldrCommunityColorsV2.goalBg,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: BldrCommunityColorsV2.modeBorder,
                            width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_modeName(l10n),
                              style: BldrCommunityTextV2.type),
                          const SizedBox(height: 4),
                          Text(_modeInfo(l10n),
                              style: BldrCommunityTextV2.body),
                        ],
                      ),
                    ),
                    if (!_honorOnly) ...[
                      const SizedBox(height: 24),
                      Text(l10n.sq_field_validation,
                          style: BldrCommunityTextV2.sqLabel),
                      const SizedBox(height: 8),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _OptionCard(
                                title: l10n.sq_validation_photo,
                                subtitle: l10n.sq_validation_photo_sub,
                                selected: _selectedValidation == 'photo',
                                onTap: () => setState(
                                    () => _selectedValidation = 'photo'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _OptionCard(
                                title: l10n.sq_validation_honor,
                                subtitle: l10n.sq_validation_honor_sub,
                                selected: _selectedValidation == 'manual',
                                onTap: () => setState(
                                    () => _selectedValidation = 'manual'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(l10n.sq_field_duration,
                        style: BldrCommunityTextV2.sqLabel),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final days in const [7, 15, 30]) ...[
                          if (days != 7) const SizedBox(width: 8),
                          Expanded(
                            child: _DurationChip(
                              label: l10n.sq_duration_days(days),
                              selected: _durationDays == days,
                              onTap: () => setState(() => _durationDays = days),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!_isCheckingQuota && !_isClub) ...[
                      const SizedBox(height: 20),
                      BldrSquadQuotaNote(
                        text: _limitReached
                            ? l10n.sq_quota_create_full(_freeCreateLimit)
                            : l10n.sq_quota_create(
                                _freeCreateLimit - _createdThisMonth,
                                _freeCreateLimit),
                        blocked: _limitReached,
                      ),
                    ],
                    const SizedBox(height: 24),
                    BldrV2SheetButton(
                      label: _limitReached
                          ? l10n.sq_subscribe
                          : l10n.sq_create_cta,
                      onTap:
                          _isLoading || _isCheckingQuota ? null : _createArena,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cartão de modo/validação (93:928, 93:937).
class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? BldrCommunityColorsV2.modeOnBg
                : BldrCommunityColorsV2.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? BldrCommunityColorsV2.gold
                  : BldrCommunityColorsV2.modeBorder,
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: selected
                      ? BldrCommunityTextV2.sqModeOn
                      : BldrCommunityTextV2.sqModeOff),
              const SizedBox(height: 4),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: selected
                      ? BldrCommunityTextV2.sqModeSubOn
                      : BldrCommunityTextV2.rowSub),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? null : BldrCommunityColorsV2.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? BldrCommunityColorsV2.goldBrand
                  : BldrCommunityColorsV2.modeBorder,
              width: 0.8,
            ),
          ),
          child: Text(label,
              maxLines: 1,
              style: selected
                  ? BldrCommunityTextV2.cta
                  : BldrCommunityTextV2.sqModeOn),
        ),
      ),
    );
  }
}
