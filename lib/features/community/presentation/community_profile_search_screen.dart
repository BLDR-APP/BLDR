import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_profile.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class CommunityProfileSearchScreen extends StatefulWidget {
  const CommunityProfileSearchScreen({super.key});

  @override
  State<CommunityProfileSearchScreen> createState() => _SearchState();
}

class _SearchState extends State<CommunityProfileSearchScreen> {
  final _repository = getIt<CommunityFeedRepository>();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<CommunityProfile> _profiles = [];
  List<CommunityPost> _posts = [];
  bool _loading = false;
  String? _error;
  final Set<String> _updating = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _profiles = [];
        _posts = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final profileResult = await _repository.searchProfiles(query);
    final postResult = await _repository.searchPublicPosts(query);
    if (!mounted) return;
    String? error;
    profileResult.fold(
      onSuccess: (profiles) => _profiles = profiles,
      onFailure: (failure) => error = failure.message,
    );
    postResult.fold(
      onSuccess: (posts) => _posts = posts,
      onFailure: (failure) => error ??= failure.message,
    );
    setState(() {
      _error = error;
      _loading = false;
    });
  }

  Future<void> _toggle(CommunityProfile profile) async {
    setState(() => _updating.add(profile.id));
    final result = profile.isFollowing
        ? await _repository.unfollowUser(profile.id)
        : await _repository.followUser(profile.id);
    if (!mounted) return;
    result.fold(
      onSuccess: (_) => setState(() {
        final index = _profiles.indexWhere((item) => item.id == profile.id);
        if (index != -1) {
          _profiles[index] =
              profile.copyWith(isFollowing: !profile.isFollowing);
        }
        _updating.remove(profile.id);
      }),
      onFailure: (failure) {
        setState(() => _updating.remove(profile.id));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BldrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Buscar na comunidade', style: BldrText.screenTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                onChanged: _onChanged,
                style: BldrText.body,
                decoration: const InputDecoration(
                  hintText: 'Nome, @username ou legenda',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: BldrText.body, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => _search(_controller.text),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (_controller.text.trim().length < 2) {
      return Center(
        child:
            Text('Digite ao menos 2 caracteres.', style: BldrText.description),
      );
    }
    if (_profiles.isEmpty && _posts.isEmpty) {
      return Center(
        child: Text('Nenhum resultado encontrado.', style: BldrText.body),
      );
    }
    return ListView(
      children: [
        if (_profiles.isNotEmpty) ...[
          Text('Atletas', style: BldrText.sectionTitle),
          ..._profiles.map(_buildProfile),
        ],
        if (_posts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Posts públicos', style: BldrText.sectionTitle),
          ..._posts.map(
            (post) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.article_outlined),
              title: Text(
                post.caption ?? 'Publicação',
                style: BldrText.cardTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(post.displayName, style: BldrText.description),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfile(CommunityProfile profile) {
    final busy = _updating.contains(profile.id);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage: profile.avatarUrl?.isNotEmpty == true
            ? NetworkImage(profile.avatarUrl!)
            : null,
        child: profile.avatarUrl?.isNotEmpty == true
            ? null
            : Text(profile.displayName[0].toUpperCase()),
      ),
      title: Text(profile.displayName, style: BldrText.cardTitle),
      subtitle: profile.username == null
          ? null
          : Text('@${profile.username}', style: BldrText.description),
      trailing: TextButton(
        onPressed: busy ? null : () => _toggle(profile),
        child: Text(
          busy
              ? '...'
              : profile.isFollowing
                  ? 'Seguindo'
                  : 'Seguir',
        ),
      ),
    );
  }
}
