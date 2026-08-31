import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_comment.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_profile.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class CommunityCommentsSheet extends StatefulWidget {
  final String feedId;
  const CommunityCommentsSheet({super.key, required this.feedId});

  @override
  State<CommunityCommentsSheet> createState() => _CommentsState();
}

class _CommentsState extends State<CommunityCommentsSheet> {
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
    _commentsChannel = Supabase.instance.client
        .channel('comments_${widget.feedId}')
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
    final reply = await showModalBottomSheet<_ReplyDraft>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .68),
      builder: (_) => _ReplyComposerSheet(
        draft: draft,
        currentProfile: _currentProfile,
      ),
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
    _persist(optimistic, retry: reply);
  }

  _ReplyDraft _replyDraftFor(CommunityComment target, CommunityComment root) =>
      _ReplyDraft(rootComment: root, target: target);

  Future<void> _edit(CommunityComment comment) async {
    final controller = TextEditingController(text: comment.body);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar comentário'),
        content: TextField(controller: controller, maxLength: 300),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Salvar')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    final result = await _repo.editComment(id: comment.id, body: value);
    if (!mounted) return;
    if (result.isFailure) {
      _message(result.failureOrNull!.message);
      return;
    }
    await _load();
  }

  Future<void> _delete(CommunityComment comment) async {
    final result = await _repo.deleteComment(comment.id);
    if (!mounted) return;
    if (result.isFailure) {
      _message(result.failureOrNull!.message);
      return;
    }
    await _load();
  }

  void _message(String value, {VoidCallback? retry}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value),
        action: retry == null
            ? null
            : SnackBarAction(label: 'Tentar novamente', onPressed: retry),
      ));

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          height: MediaQuery.sizeOf(context).height * .78,
          decoration: const BoxDecoration(
            color: BldrColors.bgBase,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: BldrColors.border)),
          ),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: BldrColors.textMuted,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text('Comentários', style: BldrText.sectionTitle),
            const SizedBox(height: 14),
            const Divider(height: 1, color: BldrColors.border),
            Expanded(child: _body()),
            const Divider(height: 1, color: BldrColors.border),
            _rootComposer(),
          ]),
        ),
      );

  Widget _rootComposer() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _CommentAvatar(profile: _currentProfile, radius: 17),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _rootText,
                minLines: 1,
                maxLines: 4,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: 'Adicione um comentário...',
                ),
              ),
            ),
            IconButton(
              tooltip: 'Enviar comentário',
              onPressed: _sendingRoot ? null : _sendRoot,
              color: BldrColors.goldBright,
              icon: _sendingRoot
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
            ),
          ]),
        ),
      );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: TextButton(
          onPressed: _load,
          child: Text('$_error\nTentar novamente', textAlign: TextAlign.center),
        ),
      );
    }
    if (_comments.isEmpty) {
      return Center(
          child:
              Text('Seja o primeiro a comentar.', style: BldrText.description));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        for (final comment in _comments) ...[
          _tile(comment: comment, root: comment),
          for (final reply in comment.replies)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 10),
              child: _tile(comment: reply, root: comment, isReply: true),
            ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _tile({
    required CommunityComment comment,
    required CommunityComment root,
    bool isReply = false,
  }) =>
      InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openReply(_replyDraftFor(comment, root)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _CommentAvatar(
            avatarUrl: comment.avatarUrl,
            label: comment.authorName,
            radius: isReply ? 15 : 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(comment.authorName,
                        style: BldrText.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                if (comment.canEdit || comment.canDelete)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    onSelected: (value) =>
                        value == 'edit' ? _edit(comment) : _delete(comment),
                    itemBuilder: (_) => [
                      if (comment.canEdit)
                        const PopupMenuItem(
                            value: 'edit', child: Text('Editar')),
                      if (comment.canDelete)
                        const PopupMenuItem(
                            value: 'delete', child: Text('Excluir')),
                    ],
                  ),
              ]),
              const SizedBox(height: 2),
              Text('${comment.body}${comment.wasEdited ? ' · editado' : ''}',
                  style: BldrText.body),
              const SizedBox(height: 5),
              Row(children: [
                Text(_relativeTime(comment.createdAt), style: BldrText.metaSm),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => _openReply(_replyDraftFor(comment, root)),
                  style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(
                    Localizations.localeOf(context).languageCode == 'en'
                        ? 'Reply'
                        : 'Responder',
                    style: BldrText.buttonSecondary,
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      );

  String _relativeTime(DateTime value) {
    final delta = DateTime.now().difference(value);
    if (delta.inMinutes < 1) return 'agora';
    if (delta.inHours < 1) return '${delta.inMinutes} min';
    if (delta.inDays < 1) return '${delta.inHours} h';
    return '${delta.inDays} d';
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

class _ReplyComposerSheet extends StatefulWidget {
  final _ReplyDraft draft;
  final CommunityProfile? currentProfile;

  const _ReplyComposerSheet({
    required this.draft,
    required this.currentProfile,
  });

  @override
  State<_ReplyComposerSheet> createState() => _ReplyComposerSheetState();
}

class _ReplyComposerSheetState extends State<_ReplyComposerSheet> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.draft.initialText);
  }

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
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
            decoration: const BoxDecoration(
              color: BldrColors.bgBase,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: BldrColors.border)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  height: 4,
                  width: 36,
                  decoration: BoxDecoration(
                      color: BldrColors.textMuted,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: Text('Respondendo a ${widget.draft.targetHandle}',
                        style: BldrText.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _CommentAvatar(profile: widget.currentProfile, radius: 17),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _text,
                    autofocus: true,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                        counterText: '', hintText: 'Escreva uma resposta...'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                TextButton(onPressed: _send, child: const Text('Enviar')),
              ]),
            ]),
          ),
        ),
      );
}

class _CommentAvatar extends StatelessWidget {
  final CommunityProfile? profile;
  final String? avatarUrl;
  final String? label;
  final double radius;

  const _CommentAvatar(
      {this.profile, this.avatarUrl, this.label, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    final image = avatarUrl ?? profile?.avatarUrl;
    final name = label ?? profile?.displayName ?? 'Atleta';
    return CircleAvatar(
      radius: radius,
      backgroundColor: BldrColors.goldTint,
      backgroundImage: image?.isNotEmpty == true ? NetworkImage(image!) : null,
      child: image?.isNotEmpty == true
          ? null
          : Text(name.isNotEmpty ? name[0].toUpperCase() : 'A',
              style: BldrText.meta.copyWith(color: BldrColors.goldBright)),
    );
  }
}
