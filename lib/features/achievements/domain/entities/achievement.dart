/// Conquista do catálogo (Supabase `achievements`).
class Achievement {
  final String? id;
  final String name;
  final String? description;
  final String? category;
  final String? iconName;
  final int? xpValue;
  final String? criteriaType;
  final num? criteriaValue;

  const Achievement({
    this.id,
    required this.name,
    this.description,
    this.category,
    this.iconName,
    this.xpValue,
    this.criteriaType,
    this.criteriaValue,
  });
}

/// Conquista já desbloqueada pelo usuário (Supabase `user_achievements`).
class UnlockedAchievement {
  final String? id;
  final String achievementName;
  final String? achievementDescription;
  final DateTime? achievedAt;

  const UnlockedAchievement({
    this.id,
    required this.achievementName,
    this.achievementDescription,
    this.achievedAt,
  });
}
