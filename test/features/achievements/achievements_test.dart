import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/achievements/domain/entities/achievement.dart';
import 'package:bldr_fitness/features/achievements/domain/repositories/achievements_repository.dart';
import 'package:bldr_fitness/features/achievements/domain/usecases/achievement_usecases.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeAchievementsRepository implements AchievementsRepository {
  // Conquistas já obtidas pelo usuário (simula user_achievements)
  final Set<String> obtained;
  // Triggers chamados durante o teste
  final List<String> triggersChecked = [];
  // Conquistas que o fake desbloqueia quando chamado
  final Map<String, List<Achievement>> unlockOnTrigger;

  _FakeAchievementsRepository({
    required this.obtained,
    this.unlockOnTrigger = const {},
  });

  @override
  Future<Result<List<Achievement>>> catalog() async => const Result.success([]);

  @override
  Future<Result<List<UnlockedAchievement>>> userAchievements(String userId) async =>
      const Result.success([]);

  @override
  Future<Result<List<Achievement>>> checkAndUnlock(String triggerType) async {
    triggersChecked.add(triggerType);
    return Result.success(unlockOnTrigger[triggerType] ?? []);
  }

  @override
  Future<Result<Map<String, dynamic>>> workoutContext(String userId) async =>
      const Result.success({});
}

// ── Auxiliar ──────────────────────────────────────────────────────────────────

Achievement _ach(String name, String criteriaType) => Achievement(
      id: name,
      name: name,
      criteriaType: criteriaType,
    );

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  group('B2 — CheckAndUnlockAchievements', () {
    test('trigger workout chama checkAndUnlock com "workout"', () async {
      final repo = _FakeAchievementsRepository(obtained: {});
      final uc = CheckAndUnlockAchievements(repo);
      await uc('workout');
      expect(repo.triggersChecked, contains('workout'));
    });

    test('trigger bldr_club chama checkAndUnlock com "bldr_club"', () async {
      final repo = _FakeAchievementsRepository(obtained: {});
      final uc = CheckAndUnlockAchievements(repo);
      await uc('bldr_club');
      expect(repo.triggersChecked, contains('bldr_club'));
    });

    test('backfill incremental — chama todos os 6 triggers em sequência', () async {
      final repo = _FakeAchievementsRepository(obtained: {});
      final uc = CheckAndUnlockAchievements(repo);

      const triggers = ['workout', 'onboarding', 'profile', 'nutrition', 'photo', 'bldr_club'];
      for (final t in triggers) {
        await uc(t);
      }

      expect(repo.triggersChecked, triggers);
    });

    test('checkAndUnlock retorna conquistas recém-desbloqueadas (não as já obtidas)', () async {
      final nova = _ach('Primeira Semana', 'workout_count');
      final repo = _FakeAchievementsRepository(
        obtained: {'Primeiro Treino'},
        unlockOnTrigger: {
          'workout': [nova],
        },
      );
      final uc = CheckAndUnlockAchievements(repo);

      final result = await uc('workout');

      expect(result.isSuccess, isTrue);
      final unlocked = result.valueOrNull!;
      expect(unlocked.length, 1);
      expect(unlocked.first.name, 'Primeira Semana');
    });

    test('checkAndUnlock retorna lista vazia quando todas as conquistas já foram obtidas', () async {
      final repo = _FakeAchievementsRepository(
        obtained: {'Primeiro Treino', 'Primeira Semana'},
        unlockOnTrigger: {'workout': []},
      );
      final uc = CheckAndUnlockAchievements(repo);

      final result = await uc('workout');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('falha no repositório (Result.failure) é repassada sem alteração', () async {
      final repo = _FailingRepository();
      final uc = CheckAndUnlockAchievements(repo);

      final result = await uc('workout');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('erro simulado'));
    });
  });
}

// ── Repositório que retorna Result.failure ────────────────────────────────────

class _FailingRepository implements AchievementsRepository {
  @override
  Future<Result<List<Achievement>>> catalog() async => const Result.success([]);

  @override
  Future<Result<List<UnlockedAchievement>>> userAchievements(String userId) async =>
      const Result.success([]);

  @override
  Future<Result<List<Achievement>>> checkAndUnlock(String triggerType) async =>
      const Result.failure(UnexpectedFailure('erro simulado'));

  @override
  Future<Result<Map<String, dynamic>>> workoutContext(String userId) async =>
      const Result.success({});
}
