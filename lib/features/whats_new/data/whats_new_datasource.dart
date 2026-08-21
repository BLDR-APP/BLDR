import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/features/whats_new/domain/entities/whats_new_entity.dart';

const _kSeenPrefix = 'whats_new_seen_';

class WhatsNewDatasource {
  static final _instance = WhatsNewDatasource._();
  factory WhatsNewDatasource() => _instance;
  WhatsNewDatasource._();

  final _client = Supabase.instance.client;

  Future<WhatsNewData?> fetchIfUnseen() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final response = await _client.functions.invoke(
        'get-whats-new',
        body: {'appVersion': info.version},
      );
      if (response.status != 200 || response.data == null) return null;

      final data = response.data as Map<String, dynamic>;
      if (data['show'] != true) return null;

      final id = data['id'] as String;

      // SharedPreferences check: se já viu localmente, não mostra novamente
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('$_kSeenPrefix$id') == true) return null;

      final rawSlides = data['slides'] as List<dynamic>? ?? [];
      return WhatsNewData(
        id: id,
        title: data['title'] as String? ?? 'O que há de novo',
        subtitle: data['subtitle'] as String? ?? '',
        slides: rawSlides
            .map((s) => WhatsNewSlide.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      debugPrint('[WhatsNew] fetch error: $e');
      return null;
    }
  }

  Future<void> markAsSeen(String id) async {
    // Imediato: SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kSeenPrefix$id', true);

    // Background: Supabase BLDR
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client.from('whats_new_seen').upsert({
        'user_id': userId,
        'whats_new_id': id,
      }, onConflict: 'user_id,whats_new_id');
    } catch (e) {
      debugPrint('[WhatsNew] markAsSeen error: $e');
    }
  }
}
