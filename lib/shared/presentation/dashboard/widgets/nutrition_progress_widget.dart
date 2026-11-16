import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

// NOVAS DEPENDÊNCIAS
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/integrations/data/health_kit_service.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/nutrition/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';
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
  // Linha "kcal gastas" saiu da Home v2 (decisão 4); a consulta ao
  // HealthKit continua abaixo.
  // ignore: unused_field
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
    return widget.variant == NutritionTile.calories
        ? _buildCaloriesTile()
        : _buildMacrosTile();
  }

  /// Tile "Calorias" v2: label → "N kcal" → "de X kcal" → barra.
  /// O ícone de chama e a linha de kcal gastas saíram (decisão 4).
  Widget _buildCaloriesTile() {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final target = _goals.calories;
    final progress = (_calories / target).clamp(0.0, 1.0).toDouble();

    return BldrTileV2(
      label: l10n.dashboard_calories_label,
      value: isLoading
          ? '—'
          : '${HomeV2Format.thousands(_calories, locale)} kcal',
      caption: l10n.dashboard_v2_calories_of_target(
          HomeV2Format.thousands(target, locale)),
      progress: isLoading ? 0 : progress,
    );
  }

  /// Tile "Macros" v2: 3 linhas P/C/G com barra de 4 px e "valor/meta".
  /// Posições do mockup: label 11, linhas em 32 / 50 / 68.
  Widget _buildMacrosTile() {
    final l10n = AppLocalizations.of(context);
    return BldrSolidCard(
      color: BldrColorsV2.tileBg,
      radius: BldrRadiusV2.tile,
      height: BldrSpacingV2.tileHeight,
      padding: const EdgeInsets.fromLTRB(BldrSpacingV2.tilePad, 11, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashboard_macros_label, style: BldrTextV2.tileLabel),
          const SizedBox(height: 8.9),
          _macroRow(l10n.dashboard_macro_protein_abbrev, _protein, _goals.protein),
          const SizedBox(height: 5.9),
          _macroRow(l10n.dashboard_macro_carbs_abbrev, _carbs, _goals.carbs),
          const SizedBox(height: 5.9),
          _macroRow(l10n.dashboard_macro_fat_abbrev, _fat, _goals.fat),
        ],
      ),
    );
  }

  Widget _macroRow(String label, num value, num target) {
    final progress =
        target > 0 ? (value / target).clamp(0.0, 1.0).toDouble() : 0.0;
    return SizedBox(
      height: 12.1,
      child: Row(
        children: [
          SizedBox(
            width: 17,
            child: Text(label, style: BldrTextV2.tileLabel),
          ),
          Expanded(child: BldrBarV2(value: isLoading ? 0 : progress)),
          const SizedBox(width: 7),
          SizedBox(
            width: 59,
            child: Text(
              isLoading ? '—' : '${value.round()}/$target',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrTextV2.macroValue,
            ),
          ),
        ],
      ),
    );
  }
}
