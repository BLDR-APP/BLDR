import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/achievements/domain/usecases/achievement_usecases.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';

class AchievementProvider extends ChangeNotifier {
  static const _storageKey  = 'bldr_unseen_achievements';

  final List<Map<String, dynamic>> _queue = [];
  bool _isChecking = false;
  RealtimeChannel? _channel;

  List<Map<String, dynamic>> get queue => List.unmodifiable(_queue);
  Map<String, dynamic>?      get current => _queue.isNotEmpty ? _queue.first : null;
  bool                        get hasPending => _queue.isNotEmpty;

  Future<void> init() async {
    await _loadUnseen();
    await _subscribeRealtime(); // awaited: garante canal pronto antes do backfill
    await _runBackfill();
  }

  Future<void> _subscribeRealtime() async {
    final user = getIt<AuthRepository>().currentUser;
    if (user == null) return;

    final completer = Completer<void>();

    _channel = Supabase.instance.client
        .channel('user_achievements:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_achievements',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) => _onNewAchievement(payload),
        )
        .subscribe((status, [error]) {
          debugPrint('[ACH-REALTIME] status: $status error: $error');
          if (status == RealtimeSubscribeStatus.subscribed) {
            if (!completer.isCompleted) completer.complete();
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            debugPrint('[ACH-REALTIME] falhou — backfill como fallback');
            if (!completer.isCompleted) completer.complete();
          }
        });

    // Timeout de segurança: não travar o init se o Realtime demorar
    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => debugPrint('[ACH-REALTIME] timeout ao conectar'),
    );
  }

  Future<void> _onNewAchievement(PostgresChangePayload payload) async {
    final row  = payload.newRecord;
    final name = row['achievement_name'] as String?;
    if (name == null) return;
    if (_queue.any((a) => a['name'] == name)) return;

    debugPrint('[ACH-RT] novo insert: $name');

    try {
      final result = await Supabase.instance.client
          .from('achievements')
          .select()
          .eq('name', name)
          .maybeSingle();

      final achievement = result != null
          ? Map<String, dynamic>.from(result as Map)
          : {
              'name':        name,
              'description': row['achievement_description'] ?? '',
              'icon_name':   'emoji_events',
            };

      _queue.add(achievement);
      await _persistUnseen();
      notifyListeners();
    } catch (e) {
      debugPrint('[ACH-RT] ERRO _onNewAchievement: $e');
    }
  }

  /// Backfill incremental: roda a cada abertura do app, mas checkAndUnlock
  /// já filtra conquistas obtidas — só processa as pendentes.
  Future<void> _runBackfill() async {
    if (!getIt<AuthRepository>().isAuthenticated) return;
    try {
      for (final trigger in ['workout', 'onboarding', 'profile', 'nutrition', 'photo', 'bldr_club']) {
        await getIt<CheckAndUnlockAchievements>()(trigger);
      }
    } catch (_) {}
  }

  /// Verifica e desbloqueia conquistas não cobertas pelo trigger do banco
  /// (consecutive_days, weekend_warrior, trained_before_hour, etc.).
  /// O toast é disparado pelo Realtime listener (_onNewAchievement).
  Future<void> checkAchievements(String triggerType) async {
    if (!getIt<AuthRepository>().isAuthenticated) return;
    if (_isChecking) return;
    _isChecking = true;
    debugPrint('[ACH] checkAchievements trigger=$triggerType');
    try {
      await getIt<CheckAndUnlockAchievements>()(triggerType);
    } catch (e, st) {
      debugPrint('[ACH] ERRO checkAchievements: $e\n$st');
    } finally {
      _isChecking = false;
    }
  }

  void dismissCurrent() {
    if (_queue.isEmpty) return;
    _queue.removeAt(0);
    _persistUnseen();
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _persistUnseen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_queue.isEmpty) {
        await prefs.remove(_storageKey);
      } else {
        await prefs.setString(_storageKey, jsonEncode(_queue));
      }
    } catch (_) {}
  }

  Future<void> _loadUnseen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        _queue.addAll(list.cast<Map<String, dynamic>>());
        if (_queue.isNotEmpty) notifyListeners();
      }
    } catch (_) {}
  }
}
