// lib/services/exercise_db_rapid_service.dart
//
// Fonte primária: oss.exercisedb.dev/api/v1 — 1 500+ exercícios com GIFs.
//   IMPORTANTE: paginação usa o parâmetro "after" (não "cursor").
//               limit máximo = 25. Filtro por bodyParts funciona.
//   GIFs: https://static.exercisedb.dev/media/{exerciseId}.gif
//
// Estratégia de carregamento:
//   Buscamos todos os exercícios em paralelo por bodyPart (10 categorias).
//   Cada categoria pode ter até ~13 páginas de 25 exercícios.
//   Resultado: ~1 500 exercícios com GIFs reais em ~4 segundos.
//
// Fonte secundária: RapidAPI AscendAPI (lookup individual por ID)
//   Host: edb-with-videos-and-images-by-ascendapi.p.rapidapi.com
//   Key : c039a66d8fmshb637ecfefe6d2f8p16cf1djsn9b3d2839273b

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class ExDbExercise {
  final String exerciseId;
  final String name;
  final String gifUrl;    // GIF URL (static.exercisedb.dev CDN)
  final String imageUrl;  // fallback static image (RapidAPI)
  final List<String> instructions;
  final List<String> targetMuscles;    // lowercase
  final List<String> bodyParts;        // lowercase
  final List<String> equipments;       // lowercase
  final List<String> secondaryMuscles; // lowercase
  final String apiExerciseType;        // STRENGTH / CARDIO / PLYOMETRICS …

  const ExDbExercise({
    required this.exerciseId,
    required this.name,
    required this.gifUrl,
    this.imageUrl = '',
    required this.instructions,
    required this.targetMuscles,
    required this.bodyParts,
    required this.equipments,
    required this.secondaryMuscles,
    required this.apiExerciseType,
  });

  // ── Display URL ───────────────────────────────────────────────────────────
  String get displayUrl {
    if (gifUrl.isNotEmpty) return gifUrl;
    if (imageUrl.isNotEmpty) return imageUrl;
    // Fallback: construct GIF URL from exerciseId
    if (exerciseId.isNotEmpty) {
      return 'https://static.exercisedb.dev/media/$exerciseId.gif';
    }
    return '';
  }

  // ── Disk-cache serialization ──────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'exerciseId':      exerciseId,
        'name':            name,
        'gifUrl':          gifUrl,
        'imageUrl':        imageUrl,
        'instructions':    instructions,
        'targetMuscles':   targetMuscles,
        'bodyParts':       bodyParts,
        'equipments':      equipments,
        'secondaryMuscles': secondaryMuscles,
        'apiExerciseType': apiExerciseType,
      };

  factory ExDbExercise.fromJson(Map<String, dynamic> j) => ExDbExercise(
        exerciseId:      j['exerciseId']      as String? ?? '',
        name:            j['name']            as String? ?? '',
        gifUrl:          j['gifUrl']          as String? ?? '',
        imageUrl:        j['imageUrl']        as String? ?? '',
        instructions:    List<String>.from(j['instructions']    as List? ?? []),
        targetMuscles:   List<String>.from(j['targetMuscles']   as List? ?? []),
        bodyParts:       List<String>.from(j['bodyParts']       as List? ?? []),
        equipments:      List<String>.from(j['equipments']      as List? ?? []),
        secondaryMuscles: List<String>.from(j['secondaryMuscles'] as List? ?? []),
        apiExerciseType: j['apiExerciseType'] as String? ?? 'STRENGTH',
      );

  // ── OSS factory (oss.exercisedb.dev) ──────────────────────────────────────
  //
  // Fields: exerciseId, name, gifUrl, bodyParts[], equipments[],
  //         targetMuscles[], secondaryMuscles[], instructions[]
  // GIF URL format: https://static.exercisedb.dev/media/{exerciseId}.gif

  factory ExDbExercise.fromOss(Map<String, dynamic> json) {
    String lower(dynamic v) => (v as String? ?? '').toLowerCase();
    List<String> lowerList(dynamic v) =>
        (v as List? ?? []).map((e) => lower(e)).toList();

    final id = json['exerciseId'] as String? ?? '';
    // gifUrl comes from API; if empty, construct from ID
    final rawGif = json['gifUrl'] as String? ?? '';
    final gif = rawGif.isNotEmpty
        ? rawGif
        : (id.isNotEmpty ? 'https://static.exercisedb.dev/media/$id.gif' : '');

    return ExDbExercise(
      exerciseId: id,
      name: (json['name'] as String? ?? '').trim(),
      gifUrl: gif,
      instructions: List<String>.from(json['instructions'] as List? ?? []),
      targetMuscles: lowerList(json['targetMuscles']),
      bodyParts: lowerList(json['bodyParts']),
      equipments: lowerList(json['equipments']),
      secondaryMuscles: lowerList(json['secondaryMuscles']),
      apiExerciseType: 'STRENGTH',
    );
  }

  // ── RapidAPI factory (fallback for individual lookups) ───────────────────
  factory ExDbExercise.fromRapid(Map<String, dynamic> json) {
    String lower(dynamic v) => (v as String? ?? '').toLowerCase();
    List<String> lowerList(dynamic v) =>
        (v as List? ?? []).map((e) => lower(e)).toList();

    return ExDbExercise(
      exerciseId: json['exerciseId'] as String? ?? '',
      name: (json['name'] as String? ?? '').trim(),
      gifUrl: '',
      imageUrl: json['imageUrl'] as String? ?? '',
      instructions: List<String>.from(json['instructions'] as List? ?? []),
      targetMuscles: lowerList(json['targetMuscles']),
      bodyParts: lowerList(json['bodyParts']),
      equipments: lowerList(json['equipments']),
      secondaryMuscles: lowerList(json['secondaryMuscles']),
      apiExerciseType: json['exerciseType'] as String? ?? 'STRENGTH',
    );
  }

  // ── Supabase ENUM mapping ──────────────────────────────────────────────────
  // exercise_type ENUM: compound | isolation | cardio | stretching | plyometric
  // muscle_group  ENUM: chest | back | shoulders | biceps | triceps |
  //                     legs | abs | cardio | full_body

  String get supabaseExerciseType {
    switch (apiExerciseType.toUpperCase()) {
      case 'CARDIO':
        return 'cardio';
      case 'PLYOMETRICS':
        return 'plyometric';
      case 'STRETCHING':
        return 'stretching';
      default:
        return 'compound';
    }
  }

  String get supabasePrimaryMuscle {
    final allParts = [...bodyParts, ...targetMuscles];
    for (final p in allParts) {
      if (p.contains('chest') || p.contains('pectoral')) return 'chest';
      if (p.contains('back') || p.contains('lat') || p.contains('trap') ||
          p.contains('erector') || p.contains('teres') ||
          p.contains('rhomb') || p.contains('spine')) {
        return 'back';
      }
      if (p.contains('shoulder') || p.contains('delt') ||
          p.contains('infraspinatus')) {
        return 'shoulders';
      }
      if (p.contains('bicep')) return 'biceps';
      if (p.contains('tricep')) return 'triceps';
      if (p.contains('quad') || p.contains('hamstring') ||
          p.contains('glute') || p.contains('calf') ||
          p.contains('calve') || p.contains('hip') ||
          p.contains('thigh') || p.contains('gastro') ||
          p.contains('soleus') || p.contains('tibial') ||
          p.contains('adduct') || p.contains('abduct')) {
        return 'legs';
      }
      if (p.contains('waist') || p.contains('abs') ||
          p.contains('oblique') || p.contains('rectus abdominis') ||
          p.contains('abdominal') || p.contains('core')) {
        return 'abs';
      }
      if (p.contains('cardio')) return 'cardio';
    }
    return 'full_body';
  }

  List<String> get supabaseSecondaryMuscles {
    final validGroups = <String>{};
    for (final m in secondaryMuscles) {
      if (m.contains('chest') || m.contains('pectoral')) {
        validGroups.add('chest');
      } else if (m.contains('back') || m.contains('lat') ||
          m.contains('trap') || m.contains('teres') ||
          m.contains('erector')) {
        validGroups.add('back');
      } else if (m.contains('shoulder') || m.contains('delt')) {
        validGroups.add('shoulders');
      } else if (m.contains('bicep')) {
        validGroups.add('biceps');
      } else if (m.contains('tricep')) {
        validGroups.add('triceps');
      } else if (m.contains('quad') || m.contains('hamstring') ||
          m.contains('glute') || m.contains('hip') ||
          m.contains('thigh') || m.contains('calf') ||
          m.contains('gastro') || m.contains('soleus') ||
          m.contains('adduct') || m.contains('abduct')) {
        validGroups.add('legs');
      } else if (m.contains('abs') || m.contains('oblique') ||
          m.contains('waist') || m.contains('abdominal') ||
          m.contains('core')) {
        validGroups.add('abs');
      }
    }
    validGroups.remove(supabasePrimaryMuscle);
    return validGroups.toList();
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class ExerciseDbRapidService {
  static ExerciseDbRapidService? _instance;
  static ExerciseDbRapidService get instance =>
      _instance ??= ExerciseDbRapidService._();
  ExerciseDbRapidService._();

  // ── Endpoints ──────────────────────────────────────────────────────────────

  static const _ossBase = 'https://oss.exercisedb.dev/api/v1';

  static const _rapidBase =
      'https://edb-with-videos-and-images-by-ascendapi.p.rapidapi.com/api/v1';
  static const _rapidKey =
      'c039a66d8fmshb637ecfefe6d2f8p16cf1djsn9b3d2839273b';
  static const _rapidHost =
      'edb-with-videos-and-images-by-ascendapi.p.rapidapi.com';

  static const Map<String, String> _rapidHeaders = {
    'x-rapidapi-key': _rapidKey,
    'x-rapidapi-host': _rapidHost,
  };

  // ── Cache ──────────────────────────────────────────────────────────────────

  List<ExDbExercise>? _cache;
  bool _isFetching = false;

  static const int _minExpectedCount = 800;
  /// Disk cache is considered stale after this many days.
  static const int _diskCacheMaxAgeDays = 7;

  bool _hasLoadErrors = false;
  bool get hasLoadErrors => _hasLoadErrors;
  int get loadedCount => _cache?.length ?? 0;

  // ── Disk cache ─────────────────────────────────────────────────────────────

  Future<File> get _diskCacheFile async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/exercise_db_cache.json.gz');
  }

  /// Loads exercises from disk. Returns null if file is absent, corrupt, or stale.
  Future<List<ExDbExercise>?> _loadFromDisk() async {
    try {
      final file = await _diskCacheFile;
      if (!file.existsSync()) return null;

      final compressed = await file.readAsBytes();
      final jsonBytes  = gzip.decode(compressed);
      final envelope   = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;

      final savedAt = DateTime.tryParse(envelope['saved_at'] as String? ?? '');
      if (savedAt == null) return null;
      if (DateTime.now().difference(savedAt).inDays >= _diskCacheMaxAgeDays) {
        debugPrint('[ExerciseDB] cache em disco expirado — buscando API');
        return null;
      }

      final list = (envelope['exercises'] as List? ?? [])
          .map((e) => ExDbExercise.fromJson(e as Map<String, dynamic>))
          .toList();

      if (list.length < _minExpectedCount) return null;
      return list;
    } catch (e) {
      debugPrint('[ExerciseDB] erro ao ler cache do disco: $e');
      return null;
    }
  }

  /// Serialises exercises to gzip-compressed JSON and writes to disk.
  Future<void> _saveToDisk(List<ExDbExercise> exercises) async {
    try {
      final file    = await _diskCacheFile;
      final json    = jsonEncode({
        'saved_at':  DateTime.now().toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
      });
      final compressed = gzip.encode(utf8.encode(json));
      await file.writeAsBytes(compressed);
      debugPrint('[ExerciseDB] cache salvo em disco (${exercises.length} exercícios, '
          '${(compressed.length / 1024).toStringAsFixed(0)} KB)');
    } catch (e) {
      debugPrint('[ExerciseDB] erro ao salvar cache: $e');
    }
  }

  /// Returns the unique targetMuscles for the given exerciseIds from the
  /// in-memory cache. Never triggers a network call — returns empty list if
  /// the cache hasn't been populated yet.
  List<String> musclesFromCache(List<String> exerciseIds) {
    if (_cache == null || exerciseIds.isEmpty) return [];
    final ids = exerciseIds.toSet();
    final muscles = <String>{};
    for (final ex in _cache!) {
      if (ids.contains(ex.exerciseId)) {
        muscles.addAll(ex.targetMuscles);
      }
    }
    return muscles.toList();
  }

  // ── List all exercises (~1 500) ────────────────────────────────────────────

  /// Returns all exercises following the chain: memory → disk → API.
  ///
  /// • Memory hit  : instant (same session, already loaded).
  /// • Disk hit    : ~100–200 ms (gzip decompress + JSON parse, no network).
  /// • API fetch   : ~25 s sequential pagination; result is persisted to disk
  ///                 so the next session uses the fast disk path.
  Future<List<ExDbExercise>> listAllExercises() async {
    // 1 — memory
    if (_cache != null && _cache!.length >= _minExpectedCount) return _cache!;

    // Coalesce concurrent callers — only one fetch at a time
    if (_isFetching) {
      while (_isFetching) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
      return _cache ?? [];
    }

    _isFetching = true;
    _hasLoadErrors = false;

    try {
      // 2 — disk
      final disk = await _loadFromDisk();
      if (disk != null) {
        _cache = disk;
        debugPrint('[ExerciseDB] ${_cache!.length} exercícios carregados do disco ✓');
        return _cache!;
      }

      // 3 — API (slow path, first run only)
      final all = await _fetchAllPages();

      final seen = <String>{};
      _cache = all
          .where((e) => e.exerciseId.isNotEmpty && seen.add(e.exerciseId))
          .toList();

      _hasLoadErrors = _cache!.length < _minExpectedCount;
      debugPrint(
        '[ExerciseDB] ${_cache!.length} exercícios carregados da API'
        '${_hasLoadErrors ? " (parcial)" : " ✓"}',
      );

      // Persist to disk so the next launch is instant (fire-and-forget)
      if (!_hasLoadErrors) _saveToDiskAsync(_cache!);
    } catch (e) {
      _hasLoadErrors = true;
      _cache ??= [];
      debugPrint('[ExerciseDB] Erro: $e');
    } finally {
      _isFetching = false;
    }

    return _cache!;
  }

  /// Fire-and-forget wrapper — avoids unawaited_futures lint.
  void _saveToDiskAsync(List<ExDbExercise> exercises) {
    _saveToDisk(exercises).catchError((_) {});
  }

  /// Paginates through ALL exercises (no filter) using meta.nextCursor.
  /// Sequential — one request at a time — avoids rate-limit errors entirely.
  /// ~60 pages × ~0.4 s/page ≈ 25 s for ~1 500 exercises.
  Future<List<ExDbExercise>> _fetchAllPages() async {
    final result = <ExDbExercise>[];
    String? afterCursor;
    int pageNum = 0;

    do {
      List<ExDbExercise>? pageResult;
      String? nextCursor;

      // Up to 3 retries per page
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final params = <String, String>{'limit': '25'};
          if (afterCursor != null) params['after'] = afterCursor;

          final uri =
              Uri.parse('$_ossBase/exercises').replace(queryParameters: params);
          final response =
              await http.get(uri).timeout(const Duration(seconds: 20));

          if (response.statusCode == 429) {
            // Back off and retry
            final wait = Duration(seconds: 4 + attempt * 4);
            debugPrint('[ExerciseDB] 429 página $pageNum — aguarda ${wait.inSeconds}s');
            await Future.delayed(wait);
            continue;
          }
          if (response.statusCode != 200) break;

          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['success'] != true) break;

          final data = body['data'] as List? ?? [];
          pageResult = data
              .map((e) => ExDbExercise.fromOss(e as Map<String, dynamic>))
              .toList();

          final meta = body['meta'] as Map<String, dynamic>? ?? {};
          final hasNext = meta['hasNextPage'] as bool? ?? false;
          nextCursor = hasNext ? meta['nextCursor'] as String? : null;

          break; // success
        } catch (_) {
          if (attempt < 2) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          }
        }
      }

      if (pageResult == null) break; // unrecoverable page failure — stop

      result.addAll(pageResult);
      pageNum++;
      afterCursor = nextCursor;

      debugPrint('[ExerciseDB] página $pageNum — ${result.length} total');
    } while (afterCursor != null);

    return result;
  }

  // ── Single exercise by ID ──────────────────────────────────────────────────

  /// Returns exercise from cache, then OSS API, then RapidAPI fallback.
  Future<ExDbExercise?> getById(String exerciseId) async {
    if (exerciseId.isEmpty) return null;

    if (_cache != null) {
      try {
        return _cache!.firstWhere((e) => e.exerciseId == exerciseId);
      } catch (_) {}
    }

    // Try OSS API
    try {
      final uri = Uri.parse('$_ossBase/exercises/$exerciseId');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return ExDbExercise.fromOss(body['data'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}

    // Fallback: RapidAPI
    try {
      final uri = Uri.parse('$_rapidBase/exercises/$exerciseId');
      final res = await http
          .get(uri, headers: _rapidHeaders)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return ExDbExercise.fromRapid(body['data'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}

    return null;
  }

  // ── Upsert to Supabase ────────────────────────────────────────────────────

  Future<String?> upsertToSupabase(ExDbExercise ex) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;

    // Check if already exists by name
    try {
      final existing = await client
          .from('exercises')
          .select('id')
          .eq('name', ex.name)
          .maybeSingle();
      if (existing != null) return existing['id'] as String?;
    } catch (_) {}

    // Insert with exercise_db_id
    try {
      final result = await client
          .from('exercises')
          .insert({
            'name': ex.name,
            'exercise_type': ex.supabaseExerciseType,
            'primary_muscle_group': ex.supabasePrimaryMuscle,
            'secondary_muscle_groups': ex.supabaseSecondaryMuscles,
            'instructions': ex.instructions,
            'image_url': ex.displayUrl,
            'equipment_needed': ex.equipments,
            'is_system_exercise': false,
            'created_by': uid,
            'exercise_db_id': ex.exerciseId,
          })
          .select('id')
          .single();
      return result['id'] as String?;
    } catch (_) {}

    // Retry without exercise_db_id (column may not exist in schema)
    try {
      final result = await client
          .from('exercises')
          .insert({
            'name': ex.name,
            'exercise_type': ex.supabaseExerciseType,
            'primary_muscle_group': ex.supabasePrimaryMuscle,
            'secondary_muscle_groups': ex.supabaseSecondaryMuscles,
            'instructions': ex.instructions,
            'image_url': ex.displayUrl,
            'equipment_needed': ex.equipments,
            'is_system_exercise': false,
            'created_by': uid,
          })
          .select('id')
          .single();
      return result['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Clears memory cache only (disk is preserved).
  void clearCache() {
    _cache = null;
    _hasLoadErrors = false;
  }

  /// Clears both memory and disk cache, forcing a full API reload on next call.
  Future<void> clearAllCaches() async {
    _cache = null;
    _hasLoadErrors = false;
    try {
      final file = await _diskCacheFile;
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}
