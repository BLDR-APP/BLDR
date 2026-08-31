import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_comment.dart';
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
  final _text = TextEditingController();
  List<CommunityComment> _comments = [];
  CommunityComment? _replying;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.fetchComments(widget.feedId);
    if (!mounted) return;
    result.fold(
      onSuccess: (value) => setState(() {
        _comments = value;
        _loading = false;
      }),
      onFailure: (failure) => setState(() {
        _error = failure.message;
        _loading = false;
      }),
    );
  }

  Future<void> _send() async {
    if (_sending || _text.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final result = await _repo.addComment(
      feedId: widget.feedId,
      body: _text.text,
      parentId: _replying?.parentId ?? _replying?.id,
    );
    if (!mounted) return;
    if (result.isFailure) {
      setState(() => _sending = false);
      _message(result.failureOrNull!.message);
      return;
    }
    _text.clear();
    setState(() {
      _sending = false;
      _replying = null;
    });
    await _load();
  }

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

  void _message(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .78,
            child: Column(children: [
              const SizedBox(height: 12),
              Text('Comentários', style: BldrText.sectionTitle),
              const Divider(color: BldrColors.border),
              Expanded(child: _body()),
              if (_replying != null)
                ListTile(
                  dense: true,
                  title: Text('Respondendo a ${_replying!.authorName}',
                      style: BldrText.meta),
                  trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _replying = null)),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                      child: TextField(
                          controller: _text,
                          maxLength: 300,
                          decoration: const InputDecoration(
                              hintText: 'Escreva um comentário...'))),
                  IconButton(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send)),
                ]),
              ),
            ]),
          ),
        ),
      );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
          child: TextButton(
              onPressed: _load,
              child: Text('$_error\nTentar novamente',
                  textAlign: TextAlign.center)));
    if (_comments.isEmpty)
      return Center(
          child:
              Text('Seja o primeiro a comentar.', style: BldrText.description));
    return ListView(children: [
      for (final comment in _comments) ...[
        _tile(comment),
        for (final reply in comment.replies)
          Padding(
              padding: const EdgeInsets.only(left: 32), child: _tile(reply)),
      ],
    ]);
  }

  Widget _tile(CommunityComment comment) => ListTile(
        title: Text(comment.authorName, style: BldrText.cardTitle),
        subtitle: Text(
            '${comment.body}${comment.wasEdited ? ' · editado' : ''}',
            style: BldrText.body),
        onTap: () => setState(() => _replying = comment),
        trailing: comment.canEdit || comment.canDelete
            ? PopupMenuButton<String>(
                onSelected: (value) =>
                    value == 'edit' ? _edit(comment) : _delete(comment),
                itemBuilder: (_) => [
                  if (comment.canEdit)
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  if (comment.canDelete)
                    const PopupMenuItem(
                        value: 'delete', child: Text('Excluir')),
                ],
              )
            : null,
      );
}
