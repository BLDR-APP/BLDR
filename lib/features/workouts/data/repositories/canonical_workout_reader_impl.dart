import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/workouts/data/datasources/supabase_canonical_workout_datasource.dart';
import 'package:bldr_fitness/features/workouts/data/mappers/canonical_workout_mapper.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/canonical_workout.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/canonical_workout_reader.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Leitor raw injetável para testar o reader sem acessar Supabase.
abstract class CanonicalWorkoutReadSource {
  Future<List<Map<String, dynamic>>> personalSessionPage(
    CanonicalWorkoutSessionPageRequest request,
  );
  Future<List<Map<String, dynamic>>> clubSessionPage(
    CanonicalWorkoutSessionPageRequest request,
  );
  Future<List<Map<String, dynamic>>> personalSets(List<String> sessionIds);
  Future<List<Map<String, dynamic>>> clubSets(List<String> sessionIds);
  Future<List<Map<String, dynamic>>> exercises(List<String> exerciseIds);
}

class SupabaseCanonicalWorkoutReadSource implements CanonicalWorkoutReadSource {
  final SupabaseCanonicalWorkoutDatasource _datasource;

  SupabaseCanonicalWorkoutReadSource(this._datasource);

  @override
  Future<List<Map<String, dynamic>>> personalSessionPage(
    CanonicalWorkoutSessionPageRequest request,
  ) =>
      _datasource.personalSessionPage(request);

  @override
  Future<List<Map<String, dynamic>>> clubSessionPage(
    CanonicalWorkoutSessionPageRequest request,
  ) =>
      _datasource.clubSessionPage(request);

  @override
  Future<List<Map<String, dynamic>>> personalSets(List<String> sessionIds) =>
      _datasource.personalSets(sessionIds);

  @override
  Future<List<Map<String, dynamic>>> clubSets(List<String> sessionIds) =>
      _datasource.clubSets(sessionIds);

  @override
  Future<List<Map<String, dynamic>>> exercises(List<String> exerciseIds) =>
      _datasource.exercises(exerciseIds);
}

/// Une sessões pessoais e CLUB exclusivamente para o usuário autenticado.
class CanonicalWorkoutReaderImpl implements CanonicalWorkoutReader {
  static const _cursorPrefix = 'cw1.';
  static final _cursorIdPattern = RegExp(r'^[A-Za-z0-9_-]+$');
  final CanonicalWorkoutReadSource _source;
  final String? Function() _currentUserId;

  CanonicalWorkoutReaderImpl({
    required CanonicalWorkoutReadSource source,
    required String? Function() currentUserId,
  })  : _source = source,
        _currentUserId = currentUserId;

  @override
  Future<Result<CanonicalWorkoutPage>> history({
    required String userId,
    CanonicalWorkoutCursor? cursor,
    int limit = 20,
  }) async {
    final authenticatedUserId = _currentUserId();
    if (authenticatedUserId == null) {
      return const Result.failure(AuthFailure('Usuário não autenticado.'));
    }
    if (authenticatedUserId != userId) {
      return const Result.failure(
        AuthFailure('Não é permitido ler treinos de outro usuário.'),
      );
    }
    if (limit <= 0) {
      return const Result.failure(
          ValidationFailure('O limite deve ser maior que zero.'));
    }

    final boundary = _decodeCursor(cursor);
    if (cursor != null && boundary == null) {
      return const Result.failure(
        ValidationFailure('Cursor do histórico de treinos inválido.'),
      );
    }

    try {
      // Há seis fluxos indexáveis: concluídos, em andamento e sem timestamp,
      // para FREE e CLUB. Cada um busca no máximo limit + 1 candidatos.
      final candidateRows = await Future.wait([
        for (final source in WorkoutSessionSource.values)
          for (final bucket in CanonicalWorkoutSessionBucket.values)
            _sessionPage(
              source: source,
              bucket: bucket,
              userId: authenticatedUserId,
              boundary: boundary,
              limit: limit + 1,
            ),
      ]);
      final candidates = <_SourceSessionRow>[];
      var responseIndex = 0;
      for (final source in WorkoutSessionSource.values) {
        for (final _ in CanonicalWorkoutSessionBucket.values) {
          candidates.addAll(
              _ownedRows(candidateRows[responseIndex++], authenticatedUserId)
                  .map((row) => _SourceSessionRow(source, row)));
        }
      }
      candidates.sort(_compareSourceRows);
      final pageRows = candidates.take(limit + 1).toList();
      final hasMore = pageRows.length > limit;
      final selectedRows = hasMore ? pageRows.take(limit).toList() : pageRows;

      final personalRows = selectedRows
          .where((item) => item.source == WorkoutSessionSource.personal)
          .map((item) => item.row)
          .toList();
      final clubRows = selectedRows
          .where((item) => item.source == WorkoutSessionSource.bldrClub)
          .map((item) => item.row)
          .toList();
      final personalIds = _ids(personalRows);
      final clubIds = _ids(clubRows);

      final setRows = await Future.wait([
        _source.personalSets(personalIds),
        _source.clubSets(clubIds),
      ]);
      final personalSets = _setsForSessions(setRows[0], personalIds);
      final clubSets = _setsForSessions(setRows[1], clubIds);
      final exerciseIds = {
        ..._exerciseIds(personalSets),
        ..._exerciseIds(clubSets),
      }.toList();
      final exerciseRows = await _source.exercises(exerciseIds);
      final exercisesById = {
        for (final row in exerciseRows)
          if (row['id'] != null) row['id'].toString(): row,
      };

      final pageSessions = <CanonicalWorkoutSession>[
        for (final item in selectedRows)
          switch (item.source) {
            WorkoutSessionSource.personal => CanonicalWorkoutMapper.personal(
                session: item.row,
                sets: _setsForSession(personalSets, item.row['id'].toString()),
                exercisesById: exercisesById,
              ),
            WorkoutSessionSource.bldrClub => CanonicalWorkoutMapper.club(
                session: item.row,
                sets: _setsForSession(clubSets, item.row['id'].toString()),
                exercisesById: exercisesById,
              ),
          },
      ];
      return Result.success(CanonicalWorkoutPage(
        sessions: pageSessions,
        hasMore: hasMore,
        nextCursor: hasMore ? _encodeCursor(pageSessions.last) : null,
      ));
    } on supabase.PostgrestException catch (error) {
      return Result.failure(
        ServerFailure(
          'Não foi possível carregar o histórico de treinos.',
          cause: error,
        ),
      );
    } on SocketException catch (error) {
      return Result.failure(
          NetworkFailure('Sem conexão com a internet.', error));
    } on TimeoutException catch (error) {
      return Result.failure(
          NetworkFailure('Tempo de conexão esgotado.', error));
    } on FormatException catch (error) {
      return Result.failure(
          DataFailure('Dados de treino inválidos.', cause: error));
    } catch (error) {
      return Result.failure(
          UnexpectedFailure('Ocorreu um erro inesperado.', error));
    }
  }

  Future<List<Map<String, dynamic>>> _sessionPage({
    required WorkoutSessionSource source,
    required CanonicalWorkoutSessionBucket bucket,
    required String userId,
    required _CanonicalCursorBoundary? boundary,
    required int limit,
  }) {
    final request = CanonicalWorkoutSessionPageRequest(
      userId: userId,
      bucket: bucket,
      limit: limit,
      hasCursor: boundary != null,
      cursorTimestamp: boundary?.timestamp,
      tie: _tieFor(source, boundary),
      cursorSessionId: boundary?.sourceSessionId,
    );
    return switch (source) {
      WorkoutSessionSource.personal => _source.personalSessionPage(request),
      WorkoutSessionSource.bldrClub => _source.clubSessionPage(request),
    };
  }

  static CanonicalWorkoutCursorTie _tieFor(
    WorkoutSessionSource source,
    _CanonicalCursorBoundary? boundary,
  ) {
    if (boundary == null) return CanonicalWorkoutCursorTie.exclude;
    final comparison = source.index.compareTo(boundary.source.index);
    if (comparison < 0) return CanonicalWorkoutCursorTie.exclude;
    if (comparison > 0) return CanonicalWorkoutCursorTie.includeAll;
    return CanonicalWorkoutCursorTie.afterId;
  }

  static CanonicalWorkoutCursor _encodeCursor(CanonicalWorkoutSession session) {
    final payload = jsonEncode({
      'v': 1,
      't':
          (session.completedAt ?? session.startedAt)?.toUtc().toIso8601String(),
      's': session.source.name,
      'i': session.sourceSessionId,
    });
    return CanonicalWorkoutCursor(
        '$_cursorPrefix${base64UrlEncode(utf8.encode(payload))}');
  }

  static _CanonicalCursorBoundary? _decodeCursor(
    CanonicalWorkoutCursor? cursor,
  ) {
    if (cursor == null) return null;
    final token = cursor.toString();
    if (!token.startsWith(_cursorPrefix)) return null;
    try {
      final value = jsonDecode(
          utf8.decode(base64Url.decode(token.substring(_cursorPrefix.length))));
      if (value is! Map || value['v'] != 1) return null;
      WorkoutSessionSource? source;
      for (final item in WorkoutSessionSource.values) {
        if (item.name == value['s']) {
          source = item;
          break;
        }
      }
      final id = value['i'];
      if (source == null || id is! String || !_cursorIdPattern.hasMatch(id)) {
        return null;
      }
      final timestampValue = value['t'];
      final timestamp = timestampValue == null
          ? null
          : timestampValue is String
              ? DateTime.tryParse(timestampValue)?.toUtc()
              : null;
      if (timestampValue != null && timestamp == null) return null;
      return _CanonicalCursorBoundary(timestamp, source, id);
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> _ownedRows(
    List<Map<String, dynamic>> rows,
    String userId,
  ) =>
      rows.where((row) => row['user_id']?.toString() == userId).toList();

  static List<String> _ids(List<Map<String, dynamic>> rows) => rows
      .map((row) => row['id']?.toString())
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toList();

  static List<Map<String, dynamic>> _setsForSessions(
    List<Map<String, dynamic>> rows,
    List<String> sessionIds,
  ) {
    final sessionIdSet = sessionIds.toSet();
    return rows
        .where(
            (row) => sessionIdSet.contains(row['user_workout_id']?.toString()))
        .toList();
  }

  static Set<String> _exerciseIds(List<Map<String, dynamic>> rows) => rows
      .map((row) => row['exercise_id']?.toString())
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet();

  static List<Map<String, dynamic>> _setsForSession(
    List<Map<String, dynamic>> rows,
    String sessionId,
  ) =>
      rows
          .where((row) => row['user_workout_id']?.toString() == sessionId)
          .toList();

  static int _compareSourceRows(
    _SourceSessionRow left,
    _SourceSessionRow right,
  ) {
    final leftDate = _sortTimestamp(left.row);
    final rightDate = _sortTimestamp(right.row);
    if (leftDate != null && rightDate != null) {
      final date = rightDate.compareTo(leftDate);
      if (date != 0) return date;
    } else if (leftDate != null) {
      return -1;
    } else if (rightDate != null) {
      return 1;
    }

    final source = left.source.index.compareTo(right.source.index);
    if (source != 0) return source;
    return left.row['id'].toString().compareTo(right.row['id'].toString());
  }

  static DateTime? _sortTimestamp(Map<String, dynamic> row) {
    final raw = row['completed_at'] ?? row['started_at'];
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) throw const FormatException('Invalid timestamp.');
    return parsed;
  }
}

class _SourceSessionRow {
  final WorkoutSessionSource source;
  final Map<String, dynamic> row;

  const _SourceSessionRow(this.source, this.row);
}

class _CanonicalCursorBoundary {
  final DateTime? timestamp;
  final WorkoutSessionSource source;
  final String sourceSessionId;

  const _CanonicalCursorBoundary(
    this.timestamp,
    this.source,
    this.sourceSessionId,
  );
}
