// lib/features/club/presentation/bldr_club/widgets/squad_member_card.dart
import 'package:flutter/material.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Displays one Squad member in a ranking list.
///
/// [data] must contain the keys returned by [ArenaRepository.participantsCombined]:
///   - name      : String
///   - avatar    : String? (URL)
///   - current_score : num?
///   - lives_count   : num?  (survivor mode)
///   - user_id   : String
///
/// [mode] drives which metric is displayed ('alpha', 'survivor', 'hustle', 'roadrunner').
/// [rank] is 1-based; used for non-survivor modes.
/// [maxScore] normalises the progress bar; must be >= 1.
class SquadMemberCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final bool isCreator;
  final String mode;
  final int rank;
  final double maxScore;

  const SquadMemberCard({
    super.key,
    required this.data,
    required this.isMe,
    required this.isCreator,
    required this.mode,
    required this.rank,
    required this.maxScore,
  });

  static Color _scoreColor(String mode) {
    switch (mode) {
      case 'roadrunner': return Colors.cyanAccent;
      case 'hustle':     return Colors.orangeAccent;
      default:           return BldrColors.goldBright;
    }
  }

  static String _scoreLabel(String mode, double score) {
    switch (mode) {
      case 'roadrunner': return '${score.toStringAsFixed(1)} KM';
      case 'hustle':     return '${score.toInt()} DIAS';
      default:           return '${score.toInt()} PTS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int lives     = (data['lives_count'] as num?)?.toInt() ?? 0;
    final String name   = (data['name'] as String?) ?? 'Atleta';
    final String? avatar = data['avatar'] as String?;
    final double score  = (data['current_score'] as num?)?.toDouble() ?? 0.0;
    final double ratio  = (score / maxScore).clamp(0.0, 1.0);
    final bool isSurvivor = mode == 'survivor';
    final Color scoreColor = _scoreColor(mode);

    final Color borderColor = isCreator
        ? BldrColors.goldBorder
        : isMe
            ? Colors.green.withOpacity(0.4)
            : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: BldrColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank number (non-survivor only)
              if (!isSurvivor)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: isMe ? Colors.green : BldrColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Avatar
              _Avatar(name: name, url: avatar, isCreator: isCreator),
              const SizedBox(width: 12),

              // Name + badges
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isMe ? '$name (Você)' : name,
                        style: TextStyle(
                          color: isMe ? Colors.green : BldrColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCreator) ...[
                      const SizedBox(width: 6),
                      _CreatorBadge(),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Score / lives
              if (isSurvivor)
                Row(
                  children: List.generate(2, (i) => Icon(
                    i < lives ? Icons.favorite : Icons.favorite_border,
                    color: i < lives ? Colors.red : BldrColors.textMuted,
                    size: 18,
                  )),
                )
              else
                Text(
                  _scoreLabel(mode, score),
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),

          // Progress bar (non-survivor)
          if (!isSurvivor) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 3,
                backgroundColor: BldrColors.track,
                color: scoreColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? url;
  final bool isCreator;

  const _Avatar({required this.name, this.url, required this.isCreator});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: url != null ? NetworkImage(url!) : null,
          backgroundColor: isCreator
              ? BldrColors.goldTint
              : const Color(0xFF2A2A2A),
          child: url == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: isCreator ? BldrColors.goldBright : BldrColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (isCreator)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: BldrColors.goldSolid,
                shape: BoxShape.circle,
                border: Border.all(color: BldrColors.bgBase, width: 1.5),
              ),
              child: const Icon(Icons.star, size: 7, color: Colors.black),
            ),
          ),
      ],
    );
  }
}

class _CreatorBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: BldrColors.goldTint,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: BldrColors.goldBorder),
      ),
      child: const Text(
        'Criador',
        style: TextStyle(
          color: BldrColors.goldBright,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
