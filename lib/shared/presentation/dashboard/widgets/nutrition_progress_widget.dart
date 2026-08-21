import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

// NOVAS DEPENDÊNCIAS
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/integrations/data/health_kit_service.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/nutrition/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/services/firebase_auth_service.dart'; // Novo serviço de Auth (Custom Token)

/// Qual bloco do grid 2×2 este widget renderiza.
/// Os dois compartilham a mesma carga de dados (mesmo use case, mesma query).
enum NutritionTile { calories, macros }

class NutritionProgressWidget extends StatefulWidget {
  final NutritionTile variant;

  const NutritionProgressWidget({
    super.key,
    this.variant = NutritionTile.calories,
  });

  @override
  State<NutritionProgressWidget> createState() =>
      _NutritionProgressWidgetState();
}

class _NutritionProgressWidgetState extends State<NutritionProgressWidget> {
  Map<String, dynamic>? nutritionData;
  NutritionGoals _goals = NutritionGoals.defaults;
  double _caloriesBurned = 0;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  Future<void> _loadNutritionData() async {
    try {
      if (!AuthService.instance.isAuthenticated) {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = false;
          });
        }
        return;
      }

      final userId = AuthService.instance.currentUser?.id;

      // 1. AUTENTICAÇÃO NO FIREBASE (Custom Token)
      if (userId != null) {
        // Obtém o token (se não estiver em cache) e faz login no Firebase Auth.
        final token = await FirebaseAuthService().getFirebaseCustomToken();
        if (token != null) {
          await FirebaseAuthService().signInWithCustomToken(token);
        }
      }

      // 2. BUSCA DE DADOS (USANDO O USE CASE)
      final result = await getIt<GetDailySummary>()(DateTime.now());
      final data = result.fold(
        onSuccess: summaryToLegacyMap,
        onFailure: (failure) => throw Exception(failure.message),
      );

      // 3. BUSCA DE METAS (mesma fonte usada pela tela de Nutrição)
      NutritionGoals goals = NutritionGoals.defaults;
      if (userId != null) {
        final goalsResult = await getIt<GetNutritionGoals>()(userId);
        goals = goalsResult.valueOrNull ?? NutritionGoals.defaults;
      }

      if (mounted) {
        setState(() {
          nutritionData = data;
          _goals = goals;
          isLoading = false;
          hasError = false;
        });
      }
      // Calorias gastas do dia via HealthKit (fire-and-forget — falha silenciosa)
      final burned = await getIt<HealthKitService>().fetchTodayCaloriesBurned();
      if (mounted && burned > 0) setState(() => _caloriesBurned = burned);
    } catch (error) {
      // Captura erros de permissão ou falhas na Edge Function
      debugPrint('Erro ao carregar dados de nutrição: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  num get _calories => nutritionData?['total_calories'] ?? 0;
  num get _protein => nutritionData?['total_protein'] ?? 0;
  num get _carbs => nutritionData?['total_carbs'] ?? 0;
  num get _fat => nutritionData?['total_fat'] ?? 0;

  @override
  Widget build(BuildContext context) {
    return BldrGlassCard(
      child: widget.variant == NutritionTile.calories
          ? _buildCaloriesTile()
          : _buildMacrosTile(),
    );
  }

  /// D5 — bloco "Calorias" do grid.
  /// Ordem (mockup): [label + ícone] → [valor + unidade] → [meta] → [barra].
  Widget _buildCaloriesTile() {
    final l10n = AppLocalizations.of(context);
    final target = _goals.calories;
    final progress = (_calories / target).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.dashboard_calories_label, style: BldrText.meta),
            const Icon(Icons.local_fire_department_rounded,
                color: BldrColors.goldBright, size: 14),
          ],
        ),
        const SizedBox(height: 14),
        if (isLoading)
          Text('—', style: BldrText.kpiLg)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${_calories.round()}', style: BldrText.kpiLg),
              const SizedBox(width: 4),
              Text('kcal', style: BldrText.unit),
            ],
          ),
        const SizedBox(height: 2),
        Text(l10n.dashboard_calories_of_target(target), style: BldrText.meta),
        if (_caloriesBurned > 0) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.local_fire_department_rounded,
                size: 11, color: BldrColors.danger),
            const SizedBox(width: 3),
            Text('${_caloriesBurned.round()} kcal gastas',
                style: BldrText.meta.copyWith(color: BldrColors.danger)),
          ]),
        ],
        const SizedBox(height: 12),
        BldrProgressBar(value: isLoading ? 0 : progress),
      ],
    );
  }

  /// D6 — macros em 3 linhas empilhadas (P/C/G) com mini-barras,
  /// em cor única (G4: sem vermelho/azul/laranja por macro).
  Widget _buildMacrosTile() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dashboard_macros_label, style: BldrText.meta),
        const SizedBox(height: 14),
        _macroRow(l10n.dashboard_macro_protein_abbrev, _protein, _goals.protein),
        const SizedBox(height: 10),
        _macroRow(l10n.dashboard_macro_carbs_abbrev, _carbs, _goals.carbs),
        const SizedBox(height: 10),
        _macroRow(l10n.dashboard_macro_fat_abbrev, _fat, _goals.fat),
      ],
    );
  }

  Widget _macroRow(String label, num value, num target) {
    final progress =
        target > 0 ? (value / target).clamp(0.0, 1.0).toDouble() : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(label, style: BldrText.meta),
        ),
        Expanded(
          child: BldrProgressBar(value: isLoading ? 0 : progress, height: 5),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text.rich(
            TextSpan(
              text: isLoading ? '—' : '${value.round()}',
              style: BldrText.metaSm.copyWith(color: BldrColors.textPrimary),
              children: [
                TextSpan(
                  text: isLoading ? '' : '/$target',
                  style: BldrText.metaSm,
                ),
              ],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
