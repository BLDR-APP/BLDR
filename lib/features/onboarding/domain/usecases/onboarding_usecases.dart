import 'package:flutter/foundation.dart';
import 'package:postgrest/postgrest.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';

/// Lê o perfil de onboarding do usuário para injetar no contexto do HAVOK.
class GetOnboardingContext {
  final OnboardingRepository _repo;
  const GetOnboardingContext(this._repo);

  Future<Result<Map<String, dynamic>>> call() => _repo.getOnboardingData();
}

int? _asInt(dynamic v) => v is num ? v.round() : int.tryParse(v?.toString() ?? '');

/// Extrai o primeiro número de "8-12", "10", "12-15", etc.
int? _parseReps(dynamic raw) {
  final text = raw?.toString() ?? '';
  final match = RegExp(r'\d+').firstMatch(text);
  return match == null ? null : int.tryParse(match.group(0)!);
}

/// Mapa de nome de dia (PT) → diaSemana int (1=segunda…7=domingo).
const _kDiaToInt = {
  'segunda': 1, 'terça': 2, 'terca': 2,
  'quarta': 3, 'quinta': 4, 'sexta': 5,
  'sábado': 6, 'sabado': 6, 'domingo': 7,
};

int _diaToWeekday(Map<String, dynamic> map) {
  final dia = (map['dia'] as String?)?.toLowerCase().trim();
  if (dia != null) {
    for (final entry in _kDiaToInt.entries) {
      if (dia.startsWith(entry.key)) return entry.value;
    }
  }
  return _asInt(map['diaSemana']) ?? 1;
}

/// Converte o dia do plano (JSON schemaless do HAVOK) num WorkoutTemplate.
/// Aceita tanto o novo schema (exercicios no topo, dia como string) quanto
/// o schema legado (exercicios dentro de treino, diaSemana como int).
WorkoutTemplate? _templateFromPlanDay(Map<String, dynamic> day) {
  // Novo schema: exercicios e nome estão no próprio day
  // Schema legado: dentro de day['treino']
  final treino = day['treino'];
  final List rawExercises = day.containsKey('exercicios')
      ? (day['exercicios'] as List? ?? const [])
      : treino is Map
          ? (treino['exercicios'] as List? ?? const [])
          : const [];

  if (rawExercises.isEmpty) return null;

  final name = (day['nome'] as String?)?.trim().isNotEmpty == true
      ? day['nome'] as String
      : treino is Map
          ? (treino['nome'] as String?) ?? 'Treino'
          : 'Treino';

  final durationMin = treino is Map ? _asInt(treino['duracaoEstimada']) : null;

  final exercises = rawExercises.asMap().entries.map((entry) {
    final e = Map<String, dynamic>.from(entry.value as Map);
    return TemplateExercise(
      orderIndex: entry.key + 1,
      sets: _asInt(e['series']) ?? 3,
      reps: _parseReps(e['repeticoes'] ?? e['reps']),
      restSeconds: _asInt(e['descanso_segundos'] ?? e['descanso']),
      notes: (e['instrucao'] ?? e['notes']) as String?,
      freeName: ((e['nome'] ?? e['name']) as String?)?.trim().isNotEmpty == true
          ? (e['nome'] ?? e['name']) as String
          : 'Exercício',
    );
  }).toList();

  return WorkoutTemplate(
    name: name,
    workoutType: 'força',
    estimatedDurationMinutes: durationMin,
    source: 'havok',
    exercises: exercises,
  );
}

/// Gera o plano semanal do onboarding via HAVOK (HAVOK_SPEC.md §7.1 / L4).
///
/// Cria um WorkoutTemplate por dia com treino (via CreateWorkoutTemplate,
/// já compatível com exercícios de nome livre) e grava as metas
/// nutricionais na mesma fonte que a tela de Nutrição lê.
class GenerateOnboardingPlan {
  final OnboardingRepository _repo;
  final CreateWorkoutTemplate _createTemplate;
  const GenerateOnboardingPlan(this._repo, this._createTemplate);

  Future<Result<OnboardingPlan>> call(
      Map<String, dynamic> onboardingData) async {
    final genResult = await _repo.generatePlan(onboardingData);
    final failure = genResult.failureOrNull;
    if (failure != null) return Result.failure(failure);

    final raw = genResult.valueOrNull ?? const {};
    // Aceita tanto o novo schema ("semana") quanto o legado ("plano")
    final rawDays = (raw['semana'] ?? raw['plano'] as List?) ?? const [];

    final days = <PlanDay>[];
    for (final rawDay in rawDays) {
      final map = Map<String, dynamic>.from(rawDay as Map);
      final tipo = (map['tipo'] as String?) ?? 'descanso';
      final template = tipo == 'treino' ? _templateFromPlanDay(map) : null;

      WorkoutTemplate? savedTemplate;
      if (template != null) {
        debugPrint('[PLANO] criando template: ${template.name} (source=${template.source})');
        final createResult = await _createTemplate(template);
        final failure = createResult.failureOrNull;
        if (failure != null) {
          debugPrint('[PLANO] ERRO ao criar template: ${failure.message}');
          debugPrint('[PLANO] ERRO tipo: ${failure.runtimeType}');
          final cause = (failure as dynamic).cause;
          debugPrint('[PLANO] ERRO cause tipo: ${cause?.runtimeType}');
          debugPrint('[PLANO] ERRO cause: $cause');
          if (cause is PostgrestException) {
            debugPrint('[PLANO] Postgrest code: ${cause.code}');
            debugPrint('[PLANO] Postgrest message: ${cause.message}');
            debugPrint('[PLANO] Postgrest details: ${cause.details}');
            debugPrint('[PLANO] Postgrest hint: ${cause.hint}');
          }
        }
        savedTemplate = createResult.valueOrNull ?? template;
        debugPrint('[PLANO] template criado: id=${savedTemplate.id}');
      }

      days.add(PlanDay(
        diaSemana: _diaToWeekday(map),
        tipo: tipo,
        treino: savedTemplate,
      ));
    }

    final metaCalorica = _asInt(raw['metaCalorica']) ?? 0;
    final metaProteina = _asInt(raw['metaProteina']) ?? 0;
    final metaCarboidrato = _asInt(raw['metaCarboidrato']) ?? 0;
    final metaGordura = _asInt(raw['metaGordura']) ?? 0;

    if (metaCalorica > 0) {
      await _repo.saveNutritionGoals(
        calories: metaCalorica,
        protein: metaProteina,
        carbs: metaCarboidrato,
        fat: metaGordura,
      );
    }

    return Result.success(OnboardingPlan(
      plano: days,
      resumo: (raw['resumo'] as String?) ?? '',
      metaCalorica: metaCalorica,
      metaProteina: metaProteina,
      metaCarboidrato: metaCarboidrato,
      metaGordura: metaGordura,
    ));
  }
}
