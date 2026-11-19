import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_details_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Configurações do Squad (Figma 86:919 e sheets 98:1291–98:1653).
/// Visibilidade pública fica oculta até o lote 2.
class SquadSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> arenaData;

  const SquadSettingsScreen({super.key, required this.arenaData});

  @override
  State<SquadSettingsScreen> createState() => _SquadSettingsScreenState();
}

class _SquadSettingsScreenState extends State<SquadSettingsScreen> {
  final _repo = getIt<ArenaRepository>();
  late final Map<String, dynamic> _arena = Map.of(widget.arenaData);
  int? _memberCount;

  String get _id => _arena['id'].toString();
  String? get _myId => getIt<GetCurrentUser>()()?.id;
  bool get _isCreator => _arena['creator_id']?.toString() == _myId;
  String get _mode => _arena['game_mode']?.toString() ?? 'alpha';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = (await _repo.membersCombined(_id)).valueOrNull;
    if (mounted && members != null) {
      setState(() => _memberCount = members.length);
    }
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save(Map<String, dynamic> updates) async {
    final l10n = AppLocalizations.of(context);
    final result = await _repo.updateArena(_id, updates);
    if (!mounted) return;
    if (result.isFailure) {
      _snack(l10n.sq_save_error);
      return;
    }
    setState(() => _arena.addAll(updates));
    _snack(l10n.sq_saved);
  }

  String? _clean(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _editInfo() async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController(text: _arena['title']?.toString());
    final stake = TextEditingController(text: _arena['stake']?.toString());
    final desc = TextEditingController(text: _arena['description']?.toString());
    final saved = await BldrV2Sheet.show<bool>(
      context,
      title: l10n.sq_info,
      child: Builder(
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.sq_info_sheet_sub,
                textAlign: TextAlign.center,
                style: BldrCommunityTextV2.sheetSub),
            const SizedBox(height: 16),
            BldrSquadField(
              label: l10n.sq_field_name,
              hint: l10n.sq_field_name_hint,
              controller: name,
              maxLength: 60,
            ),
            const SizedBox(height: 16),
            BldrSquadField(
              label: l10n.sq_field_stake,
              hint: l10n.sq_field_stake_hint,
              controller: stake,
              maxLength: 120,
            ),
            const SizedBox(height: 16),
            BldrSquadField(
              label: l10n.sq_field_desc,
              hint: l10n.sq_field_desc_hint,
              controller: desc,
              maxLength: 200,
            ),
            const SizedBox(height: 20),
            BldrV2SheetButton(
              label: l10n.sq_save,
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    final title = name.text.trim();
    if (title.isEmpty) {
      _snack(l10n.sq_name_required);
      return;
    }
    await _save({
      'title': title,
      'stake': _clean(stake.text),
      'description': desc.text.trim(),
    });
  }

  Future<void> _editGoal() async {
    final l10n = AppLocalizations.of(context);
    final goal = TextEditingController(text: _arena['daily_goal']?.toString());
    final saved = await BldrV2Sheet.show<bool>(
      context,
      title: l10n.sq_goal,
      child: Builder(
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.sq_goal_sheet_sub,
                textAlign: TextAlign.center,
                style: BldrCommunityTextV2.sheetSub),
            const SizedBox(height: 16),
            BldrSquadField(
              label: l10n.sq_goal_label,
              hint: l10n.sq_goal_hint,
              controller: goal,
              maxLength: 120,
            ),
            const SizedBox(height: 12),
            Text(l10n.sq_goal_help, style: BldrCommunityTextV2.rowSub),
            const SizedBox(height: 20),
            BldrV2SheetButton(
              label: l10n.sq_goal_save,
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      await _save({'daily_goal': _clean(goal.text)});
    }
  }

  Future<void> _showRules() async {
    final l10n = AppLocalizations.of(context);
    final canEditLimit = _isCreator && _mode == 'alpha';
    final current = (_arena['xp_limit_per_day'] as num?)?.toInt() ?? 0;
    final limit = TextEditingController(text: current > 0 ? '$current' : '');
    final body = switch (_mode) {
      'survivor' => l10n.sq_rules_survivor,
      'roadrunner' => l10n.sq_rules_roadrunner,
      'hustle' => l10n.sq_rules_hustle,
      _ => l10n.sq_rules_alpha,
    };
    final saved = await BldrV2Sheet.show<bool>(
      context,
      title: l10n.sq_rules,
      child: Builder(
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.sq_rules_sheet_sub,
                textAlign: TextAlign.center,
                style: BldrCommunityTextV2.sheetSub),
            const SizedBox(height: 16),
            Text(l10n.sq_rules_label, style: BldrCommunityTextV2.sqLabel),
            const SizedBox(height: 6),
            Text(squadModeLabel(l10n, _mode).toUpperCase(),
                style: BldrCommunityTextV2.cta),
            const SizedBox(height: 14),
            Text(body, style: BldrCommunityTextV2.body),
            if (canEditLimit) ...[
              const SizedBox(height: 16),
              BldrSquadField(
                label: l10n.sq_xp_limit,
                hint: l10n.sq_xp_limit_hint,
                controller: limit,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ],
            const SizedBox(height: 12),
            Text(l10n.sq_rules_note, style: BldrCommunityTextV2.rowSub),
            const SizedBox(height: 20),
            BldrV2SheetButton(
              label: canEditLimit ? l10n.sq_save : l10n.sq_rules_ok,
              onTap: () => Navigator.pop(ctx, canEditLimit),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      final digits = limit.text.replaceAll(RegExp(r'\D'), '');
      await _save({'xp_limit_per_day': int.tryParse(digits) ?? 0});
    }
  }

  Future<void> _showMembers() async {
    final l10n = AppLocalizations.of(context);
    final members = (await _repo.membersCombined(_id)).valueOrNull ?? const [];
    if (!mounted) return;
    final code = _arena['share_code']?.toString() ?? _id;
    final title = _arena['title']?.toString() ?? 'Squad';
    await BldrV2Sheet.show<void>(
      context,
      title: l10n.sq_members,
      child: Builder(
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.sq_members_sub,
                textAlign: TextAlign.center,
                style: BldrCommunityTextV2.sheetSub),
            const SizedBox(height: 12),
            for (final m in members)
              _MemberRow(
                name: m['name']?.toString() ?? 'Atleta',
                avatar: m['avatar']?.toString(),
                role:
                    m['user_id']?.toString() == _arena['creator_id']?.toString()
                        ? l10n.sq_role_admin
                        : m['status'] == 'eliminated'
                            ? l10n.sq_role_eliminated
                            : l10n.sq_role_member,
                onMore: _isCreator && m['user_id']?.toString() != _myId
                    ? () {
                        Navigator.pop(ctx);
                        _kick(m['user_id'].toString(),
                            m['name']?.toString() ?? 'Atleta');
                      }
                    : null,
              ),
            const SizedBox(height: 16),
            BldrV2SheetButton(
              label: l10n.sq_invite_members,
              onTap: () {
                Navigator.pop(ctx);
                SharePlus.instance.share(ShareParams(
                  text: l10n.sq_invite_text(title, 'bldr://invite/$code', code),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _kick(String userId, String name) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await BldrV2ConfirmDialog.show(
      context,
      title: l10n.sq_kick,
      message: l10n.sq_kick_msg(name),
      confirmLabel: l10n.sq_kick_confirm,
      cancelLabel: l10n.comm_cancel,
      destructive: true,
    );
    if (!confirmed) return;
    final result = await _repo.kickMember(_id, userId);
    if (!mounted) return;
    if (result.isFailure) {
      _snack(l10n.sq_save_error);
      return;
    }
    _snack(l10n.sq_kick_sub(name));
    _loadMembers();
  }

  Future<bool> _dangerSheet({
    required String title,
    required String subtitle,
    required String body,
    required String note,
    required String cta,
  }) async {
    final confirmed = await BldrV2Sheet.show<bool>(
      context,
      title: title,
      child: Builder(
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(subtitle,
                textAlign: TextAlign.center,
                style: BldrCommunityTextV2.sheetSub),
            const SizedBox(height: 20),
            Text(body, style: BldrCommunityTextV2.body),
            const SizedBox(height: 14),
            Text(note, style: BldrCommunityTextV2.sqDanger),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(ctx, true),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 46),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BldrCommunityColorsV2.dangerBg,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                        color: BldrCommunityColorsV2.danger, width: 0.8),
                  ),
                  child: Text(cta, style: BldrCommunityTextV2.sqDangerCta),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _dangerSheet(
      title: l10n.sq_leave,
      subtitle: l10n.sq_leave_sub,
      body: l10n.sq_leave_body,
      note: l10n.sq_leave_note,
      cta: l10n.sq_leave_cta,
    );
    if (!confirmed || !mounted) return;
    final result = await _repo.leaveArena(_id);
    if (!mounted) return;
    if (result.isFailure) {
      _snack(l10n.sq_save_error);
      return;
    }
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Future<void> _end() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _dangerSheet(
      title: l10n.sq_end,
      subtitle: l10n.sq_end_sub,
      body: l10n.sq_end_body,
      note: l10n.sq_end_note,
      cta: l10n.sq_end_cta,
    );
    if (!confirmed || !mounted) return;
    final result = await _repo.deleteArenaTotally(_id);
    if (!mounted) return;
    if (result.isFailure) {
      _snack(l10n.sq_save_error);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    messenger.showSnackBar(SnackBar(content: Text(l10n.sq_ended)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goal = _arena['daily_goal']?.toString().trim();
    final modeSub = switch (_mode) {
      'survivor' => l10n.sq_mode_survivor_sub,
      'roadrunner' => l10n.sq_mode_roadrunner_sub,
      'hustle' => l10n.sq_mode_hustle_sub,
      _ => l10n.sq_mode_alpha_sub,
    };
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
                      child: Text(l10n.sq_settings_label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrCommunityTextV2.sqTitle),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      BldrCommunityV2.pageX, 16, BldrCommunityV2.pageX, 32),
                  children: [
                    Text(l10n.sq_section_general,
                        style: BldrCommunityTextV2.sqLabel),
                    const SizedBox(height: 6),
                    if (_isCreator)
                      _SettingRow(
                        title: l10n.sq_info,
                        subtitle: l10n.sq_info_sub,
                        onTap: _editInfo,
                      ),
                    _SettingRow(
                      title: l10n.sq_members,
                      subtitle: _memberCount == null
                          ? l10n.sq_members_sub
                          : l10n.sq_members_count(_memberCount!),
                      onTap: _showMembers,
                    ),
                    const SizedBox(height: 28),
                    Text(l10n.sq_section_rules,
                        style: BldrCommunityTextV2.sqLabel),
                    const SizedBox(height: 6),
                    if (_isCreator)
                      _SettingRow(
                        title: l10n.sq_goal,
                        subtitle: goal == null || goal.isEmpty
                            ? l10n.sq_goal_none
                            : goal,
                        onTap: _editGoal,
                      ),
                    _SettingRow(
                      title: l10n.sq_rules,
                      subtitle: '${squadModeLabel(l10n, _mode)} · $modeSub',
                      onTap: _showRules,
                    ),
                    const SizedBox(height: 28),
                    Text(l10n.sq_section_danger,
                        style: BldrCommunityTextV2.sqDangerLabel),
                    const SizedBox(height: 6),
                    _SettingRow(
                      title: l10n.sq_leave,
                      subtitle: l10n.sq_leave_sub,
                      danger: true,
                      onTap: _leave,
                    ),
                    if (_isCreator)
                      _SettingRow(
                        title: l10n.sq_end,
                        subtitle: l10n.sq_end_sub,
                        danger: true,
                        onTap: _end,
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

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback onTap;

  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: BldrCommunityColorsV2.fieldBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: danger
                            ? BldrCommunityTextV2.sqDanger
                            : BldrCommunityTextV2.exercise),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BldrCommunityTextV2.rowSub),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(TablerIcons.chevron_right,
                  size: 18,
                  color: danger
                      ? BldrCommunityColorsV2.dangerBright
                      : BldrCommunityColorsV2.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String name;
  final String? avatar;
  final String role;
  final VoidCallback? onMore;

  const _MemberRow({
    required this.name,
    required this.avatar,
    required this.role,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          BldrCommunityAvatar(name: name, imageUrl: avatar),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrCommunityTextV2.exercise),
                Text(role, style: BldrCommunityTextV2.rowSub),
              ],
            ),
          ),
          if (onMore != null)
            Semantics(
              button: true,
              label: l10n.sq_kick,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMore,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Text('•••', style: BldrCommunityTextV2.more),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
