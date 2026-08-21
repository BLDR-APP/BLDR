import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/main.dart' show appNavigatorKey;
import 'package:bldr_fitness/services/push_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _gold = Color(0xFFD4AF37);


  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  Timer? _markReadTimer;

  String? get _myUserId => getIt<GetCurrentUser>()()?.id;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _markReadTimer = Timer(const Duration(seconds: 3), _markAllRead);
  }

  @override
  void dispose() {
    _markReadTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    if (_myUserId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await getIt<GetClubNotifications>()(limit: 50);
      final items = result.valueOrNull;
      if (items == null) throw Exception(result.failureOrNull?.message);

      if (mounted) {
        setState(() {
          _notifications = items
              .map((n) => {
                    'id': n.id,
                    'title': n.title,
                    'message': n.message,
                    'type': n.type,
                    'is_read': n.isRead,
                    'created_at': n.createdAt?.toIso8601String(),
                    'action_type': n.actionType,
                    'action_data': n.actionData,
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      // Table may not exist yet — show empty state gracefully
      debugPrint('[NOTIFICACOES] Erro: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    if (_myUserId == null) return;
    try {
      final result = await getIt<MarkAllNotificationsRead>()();
      if (result.isFailure) return;

      if (mounted) {
        setState(() {
          _notifications = _notifications
              .map((n) => {...n, 'is_read': true})
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _markOneRead(String id) async {
    try {
      final result = await getIt<MarkNotificationRead>()(id);
      if (result.isFailure) return;

      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) {
            if (n['id'].toString() == id) return {...n, 'is_read': true};
            return n;
          }).toList();
        });
      }
    } catch (_) {}
  }

  String _timeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'agora';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m atrás';
      if (diff.inHours < 24) return '${diff.inHours}h atrás';
      if (diff.inDays == 1) return 'ontem';
      return '${diff.inDays}d atrás';
    } catch (_) {
      return '';
    }
  }

  String _groupLabel(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return 'Agora';
      if (diff.inHours < 24) return 'Hoje';
      if (diff.inDays == 1) return 'Ontem';
      if (diff.inDays <= 7) return 'Esta semana';
      return 'Mais antigo';
    } catch (_) {
      return 'Geral';
    }
  }

  _NotifConfig _configFor(Map<String, dynamic> n) {
    final type = n['type'] as String? ?? 'info';
    final title = n['title'] as String? ?? '';
    final t = title.toLowerCase();

    if (type == 'ranking' || t.contains('ranking')) {
      return _NotifConfig(
        icon: Icons.trending_up,
        iconColor: const Color(0xFF4CAF50),
        bgColor: const Color(0xFF0A2614),
        actions: [AppLocalizations.of(context).notifications_see_ranking],
      );
    }
    if (type == 'challenge' || t.contains('desafio')) {
      return _NotifConfig(
        icon: Icons.emoji_events,
        iconColor: const Color(0xFF4CAF50),
        bgColor: const Color(0xFF0A2614),
        actions: [AppLocalizations.of(context).notifications_see_challenge],
      );
    }
    if (type == 'reaction' || t.contains('reagiu') || t.contains('moral')) {
      return _NotifConfig(
        icon: Icons.favorite,
        iconColor: const Color(0xFF9C27B0),
        bgColor: const Color(0xFF1A0A2A),
      );
    }
    if (type == 'level_up' || t.contains('level up') || t.contains('nível')) {
      return _NotifConfig(
        icon: Icons.rocket_launch,
        iconColor: _gold,
        bgColor: const Color(0xFF1A1400),
      );
    }
    if (type == 'success' || t.contains('vitória') || t.contains('venceu')) {
      return _NotifConfig(
        icon: Icons.emoji_events,
        iconColor: _gold,
        bgColor: const Color(0xFF1A1400),
      );
    }
    if (type == 'streak' || t.contains('streak') || t.contains('sequência')) {
      return _NotifConfig(
        icon: Icons.local_fire_department,
        iconColor: Colors.redAccent,
        bgColor: const Color(0xFF2A0A0A),
      );
    }
    if (t.contains('bem-vindo') || t.contains('novo membro')) {
      return _NotifConfig(
        icon: Icons.group_add,
        iconColor: const Color(0xFF4CAF50),
        bgColor: const Color(0xFF0A2614),
        actions: const ['👊 Dar boas-vindas'],
      );
    }
    // Default / info
    return _NotifConfig(
      icon: Icons.notifications,
      iconColor: Colors.white54,
      bgColor: const Color(0xFF1A1A1A),
    );
  }

  // Group notifications by time bucket
  Map<String, List<Map<String, dynamic>>> _grouped() {
    final Map<String, List<Map<String, dynamic>>> result = {};
    for (final n in _notifications) {
      final group = _groupLabel(n['created_at'] ?? '');
      result.putIfAbsent(group, () => []).add(n);
    }
    const order = ['Agora', 'Hoje', 'Ontem', 'Esta semana', 'Mais antigo', 'Geral'];
    final sorted = Map.fromEntries(
        order.where(result.containsKey).map((k) => MapEntry(k, result[k]!)));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBg(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (_isLoading)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator(color: _gold)))
                else if (_notifications.isEmpty)
                  _buildEmptyState()
                else
                  Expanded(child: _buildList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBg() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: 0,
              right: 0,
              child: LayoutBuilder(builder: (context, _) {
                final w = MediaQuery.of(context).size.width * 1.6;
                final c = _gold.withOpacity(0.18);
                return Center(
                  child: Container(
                    width: w, height: w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient:
                          RadialGradient(colors: [c, c.withOpacity(0)], radius: 0.75),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount = _notifications.where((n) => n['is_read'] != true).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              children: [
                Text(AppLocalizations.of(context).notifications_title,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: _gold, borderRadius: BorderRadius.circular(10)),
                    child: Text('$unreadCount',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: _markAllRead,
            child: Text(AppLocalizations.of(context).notifications_mark_read,
                style: TextStyle(color: _gold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).notifications_empty,
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).notifications_up_to_date,
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final grouped = _grouped();

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: _gold,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(entry.key,
                  style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ),
            for (final n in entry.value) _buildNotifCard(n),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> n) {
    final id = n['id'].toString();
    final isRead = n['is_read'] == true;
    final title = n['title'] as String? ?? '';
    final message = n['message'] as String? ?? '';
    final createdAt = n['created_at'] as String? ?? '';
    final config = _configFor(n);

    return GestureDetector(
      onTap: () => _markOneRead(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? const Color(0xFF111111) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead ? Colors.white.withOpacity(0.05) : _gold.withOpacity(0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: config.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(config.icon, color: config.iconColor, size: 18),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 13)),
                      ),
                      if (!isRead)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: _gold, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(message,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(_timeAgo(createdAt),
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 10)),
                      const Spacer(),
                      ...config.actions.map((action) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: GestureDetector(
                              onTap: () {
                                _markOneRead(id);
                                final type = n['type'] as String?;
                                final rawData = n['action_data'];
                                final Map<String, dynamic> parsed =
                                    rawData is String && rawData.isNotEmpty
                                        ? (jsonDecode(rawData)
                                            as Map<String, dynamic>)
                                        : rawData is Map
                                            ? Map<String, dynamic>.from(
                                                rawData)
                                            : {};
                                NotificationRouter.navigate(
                                  type,
                                  parsed,
                                  navigatorKey: appNavigatorKey,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: action.startsWith('👊')
                                      ? const Color(0xFF4CAF50).withOpacity(0.15)
                                      : _gold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: action.startsWith('👊')
                                        ? const Color(0xFF4CAF50).withOpacity(0.4)
                                        : _gold.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(action,
                                    style: TextStyle(
                                        color: action.startsWith('👊')
                                            ? const Color(0xFF4CAF50)
                                            : _gold,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifConfig {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final List<String> actions;

  const _NotifConfig({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.actions = const [],
  });
}
