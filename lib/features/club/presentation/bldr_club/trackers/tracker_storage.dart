import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TrackerStorage {
  static const _prefix = 'tracker_';

  // ── BLDR RUN modality ──────────────────────────────────────────────
  static const _runModalityKey = '${_prefix}run_modality';

  static Future<String> getRunModality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_runModalityKey) ?? 'corrida';
  }

  static Future<void> saveRunModality(String modality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_runModalityKey, modality);
  }

  // ── Round Timer settings ───────────────────────────────────────────
  static String _roundSettingsKey(String modality) =>
      '${_prefix}round_settings_$modality';

  static Future<Map<String, dynamic>> getRoundSettings(String modality) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_roundSettingsKey(modality));
    if (raw == null) return {'roundMins': 3, 'restMins': 1, 'numRounds': 6};
    return Map<String, dynamic>.from(json.decode(raw));
  }

  static Future<void> saveRoundSettings(
      String modality, int roundMins, int restMins, int numRounds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roundSettingsKey(modality),
        json.encode({'roundMins': roundMins, 'restMins': restMins, 'numRounds': numRounds}));
  }

  // ── Session history ─────────────────────────────────────────────────
  static String _historyKey(String trackerType) =>
      '${_prefix}history_$trackerType';

  static Future<List<Map<String, dynamic>>> getHistory(String trackerType) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey(trackerType));
    if (raw == null) return [];
    final List decoded = json.decode(raw);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> saveSession(
      String trackerType, Map<String, dynamic> session) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory(trackerType);
    history.insert(0, {...session, 'savedAt': DateTime.now().toIso8601String()});
    // Keep last 50 sessions per tracker
    if (history.length > 50) history.removeRange(50, history.length);
    await prefs.setString(_historyKey(trackerType), json.encode(history));
  }

  // ── Personal Records ────────────────────────────────────────────────
  static String _prKey(String trackerType, String metric) =>
      '${_prefix}pr_${trackerType}_$metric';

  static Future<double?> getPR(String trackerType, String metric) async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getDouble(_prKey(trackerType, metric));
    return val;
  }

  static Future<bool> updatePRIfBetter(
      String trackerType, String metric, double value,
      {bool lowerIsBetter = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prKey(trackerType, metric);
    final current = prefs.getDouble(key);
    if (current == null ||
        (lowerIsBetter ? value < current : value > current)) {
      await prefs.setDouble(key, value);
      return true;
    }
    return false;
  }

  // ── Pool Tracker config ─────────────────────────────────────────────
  static const _poolConfigKey = '${_prefix}pool_config';

  static Future<Map<String, dynamic>> getPoolConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_poolConfigKey);
    if (raw == null) return {'laneSize': 25, 'stroke': 'Livre'};
    return Map<String, dynamic>.from(json.decode(raw));
  }

  static Future<void> savePoolConfig(int laneSize, String stroke) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _poolConfigKey, json.encode({'laneSize': laneSize, 'stroke': stroke}));
  }

  // ── Active sports bridge (set by EsportesScreen, read by trackers) ──
  static const _activeSportsKey = '${_prefix}active_sports';

  /// Called by EsportesScreen whenever plans are loaded from Supabase.
  static Future<void> saveActiveSports(List<String> sports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_activeSportsKey, sports);
  }

  /// Returns true if there's already an active protocol that covers [sport].
  /// Matches case-insensitively; e.g. "Tênis" matches plan.sport "Tênis".
  static Future<bool> hasActivePlanForSport(String sport) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_activeSportsKey) ?? [];
    final needle = sport.toLowerCase();
    return saved.any((s) {
      final hay = s.toLowerCase();
      return hay == needle || hay.contains(needle) || needle.contains(hay);
    });
  }

  // ── Protocol day progress ───────────────────────────────────────────
  static String _protocolDayKey(String planId) =>
      '${_prefix}protocol_day_$planId';

  static Future<int> getProtocolCurrentDay(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_protocolDayKey(planId)) ?? 1;
  }

  static Future<void> advanceProtocolDay(String planId, int totalDays) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_protocolDayKey(planId)) ?? 1;
    if (current < totalDays) {
      await prefs.setInt(_protocolDayKey(planId), current + 1);
    }
  }

  static Future<void> clearProtocolState(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys().where((k) => k.contains(planId)).toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }
}
