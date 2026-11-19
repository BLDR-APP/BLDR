import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/club/domain/entities/notification_category.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/main.dart' show appNavigatorKey;
import 'package:bldr_fitness/services/push_notification_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Central de notificações (Figma 121:1128): abas Todas/Social/Performance
/// por `type`, grupos por dia e as mesmas ações inline da tela anterior.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<ClubNotification> _items = [];
  bool _loading = true;
  NotificationTab _tab = NotificationTab.all;
  Timer? _markReadTimer;

  String? get _myUserId => getIt<GetCurrentUser>()()?.id;

  @override
  void initState() {
    super.initState();
    _fetch();
    _markReadTimer = Timer(const Duration(seconds: 3), _markAllRead);
  }

  @override
  void dispose() {
    _markReadTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_myUserId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final result = await getIt<GetClubNotifications>()(limit: 50);
    if (!mounted) return;
    setState(() {
      // Falha mostra o estado vazio, como antes.
      _items = result.valueOrNull ?? const [];
      _loading = false;
    });
  }

  ClubNotification _asRead(ClubNotification n) => ClubNotification(
        id: n.id,
        title: n.title,
        message: n.message,
        type: n.type,
        isRead: true,
        createdAt: n.createdAt,
        actionType: n.actionType,
        actionData: n.actionData,
      );

  Future<void> _markAllRead() async {
    if (_myUserId == null) return;
    final result = await getIt<MarkAllNotificationsRead>()();
    if (result.isFailure || !mounted) return;
    setState(() => _items = _items.map(_asRead).toList());
  }

  Future<void> _markOneRead(String id) async {
    final result = await getIt<MarkNotificationRead>()(id);
    if (result.isFailure || !mounted) return;
    setState(
        () => _items = [for (final n in _items) n.id == id ? _asRead(n) : n]);
  }

  void _runAction(ClubNotification n) {
    _markOneRead(n.id);
    final raw = n.actionData;
    NotificationRouter.navigate(
      n.actionType ?? n.type,
      raw == null ? <String, dynamic>{} : Map<String, dynamic>.from(raw),
      navigatorKey: appNavigatorKey,
    );
  }

  String? _actionLabel(AppLocalizations l10n, NotificationKind kind) =>
      switch (kind) {
        NotificationKind.ranking => l10n.notifications_see_ranking,
        NotificationKind.challenge => l10n.notifications_see_challenge,
        NotificationKind.wearable => l10n.notif_confirm_workout,
        NotificationKind.welcome => l10n.notif_welcome,
        _ => null,
      };

  IconData _icon(NotificationKind kind) => switch (kind) {
        NotificationKind.ranking => TablerIcons.trending_up,
        NotificationKind.challenge => TablerIcons.target_arrow,
        NotificationKind.reaction => TablerIcons.heart,
        NotificationKind.comment => TablerIcons.message_circle,
        NotificationKind.follow => TablerIcons.user_plus,
        NotificationKind.welcome => TablerIcons.users_plus,
        NotificationKind.levelUp => TablerIcons.rocket,
        NotificationKind.success => TablerIcons.trophy,
        NotificationKind.streak => TablerIcons.flame,
        NotificationKind.wearable => TablerIcons.device_watch,
        NotificationKind.info => TablerIcons.bell,
      };

  String _when(AppLocalizations l10n, DateTime created, DateTime now) {
    final locale = l10n.localeName;
    return switch (NotificationRules.group(created, now)) {
      NotificationGroup.today => () {
          final d = now.difference(created);
          if (d.inMinutes < 1) return l10n.comm_time_now;
          if (d.inHours < 1) return l10n.comm_time_min(d.inMinutes);
          return l10n.comm_time_hour(d.inHours);
        }(),
      NotificationGroup.yesterday =>
        l10n.notif_yesterday_at(DateFormat.Hm(locale).format(created)),
      NotificationGroup.thisWeek => DateFormat.EEEE(locale).format(created),
      NotificationGroup.older => DateFormat('d MMM', locale).format(created),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BldrBackground(
      v2: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(l10n),
              const SizedBox(height: 18),
              _tabs(l10n),
              Expanded(child: _body(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, BldrCommunityV2.pageX, 0),
        child: Row(
          children: [
            BldrCommunityBackButton(onTap: () => Navigator.maybePop(context)),
            // Título reduz junto com a ação em telas estreitas, sem cortar.
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(l10n.notifications_title,
                    maxLines: 1, style: BldrRankingTextV2.heading),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _markAllRead,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(l10n.notif_mark_all,
                          maxLines: 1, style: BldrNotificationTextV2.markAll),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _tabs(AppLocalizations l10n) {
    final labels = {
      NotificationTab.all: l10n.notif_tab_all,
      NotificationTab.social: l10n.notif_tab_social,
      NotificationTab.performance: l10n.notif_tab_perf,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BldrCommunityV2.pageX),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in labels.entries)
                Semantics(
                  button: true,
                  selected: _tab == e.key,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _tab = e.key),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 92),
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 14),
                              child: Text(e.value,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: _tab == e.key
                                      ? BldrNotificationTextV2.tabOn
                                      : BldrNotificationTextV2.tabOff),
                            ),
                            Container(
                              height: 2,
                              color: _tab == e.key
                                  ? BldrCommunityColorsV2.gold
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: BldrCommunityColorsV2.gold, strokeWidth: 2),
      );
    }
    final now = DateTime.now();
    final visible = _items
        .where((n) => NotificationRules.inTab(
            NotificationRules.kind(n.type, n.title), _tab))
        .toList();
    final groups = <NotificationGroup, List<ClubNotification>>{};
    for (final n in visible) {
      final g = NotificationRules.group(n.createdAt?.toLocal() ?? now, now);
      (groups[g] ??= []).add(n);
    }
    final labels = {
      NotificationGroup.today: l10n.notif_today,
      NotificationGroup.yesterday: l10n.notif_yesterday,
      NotificationGroup.thisWeek: l10n.notif_week,
      NotificationGroup.older: l10n.notif_older,
    };
    return RefreshIndicator(
      color: BldrCommunityColorsV2.gold,
      backgroundColor: BldrCommunityColorsV2.surface,
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            BldrCommunityV2.pageX, 12, BldrCommunityV2.pageX, 48),
        children: [
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Text(
                _items.isEmpty
                    ? '${l10n.notifications_empty}\n${l10n.notifications_up_to_date}'
                    : l10n.notif_empty_tab,
                textAlign: TextAlign.center,
                style: BldrRankingTextV2.subtitle,
              ),
            ),
          for (final g in NotificationGroup.values)
            if (groups[g] case final list?) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 2),
                child: Text(labels[g]!, style: BldrNotificationTextV2.group),
              ),
              for (final n in list) _tile(l10n, n, now),
            ],
        ],
      ),
    );
  }

  Widget _tile(AppLocalizations l10n, ClubNotification n, DateTime now) {
    final kind = NotificationRules.kind(n.type, n.title);
    final action = _actionLabel(l10n, kind);
    final message = n.message.trim();
    final created = n.createdAt?.toLocal();
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _markOneRead(n.id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: BldrNotificationColorsV2.divider),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BldrCommunityColorsV2.avatarBg,
                  border: Border.all(color: BldrCommunityColorsV2.gold),
                ),
                child: Icon(_icon(kind),
                    size: 17, color: BldrCommunityColorsV2.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: n.isRead
                            ? BldrNotificationTextV2.title
                            : BldrNotificationTextV2.titleUnread),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BldrNotificationTextV2.meta),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            created == null ? '' : _when(l10n, created, now),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BldrNotificationTextV2.meta,
                          ),
                        ),
                        if (action != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Semantics(
                              button: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _runAction(n),
                                child: Container(
                                  constraints: const BoxConstraints(
                                      minHeight: 28, minWidth: 88),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: BldrNotificationColorsV2.actionBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: BldrNotificationColorsV2
                                            .actionBorder),
                                  ),
                                  child: Text(action,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: BldrNotificationTextV2.action),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!n.isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: BldrCommunityColorsV2.gold,
                        shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
