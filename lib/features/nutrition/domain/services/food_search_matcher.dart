/// Busca de alimentos sem diferenciar maiúsculas/minúsculas nem acentos.
///
/// Os nomes do catálogo estão gravados em caixa mista ("Azeite de Oliva"),
/// enquanto a busca antiga fazia prefixo em CAIXA ALTA no Firestore e não
/// encontrava nada. A comparação agora é feita no app.
abstract final class FoodSearchMatcher {
  static const _from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
  static const _to = 'aaaaaaceeeeiiiinooooouuuuyy';

  /// Minúsculas, sem acentos e com espaços normalizados.
  static String normalize(String s) {
    final b = StringBuffer();
    for (final ch in s.toLowerCase().runes) {
      final c = String.fromCharCode(ch);
      final i = _from.indexOf(c);
      b.write(i >= 0 ? _to[i] : c);
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Filtra [names] pelo [query]: todas as palavras precisam aparecer.
  /// Quem começa com o termo vem primeiro; depois, ordem alfabética.
  /// Devolve os índices dos itens encontrados (até [limit]).
  static List<int> match(List<String> names, String query, {int limit = 20}) {
    final q = normalize(query);
    if (q.isEmpty) return const [];
    final words = q.split(' ');
    final hits = <(int, bool, String)>[];
    for (var i = 0; i < names.length; i++) {
      final n = normalize(names[i]);
      if (words.every(n.contains)) hits.add((i, n.startsWith(q), n));
    }
    hits.sort((a, b) {
      if (a.$2 != b.$2) return a.$2 ? -1 : 1;
      return a.$3.compareTo(b.$3);
    });
    return [for (final h in hits.take(limit)) h.$1];
  }
}
