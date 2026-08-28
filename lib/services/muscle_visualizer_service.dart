// lib/services/muscle_visualizer_service.dart
//
// Muscle Visualizer API (AscendAPI via RapidAPI)
// Endpoint: GET https://muscle-visualizer-api.p.rapidapi.com/api/v1/visualize/workout
//
// Confirmed behaviour (via live API testing):
//   • secondaryMuscles is REQUIRED and must be non-empty.
//     When there are no real secondary muscles, mirror the primary list.
//   • Colors must be 6-digit hex only (#RRGGBB). Alpha digits cause 400.
//   • background=transparent with format=jpeg renders as white (#FFFFFF).
//   • view=front / view=back return separate portrait images (360×360 px).
//   • Cache key includes the view so front/back are stored independently.
//
// Cache strategy:
//   1. In-memory cache (session lifetime)
//   2. Persistent disk cache (survives restarts — critical: 100 req/month limit)
//
// Pre-cache: front-only primary combinations after exercise library loads.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';

class MuscleVisualizerService {
  MuscleVisualizerService._();
  static final instance = MuscleVisualizerService._();

  // ── API constants ──────────────────────────────────────────────────────────

  static const _apiKey  = 'c039a66d8fmshb637ecfefe6d2f8p16cf1djsn9b3d2839273b';
  static const _apiHost = 'muscle-visualizer-api.p.rapidapi.com';
  static const _endpointWorkout =
      'https://muscle-visualizer-api.p.rapidapi.com/api/v1/visualize/workout';
  static const _endpointHeatmap =
      'https://muscle-visualizer-api.p.rapidapi.com/api/v1/visualize/heatmap';
  // Alias kept for backward-compat with existing callers
  static const _endpoint = _endpointWorkout;

  // ── ExerciseDB → API muscle name mapping ──────────────────────────────────

  // Only muscles the API can render on the silhouette.
  // Unmapped names are silently dropped (mapMuscle returns null).
  static const Map<String, String> _muscleMap = {
    'quads':            'QUADRICEPS',
    'quadriceps':       'QUADRICEPS',
    'glutes':           'GLUTES',
    'hamstrings':       'HAMSTRINGS',
    'calves':           'CALVES',
    'chest':            'CHEST',
    'pectorals':        'CHEST',
    'upper back':       'UPPER BACK',
    'lats':             'LATS',
    'latissimus dorsi': 'LATS',
    'traps':            'TRAPS',
    'trapezius':        'TRAPS',
    'biceps':           'BICEPS',
    'triceps':          'TRICEPS',
    'shoulders':        'SHOULDERS',
    'delts':            'SHOULDERS',
    'deltoids':         'SHOULDERS',
    'abs':              'ABS',
    'abdominals':       'ABS',
    'lower back':       'LOWER BACK',
    // 'spine', 'forearms', etc. intentionally excluded
  };

  static String? mapMuscle(String raw) =>
      _muscleMap[raw.toLowerCase().trim()];

  // ── Cache ──────────────────────────────────────────────────────────────────

  final Map<String, Uint8List> _memCache = {};

  /// Stable, order-independent cache key that includes the view.
  String cacheKey(List<String> targets, List<String> secondary,
      {String view = 'front'}) {
    final t = targets
        .map(mapMuscle)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final s = secondary
        .map(mapMuscle)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return 't:${t.join(',')}_s:${s.join(',')}_v:$view';
  }

  Future<Directory> get _cacheDir async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/muscle_viz');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _diskFileName(String key) =>
      md5.convert(utf8.encode(key)).toString() + '.jpg';

  Future<Uint8List?> _loadFromDisk(String key) async {
    try {
      final dir  = await _cacheDir;
      final file = File('${dir.path}/${_diskFileName(key)}');
      if (file.existsSync()) return file.readAsBytesSync();
    } catch (_) {}
    return null;
  }

  Future<void> _saveToDisk(String key, Uint8List bytes) async {
    try {
      final dir  = await _cacheDir;
      final file = File('${dir.path}/${_diskFileName(key)}');
      await file.writeAsBytes(bytes);
    } catch (_) {}
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns JPEG bytes for a single view ('front' or 'back').
  /// mem-cache → disk-cache → API fetch.
  Future<Uint8List?> getVisualization({
    required List<String> targetMuscles,
    List<String> secondaryMuscles = const [],
    String view = 'front',
  }) async {
    final mappedTargets = targetMuscles
        .map(mapMuscle)
        .whereType<String>()
        .toSet()
        .toList();
    if (mappedTargets.isEmpty) return null;

    final mappedSecondary = secondaryMuscles
        .map(mapMuscle)
        .whereType<String>()
        .toSet()
        .toList();

    final key = cacheKey(targetMuscles, secondaryMuscles, view: view);

    if (_memCache.containsKey(key)) return _memCache[key];

    final disk = await _loadFromDisk(key);
    if (disk != null) {
      _memCache[key] = disk;
      return disk;
    }

    return _fetchAndCache(key, mappedTargets, mappedSecondary, view: view);
  }

  /// Returns a Muscle Highlight image (all muscles in the same gold colour).
  /// Uses the Heatmap endpoint with a uniform colour list — visually equivalent
  /// to the "Muscle Highlight" mode.
  Future<Uint8List?> getHighlight({
    required List<String> muscles,
    String view = '',
  }) async {
    final mapped = muscles
        .map(mapMuscle)
        .whereType<String>()
        .toSet()
        .toList();
    if (mapped.isEmpty) return null;

    final key = 'hl:${(mapped..sort()).join(',')}_v:$view';

    if (_memCache.containsKey(key)) return _memCache[key];

    final disk = await _loadFromDisk(key);
    if (disk != null) {
      _memCache[key] = disk;
      return disk;
    }

    return _fetchHighlightAndCache(key, mapped, view: view);
  }

  Future<Uint8List?> _fetchHighlightAndCache(
    String key,
    List<String> muscles, {
    String view = '',
  }) async {
    try {
      // Heatmap with the same gold colour for every muscle = Highlight effect.
      // 'colors' must have exactly as many entries as 'muscles'.
      final colorList = List.filled(muscles.length, '%23D4AF37').join(',');

      final buffer = StringBuffer(_endpointHeatmap);
      buffer.write('?muscles=${Uri.encodeComponent(muscles.join(','))}');
      buffer.write('&colors=$colorList');
      buffer.write('&gender=male');
      buffer.write('&background=transparent');
      buffer.write('&size=small');
      buffer.write('&format=jpeg');
      if (view.isNotEmpty) buffer.write('&view=$view');

      final uri = Uri.parse(buffer.toString());
      final response = await http.get(uri, headers: {
        'X-RapidAPI-Key':  _apiKey,
        'X-RapidAPI-Host': _apiHost,
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        _memCache[key] = response.bodyBytes;
        unawaited(_saveToDisk(key, response.bodyBytes));
        debugPrint('[MuscleViz] highlight cached: $key');
        return response.bodyBytes;
      }
      debugPrint('[MuscleViz] highlight ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('[MuscleViz] highlight error: $e');
    }
    return null;
  }

  Future<Uint8List?> _fetchAndCache(
    String key,
    List<String> targets,
    List<String> secondary, {
    String view = 'front',
  }) async {
    try {
      // secondaryMuscles MUST be non-empty (API requirement).
      // When absent, mirror primary muscles — visually identical to primary-only.
      //
      // Colors: 6-digit hex only (#RRGGBB). Alpha digits cause 400.
      // background=transparent → JPEG renders as white (#FFFFFF).
      final effectiveSecondary = secondary.isNotEmpty ? secondary : targets;

      final buffer = StringBuffer(_endpoint);
      buffer.write('?targetMuscles=${Uri.encodeComponent(targets.join(','))}');
      buffer.write('&targetMusclesColor=%23D4AF37');
      buffer.write('&secondaryMuscles=${Uri.encodeComponent(effectiveSecondary.join(','))}');
      buffer.write('&secondaryMusclesColor=%23F1E5AC');
      buffer.write('&gender=male');
      buffer.write('&background=transparent');
      buffer.write('&size=small');
      buffer.write('&format=jpeg');
      // view='' means "combined" — omit the param so the API returns both views
      if (view.isNotEmpty) buffer.write('&view=$view');

      final uri = Uri.parse(buffer.toString());
      final response = await http.get(uri, headers: {
        'X-RapidAPI-Key':  _apiKey,
        'X-RapidAPI-Host': _apiHost,
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        _memCache[key] = response.bodyBytes;
        unawaited(_saveToDisk(key, response.bodyBytes));
        debugPrint('[MuscleViz] cached [$view]: $key');
        return response.bodyBytes;
      }
      debugPrint('[MuscleViz] API ${response.statusCode} [$view]: ${response.body}');
    } catch (e) {
      debugPrint('[MuscleViz] error: $e');
    }
    return null;
  }

  // ── Pre-cache ──────────────────────────────────────────────────────────────

  /// Pre-caches front-only primary-muscle combinations from the exercise library.
  /// Skips entries already on disk. ~20-30 unique combos ≪ 100 req/month limit.
  Future<void> preCachePrimaries(List<ExDbExercise> exercises) async {
    final unique = <String, List<String>>{};
    for (final ex in exercises) {
      if (ex.targetMuscles.isEmpty) continue;
      final key = cacheKey(ex.targetMuscles, [], view: 'front');
      unique.putIfAbsent(key, () => ex.targetMuscles);
    }

    for (final entry in unique.entries) {
      if (_memCache.containsKey(entry.key)) continue;

      final disk = await _loadFromDisk(entry.key);
      if (disk != null) {
        _memCache[entry.key] = disk;
        continue;
      }

      final mapped = entry.value
          .map(mapMuscle)
          .whereType<String>()
          .toSet()
          .toList();
      if (mapped.isEmpty) continue;
      await _fetchAndCache(entry.key, mapped, [], view: 'front');
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }
}

/// Fire-and-forget helper (avoids unawaited_futures lint)
void unawaited(Future<void> future) {
  future.catchError((_) {});
}
