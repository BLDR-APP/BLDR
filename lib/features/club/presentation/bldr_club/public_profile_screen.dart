// lib/presentation/bldr_club/public_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String? displayName;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.displayName,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  static const _gold = Color(0xFFD4AF37);


  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _rankData;
  int _rankPosition = 0;
  int _totalWorkouts = 0;
  int _currentStreak = 0;
  List<Map<String, dynamic>> _recentActivity = [];

  String? get _myUserId => getIt<GetCurrentUser>()()?.id;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await getIt<GetPublicClubProfile>()(widget.userId);
      final p = result.valueOrNull;
      if (p == null) throw Exception(result.failureOrNull?.message);

      if (mounted) {
        setState(() {
          _profileData = {
            'id': p.userId,
            'full_name': p.fullName,
            'avatar_url': p.avatarUrl,
            'email': p.email,
          };
          _rankData = {
            'xp_total': p.xpTotal,
            'current_level': p.currentLevel,
          };
          _rankPosition = p.rankPosition;
          _totalWorkouts = p.totalWorkouts;
          _recentActivity = p.recentActivity
              .map((e) => {
                    'id': e.id,
                    'delta': e.xp,
                    'reason': e.reason,
                    'created_at': e.createdAt?.toIso8601String(),
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar perfil: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  Color _rankBorderColor() {
    if (_rankPosition == 1) return _gold;
    if (_rankPosition == 2) return Colors.grey.shade400;
    if (_rankPosition == 3) return const Color(0xFFCD7F32);
    return Colors.white24;
  }

  String _timeAgo(String dateString) {
    final date = DateTime.parse(dateString).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _formatAction(String? raw, int xp) {
    final r = (raw ?? '').toLowerCase();
    if (r.contains('treino') || r.contains('workout')) return 'concluiu um treino';
    if (r.contains('pr') || r.contains('record')) return 'bateu um PR';
    if (r.isEmpty) return 'ganhou +$xp XP';
    return raw ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final name = _profileData?['full_name'] ?? widget.displayName ?? 'Atleta';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text('Perfil de $name',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),

                if (_isLoading)
                  const Expanded(
                      child: Center(
                          child: CircularProgressIndicator(color: _gold)))
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 36),
                          const SizedBox(height: 12),
                          Text(_error!,
                              style: const TextStyle(color: Colors.white54),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadProfile,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _gold),
                            child: Text(AppLocalizations.of(context).profile_retry,
                                style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildProfileHeader(name),
                          const SizedBox(height: 16),
                          _buildXpBar(),
                          const SizedBox(height: 12),
                          _buildStatsRow(),
                          const SizedBox(height: 12),
                          _buildBadgesSection(),
                          if (_recentActivity.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildRecentActivity(),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Footer buttons
          if (!_isLoading && _error == null && widget.userId != _myUserId)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0), Colors.black],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context).profile_react_sent),
                              backgroundColor: _gold,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _gold,
                          side: const BorderSide(color: _gold),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(AppLocalizations.of(context).profile_react,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(color: Colors.black),
          child: Stack(
            children: [
              Positioned(
                top: -180,
                left: 0,
                right: 0,
                child: _blob(1.8, 0.22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob(double factor, double opacity) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = MediaQuery.of(context).size.width * factor;
      final c = _gold.withOpacity(opacity);
      return Center(
        child: Container(
          width: w,
          height: w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: RadialGradient(colors: [c, c.withOpacity(0)], radius: 0.75),
          ),
        ),
      );
    });
  }

  Widget _buildProfileHeader(String name) {
    final hasAvatar = (_profileData?['avatar_url'] as String?)?.isNotEmpty == true;
    final avatar = _profileData?['avatar_url'] as String?;
    final level = (_rankData?['current_level'] as num?)?.toInt() ?? 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _rankBorderColor(), width: 3),
              boxShadow: [
                BoxShadow(color: _rankBorderColor().withOpacity(0.3), blurRadius: 16)
              ],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.grey[900],
              backgroundImage: hasAvatar ? NetworkImage(avatar!) : null,
              child: !hasAvatar
                  ? Text(_initials(name),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28))
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (_rankPosition > 0)
                _chip('#$_rankPosition Ranking', Icons.emoji_events),
              _chip('Nível $level', Icons.bolt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _gold, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: _gold, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildXpBar() {
    final totalXp = (_rankData?['xp_total'] as num?)?.toInt() ?? 0;
    final level = (_rankData?['current_level'] as num?)?.toInt() ?? 1;
    const Map<int, int> thresholds = {1: 0, 2: 1000, 3: 2500, 4: 5000, 5: 10000};
    final xpStart = thresholds[level] ?? 0;
    final xpNext = thresholds[level + 1] ?? (xpStart + 10000);
    final gained = totalXp - xpStart;
    final needed = xpNext - xpStart;
    final progress = needed > 0 ? (gained / needed).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$totalXp XP',
                    style: const TextStyle(
                        color: _gold, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Nível ${level + 1} em $xpNext XP',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFF2A2A2A),
                valueColor: const AlwaysStoppedAnimation(_gold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _statCard('$_totalWorkouts', 'Treinos', Icons.fitness_center)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('$_currentStreak', 'Streak', Icons.local_fire_department)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    final totalXp = (_rankData?['xp_total'] as num?)?.toInt() ?? 0;
    final level = (_rankData?['current_level'] as num?)?.toInt() ?? 1;

    final unlockedBadges = [
      if (_totalWorkouts >= 1)
        {'icon': Icons.fitness_center, 'label': 'Atleta'},
      if (_currentStreak >= 7)
        {'icon': Icons.local_fire_department, 'label': 'Streak 7d'},
      if (_rankPosition > 0 && _rankPosition <= 10)
        {'icon': Icons.emoji_events, 'label': 'Top 10'},
      if (level >= 3)
        {'icon': Icons.bolt, 'label': 'Nível 3'},
      if (totalXp >= 1000)
        {'icon': Icons.trending_up, 'label': '1.000 XP'},
    ];

    if (unlockedBadges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech, color: _gold, size: 14),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).profile_achievements,
                  style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: unlockedBadges.map((b) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A2614),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gold.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(b['icon'] as IconData, color: _gold, size: 14),
                    const SizedBox(width: 4),
                    Text(b['label'] as String,
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: _gold, size: 14),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).profile_activity,
                  style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          ..._recentActivity.map((e) {
            final xp = (e['delta'] as num?)?.toInt() ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_formatAction(e['reason'], xp),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: _gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _gold.withOpacity(0.3))),
                    child: Text('+$xp XP',
                        style: const TextStyle(
                            color: _gold, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(_timeAgo(e['created_at']),
                      style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
