import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_comment.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_profile.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_content_sheets_v2.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_post_card_v2.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Comentários do detalhe do post (52:829–52:851). [header] rola junto.
class CommunityCommentsPanelV2 extends StatefulWidget {
  final String feedId;
  final Widget header;
  final ValueChanged<int>? onCountChanged;

  const CommunityCommentsPanelV2({
    super.key,
    required this.feedId,
    required this.header,
    this.onCountChanged,
  });

  @override
  State<CommunityCommentsPanelV2> createState() => _CommentsState();
}

class _CommentsState extends State<CommunityCommentsPanelV2> {
  final _repo = getIt<CommunityFeedRepository>();
  final _rootText = TextEditingController();
  List<CommunityComment> _comments = [];
  CommunityProfile? _currentProfile;
  bool _loading = true;
  bool _sendingRoot = false;
  String? _error;
  RealtimeChannel? _commentsChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeComments();
  }

  void _subscribeComments() {
    _commentsChannel?.unsubscribe();
    _commentsChannel =
        Supabase.instance.client.channel('comments_${widget.feedId}')
          ..onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'community_comments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'feed_id',
              value: widget.feedId,
            ),
            callback: (payload) {
              if (!mounted) return;
              final newId = payload.newRecord['id'] as String?;
              if (newId == null) return;
              // Dedup: skip if already present (optimistic insert)
              final alreadyPresent = _comments.any((c) => c.id == newId) ||
                  _comments.any((c) => c.replies.any((r) => r.id == newId));
              if (!alreadyPresent) _load();
            },
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'community_comments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'feed_id',
              value: widget.feedId,
            ),
            callback: (payload) {
              if (!mounted) return;
              // Reload to pick up updated body with profile joins
              _load();
            },
          )
          ..subscribe();
  }

  @override
  void dispose() {
    _commentsChannel?.unsubscribe();
    _commentsChannel = null;
    _rootText.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final commentsResult = await _repo.fetchComments(widget.feedId);
    final profileResult = await _repo.fetchCurrentCommentProfile();
    if (!mounted) return;
    commentsResult.fold(
      onSuccess: (value) => setState(() {
        _comments = value;
        _currentProfile = profileResult.valueOrNull;
        _loading = false;
        _notifyCount();
      }),
      onFailure: (failure) => setState(() {
        _error = failure.message;
        _loading = false;
      }),
    );
  }

  CommunityComment _optimisticComment({
    required String body,
    String? parentId,
  }) {
    final profile = _currentProfile;
    return CommunityComment(
      id: 'optimistic-${DateTime.now().microsecondsSinceEpoch}',
      feedId: widget.feedId,
      userId: profile?.id ?? 'current-user',
      parentId: parentId,
      body: body,
      createdAt: DateTime.now(),
      username: profile?.username,
      fullName: profile?.fullName,
      avatarUrl: profile?.avatarUrl,
      canEdit: true,
      canDelete: true,
    );
  }

  Future<void> _sendRoot() async {
    final body = _rootText.text.trim();
    if (_sendingRoot || body.isEmpty) return;
    final optimistic = _optimisticComment(body: body);
    setState(() {
      _sendingRoot = true;
      _rootText.clear();
      _comments = [..._comments, optimistic];
    });
    _notifyCount();
    await _persist(optimistic);
    if (mounted) setState(() => _sendingRoot = false);
  }

  Future<void> _persist(CommunityComment optimistic,
      {_ReplyDraft? retry}) async {
    final result = await _repo.addComment(
      feedId: widget.feedId,
      body: optimistic.body,
      parentId: optimistic.parentId,
    );
    if (!mounted) return;
    result.fold(
      onSuccess: (persisted) {
        setState(() => _replaceOptimistic(optimistic, persisted));
      },
      onFailure: (failure) {
        setState(() => _removeOptimistic(optimistic.id));
        _notifyCount();
        _message(
          failure.message,
          retry: retry == null ? null : () => _openReply(retry),
        );
      },
    );
  }

  void _replaceOptimistic(
      CommunityComment optimistic, CommunityComment persisted) {
    if (optimistic.parentId == null) {
      _comments = _comments
          .map((comment) => comment.id == optimistic.id ? persisted : comment)
          .toList();
      return;
    }
    _comments = _comments.map((root) {
      if (root.id != optimistic.parentId) return root;
      return root.copyWith(
        replies: root.replies
            .map((reply) => reply.id == optimistic.id ? persisted : reply)
            .toList(),
      );
    }).toList();
  }

  void _removeOptimistic(String id) {
    _comments = _comments
        .where((comment) => comment.id != id)
        .map((root) => root.copyWith(
              replies: root.replies.where((reply) => reply.id != id).toList(),
            ))
        .toList();
  }

  Future<void> _openReply(_ReplyDraft draft) async {
    final l10n = AppLocalizations.of(context);
    final reply = await BldrV2Sheet.show<_ReplyDraft>(
      context,
      title: l10n.comm_reply_to(draft.targetHandle),
      child: _ReplyComposer(draft: draft),
    );
    if (!mounted || reply == null) return;
    final optimistic = _optimisticComment(
      body: reply.persistedBody,
      parentId: reply.rootComment.id,
    );
    setState(() {
      _comments = _comments.map((root) {
        if (root.id != reply.rootComment.id) return root;
        return root.copyWith(replies: [...root.replies, optimistic]);
      }).toList();
    });
    _notifyCount();
    _persist(optimistic, retry: reply);
  }

  _ReplyDraft _replyDraftFor(CommunityComment target, CommunityComment root) =>
      _ReplyDraft(rootComment: root, target: target);

  Future<void> _showActions(CommunityComment comment) async {
    final l10n = AppLocalizations.of(context);
    final action = await BldrV2Sheet.show<String>(
      context,
      title: l10n.comm_comment_actions,
      child: Builder(
        builder: (ctx) => Column(
          children: [
            if (comment.canEdit)
              BldrCommunitySheetRow(
                icon: TablerIcons.pencil,
                title: l10n.comm_comment_edit,
                subtitle: l10n.comm_comment_edit_sub,
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
            if (comment.canDelete)
              BldrCommunitySheetRow(
                icon: TablerIcons.trash,
                title: l10n.comm_comment_delete,
                subtitle: l10n.comm_comment_delete_sub,
                destructive: true,
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') await _edit(comment);
    if (action == 'delete') await _delete(comment);
  }

  Future<void> _edit(CommunityComment comment) async {
    final value = await CommunityEditPostSheetV2.show(
      context,
      comment.body,
      title: AppLocalizations.of(context).comm_comment_edit,
      maxLength: 300,
    );
    if (value == null || value.trim().isEmpty) return;
    final result = await _repo.editComment(id: comment.id, body: value.trim());
    if (!mounted) return;
    if (result.isFailure) {
      _message(result.failureOrNull!.message);
      return;
    }
    await _load();
  }

  Future<void> _delete(CommunityComment comment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await BldrV2ConfirmDialog.show(
      context,
      title: l10n.comm_comment_delete,
      message: l10n.comm_comment_delete_msg,
      confirmLabel: l10n.comm_delete_confirm,
      cancelLabel: l10n.comm_cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await _repo.deleteComment(comment.id);
    if (!mounted) return;
    if (result.isFailure) {
      _message(result.failureOrNull!.message);
      return;
    }
    await _load();
  }

  int get _count => _comments.fold(0, (sum, c) => sum + 1 + c.replies.length);

  void _notifyCount() => widget.onCountChanged?.call(_count);

  void _message(String value, {VoidCallback? retry}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value),
        action: retry == null
            ? null
            : SnackBarAction(label: 'Tentar novamente', onPressed: retry),
      ));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                BldrCommunityV2.pageX, 0, BldrCommunityV2.pageX, 16),
            children: [
              widget.header,
              const SizedBox(height: 14),
              Text(l10n.comm_section_comments,
                  style: BldrCommunityTextV2.section),
              const SizedBox(height: 12),
              ..._body(l10n),
            ],
          ),
        ),
        _composer(l10n),
      ],
    );
  }

  Widget _composer(AppLocalizations l10n) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              BldrCommunityV2.pageX, 8, BldrCommunityV2.pageX, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 42),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: BldrCommunityColorsV2.inputBg,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                      color: BldrCommunityColorsV2.inputBorder, width: 0.8),
                ),
                child: TextField(
                  controller: _rootText,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 300,
                  cursorColor: BldrCommunityColorsV2.gold,
                  textCapitalization: TextCapitalization.sentences,
                  style: BldrCommunityTextV2.commentBody,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: l10n.comm_comment_hint,
                    hintStyle: BldrCommunityTextV2.meta,
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
              label: l10n.comm_comment_send,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _sendingRoot ? null : _sendRoot,
                child: Container(
                  width: 48,
                  height: 42,
                  decoration: BoxDecoration(
                    color: BldrCommunityColorsV2.sendBg,
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: const Icon(TablerIcons.arrow_up,
                      size: 18, color: BldrCommunityColorsV2.gold),
                ),
              ),
            ),
          ]),
        ),
      );

  List<Widget> _body(AppLocalizations l10n) {
    if (_loading && _comments.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(
                color: BldrCommunityColorsV2.gold, strokeWidth: 2),
          ),
        ),
      ];
    }
    final error = _error;
    if (error != null) {
      return [
        Text(error, style: BldrCommunityTextV2.sheetSub),
        TextButton(
          onPressed: _load,
          child: Text(l10n.comm_retry, style: BldrCommunityTextV2.cta),
        ),
      ];
    }
    if (_comments.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(l10n.comm_comment_empty,
              style: BldrCommunityTextV2.sheetSub),
        ),
      ];
    }
    return [
      for (final comment in _comments) ...[
        _tile(l10n, comment: comment, root: comment),
        for (final reply in comment.replies)
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 10),
            child: _tile(l10n, comment: reply, root: comment),
          ),
        const SizedBox(height: 14),
      ],
    ];
  }

  Widget _tile(
    AppLocalizations l10n, {
    required CommunityComment comment,
    required CommunityComment root,
  }) {
    final meta = [
      if (comment.username?.trim().isNotEmpty == true) '@${comment.username}',
      communityAgo(l10n, comment.createdAt, DateTime.now()),
      if (comment.wasEdited) l10n.comm_comment_edited,
    ].join(' · ');
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      BldrCommunityAvatar(
        name: comment.authorName,
        imageUrl: comment.avatarUrl,
        size: 32,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(comment.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrCommunityTextV2.commentName),
            ),
            if (comment.canEdit || comment.canDelete)
              Semantics(
                button: true,
                label: l10n.comm_more_label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showActions(comment),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text('•••', style: BldrCommunityTextV2.more),
                  ),
                ),
              ),
          ]),
          Text(meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrCommunityTextV2.meta),
          const SizedBox(height: 6),
          Text(comment.body, style: BldrCommunityTextV2.commentBody),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openReply(_replyDraftFor(comment, root)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(l10n.comm_comment_reply,
                    style: BldrCommunityTextV2.commentAction),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _ReplyDraft {
  final CommunityComment rootComment;
  final CommunityComment target;
  final String initialText;

  const _ReplyDraft(
      {required this.rootComment, required this.target, this.initialText = ''});

  String get targetHandle {
    final username = target.username?.trim();
    return username?.isNotEmpty == true ? '@$username' : target.authorName;
  }

  String get persistedBody {
    final text = initialText.trim();
    final username = target.username?.trim();
    return username?.isNotEmpty == true && !text.startsWith('@$username')
        ? '@$username $text'
        : text;
  }

  _ReplyDraft withText(String value) =>
      _ReplyDraft(rootComment: rootComment, target: target, initialText: value);
}

class _ReplyComposer extends StatefulWidget {
  final _ReplyDraft draft;
  const _ReplyComposer({required this.draft});

  @override
  State<_ReplyComposer> createState() => _ReplyComposerState();
}

class _ReplyComposerState extends State<_ReplyComposer> {
  late final _text = TextEditingController(text: widget.draft.initialText);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    if (_text.text.trim().isEmpty) return;
    Navigator.of(context).pop(widget.draft.withText(_text.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _text,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          maxLength: 300,
          cursorColor: BldrCommunityColorsV2.gold,
          textCapitalization: TextCapitalization.sentences,
          style: BldrCommunityTextV2.commentBody,
          decoration: InputDecoration(
            hintText: l10n.comm_reply_hint,
            hintStyle: BldrCommunityTextV2.sheetSub,
            counterStyle: BldrCommunityTextV2.sheetSub,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BldrCommunityV2.ctaRadius),
              borderSide:
                  const BorderSide(color: BldrCommunityColorsV2.discoverBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BldrCommunityV2.ctaRadius),
              borderSide: const BorderSide(color: BldrCommunityColorsV2.gold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        BldrV2SheetButton(label: l10n.comm_reply_send, onTap: _send),
      ],
    );
  }
}
