import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_history_sheet.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/create_checkin_sheet.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/squad_chat_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/squad_settings_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/tribunal_screen.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_post_card_v2.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Nome do modo em texto corrido ("Hustle").
String squadModeLabel(AppLocalizations l10n, String? mode) => switch (mode) {
      'survivor' => l10n.comm_mode_survivor,
      'roadrunner' => l10n.comm_mode_roadrunner,
      'hustle' => l10n.comm_mode_hustle,
      _ => l10n.comm_mode_alpha,
    };

/// Compartilhar Squad (Figma 117:897).
Future<void> showSquadShareSheet(
  BuildContext context, {
  required Map<String, dynamic> arena,
  required String meta,
  int? rank,
}) {
  final l10n = AppLocalizations.of(context);
  final title = arena['title']?.toString() ?? 'Squad';
  final code = arena['share_code']?.toString() ?? arena['id'].toString();
  final link = 'bldr://invite/$code';
  void copy(BuildContext ctx, String value) {
    Clipboard.setData(ClipboardData(text: value));
    Navigator.pop(ctx);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.sq_copied)));
  }

  return BldrV2Sheet.show<void>(
    context,
    title: l10n.sq_share_label,
    child: Builder(
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.sq_share_sub(title),
              textAlign: TextAlign.center, style: BldrCommunityTextV2.sheetSub),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: BldrCommunityColorsV2.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: BldrCommunityColorsV2.modeBorder, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrCommunityTextV2.name),
                      const SizedBox(height: 3),
                      Text(meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrCommunityTextV2.rowSub),
                    ],
                  ),
                ),
                if (rank != null)
                  Text('#$rank', style: BldrCommunityTextV2.sqRankPos),
              ],
            ),
          ),
          const SizedBox(height: 8),
          BldrCommunitySheetRow(
            icon: TablerIcons.share_3,
            title: l10n.sq_share_invite,
            subtitle: l10n.sq_share_invite_sub,
            onTap: () {
              Navigator.pop(ctx);
              SharePlus.instance.share(
                  ShareParams(text: l10n.sq_invite_text(title, link, code)));
            },
          ),
          BldrCommunitySheetRow(
            icon: TablerIcons.link,
            title: l10n.sq_share_link,
            subtitle: l10n.sq_share_link_sub,
            onTap: () => copy(ctx, link),
          ),
          BldrCommunitySheetRow(
            icon: TablerIcons.hash,
            title: l10n.sq_share_code,
            subtitle: code,
            onTap: () => copy(ctx, code),
          ),
        ],
      ),
    ),
  );
}

/// Detalhe do Squad (Figma 86:878, 87:827, 87:884).
class ArenaDetailsScreen extends StatefulWidget {
  final String arenaId;

  const ArenaDetailsScreen({super.key, required this.arenaId});

  @override
  State<ArenaDetailsScreen> createState() => _ArenaDetailsScreenState();
}

class _ArenaDetailsScreenState extends State<ArenaDetailsScreen> {
  final _repo = getIt<ArenaRepository>();

  bool _loading = true;
  int _tab = 0;
  Map<String, dynamic>? _arena;
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _posts = [];
  String? _todayStatus;

  String? get _myId => getIt<GetCurrentUser>()()?.id;
  String get _mode => _arena?['game_mode']?.toString() ?? 'alpha';
  bool get _survivor => _mode == 'survivor';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final arena = (await _repo.arenaById(widget.arenaId)).valueOrNull;
    if (arena == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final survivor = arena['game_mode'] == 'survivor';
    final results = await Future.wait([
      _repo.participantsCombined(widget.arenaId,
          orderBy: survivor ? 'lives_count' : 'current_score'),
      _repo.tribunalFeed(widget.arenaId),
    ]);
    final status = await _repo.todayCheckinStatus(widget.arenaId);
    if (!mounted) return;
    final participants = [...?results[0].valueOrNull];
    if (survivor) {
      // Vidas primeiro; no empate, o check-in mais recente.
      participants.sort((a, b) {
        final lives = ((b['lives_count'] as num?)?.toInt() ?? 0)
            .compareTo((a['lives_count'] as num?)?.toInt() ?? 0);
        if (lives != 0) return lives;
        return (b['updated_at']?.toString() ?? '')
            .compareTo(a['updated_at']?.toString() ?? '');
      });
    }
    setState(() {
      _arena = arena;
      _participants = participants;
      _posts = results[1].valueOrNull ?? [];
      _todayStatus = status.valueOrNull;
      _loading = false;
    });
  }

  void _checkIn() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateCheckinSheet(
        arenaId: widget.arenaId,
        validationType: _arena?['validation_type']?.toString() ?? 'photo',
        xpLimitPerDay: (_arena?['xp_limit_per_day'] as num?)?.toInt(),
        gameMode: _mode,
      ),
    ).then((posted) {
      if (posted != true || !mounted) return;
      _load();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.sq_checkin_done)));
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arena = _arena;
    if (_loading || arena == null) {
      return BldrBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BldrCommunityBackButton(
                      onTap: () => Navigator.maybePop(context)),
                ),
                Expanded(
                  child: Center(
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: BldrCommunityColorsV2.gold, strokeWidth: 2)
                        : Text(l10n.sq_load_error,
                            style: BldrCommunityTextV2.sheetSub),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final summary = CommunityV2Format.squad(
      arena: arena,
      participants: _participants,
      posts: _posts,
      myUserId: _myId,
      now: now,
    );
    final title = arena['title']?.toString() ?? 'Squad';
    final meta = [
      squadModeLabel(l10n, _mode),
      l10n.sq_members_count(_participants.length),
      if (summary.week case final w?) l10n.comm_squad_week(w),
    ].join(' · ');
    final daysLeft = CommunityV2Format.squadDaysLeft(arena, now);
    final closed = daysLeft != null && daysLeft < 0;

    return BldrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 64,
                child: Row(
                  children: [
                    BldrCommunityBackButton(
                        onTap: () => Navigator.maybePop(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BldrCommunityTextV2.sqTitle),
                          Text(meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BldrCommunityTextV2.squadMeta),
                        ],
                      ),
                    ),
                    _HeaderIcon(
                      icon: TablerIcons.share_3,
                      label: l10n.sq_share_label,
                      onTap: () => showSquadShareSheet(context,
                          arena: arena, meta: meta, rank: summary.myRank),
                    ),
                    _HeaderIcon(
                      icon: TablerIcons.dots,
                      label: l10n.sq_settings_label,
                      onTap: () => _open(SquadSettingsScreen(arenaData: arena)),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: BldrCommunityColorsV2.gold,
                  backgroundColor: BldrCommunityColorsV2.surface,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        BldrCommunityV2.pageX, 4, BldrCommunityV2.pageX, 16),
                    children: [
                      if (_tab != 1) ...[
                        _avatars(),
                        const SizedBox(height: 14),
                      ],
                      _performance(l10n, summary),
                      const SizedBox(height: 14),
                      _tabs(l10n),
                      const SizedBox(height: 20),
                      ...switch (_tab) {
                        0 => _overview(l10n, arena, daysLeft),
                        1 => _feed(l10n),
                        _ => _ranking(l10n, summary),
                      },
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    BldrCommunityV2.pageX, 8, BldrCommunityV2.pageX, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _BottomButton(
                        label: l10n.sq_chat,
                        icon: TablerIcons.message_circle,
                        onTap: () => _open(SquadChatScreen(
                          arenaId: widget.arenaId,
                          title: title,
                          members: _participants.length,
                        )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BottomButton(
                        label:
                            closed ? l10n.sq_checkin_closed : l10n.sq_checkin,
                        primary: true,
                        onTap: closed ? null : _checkIn,
                      ),
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

  Widget _avatars() {
    final shown = _participants.take(5).toList();
    return SizedBox(
      height: 32,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * 30.0,
              child: BldrCommunityAvatar(
                name: shown[i]['name']?.toString() ?? '?',
                imageUrl: shown[i]['avatar']?.toString(),
                size: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _performance(AppLocalizations l10n, SquadHubSummary summary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: BldrCommunityColorsV2.goldBrand, width: 0.7),
      ),
      child: BldrCommunityMetricRow(items: [
        (
          value: summary.myRank == null ? '—' : '#${summary.myRank}',
          label: l10n.comm_squad_ranking,
        ),
        (
          value: '${summary.trainedToday}/${_participants.length}',
          label: l10n.sq_label_today,
        ),
      ]),
    );
  }

  Widget _tabs(AppLocalizations l10n) {
    final labels = [
      l10n.sq_tab_overview,
      l10n.sq_tab_feed,
      l10n.sq_tab_ranking
    ];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: _tab == i,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = i),
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(labels[i],
                              maxLines: 1,
                              style: _tab == i
                                  ? BldrCommunityTextV2.cta
                                  : BldrCommunityTextV2.sqTab),
                        ),
                      ),
                    ),
                    Container(
                      height: 1.5,
                      color: _tab == i
                          ? BldrCommunityColorsV2.gold
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _overview(
      AppLocalizations l10n, Map<String, dynamic> arena, int? daysLeft) {
    final goal = arena['daily_goal']?.toString().trim();
    final stake = arena['stake']?.toString().trim();
    final description = arena['description']?.toString().trim();
    final status = switch (_todayStatus) {
      null => l10n.sq_goal_sub,
      'approved' => l10n.sq_status_approved,
      'rejected' => l10n.sq_status_rejected,
      _ => l10n.sq_status_pending,
    };
    final time = switch (daysLeft) {
      null => null,
      < 0 => l10n.sq_finished,
      0 => l10n.sq_last_day,
      1 => l10n.sq_day_left,
      final n => l10n.sq_days_left(n),
    };
    final activity = CommunityV2Format.squadActivity(_posts).take(3).toList();
    final isPhoto = arena['validation_type'] == 'photo';
    return [
      if (time != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            color: BldrCommunityColorsV2.timeBg,
            borderRadius: BorderRadius.circular(17),
            border:
                Border.all(color: BldrCommunityColorsV2.goldBrand, width: 0.7),
          ),
          child: Row(
            children: [
              const Icon(TablerIcons.bolt,
                  size: 14, color: BldrCommunityColorsV2.gold),
              const SizedBox(width: 8),
              Expanded(child: Text(time, style: BldrCommunityTextV2.sqTime)),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
      Text(l10n.sq_goal_section, style: BldrCommunityTextV2.section),
      const SizedBox(height: 8),
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal == null || goal.isEmpty ? l10n.sq_goal_default : goal,
                style: BldrCommunityTextV2.sqGoal),
            const SizedBox(height: 6),
            Text(status, style: BldrCommunityTextV2.discoverSub),
          ],
        ),
      ),
      if (stake != null && stake.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(l10n.sq_stake_section, style: BldrCommunityTextV2.section),
        const SizedBox(height: 8),
        _Panel(child: Text(stake, style: BldrCommunityTextV2.body)),
      ],
      if (description != null && description.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(l10n.sq_about_section, style: BldrCommunityTextV2.section),
        const SizedBox(height: 8),
        _Panel(child: Text(description, style: BldrCommunityTextV2.body)),
      ],
      const SizedBox(height: 12),
      if (isPhoto)
        BldrCommunitySheetRow(
          icon: TablerIcons.gavel,
          title: l10n.sq_tribunal,
          subtitle: l10n.sq_tribunal_sub,
          onTap: () => _open(TribunalScreen(arenaId: widget.arenaId)),
        ),
      BldrCommunitySheetRow(
        icon: TablerIcons.history,
        title: l10n.sq_history,
        subtitle: l10n.sq_history_sub,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              ArenaHistorySheet(arenaId: widget.arenaId, gameMode: _mode),
        ),
      ),
      const SizedBox(height: 22),
      Text(l10n.sq_activity_section, style: BldrCommunityTextV2.section),
      const SizedBox(height: 12),
      if (activity.isEmpty)
        Text(l10n.sq_activity_empty, style: BldrCommunityTextV2.sheetSub),
      for (final post in activity)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_postAuthor(post),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrCommunityTextV2.activityName),
              const SizedBox(height: 2),
              Text('${l10n.sq_activity_checkin} · ${_postAgo(l10n, post)}',
                  style: BldrCommunityTextV2.activityMeta),
            ],
          ),
        ),
    ];
  }

  String _postAuthor(Map<String, dynamic> post) =>
      (post['user_profiles'] as Map?)?['full_name']?.toString() ?? 'Atleta';

  String _postAgo(AppLocalizations l10n, Map<String, dynamic> post) {
    final created = DateTime.tryParse(post['created_at']?.toString() ?? '');
    return created == null
        ? ''
        : communityAgo(l10n, created.toLocal(), DateTime.now());
  }

  List<Widget> _feed(AppLocalizations l10n) {
    final posts = CommunityV2Format.squadActivity(_posts);
    return [
      Text(l10n.sq_feed_section, style: BldrCommunityTextV2.section),
      const SizedBox(height: 12),
      if (posts.isEmpty)
        Text(l10n.sq_activity_empty, style: BldrCommunityTextV2.sheetSub),
      for (final post in posts) ...[
        Row(
          children: [
            BldrCommunityAvatar(
              name: _postAuthor(post),
              imageUrl:
                  (post['user_profiles'] as Map?)?['avatar_url']?.toString(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_postAuthor(post),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrCommunityTextV2.activityName),
                  Text(_postAgo(l10n, post),
                      style: BldrCommunityTextV2.activityMeta),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(l10n.sq_feed_checkin, style: BldrCommunityTextV2.type),
        if (post['caption']?.toString().trim().isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(post['caption'].toString(),
              style: BldrCommunityTextV2.activityBody),
        ],
        const SizedBox(height: 16),
        const BldrCommunitySheetDivider(),
        const SizedBox(height: 18),
      ],
    ];
  }

  String _score(AppLocalizations l10n, Map<String, dynamic> p) {
    final score = (p['current_score'] as num?)?.toDouble() ?? 0;
    return switch (_mode) {
      'survivor' => l10n.sq_lives((p['lives_count'] as num?)?.toInt() ?? 0),
      'roadrunner' => l10n.sq_score_km(CommunityV2Format.decimal(
          score, Localizations.localeOf(context).toString(),
          digits: 1)),
      'hustle' => l10n.sq_score_days(score.toInt()),
      _ => l10n.sq_score_points(score.toInt()),
    };
  }

  List<Widget> _ranking(AppLocalizations l10n, SquadHubSummary summary) {
    bool alive(Map<String, dynamic> p) =>
        !_survivor || ((p['lives_count'] as num?)?.toInt() ?? 0) > 0;
    final active = _participants.where(alive).toList();
    final out = _participants.where((p) => !alive(p)).toList();
    Widget row(Map<String, dynamic> p, int? position) {
      final me = p['user_id']?.toString() == _myId;
      final name = p['name']?.toString() ?? 'Atleta';
      return Container(
        constraints: const BoxConstraints(minHeight: 55),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: BldrCommunityColorsV2.goalBg,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: me
                ? BldrCommunityColorsV2.chatMineBorder
                : BldrCommunityColorsV2.divider,
            width: 0.7,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(position == null ? '—' : '#$position',
                  style: position != null && position <= 3
                      ? BldrCommunityTextV2.sqRankPos
                      : BldrCommunityTextV2.sqRankPosOff),
            ),
            Expanded(
              child: Text(me ? '$name · ${l10n.sq_you}' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrCommunityTextV2.sqRankName),
            ),
            const SizedBox(width: 8),
            Text(_score(l10n, p), style: BldrCommunityTextV2.sqRankPos),
          ],
        ),
      );
    }

    return [
      if (summary.week case final w?) ...[
        Text(l10n.sq_week(w), style: BldrCommunityTextV2.section),
        const SizedBox(height: 10),
      ],
      for (var i = 0; i < active.length; i++) row(active[i], i + 1),
      if (out.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(l10n.sq_eliminated_section, style: BldrCommunityTextV2.section),
        const SizedBox(height: 10),
        for (final p in out) row(p, null),
      ],
    ];
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: BldrCommunityColorsV2.goalBg,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: BldrCommunityColorsV2.divider, width: 0.7),
        ),
        child: child,
      );
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderIcon(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: BldrCommunityColorsV2.icon),
          ),
        ),
      );
}

class _BottomButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool primary;
  final VoidCallback? onTap;

  const _BottomButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: BldrCommunityColorsV2.fieldBg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: primary
                    ? BldrCommunityColorsV2.gold
                    : BldrCommunityColorsV2.fieldBorder,
                width: 0.7,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: BldrCommunityColorsV2.text),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: primary
                          ? BldrCommunityTextV2.cta
                          : BldrCommunityTextV2.sqModeOn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
