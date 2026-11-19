import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Chat do Squad (Figma 96:830). Só mensagens de texto; usa o mesmo envio de
/// sempre (`sendChatMessage`). Provas e votação ficam no Tribunal.
class SquadChatScreen extends StatefulWidget {
  final String arenaId;
  final String title;
  final int members;

  const SquadChatScreen({
    super.key,
    required this.arenaId,
    required this.title,
    required this.members,
  });

  @override
  State<SquadChatScreen> createState() => _SquadChatScreenState();
}

class _SquadChatScreenState extends State<SquadChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _messages = [];

  String? get _myId => getIt<GetCurrentUser>()()?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await getIt<ArenaRepository>().tribunalFeed(widget.arenaId);
    if (!mounted) return;
    setState(() {
      _messages = CommunityV2Format.squadChat(result.valueOrNull ?? const []);
      _loading = false;
    });
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _text.clear();
      _messages = [
        ..._messages,
        {
          'user_id': _myId,
          'caption': body,
          'status': 'chat',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      ];
    });
    final result =
        await getIt<ArenaRepository>().sendChatMessage(widget.arenaId, body);
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.isFailure) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.sq_chat_error)));
      setState(() => _text.text = body);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = _messages.reversed.toList();
    return BldrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    BldrCommunityBackButton(
                        onTap: () => Navigator.maybePop(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.sq_chat_title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BldrCommunityTextV2.sqTitle),
                          Text(
                            '${widget.title} · ${l10n.sq_members_count(widget.members)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BldrCommunityTextV2.meta,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    BldrCommunityV2.pageX, 6, BldrCommunityV2.pageX, 6),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: BldrCommunityColorsV2.goalBg,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: BldrCommunityColorsV2.modeBorder, width: 0.7),
                  ),
                  child: Text(l10n.sq_chat_info,
                      textAlign: TextAlign.center,
                      style: BldrCommunityTextV2.rowSub),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: BldrCommunityColorsV2.gold, strokeWidth: 2),
                      )
                    : items.isEmpty
                        ? Center(
                            child: Text(l10n.sq_chat_empty,
                                style: BldrCommunityTextV2.sheetSub),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: BldrCommunityV2.pageX,
                                vertical: 12),
                            itemCount: items.length,
                            itemBuilder: (_, i) => _Bubble(
                              message: items[i],
                              mine: items[i]['user_id']?.toString() == _myId,
                            ),
                          ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    BldrCommunityV2.pageX, 6, BldrCommunityV2.pageX, 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 6, 7, 6),
                  decoration: BoxDecoration(
                    color: BldrCommunityColorsV2.fieldBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: BldrCommunityColorsV2.fieldBorder, width: 0.7),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: TextField(
                            controller: _text,
                            minLines: 1,
                            maxLines: 4,
                            cursorColor: BldrCommunityColorsV2.gold,
                            textCapitalization: TextCapitalization.sentences,
                            style: BldrCommunityTextV2.sqBubble,
                            decoration: InputDecoration(
                              hintText: l10n.sq_chat_hint,
                              hintStyle: BldrCommunityTextV2.sqHint,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        button: true,
                        label: l10n.sq_chat_send,
                        child: GestureDetector(
                          onTap: _send,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: BldrCommunityColorsV2.gold,
                            ),
                            child: const Icon(TablerIcons.arrow_up,
                                size: 18, color: BldrColorsV2.bg),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool mine;

  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final profile = message['user_profiles'] as Map?;
    final name = profile?['full_name']?.toString() ?? 'Atleta';
    final created = DateTime.tryParse(message['created_at']?.toString() ?? '');
    final time =
        created == null ? '' : DateFormat.Hm(locale).format(created.toLocal());
    final maxWidth = MediaQuery.sizeOf(context).width * 0.68;
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 9),
        decoration: BoxDecoration(
          color: mine
              ? BldrCommunityColorsV2.timeBg
              : BldrCommunityColorsV2.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: mine
                ? BldrCommunityColorsV2.chatMineBorder
                : BldrCommunityColorsV2.fieldBorder,
            width: 0.7,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message['caption']?.toString() ?? '',
                style: BldrCommunityTextV2.sqBubble),
            const SizedBox(height: 6),
            Text(time,
                style: mine
                    ? BldrCommunityTextV2.sqBubbleTimeMine
                    : BldrCommunityTextV2.sqBubbleTime),
          ],
        ),
      ),
    );
    if (mine) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Align(alignment: Alignment.centerRight, child: bubble),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BldrCommunityAvatar(
            name: name,
            imageUrl: profile?['avatar_url']?.toString(),
            size: 32,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrCommunityTextV2.rowSub),
                const SizedBox(height: 3),
                bubble,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
