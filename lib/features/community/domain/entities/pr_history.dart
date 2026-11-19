/// Melhor série de um dia para um exercício (RPC `public_pr_history`).
class PrHistoryEntry {
  final DateTime performedOn;
  final double weightKg;
  final int reps;
  final double e1rm;

  const PrHistoryEntry({
    required this.performedOn,
    required this.weightKg,
    required this.reps,
    required this.e1rm,
  });

  factory PrHistoryEntry.fromRow(Map<String, dynamic> row) => PrHistoryEntry(
        performedOn: DateTime.parse(row['performed_on'] as String),
        weightKg: (row['weight_kg'] as num).toDouble(),
        reps: (row['reps'] as num).toInt(),
        e1rm: (row['e1rm'] as num).toDouble(),
      );
}

/// Comparação do PR do post com o melhor registro anterior a ele.
class PrEvolution {
  final PrHistoryEntry? previous;
  final double? deltaKg;
  final double? deltaPercent;

  const PrEvolution({this.previous, this.deltaKg, this.deltaPercent});

  /// e1RM de Epley, a mesma fórmula da RPC.
  static double epley(double weightKg, int reps) => weightKg * (1 + reps / 30);

  /// [history] pode vir em qualquer ordem. Só contam dias anteriores a
  /// [postDate] (data local do post); sem registro anterior, tudo fica nulo.
  factory PrEvolution.from({
    required List<PrHistoryEntry> history,
    required DateTime postDate,
    required double weightKg,
    required double e1rm,
  }) {
    final day = DateTime(postDate.year, postDate.month, postDate.day);
    PrHistoryEntry? best;
    for (final entry in history) {
      final d = entry.performedOn;
      if (!DateTime(d.year, d.month, d.day).isBefore(day)) continue;
      if (best == null || entry.e1rm > best.e1rm) best = entry;
    }
    if (best == null) return const PrEvolution();
    return PrEvolution(
      previous: best,
      deltaKg: weightKg - best.weightKg,
      deltaPercent: best.e1rm <= 0 ? null : (e1rm / best.e1rm - 1) * 100,
    );
  }
}
