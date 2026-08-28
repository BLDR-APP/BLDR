import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bldr_fitness/features/nutrition/data/models/meal_entry_model.dart';

/// Acesso cru ao Firestore de nutrição (projeto `alimentosDB`).
/// Coleções: `alimentos`, `user_favorites`, `user_meals`, `user_daily_bonuses`.
/// Não trata erros — exceções sobem para os repositories.
class FirestoreNutritionDatasource {
  final FirebaseFirestore _db;

  FirestoreNutritionDatasource(this._db);

  // --- Catálogo ---

  Future<List<Map<String, dynamic>>> searchFoods(String query,
      {int limit = 20}) async {
    if (query.isEmpty) return [];
    final startQuery = query.toUpperCase();
    final endQuery = '$startQuery\uf8ff';

    final snapshot = await _db
        .collection('alimentos')
        .where('name', isGreaterThanOrEqualTo: startQuery)
        .where('name', isLessThan: endQuery)
        .limit(limit)
        .get();
    return _withIds(snapshot);
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

  Future<List<Map<String, dynamic>>> favorites(String userId) async {
    final snapshot = await _db
        .collection('user_favorites')
        .where('user_id', isEqualTo: userId)
        .orderBy('name')
        .get();
    return _withIds(snapshot);
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
