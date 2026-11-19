/// Abas da central de notificações (121:1128).
enum NotificationTab { all, social, performance }

/// Tipo visual de cada notificação, derivado de `type` e, nos registros
/// antigos sem tipo, do título (mesma heurística da tela anterior).
enum NotificationKind {
  ranking,
  challenge,
  reaction,
  comment,
  follow,
  welcome,
  levelUp,
  success,
  streak,
  wearable,
  info,
}

/// Grupo de data da lista.
enum NotificationGroup { today, yesterday, thisWeek, older }

abstract final class NotificationRules {
  static NotificationKind kind(String? type, String? title) {
    final ty = (type ?? '').toLowerCase();
    final t = (title ?? '').toLowerCase();
    if (ty == 'ranking' || t.contains('ranking'))
      return NotificationKind.ranking;
    if (ty == 'challenge' || t.contains('desafio')) {
      return NotificationKind.challenge;
    }
    if (ty == 'reaction' || t.contains('reagiu') || t.contains('moral')) {
      return NotificationKind.reaction;
    }
    if (ty == 'comment' || ty == 'community_post' || t.contains('comentou')) {
      return NotificationKind.comment;
    }
    if (ty == 'follow' || t.contains('seguir você')) {
      return NotificationKind.follow;
    }
    if (ty == 'level_up' || t.contains('level up') || t.contains('nível')) {
      return NotificationKind.levelUp;
    }
    if (ty == 'success' || t.contains('vitória') || t.contains('venceu')) {
      return NotificationKind.success;
    }
    if (ty == 'streak' || t.contains('streak') || t.contains('sequência')) {
      return NotificationKind.streak;
    }
    if (ty == 'wearable' ||
        ty == 'wearable_activity' ||
        t.contains('treino detectado')) {
      return NotificationKind.wearable;
    }
    if (t.contains('bem-vindo') || t.contains('novo membro')) {
      return NotificationKind.welcome;
    }
    return NotificationKind.info;
  }

  /// Social = interação entre pessoas; Performance = resultado próprio.
  /// Avisos genéricos aparecem só em Todas.
  static bool inTab(NotificationKind kind, NotificationTab tab) =>
      switch (tab) {
        NotificationTab.all => true,
        NotificationTab.social => const {
            NotificationKind.reaction,
            NotificationKind.comment,
            NotificationKind.follow,
            NotificationKind.welcome,
          }.contains(kind),
        NotificationTab.performance => const {
            NotificationKind.ranking,
            NotificationKind.challenge,
            NotificationKind.levelUp,
            NotificationKind.success,
            NotificationKind.streak,
            NotificationKind.wearable,
          }.contains(kind),
      };

  /// Grupo pelo dia do calendário local.
  static NotificationGroup group(DateTime created, DateTime now) {
    final day = DateTime(created.year, created.month, created.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return NotificationGroup.today;
    if (diff == 1) return NotificationGroup.yesterday;
    if (diff < 7) return NotificationGroup.thisWeek;
    return NotificationGroup.older;
  }
}
