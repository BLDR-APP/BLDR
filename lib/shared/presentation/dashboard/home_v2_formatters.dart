import 'package:intl/intl.dart';

import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

/// Formatação de apresentação da Home v2 (Figma 57:388). Funções puras —
/// nenhuma regra de negócio; só transformam o dado que os widgets já recebem.
abstract final class HomeV2Format {
  /// XP compacto no locale: 13200 → "13,2k" (pt) / "13.2k" (en); 20000 → "20k".
  static String xpCompact(int xp, String locale) {
    if (xp < 1000) return '$xp';
    final k = xp / 1000;
    if (k == k.truncateToDouble()) return '${k.toStringAsFixed(0)}k';
    final sep = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
    return '${k.toStringAsFixed(1).replaceAll('.', sep)}k';
  }

  /// Tempo total do chip de consistência: 260 → "4h 20", 240 → "4h",
  /// 45 → "45m", 0 → "—".
  static String totalDuration(int totalMinutes) {
    if (totalMinutes <= 0) return '—';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m.toString().padLeft(2, '0')}';
  }

  /// Inteiro com separador de milhar do locale: 3474 → "3.474" (pt).
  static String thousands(num value, String locale) =>
      NumberFormat.decimalPattern(locale).format(value.round());

  /// Grupos musculares de um template, na ordem dos exercícios, sem
  /// repetição, unidos por " · ". Mesma extração da tela de Treinos
  /// (`primary_muscle_group` como String ou List → texto).
  static String muscleGroups(WorkoutTemplate template) {
    final groups = <String>{};
    for (final row in template.exercises) {
      final text = _muscleGroupText(row.exercise?.primaryMuscleGroup);
      if (text != null && text.isNotEmpty) groups.add(text);
    }
    return groups.join(' · ');
  }

  /// Grupos musculares de uma sessão (ativa, pausada ou concluída), pela
  /// ordem das séries — mesma extração de [muscleGroups].
  static String muscleGroupsFromSession(WorkoutSession session) {
    final groups = <String>{};
    for (final set in session.sets) {
      final text = _muscleGroupText(set.exercise?.primaryMuscleGroup);
      if (text != null && text.isNotEmpty) groups.add(text);
    }
    return groups.join(' · ');
  }

  /// Tempo decorrido desde [start] — mesmo formato do card atual
  /// ("32 min" / "1h 05min").
  static String elapsed(DateTime start, DateTime now) {
    final d = now.difference(start);
    final m = d.inMinutes % 60;
    return d.inHours > 0
        ? '${d.inHours}h ${m.toString().padLeft(2, '0')}min'
        : '${d.inMinutes} min';
  }

  /// Duração do treino concluído: "45min" / "1h 05min".
  static String doneDuration(int seconds) {
    final min = seconds ~/ 60;
    final h = min ~/ 60;
    return h > 0 ? '${h}h ${(min % 60).toString().padLeft(2, '0')}min' : '${min}min';
  }

  /// Volume do concluído: "100kg" / "1.2t"; zero → "—".
  static String volume(double kg) {
    if (kg <= 0) return '—';
    return kg >= 1000 ? '${(kg / 1000).toStringAsFixed(1)}t' : '${kg.toStringAsFixed(0)}kg';
  }

  static String? _muscleGroupText(dynamic value) {
    if (value is String) return value.isEmpty ? null : value;
    if (value is List) {
      final parts =
          value.whereType<String>().where((e) => e.isNotEmpty).toList();
      return parts.isEmpty ? null : parts.join(', ');
    }
    return null;
  }

  /// Quantidade de treinos concluídos na janela dos últimos 7 dias
  /// (hoje incluso), a partir da contagem por dia.
  static int workoutsInLast7Days(Map<DateTime, int> countByDay, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var total = 0;
    for (var i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      total += countByDay[day] ?? 0;
    }
    return total;
  }
}
