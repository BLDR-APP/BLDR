// lib/presentation/bldr_club/collective_challenge_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';

class CollectiveChallengeDetailScreen extends StatefulWidget {
  const CollectiveChallengeDetailScreen({
    super.key,
    required this.challengeId,
  });

  final String challengeId;

  @override
  State<CollectiveChallengeDetailScreen> createState() =>
      _CollectiveChallengeDetailScreenState();
}

class _CollectiveChallengeDetailScreenState
    extends State<CollectiveChallengeDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFD4AF37);
  static const _green = Color(0xFF4CAF50);
  static const _red = Color(0xFFEF5350);

  final _commentController = TextEditingController();
  late final TabController _tabController;

  String? get _myUserId => getIt<GetCurrentUser>()()?.id;

  // Challenge data
  Map<String, dynamic>? _challenge;
  bool _loading = true;

  // Participation
  bool _isJoined = false;
  int _myContribution = 0;
  bool _joiningLeaving = false;

  // Top contributors
  List<Map<String, dynamic>> _topContributors = [];

  // Recent feed
  List<Map<String, dynamic>> _recentFeed = [];

  // Milestones
  List<Map<String, dynamic>> _milestones = [];

  // Podium
  bool _podiumShown = false;

  // Comments
  List<Map<String, dynamic>> _comments = [];
  bool _sendingComment = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([
      _fetchChallenge(),
      _fetchParticipation(),
      _fetchTopContributors(),
      _fetchMilestones(),
      _fetchComments(),
    ]);
    await _fetchRecentFeed(); // needs participant list first
    if (mounted) setState(() => _loading = false);
    if (!_podiumShown &&
        (_challenge?['status'] as String?) == 'completed' &&
        _topContributors.isNotEmpty) {
      _podiumShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPodiumModal();
      });
    }
  }

  Future<void> _fetchChallenge() async {
    final result = await getIt<GetChallengeDetail>()(widget.challengeId);
    final c = result.valueOrNull;
    if (mounted && c != null) {
      setState(() => _challenge = {
            'id': c.id,
            'title': c.title,
            'description': c.description,
            'challenge_type': c.challengeType,
            'target_value': c.targetValue,
            'current_value': c.currentValue,
            'reward_xp': c.rewardXp,
            'reward_badge': c.rewardBadge,
            'cover_image_url': c.coverImageUrl,
            'ends_at': c.endsAt?.toIso8601String(),
            'status': c.status,
            'created_by': c.createdBy,
            'created_at': c.createdAt?.toIso8601String(),
            'is_official': c.isOfficial,
            'allowed_sources': c.allowedSources,
            'participant_count': c.participantCount,
          });
    }
  }

  Future<void> _fetchParticipation() async {
    if (_myUserId == null) return;
    final result =
        await getIt<GetMyChallengeParticipation>()(widget.challengeId);
    final p = result.valueOrNull;
    if (mounted && p != null) {
      setState(() {
        _isJoined = p.joined;
        _myContribution = p.contribution;
      });
    }
  }

  Future<void> _fetchTopContributors() async {
    final result =
        await getIt<GetChallengeTopContributors>()(widget.challengeId);
    final contributors = result.valueOrNull;
    if (contributors == null || contributors.isEmpty) return;

    if (mounted) {
      setState(() {
        _topContributors = contributors.map((c) {
          final parts = c.name.trim().split(' ');
          final initials = parts.length >= 2
              ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
              : parts[0][0].toUpperCase();
          return {
            'user_id': c.userId,
            'name': c.name,
            'initials': initials,
            'avatar_url': c.avatarUrl,
            'contribution': c.contribution,
          };
        }).toList();
      });
    }
  }

  Future<void> _fetchRecentFeed() async {
    final since =
        DateTime.tryParse((_challenge?['created_at'] as String?) ?? '');
    final result =
        await getIt<GetChallengeFeed>()(widget.challengeId, since: since);
    final items = result.valueOrNull;
    if (items == null) return;

    if (mounted) {
      setState(() {
        _recentFeed = items
            .map((item) => {
                  'user_id': item.userId,
                  'name': item.userName,
                  'reason': item.reason ?? '',
                  'delta': item.delta,
                  'created_at': item.createdAt?.toIso8601String() ?? '',
                  'activity_label': item.activityLabel,
                })
            .toList();
      });
    }
  }

  Future<void> _fetchMilestones() async {
    final result = await getIt<GetChallengeMilestones>()(widget.challengeId);
    final milestones = result.valueOrNull;
    if (mounted && milestones != null) {
      setState(() => _milestones = milestones
          .map((m) => {
                'milestone_pct': m.milestonePct,
                'reached_at': m.reachedAt?.toIso8601String(),
              })
          .toList());
    }
  }

  Future<void> _fetchComments() async {
    final result = await getIt<GetChallengeComments>()(widget.challengeId);
    final comments = result.valueOrNull;
    if (comments == null || comments.isEmpty) return;

    if (mounted) {
      setState(() {
        _comments = comments
            .map((c) => {
                  'id': c.id,
                  'user_id': c.userId,
                  'name': c.userName,
                  'avatar_url': c.avatarUrl,
                  'content': c.content,
                  'created_at': c.createdAt?.toIso8601String() ?? '',
                })
            .toList();
      });
    }
  }

  Future<void> _joinChallenge() async {
    if (_myUserId == null || _joiningLeaving) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _joiningLeaving = true);
    try {
      final result = await getIt<JoinCollectiveChallenge>()(widget.challengeId);
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);

      setState(() => _isJoined = true);
      await _fetchChallenge();
      messenger.showSnackBar(const SnackBar(
        content: Text('✅ Você entrou no desafio!'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao entrar: $e'),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _joiningLeaving = false);
    }
  }

  Future<void> _leaveChallenge() async {
    if (_myUserId == null || _joiningLeaving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair do desafio?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Seu progresso individual será perdido e você não receberá a recompensa caso o grupo conclua.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair',
                style: TextStyle(color: _red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _joiningLeaving = true);
    try {
      final result =
          await getIt<LeaveCollectiveChallenge>()(widget.challengeId);
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);

      setState(() {
        _isJoined = false;
        _myContribution = 0;
      });
      await _fetchChallenge();
      messenger.showSnackBar(const SnackBar(
        content: Text('Você saiu do desafio.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao sair: $e'),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _joiningLeaving = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _myUserId == null || _sendingComment) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sendingComment = true);
    try {
      final result =
          await getIt<AddChallengeComment>()(widget.challengeId, text);
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);
      _commentController.clear();
      await _fetchComments();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao comentar: $e'),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  void _shareChallenge() {
    final c = _challenge;
    if (c == null) return;
    final title = c['title'] as String? ?? 'Desafio Coletivo';
    final target = c['target_value'];
    final type = _typeSuffix(c['challenge_type'] as String? ?? '');
    Share.share(
      '🏆 Participe do desafio coletivo "$title" no BLDR CLUB!\n'
      'Meta: $target $type\n'
      'Recompensa: +${c['reward_xp']} XP\n\n'
      'Baixe o BLDR e junte-se à comunidade!',
      subject: title,
    );
  }

  Future<void> _reportChallenge() async {
    if (_myUserId == null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String selected = 'Conteúdo inadequado';
        final options = [
          'Conteúdo inadequado',
          'Spam ou publicidade',
          'Informações falsas',
          'Outro',
        ];
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Denunciar desafio',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map((o) => RadioListTile<String>(
                        value: o,
                        groupValue: selected,
                        onChanged: (v) => setS(() => selected = v!),
                        title: Text(o,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        activeColor: _gold,
                        dense: true,
                      ))
                  .toList(),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white54))),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: const Text('Denunciar',
                      style:
                          TextStyle(color: _red, fontWeight: FontWeight.bold))),
            ],
          ),
        );
      },
    );

    if (reason == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await getIt<ReportChallenge>()(widget.challengeId, reason);
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);
      messenger.showSnackBar(const SnackBar(
        content: Text('Denúncia enviada. Obrigado!'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Você já denunciou este desafio.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _typeSuffix(String type) {
    switch (type) {
      case 'workouts':
        return 'treinos';
      case 'streak':
        return 'dias';
      default:
        return 'XP';
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'workouts':
        return 'Treinos';
      case 'streak':
        return 'Streak';
      default:
        return 'XP Total';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'workouts':
        return Icons.fitness_center;
      case 'streak':
        return Icons.local_fire_department;
      default:
        return Icons.bolt;
    }
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _feedLabel(String reason) {
    switch (reason) {
      case 'workout_complete':
        return 'completou um treino';
      case 'progress_photo':
        return 'enviou uma foto de progresso';
      case 'streak':
        return 'manteve a sequência';
      case 'run_complete':
        return 'completou uma corrida';
      case 'achievement':
        return 'conquistou uma conquista';
      default:
        return 'contribuiu com +XP';
    }
  }

  /// Status: on track or behind
  _ChallengeStatus _calcStatus() {
    final c = _challenge;
    if (c == null) return _ChallengeStatus.onTrack;

    final createdAt = DateTime.tryParse(c['created_at'] as String? ?? '');
    final endsAt = DateTime.tryParse(c['ends_at'] as String? ?? '');
    if (createdAt == null || endsAt == null) return _ChallengeStatus.onTrack;

    final total = endsAt.difference(createdAt).inSeconds;
    final elapsed = DateTime.now().difference(createdAt).inSeconds;
    if (total <= 0) return _ChallengeStatus.onTrack;

    final pctTime = (elapsed / total).clamp(0.0, 1.0);
    final target = (c['target_value'] as num?)?.toDouble() ?? 1;
    final current = (c['current_value'] as num?)?.toDouble() ?? 0;
    final expectedNow = target * pctTime;

    // On track if actual >= 85% of expected
    return current >= expectedNow * 0.85
        ? _ChallengeStatus.onTrack
        : _ChallengeStatus.behind;
  }

  /// Projection text
  String _projection() {
    final c = _challenge;
    if (c == null) return '';

    final createdAt = DateTime.tryParse(c['created_at'] as String? ?? '');
    final endsAt = DateTime.tryParse(c['ends_at'] as String? ?? '');
    if (createdAt == null || endsAt == null) return '';

    final daysElapsed = DateTime.now().difference(createdAt).inSeconds / 86400;
    final daysRemaining = endsAt.difference(DateTime.now()).inDays;
    if (daysRemaining <= 0) return 'Prazo encerrado.';

    final target = (c['target_value'] as num?)?.toDouble() ?? 1;
    final current = (c['current_value'] as num?)?.toDouble() ?? 0;

    if (daysElapsed < 0.5 || current == 0) {
      return 'Aguardando contribuições para calcular projeção.';
    }

    final dailyRate = current / daysElapsed;
    if (dailyRate <= 0) return 'Sem contribuições ainda.';

    final remaining = target - current;
    final daysToComplete = remaining / dailyRate;

    if (daysToComplete <= daysRemaining) {
      return 'No ritmo atual, a comunidade completa em '
          '${daysToComplete.ceil()} dias. 🚀';
    } else {
      final neededRate = remaining / daysRemaining;
      final pctMore = ((neededRate - dailyRate) / dailyRate * 100).round();
      return 'Atrasados — seria necessário $pctMore% a mais de ritmo para cumprir o prazo.';
    }
  }

  String _timeLeft() {
    final endsAt =
        DateTime.tryParse(_challenge?['ends_at'] as String? ?? '')?.toLocal();
    if (endsAt == null) return '';
    final diff = endsAt.difference(DateTime.now());
    if (diff.isNegative) return 'Encerrado';
    if (diff.inDays > 0) return '${diff.inDays}d restantes';
    if (diff.inHours > 0) return '${diff.inHours}h restantes';
    return 'Termina em breve';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: _gold)),
      );
    }

    final c = _challenge;
    if (c == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Desafio')),
        body: const Center(
            child: Text('Desafio não encontrado.',
                style: TextStyle(color: Colors.white54))),
      );
    }

    final isOfficial = c['is_official'] == true;
    final isCompleted = (c['status'] as String?) == 'completed';
    final coverUrl = c['cover_image_url'] as String?;
    final target = (c['target_value'] as num?)?.toInt() ?? 1;
    final current = (c['current_value'] as num?)?.toInt() ?? 0;
    final progress = (current / target).clamp(0.0, 1.0);
    final myProgress =
        (target > 0) ? (_myContribution / target).clamp(0.0, 1.0) : 0.0;
    final status = _calcStatus();
    final participantCount = c['participant_count'] as int? ?? 0;
    final rewardXp = (c['reward_xp'] as num?)?.toInt() ?? 0;
    final badge = c['reward_badge'] as String? ?? '';
    final challengeType = c['challenge_type'] as String? ?? 'xp_total';
    final suffix = _typeSuffix(challengeType);
    final createdBy = c['created_by']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Background glow ───────────────────────────────────────────────
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 1.4,
                  height: MediaQuery.of(context).size.width * 1.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _gold.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // ── Cover image + app bar ─────────────────────────────────────
              SliverAppBar(
                expandedHeight:
                    coverUrl != null && coverUrl.isNotEmpty ? 240.0 : 0.0,
                pinned: true,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_back_ios,
                        size: 16, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // Share button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.share_outlined,
                          size: 16, color: Colors.white),
                    ),
                    onPressed: _shareChallenge,
                  ),
                  // Edit sources (creator only)
                  if (createdBy == _myUserId)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune, size: 16, color: _gold),
                      ),
                      onPressed: () => _showEditSheet(
                        currentSources: List<String>.from(
                            (c['allowed_sources'] as List?)?.cast<String>() ??
                                []),
                        currentTarget: target,
                        currentType: challengeType,
                      ),
                    ),
                  // Report (user-created) or nothing (official)
                  if (!isOfficial && createdBy != _myUserId)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.flag_outlined,
                            size: 16, color: Colors.white54),
                      ),
                      onPressed: _reportChallenge,
                    ),
                ],
                flexibleSpace: coverUrl != null && coverUrl.isNotEmpty
                    ? FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: const Color(0xFF111111)),
                            ),
                            // Bottom gradient
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black,
                                  ],
                                  stops: [0.5, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),

              // ── Body content ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ── Title row ─────────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isOfficial)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _gold.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: _gold.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.verified,
                                            color: _gold, size: 12),
                                        SizedBox(width: 4),
                                        Text('OFICIAL BLDR',
                                            style: TextStyle(
                                                color: _gold,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1)),
                                      ],
                                    ),
                                  ),
                                Text(
                                  c['title'] as String? ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? _green.withOpacity(0.12)
                                  : status == _ChallengeStatus.onTrack
                                      ? _green.withOpacity(0.12)
                                      : _red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCompleted
                                    ? _green.withOpacity(0.4)
                                    : status == _ChallengeStatus.onTrack
                                        ? _green.withOpacity(0.4)
                                        : _red.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? _green
                                        : status == _ChallengeStatus.onTrack
                                            ? _green
                                            : _red,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isCompleted
                                      ? 'Concluído'
                                      : status == _ChallengeStatus.onTrack
                                          ? 'No ritmo'
                                          : 'Atrasado',
                                  style: TextStyle(
                                      color: isCompleted
                                          ? _green
                                          : status == _ChallengeStatus.onTrack
                                              ? _green
                                              : _red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Type chip + time left
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _gold.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_typeIcon(challengeType),
                                    color: _gold, size: 12),
                                const SizedBox(width: 4),
                                Text(_typeLabel(challengeType),
                                    style: const TextStyle(
                                        color: _gold, fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_timeLeft(),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                          const Spacer(),
                          const Icon(Icons.group,
                              color: Colors.white38, size: 13),
                          const SizedBox(width: 4),
                          Text('$participantCount participantes',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),

                      if ((c['description'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          c['description'] as String,
                          style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                              height: 1.5),
                        ),
                      ],

                      const SizedBox(height: 20),
                      _divider('Progresso da Comunidade'),
                      const SizedBox(height: 12),

                      // ── Community progress bar ────────────────────────────
                      _buildProgressCard(
                        label: 'Meta coletiva',
                        current: current,
                        target: target,
                        progress: progress,
                        suffix: suffix,
                        color: _gold,
                        icon: Icons.groups,
                      ),

                      const SizedBox(height: 10),

                      // ── Individual progress bar ───────────────────────────
                      if (_isJoined)
                        _buildProgressCard(
                          label: 'Minha contribuição',
                          current: _myContribution,
                          target: target,
                          progress: myProgress,
                          suffix: suffix,
                          color: const Color(0xFF7C4DFF),
                          icon: Icons.person,
                        ),

                      const SizedBox(height: 14),

                      // ── Projection ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F0F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: status == _ChallengeStatus.onTrack
                                  ? _green.withOpacity(0.2)
                                  : _red.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              status == _ChallengeStatus.onTrack
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: status == _ChallengeStatus.onTrack
                                  ? _green
                                  : _red,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _projection(),
                                style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 12,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Allowed sources chips ─────────────────────────────
                      const SizedBox(height: 20),
                      _buildSourceChips(c),

                      // ── Reward ────────────────────────────────────────────
                      const SizedBox(height: 20),
                      _divider('Recompensa'),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gold.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events,
                                color: _gold, size: 22),
                            const SizedBox(width: 12),
                            Text('+$rewardXp XP',
                                style: const TextStyle(
                                    color: _gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            if (badge.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text('· $badge',
                                    style: TextStyle(
                                        color: Colors.grey[400], fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            const Spacer(),
                            Text('para todos os participantes',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 10)),
                          ],
                        ),
                      ),

                      // ── Milestone history ─────────────────────────────────
                      const SizedBox(height: 20),
                      _divider('Marcos Atingidos'),
                      const SizedBox(height: 12),
                      _buildMilestones(progress),

                      // ── Tab section ───────────────────────────────────────
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              indicatorColor: _gold,
                              labelColor: _gold,
                              unselectedLabelColor: Colors.white38,
                              labelStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                              tabs: const [
                                Tab(text: 'Ranking'),
                                Tab(text: 'Feed'),
                                Tab(text: 'Comentários'),
                              ],
                            ),
                            SizedBox(
                              height: 320,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildRankingTab(),
                                  _buildFeedTab(),
                                  _buildCommentsTab(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom action bar ─────────────────────────────────────────────
          if (!isCompleted)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.08))),
                ),
                child: GestureDetector(
                  onTap: _joiningLeaving
                      ? null
                      : (_isJoined ? _leaveChallenge : _joinChallenge),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: _isJoined
                          ? Colors.redAccent.withOpacity(0.12)
                          : _gold,
                      borderRadius: BorderRadius.circular(14),
                      border: _isJoined
                          ? Border.all(color: Colors.redAccent.withOpacity(0.4))
                          : null,
                    ),
                    child: Center(
                      child: _joiningLeaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    _isJoined ? Colors.redAccent : Colors.black,
                              ),
                            )
                          : Text(
                              _isJoined ? 'Sair do desafio' : 'Participar',
                              style: TextStyle(
                                color:
                                    _isJoined ? Colors.redAccent : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Section helpers ────────────────────────────────────────────────────────

  // ── Source groups definition (mirrors comunidade_screen._sourceGroups) ──────
  static const _sourceGroups = [
    {
      'key': 'bldr_club',
      'label': 'BLDR CLUB',
      'icon': Icons.bolt,
      'criteria': [
        'club_workout_completed',
        'consecutive_club_workouts',
        'monthly_club_workouts'
      ]
    },
    {
      'key': 'bldr_run',
      'label': 'BLDR RUN',
      'icon': Icons.directions_run,
      'criteria': ['run_tracker']
    },
    {
      'key': 'nutrition',
      'label': 'Nutrição',
      'icon': Icons.restaurant,
      'criteria': ['meal_logged', 'daily_meals_bonus', 'hydration_log']
    },
    {
      'key': 'free_workouts',
      'label': 'Treinos Livres',
      'icon': Icons.fitness_center,
      'criteria': ['free_workout_completed']
    },
  ];

  Widget _buildSourceChips(Map<String, dynamic> challenge) {
    final raw = challenge['allowed_sources'];
    final sources = raw == null ? <String>[] : List<String>.from(raw as List);

    final activeGroups = sources.isEmpty
        ? <Map>[]
        : _sourceGroups
            .where((g) => (g['criteria'] as List)
                .cast<String>()
                .any((c) => sources.contains(c)))
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.filter_list, color: _gold, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sources.isEmpty
                  ? 'Todas as atividades contam'
                  : 'Conta: ${activeGroups.map((g) => g['label'] as String).join(' · ')}',
              style: TextStyle(
                  color: sources.isEmpty ? Colors.grey[500] : Colors.grey[300],
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet({
    required List<String> currentSources,
    required int currentTarget,
    required String currentType,
  }) {
    final selected = Set<String>.from(currentSources);
    final targetController =
        TextEditingController(text: currentTarget.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                const Text('Editar desafio',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                if (currentType == 'xp_total') ...[
                  const SizedBox(height: 16),
                  Text('META (XP)',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Ex: 100000',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon:
                          const Icon(Icons.bolt, color: _gold, size: 18),
                      suffixText: 'XP',
                      suffixStyle: const TextStyle(
                          color: _gold, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _gold.withOpacity(0.6)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text('FILTRAR ATIVIDADES',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(
                  selected.isEmpty
                      ? 'Nenhuma seleção = todas contam'
                      : '${selected.length} fonte(s) ativa(s)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 12),
                ..._sourceGroups.map((g) {
                  final criteria = (g['criteria'] as List).cast<String>();
                  final isOn = criteria.any((c) => selected.contains(c));
                  return GestureDetector(
                    onTap: () => setModal(() {
                      if (isOn) {
                        selected.removeAll(criteria);
                      } else {
                        selected.addAll(criteria);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isOn
                            ? _gold.withOpacity(0.07)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isOn ? _gold : Colors.white10,
                            width: isOn ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isOn
                                  ? _gold.withOpacity(0.15)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(g['icon'] as IconData,
                                color: isOn ? _gold : Colors.white54, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(g['label'] as String,
                                style: TextStyle(
                                    color: isOn ? _gold : Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                          Icon(
                            isOn ? Icons.toggle_on : Icons.toggle_off,
                            color: isOn ? _gold : Colors.white30,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        int? newTarget;
                        if (currentType == 'xp_total') {
                          final parsed =
                              int.tryParse(targetController.text.trim());
                          if (parsed != null && parsed > 0) newTarget = parsed;
                        }
                        final result = await getIt<UpdateChallengeSettings>()(
                          widget.challengeId,
                          allowedSources:
                              selected.isEmpty ? null : selected.toList(),
                          targetValue: newTarget,
                        );
                        final failure = result.failureOrNull;
                        if (failure != null) {
                          throw Exception(failure.message);
                        }
                        await _loadAll();
                        messenger.showSnackBar(const SnackBar(
                          content: Text('Desafio atualizado!'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(
                          content: Text('Erro ao salvar: $e'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Salvar alterações',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPodiumModal() {
    final suffix =
        _typeSuffix(_challenge?['challenge_type'] as String? ?? 'xp_total');
    final top3 = _topContributors.take(3).toList();
    final myIndex =
        _topContributors.indexWhere((e) => e['user_id'] == _myUserId);
    final myRank = myIndex >= 0 ? myIndex + 1 : null;
    final myEntry = myIndex >= 0 ? _topContributors[myIndex] : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('🏆', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_gold, Color(0xFFFFE066)],
              ).createShader(bounds),
              child: const Text(
                'DESAFIO CONCLUÍDO!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _challenge?['title'] as String? ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (myEntry != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sua contribuição  ',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 13)),
                    Text('${myEntry['contribution']} $suffix',
                        style: const TextStyle(
                            color: _gold,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            if (top3.isNotEmpty) _buildPodium(top3, suffix),
            if (myRank != null && myRank > 3 && myEntry != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text('${myRank}º',
                          style: const TextStyle(
                              color: _gold,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _gold.withOpacity(0.2),
                      child: const Text('EU',
                          style: TextStyle(
                              color: _gold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Você',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          Text('Sua posição final',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('${myEntry['contribution']} $suffix',
                        style: const TextStyle(
                            color: _gold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('FECHAR',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3, String suffix) {
    Widget podiumSlot(Map<String, dynamic> entry, int rank) {
      final Color color;
      if (rank == 1) {
        color = _gold;
      } else if (rank == 2) {
        color = const Color(0xFF94A3B8);
      } else {
        color = const Color(0xFFCD7C3D);
      }
      final blockH = rank == 1
          ? 72.0
          : rank == 2
              ? 52.0
              : 36.0;
      final avatarRadius = rank == 1 ? 28.0 : 22.0;

      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (rank == 1) const Text('👑', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: const Color(0xFF222222),
            backgroundImage: entry['avatar_url'] != null
                ? NetworkImage(entry['avatar_url'] as String)
                : null,
            child: entry['avatar_url'] == null
                ? Text(entry['initials'] as String,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: rank == 1 ? 16 : 13))
                : null,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              (entry['name'] as String).split(' ')[0],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('${entry['contribution']} $suffix',
              style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          Container(
            width: 80,
            height: blockH,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withOpacity(0.5)],
              ),
            ),
            child: Center(
              child: Text('$rank',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (top3.length > 1) podiumSlot(top3[1], 2),
        const SizedBox(width: 8),
        podiumSlot(top3[0], 1),
        const SizedBox(width: 8),
        if (top3.length > 2) podiumSlot(top3[2], 3),
      ],
    );
  }

  Widget _divider(String label) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.06))),
      ],
    );
  }

  Widget _buildProgressCard({
    required String label,
    required int current,
    required int target,
    required double progress,
    required String suffix,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                '$current / $target $suffix',
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.grey[900],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones(double currentProgress) {
    const milestones = [25, 50, 75, 100];

    return Row(
      children: milestones.map((m) {
        final reached = _milestones.any((ms) => ms['milestone_pct'] == m);
        // Also check client-side for already-reached based on current progress
        final passedByCurrent = (currentProgress * 100) >= m;
        final isReached = reached || passedByCurrent;
        final ms = _milestones.firstWhere((ms) => ms['milestone_pct'] == m,
            orElse: () => {});
        final reachedAt = ms['reached_at'] as String?;

        return Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isReached
                      ? _gold.withOpacity(0.15)
                      : Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: isReached ? _gold : Colors.white.withOpacity(0.1),
                    width: isReached ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$m%',
                    style: TextStyle(
                        color: isReached ? _gold : Colors.white24,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isReached && reachedAt != null
                    ? _formatDate(reachedAt)
                    : isReached
                        ? '✓'
                        : '—',
                style: TextStyle(
                    color: isReached ? Colors.grey[500] : Colors.white12,
                    fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRankingTab() {
    if (_topContributors.isEmpty) {
      return const Center(
        child: Text('Sem contribuições ainda.',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
      );
    }

    final suffix =
        _typeSuffix(_challenge?['challenge_type'] as String? ?? 'xp_total');

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _topContributors.length,
      itemBuilder: (context, i) {
        final entry = _topContributors[i];
        final isMe = entry['user_id'] == _myUserId;
        final contribution = entry['contribution'] as int;
        final medals = ['🥇', '🥈', '🥉'];
        final label = i < 3 ? medals[i] : '${i + 1}º';

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:
                isMe ? _gold.withOpacity(0.07) : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isMe ? _gold.withOpacity(0.3) : Colors.transparent),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 28,
                  child: Text(label,
                      style: TextStyle(
                          fontSize: i < 3 ? 16 : 12, color: Colors.white54))),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: _gold.withOpacity(0.2),
                backgroundImage: entry['avatar_url'] != null
                    ? NetworkImage(entry['avatar_url'] as String)
                    : null,
                child: entry['avatar_url'] == null
                    ? Text(entry['initials'] as String,
                        style: const TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isMe ? 'Você' : entry['name'] as String,
                  style: TextStyle(
                      color: isMe ? _gold : Colors.white,
                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13),
                ),
              ),
              Text('$contribution $suffix',
                  style: const TextStyle(
                      color: _gold, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedTab() {
    if (_recentFeed.isEmpty) {
      return const Center(
        child: Text('Nenhuma contribuição ainda.',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _recentFeed.length,
      itemBuilder: (context, i) {
        final item = _recentFeed[i];
        final isMe = item['user_id'] == _myUserId;
        final delta = item['delta'] as int;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _gold.withOpacity(0.15),
                child: Text(
                  isMe
                      ? 'EU'
                      : (item['name'] as String).isNotEmpty
                          ? (item['name'] as String)[0].toUpperCase()
                          : 'B',
                  style: const TextStyle(
                      color: _gold, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        children: [
                          TextSpan(
                            text: isMe ? 'Você' : item['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          if (item['activity_label'] != null)
                            TextSpan(
                              text: ' completou ',
                            )
                          else
                            TextSpan(
                              text: ' ${_feedLabel(item['reason'] as String)}',
                            ),
                          if (item['activity_label'] != null)
                            TextSpan(
                              text: item['activity_label'] as String,
                              style: const TextStyle(
                                  color: _gold, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(_timeAgo(item['created_at'] as String),
                            style: const TextStyle(
                                color: Colors.white24, fontSize: 10)),
                        const SizedBox(width: 8),
                        Text('+$delta XP',
                            style: const TextStyle(
                                color: _gold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        // Input
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: 'Escreva um comentário...',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendComment,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _sendingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.send, color: Colors.black, size: 16),
                ),
              ),
            ],
          ),
        ),
        // Comments list
        Expanded(
          child: _comments.isEmpty
              ? const Center(
                  child: Text('Seja o primeiro a comentar!',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: _comments.length,
                  itemBuilder: (context, i) {
                    final comment = _comments[i];
                    final isMe = comment['user_id'] == _myUserId;
                    final name = comment['name'] as String;
                    final initial =
                        name.isNotEmpty ? name[0].toUpperCase() : 'B';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: _gold.withOpacity(0.15),
                            backgroundImage: comment['avatar_url'] != null
                                ? NetworkImage(comment['avatar_url'] as String)
                                : null,
                            child: comment['avatar_url'] == null
                                ? Text(initial,
                                    style: const TextStyle(
                                        color: _gold,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isMe ? 'Você' : name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _timeAgo(comment['created_at'] as String),
                                      style: const TextStyle(
                                          color: Colors.white24, fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  comment['content'] as String,
                                  style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

enum _ChallengeStatus { onTrack, behind }
