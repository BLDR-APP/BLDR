import 'package:intl/intl.dart';

/// Unidade do tempo relativo do post (4:2 META: "agora", "18 min", "1 h").
enum CommunityAgoUnit { now, minutes, hours, days }

/// Resumo do squad em destaque (80:853), calculado dos dados que o
/// `ArenaRepository` já devolve (participantes e posts do tribunal).
class SquadHubSummary {
  /// Posição do usuário no ranking do squad (1 = líder); null se não está.
  final int? myRank;

  /// Membros distintos com check-in/prova hoje (data local).
  final int trainedToday;

  /// Semana da arena desde `created_at` (1 = primeira semana).
  final int? week;

  /// Post mais recente que não é chat (check-in ou prova).
  final Map<String, dynamic>? latest;

  const SquadHubSummary({
    required this.myRank,
    required this.trainedToday,
    required this.week,
    required this.latest,
  });
}

/// Formatação de apresentação da Comunidade v2. Funções puras.
abstract final class CommunityV2Format {
  static ({CommunityAgoUnit unit, int value}) ago(
      DateTime created, DateTime now) {
    final d = now.difference(created);
    if (d.inMinutes < 1) return (unit: CommunityAgoUnit.now, value: 0);
    if (d.inMinutes < 60) {
      return (unit: CommunityAgoUnit.minutes, value: d.inMinutes);
    }
    if (d.inHours < 24) return (unit: CommunityAgoUnit.hours, value: d.inHours);
    return (unit: CommunityAgoUnit.days, value: d.inDays);
  }

  /// Duração do título do treino: 4320 → "1h 12min"; 2700 → "45min".
  static String duration(int seconds) {
    final min = seconds ~/ 60;
    final h = min ~/ 60;
    return h > 0
        ? '${h}h ${(min % 60).toString().padLeft(2, '0')}min'
        : '${min}min';
  }

  /// Relógio da atividade: 2058 → "34:18"; 3725 → "1:02:05".
  static String clock(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  /// 12480 → "12.480" (pt).
  static String thousands(num value, String locale) =>
      NumberFormat.decimalPattern(locale).format(value.round());

  /// 6.42 → "6,42" (pt).
  static String decimal(double value, String locale, {int digits = 2}) =>
      NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: digits)
          .format(value);

  /// Pace por km: 2058 s em 6,42 km → "5:21". Null se faltar dado.
  static String? pace(int? seconds, double? km) {
    if (seconds == null || km == null || km <= 0 || seconds <= 0) return null;
    final perKm = (seconds / km).round();
    return '${perKm ~/ 60}:${(perKm % 60).toString().padLeft(2, '0')}';
  }

  /// Resumo das séries: 4 séries de 8 com até 32 kg → "4 × 8 · 32 kg".
  /// Usa as repetições mais frequentes e a maior carga.
  static String exerciseMeta(
      List<({double? weightKg, int? reps})> sets, String locale) {
    if (sets.isEmpty) return '';
    final counts = <int, int>{};
    double? top;
    for (final s in sets) {
      if (s.reps case final r?) counts[r] = (counts[r] ?? 0) + 1;
      if (s.weightKg case final w? when top == null || w > top) top = w;
    }
    int? reps;
    counts.forEach((r, c) {
      if (reps == null || c > counts[reps]!) reps = r;
    });
    final head = reps == null ? '${sets.length}' : '${sets.length} × $reps';
    final best = top;
    return best == null || best <= 0 ? head : "$head · ${kg(best, locale)}";
  }

  /// 150 → "150 kg"; 32.5 → "32,5 kg" (pt).
  static String kg(double value, String locale) =>
      '${decimal(value, locale, digits: value % 1 == 0 ? 0 : 1)} kg';

  /// 18/08 → "18 ago".
  static String shortDate(DateTime date, String locale) =>
      DateFormat('dd MMM', locale)
          .format(date)
          .replaceAll('.', '')
          .toLowerCase();

  /// Rótulo da fonte do wearable ("APPLE WATCH", "WHOOP", "GARMIN").
  static String? providerLabel(String? raw) {
    return switch (raw?.toLowerCase().trim()) {
      'whoop' => 'WHOOP',
      'garmin' => 'GARMIN',
      'apple_health' || 'apple_watch' || 'apple' => 'APPLE WATCH',
      _ => null,
    };
  }

  /// "outdoor_run" → "Outdoor Run"; nomes já legíveis ficam como vieram.
  static String activityName(String value) => !value.contains('_')
      ? value
      : value
          .replaceAll('_', ' ')
          .split(' ')
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
          .join(' ');

  /// Dias até o fim do squad; -1 quando encerrado, null sem data de fim.
  static int? squadDaysLeft(Map<String, dynamic> arena, DateTime now) {
    if (arena['is_active'] == false) return -1;
    final end = DateTime.tryParse(arena['end_date']?.toString() ?? '');
    if (end == null) return null;
    final diff = end.toLocal().difference(now);
    return diff.isNegative ? -1 : diff.inDays;
  }

  /// Check-ins e provas, sem as mensagens do chat, do mais novo ao mais antigo.
  static List<Map<String, dynamic>> squadActivity(
          List<Map<String, dynamic>> posts) =>
      posts.where((p) => p['status'] != 'chat').toList();

  /// Mensagens do chat, da mais antiga à mais nova.
  static List<Map<String, dynamic>> squadChat(
          List<Map<String, dynamic>> posts) =>
      posts.where((p) => p['status'] == 'chat').toList().reversed.toList();

  /// Resumo do squad. [participants] já vem ordenado pelo critério do modo
  /// (mesma ordem da tela da arena); [posts] é o `tribunalFeed`.
  static SquadHubSummary squad({
    required Map<String, dynamic> arena,
    required List<Map<String, dynamic>> participants,
    required List<Map<String, dynamic>> posts,
    required String? myUserId,
    required DateTime now,
  }) {
    final idx = myUserId == null
        ? -1
        : participants.indexWhere((p) => p['user_id']?.toString() == myUserId);

    final today = DateTime(now.year, now.month, now.day);
    final trained = <String>{};
    Map<String, dynamic>? latest;
    for (final p in posts) {
      if (p['status'] == 'chat') continue;
      final created = DateTime.tryParse(p['created_at']?.toString() ?? '');
      if (created == null) continue;
      latest ??= p;
      final local = created.toLocal();
      if (!DateTime(local.year, local.month, local.day).isBefore(today)) {
        trained.add(p['user_id'].toString());
      }
    }

    final createdAt = DateTime.tryParse(arena['created_at']?.toString() ?? '');
    final week = createdAt == null
        ? null
        : (now.difference(createdAt.toLocal()).inDays ~/ 7) + 1;

    return SquadHubSummary(
      myRank: idx < 0 ? null : idx + 1,
      trainedToday: trained.length,
      week: week == null || week < 1 ? null : week,
      latest: latest,
    );
  }
}
