import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bldr_fitness/features/nutrition/data/models/meal_entry_model.dart';
import 'package:bldr_fitness/features/nutrition/domain/services/food_search_matcher.dart';

/// Acesso cru ao Firestore de nutrição (projeto `alimentosDB`).
/// Coleções: `alimentos`, `user_favorites`, `user_meals`, `user_daily_bonuses`.
/// Não trata erros — exceções sobem para os repositories.
class FirestoreNutritionDatasource {
  final FirebaseFirestore _db;

  FirestoreNutritionDatasource(this._db);

  // --- Catálogo ---

  /// Catálogo em memória (carregado uma vez por sessão; ~600 docs).
  List<Map<String, dynamic>>? _catalog;

  Future<List<Map<String, dynamic>>> _loadCatalog() async =>
      _catalog ??= _withIds(await _db.collection('alimentos').get());

  /// Busca no app, sem diferenciar maiúsculas/minúsculas nem acentos
  /// ([FoodSearchMatcher]). Os nomes gravados são de caixa mista.
  Future<List<Map<String, dynamic>>> searchFoods(String query,
      {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final all = await _loadCatalog();
    final idx = FoodSearchMatcher.match(
        [for (final d in all) '${d['name'] ?? ''}'], query,
        limit: limit);
    return [for (final i in idx) all[i]];
  }

  Future<List<Map<String, dynamic>>> foodsByCategory(String category,
      {int limit = 30}) async {
    final snapshot = await _db
        .collection('alimentos')
        .where('category', isEqualTo: category)
        .limit(limit)
        .get();
    return _withIds(snapshot);
  }

  /// Alimentos favoritos. Ignora as refeições salvas (`type: 'meal'`),
  /// que moram na mesma coleção (N7).
  Future<List<Map<String, dynamic>>> favorites(String userId) async {
    final snapshot = await _db
        .collection('user_favorites')
        .where('user_id', isEqualTo: userId)
        .orderBy('name')
        .get();
    return _withIds(snapshot).where((d) => d['type'] != 'meal').toList();
  }

  /// Refeições salvas: só igualdades (`user_id`, `type`) — sem índice
  /// composto. Ordenadas por nome no cliente.
  Future<List<Map<String, dynamic>>> savedMeals(String userId) async {
    final snapshot = await _db
        .collection('user_favorites')
        .where('user_id', isEqualTo: userId)
        .where('type', isEqualTo: 'meal')
        .get();
    final rows = _withIds(snapshot);
    rows.sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
    return rows;
  }

  Future<Map<String, dynamic>> addFavorite(Map<String, dynamic> data) async {
    final docRef = await _db.collection('user_favorites').add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    final doc = await docRef.get();
    return {...doc.data()!, 'id': doc.id};
  }

  /// Últimos registros do diário, para montar a lista de "recentes".
  Future<List<Map<String, dynamic>>> recentMeals(String userId,
      {int limit = 50}) async {
    final snapshot = await _db
        .collection('user_meals')
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return _withIds(snapshot);
  }

  // --- Diário ---

  Future<void> addMeal(Map<String, dynamic> data) =>
      _db.collection('user_meals').add(data).then((_) {});

  Future<void> updateMeal(String id, Map<String, dynamic> updates) =>
      _db.collection('user_meals').doc(id).update(updates);

  Future<void> deleteMeal(String id) =>
      _db.collection('user_meals').doc(id).delete();

  Future<List<Map<String, dynamic>>> mealsForDate(
      String userId, DateTime date) async {
    final snapshot = await _db
        .collection('user_meals')
        .where('user_id', isEqualTo: userId)
        .where('date', isEqualTo: MealEntryModel.dateKey(date))
        .orderBy('timestamp', descending: false)
        .get();
    return _withIds(snapshot);
  }

  /// Vários dias numa consulta: só filtros de igualdade (`user_id ==` e
  /// `date in`), atendidos pelos índices simples — sem índice composto.
  /// O `in` aceita até 30 valores; acima disso, divide em lotes.
  Future<List<Map<String, dynamic>>> mealsForDateKeys(
      String userId, List<String> dateKeys) async {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < dateKeys.length; i += 30) {
      final chunk = dateKeys.sublist(
          i, i + 30 > dateKeys.length ? dateKeys.length : i + 30);
      final snapshot = await _db
          .collection('user_meals')
          .where('user_id', isEqualTo: userId)
          .where('date', whereIn: chunk)
          .get();
      out.addAll(_withIds(snapshot));
    }
    return out;
  }

  // --- Trava do bônus diário ---

  Future<bool> dailyBonusExists(String userId, DateTime date) async {
    final doc = await _db
        .collection('user_daily_bonuses')
        .doc(_bonusDocId(userId, date))
        .get();
    return doc.exists;
  }

  Future<void> markDailyBonusAwarded(String userId, DateTime date) =>
      _db.collection('user_daily_bonuses').doc(_bonusDocId(userId, date)).set({
        'user_id': userId,
        'date': MealEntryModel.dateKey(date),
        'awarded_at': FieldValue.serverTimestamp(),
      });

  String _bonusDocId(String userId, DateTime date) =>
      '${userId}_${MealEntryModel.dateKey(date)}';

  List<Map<String, dynamic>> _withIds(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
}
