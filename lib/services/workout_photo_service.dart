// lib/services/workout_photo_service.dart
//
// Sends a workout-sheet image to the Supabase Edge Function
// `analyze-workout-photo`, which calls Claude claude-haiku-4-5 and returns a list
// of exercises extracted from the image.
//
// Then matches each nameEN against the ExerciseDB cache to find the best
// exercise, returning:
//   - exact   : found by exact name (case-insensitive)
//   - fuzzy   : closest match with score < threshold (needs user confirmation)
//   - notFound: no reasonable match

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ExtractedExercise {
  final String nameEN;
  final int sets;
  final int reps;
  final int rest; // seconds

  const ExtractedExercise({
    required this.nameEN,
    required this.sets,
    required this.reps,
    required this.rest,
  });

  factory ExtractedExercise.fromJson(Map<String, dynamic> j) =>
      ExtractedExercise(
        nameEN: (j['nameEN'] as String? ?? '').trim(),
        sets:   (j['sets']   as num?)?.toInt() ?? 3,
        reps:   (j['reps']   as num?)?.toInt() ?? 10,
        rest:   (j['rest']   as num?)?.toInt() ?? 90,
      );
}

enum MatchType { exact, fuzzy, notFound }

class MatchedExercise {
  final ExtractedExercise extracted;
  final ExDbExercise? match;
  final MatchType matchType;

  const MatchedExercise({
    required this.extracted,
    required this.match,
    required this.matchType,
  });

  bool get needsConfirmation =>
      matchType == MatchType.fuzzy || matchType == MatchType.notFound;
}

// ── Service ───────────────────────────────────────────────────────────────────

class WorkoutPhotoService {
  WorkoutPhotoService._();
  static final instance = WorkoutPhotoService._();

  static const _functionName = 'analyze-workout-photo';

  // ── Extract from image ────────────────────────────────────────────────────

  /// Sends [imageFile] to the Edge Function and returns matched exercises.
  /// Throws on network/auth errors.
  Future<List<MatchedExercise>> analyzeImage(File imageFile) async {
    final bytes     = await imageFile.readAsBytes();
    final base64Img = base64Encode(bytes);
    final mediaType = _mediaType(imageFile.path);

    final response = await Supabase.instance.client.functions.invoke(
      _functionName,
      body: {'imageBase64': base64Img, 'mediaType': mediaType},
    );

    if (response.status != 200) {
      final err = response.data?['error'] ?? 'Erro desconhecido';
      throw Exception('Falha ao analisar imagem: $err');
    }

    final rawList = (response.data?['exercises'] as List?) ?? [];
    final extracted = rawList
        .map((e) => ExtractedExercise.fromJson(e as Map<String, dynamic>))
        .where((e) => e.nameEN.isNotEmpty)
        .toList();

    debugPrint('[WorkoutPhoto] ${extracted.length} exercícios extraídos pela IA');

    // Match against ExerciseDB cache
    final allExercises =
        await ExerciseDbRapidService.instance.listAllExercises();
    return extracted.map((e) => _matchExercise(e, allExercises)).toList();
  }

  // ── Matching ──────────────────────────────────────────────────────────────

  MatchedExercise _matchExercise(
      ExtractedExercise extracted, List<ExDbExercise> pool) {
    final query = extracted.nameEN.toLowerCase().trim();
    if (query.isEmpty) {
      return MatchedExercise(
          extracted: extracted, match: null, matchType: MatchType.notFound);
    }

    // 1. Exact match (case-insensitive)
    for (final ex in pool) {
      if (ex.name.toLowerCase() == query) {
        return MatchedExercise(
            extracted: extracted, match: ex, matchType: MatchType.exact);
      }
    }

    // 2. Contains match (e.g. "bench press" ⊂ "barbell bench press")
    ExDbExercise? containsMatch;
    for (final ex in pool) {
      final name = ex.name.toLowerCase();
      if (name.contains(query) || query.contains(name)) {
        containsMatch = ex;
        break;
      }
    }
    if (containsMatch != null) {
      return MatchedExercise(
          extracted: extracted,
          match: containsMatch,
          matchType: MatchType.exact);
    }

    // 3. Fuzzy: best Levenshtein distance
    ExDbExercise? bestMatch;
    int bestDist = 999;
    for (final ex in pool) {
      final d = _levenshtein(query, ex.name.toLowerCase());
      if (d < bestDist) {
        bestDist = d;
        bestMatch = ex;
      }
    }

    // Accept as fuzzy if distance is ≤ 40 % of query length
    final threshold = (query.length * 0.4).ceil().clamp(3, 12);
    if (bestMatch != null && bestDist <= threshold) {
      return MatchedExercise(
          extracted: extracted,
          match: bestMatch,
          matchType: MatchType.fuzzy);
    }

    return MatchedExercise(
        extracted: extracted, match: null, matchType: MatchType.notFound);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _mediaType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':  return 'image/png';
      case 'gif':  return 'image/gif';
      case 'webp': return 'image/webp';
      default:     return 'image/jpeg';
    }
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    // Cap at 50 chars to keep it fast
    if (a.length > 50) a = a.substring(0, 50);
    if (b.length > 50) b = b.substring(0, 50);

    final dp = List.generate(
        a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (int i = 0; i <= a.length; i++) dp[i][0] = i;
    for (int j = 0; j <= b.length; j++) dp[0][j] = j;
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        dp[i][j] = a[i - 1] == b[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                .reduce((x, y) => x < y ? x : y);
      }
    }
    return dp[a.length][b.length];
  }
}
