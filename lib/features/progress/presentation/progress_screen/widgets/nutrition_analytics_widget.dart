import 'dart:math';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/nutrition/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/services/firebase_auth_service.dart';
import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/services/iqd_calculator_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class NutritionAnalyticsWidget extends StatefulWidget {
  final int selectedPeriod;

  const NutritionAnalyticsWidget({
    Key? key,
    required this.selectedPeriod,
  }) : super(key: key);

  @override
  State<NutritionAnalyticsWidget> createState() =>
      _NutritionAnalyticsWidgetState();
}

class _NutritionAnalyticsWidgetState extends State<NutritionAnalyticsWidget> {
  // Dados de Nutrição
  List<Map<String, dynamic>> _recentMeals = [];
  // PN6: meals[i] = list of entries for day i (i=0 today, i=6 oldest)
  List<List<Map<String, dynamic>>> _mealsByDay = [];
  List<Map<String, dynamic>> _weeklyAdherence = [];
  List<FlSpot> _caloriesData = [];
  // PN4/PN5 — os resumos diários completos já eram buscados (dailySummaries)
  // e descartados depois de extrair só as calorias; guardamos a lista
  // inteira agora para reaproveitar macros/fibra/sódio/açúcar sem nenhuma
  // consulta nova.
  List<Map<String, dynamic>> _dailySummaries = [];

  // Meta de Calorias (Padrão 2000, atualizado via Supabase)
  double _dailyCalorieGoal = 2000.0;
  int _proteinGoal = 120;
  int _carbsGoal = 250;
  int _fatGoal = 67;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  @override
  void didUpdateWidget(NutritionAnalyticsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _loadNutritionData();
    }
  }

  Future<void> _loadNutritionData() async {
    setState(() => _isLoading = true);

    try {
      final today = DateTime.now();
      final supabase = Supabase.instance.client;

      // 1. AUTENTICAÇÃO E BUSCA DE PERFIL
      if (AuthService.instance.isAuthenticated) {
        // A. Login no Firebase
        final token = await FirebaseAuthService().getFirebaseCustomToken();
        if (token != null) {
          await FirebaseAuthService().signInWithCustomToken(token);
        }

        // B. Busca de Meta (mesma fonte usada pelo Dashboard e pela tela de Nutrição)
        try {
          final userId = supabase.auth.currentUser?.id;
          if (userId != null) {
            final goalsResult = await getIt<GetNutritionGoals>()(userId);
            final goals = goalsResult.valueOrNull;
            if (goals != null) {
              _dailyCalorieGoal = goals.calories.toDouble();
              _proteinGoal = goals.protein;
              _carbsGoal = goals.carbs;
              _fatGoal = goals.fat;
            }
          }
        } catch (e) {
          debugPrint('Erro ao buscar meta: $e');
        }

      } else {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. BUSCA DE DADOS DE NUTRIÇÃO
      final recentMealsFuture = getIt<GetMealsForDate>()(today);

      // PN6: 7 dias de refeições em paralelo
      final mealsByDayFutures = List.generate(7, (i) {
        final date = today.subtract(Duration(days: i));
        return getIt<GetMealsForDate>()(date).then(
          (result) => result.fold(
            onSuccess: (entries) => entries.map(mealEntryToLegacyMap).toList(),
            onFailure: (_) => <Map<String, dynamic>>[],
          ),
        );
      });

      final periodToFetch = widget.selectedPeriod < 7 ? 7 : widget.selectedPeriod;
      final dailySummaryFutures = <Future<Map<String, dynamic>>>[];

      for (int i = 0; i < periodToFetch; i++) {
        final date = today.subtract(Duration(days: i));
        dailySummaryFutures.add(getIt<GetDailySummary>()(date).then(
          (result) => result.fold(
            onSuccess: summaryToLegacyMap,
            onFailure: (failure) => throw Exception(failure.message),
          ),
        ));
      }

      final recentMealsResult = await recentMealsFuture;
      final recentMeals = recentMealsResult.fold(
        onSuccess: (entries) => entries.map(mealEntryToLegacyMap).toList(),
        onFailure: (failure) => throw Exception(failure.message),
      );
      final fetchResults = await Future.wait([
        Future.wait(dailySummaryFutures),
        Future.wait(mealsByDayFutures),
      ]);
      final dailySummaries =
          (fetchResults[0] as List).cast<Map<String, dynamic>>();
      final mealsByDay =
          (fetchResults[1] as List).cast<List<Map<String, dynamic>>>();

      // 3. Processamento: Consistência (Baseado em CALORIAS agora)
      final adherenceData = dailySummaries.reversed.map((summary) {
        // --- MUDANÇA AQUI: Usa Calorias ao invés de Proteína ---
        final calories = (summary['total_calories'] as num?)?.toDouble() ?? 0.0;
        final targetCalories = _dailyCalorieGoal; // Usa a meta do usuário

        final percent = (calories / targetCalories).clamp(0.0, 1.0);

        // Consideramos "Sucesso" (Barra Dourada) se bater pelo menos 85% da meta calórica
        // (Ajustável conforme sua preferência de rigidez)
        final bool hitGoal = percent >= 0.85;

        return {
          'percent': percent,
          'hit_goal': hitGoal,
          'val': calories
        };
      }).toList();

      List<Map<String, dynamic>> finalAdherenceList = [];
      final reversedSummaries = dailySummaries.reversed.toList();

      for (int i = 0; i < reversedSummaries.length; i++) {
        final daysFromEnd = reversedSummaries.length - 1 - i;
        final date = today.subtract(Duration(days: daysFromEnd));

        final weekDays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
        final label = weekDays[date.weekday - 1];

        final data = adherenceData[i];
        finalAdherenceList.add({
          'day': label,
          'percent': data['percent'],
          'hit_goal': data['hit_goal'],
          'date': date
        });
      }

      if (finalAdherenceList.length > 7) {
        finalAdherenceList = finalAdherenceList.sublist(finalAdherenceList.length - 7);
      }

      // 4. Processamento: Histórico de Calorias
      final calorieHistory = dailySummaries.map((summary) {
        return (summary['total_calories'] as num?)?.toDouble() ?? 0.0;
      }).toList().reversed.toList();

      final caloriesData = calorieHistory.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value);
      }).toList();

      if (mounted) {
        setState(() {
          _recentMeals = recentMeals;
          _mealsByDay = mealsByDay;
          _weeklyAdherence = finalAdherenceList;
          _caloriesData = caloriesData;
          _dailySummaries = dailySummaries.reversed.toList();
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Erro ao carregar dados de nutrição: $error');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: BldrColors.goldBright),
      );
    }

    // PN1 — sem toggle: as duas visões empilhadas na mesma tela.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PN2 — badge verde "0/7 Dias" → 2 cards neutros.
        _buildAdherenceStats(),
        const SizedBox(height: 18),
        _buildWeeklyAdherenceChart(),
        const SizedBox(height: 18),
        _buildCalorieChart(), // PN3
        const SizedBox(height: 18),
        _buildMacroAverages(), // PN4
        const SizedBox(height: 18),
        _buildIqdChart(), // PN5
        const SizedBox(height: 18),
        _buildRecentMeals(), // PN7
        // PN6 — card "Dicas Nutricionais" removido, sem substituto ainda
        // (F16, insight real de dado fica para depois).
      ],
    );
  }

  // PN2 — Média diária + Dias na meta, mesmo padrão dos outros grids.
  Widget _buildAdherenceStats() {
    final l10n = AppLocalizations.of(context)!;
    final hitDays = _weeklyAdherence.where((d) => d['hit_goal'] == true).length;
    final totalDays = _weeklyAdherence.length;
    final avgCalories = _caloriesData.isEmpty
        ? 0.0
        : _caloriesData.map((s) => s.y).reduce((a, b) => a + b) / _caloriesData.length;

    return Row(
      children: [
        Expanded(
          child: BldrGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.nutrition_analytics_avg_daily, style: BldrText.meta),
                const SizedBox(height: 6),
                Text('${avgCalories.round()} kcal', style: BldrText.cardTitleLg),
              ],
            ),
          ),
        ),
        const SizedBox(width: BldrSpacing.gapCard),
        Expanded(
          child: BldrGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.nutrition_analytics_days_on_target, style: BldrText.meta),
                const SizedBox(height: 6),
                Text('$hitDays / $totalDays', style: BldrText.cardTitleLg),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyAdherenceChart() {
    final l10n = AppLocalizations.of(context)!;
    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.nutrition_analytics_adherence_title, style: BldrText.cardTitle),
          const SizedBox(height: 2),
          Text(l10n.nutrition_analytics_calorie_goal, style: BldrText.meta),
          const SizedBox(height: 18),
          if (_weeklyAdherence.isEmpty)
            BldrEmptyState(
              icon: Icons.bar_chart,
              title: l10n.nutrition_analytics_no_recent_data,
            )
          else
            SizedBox(
              height: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _weeklyAdherence.map((dayData) {
                  return _buildDayBar(
                    dayData['day'],
                    (dayData['percent'] as double),
                    dayData['hit_goal'] as bool,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayBar(String label, double percent, bool hitGoal) {
    final displayPercent = percent > 1.0 ? 1.0 : (percent < 0.1 ? 0.1 : percent);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (hitGoal)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.check, color: BldrColors.goldBright, size: 14),
          ),
        Container(
          height: 100,
          width: 28,
          decoration: BoxDecoration(
            color: BldrColors.track,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: displayPercent,
            widthFactor: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: hitGoal ? null : Colors.transparent,
                gradient: hitGoal ? BldrColors.progressGradient : null,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: BldrText.metaSm.copyWith(
                color: hitGoal ? BldrColors.goldBright : BldrColors.textTertiary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // PN3 — gráfico de calorias por dia com linha de meta tracejada.
  Widget _buildCalorieChart() {
    final l10n = AppLocalizations.of(context)!;
    final calorieData = _caloriesData;

    if (calorieData.isEmpty || calorieData.every((spot) => spot.y == 0)) {
      return BldrGlassCard(
        child: BldrEmptyState(
          icon: Icons.query_stats,
          title: l10n.nutrition_analytics_log_meals_hint,
        ),
      );
    }

    final double dailyGoal = _dailyCalorieGoal;
    final double bottomInterval = max(1.0, ((calorieData.length - 1) / 5).ceilToDouble());

    final yValues = calorieData.map((spot) => spot.y).toList();
    double minYValue = yValues.reduce(min);
    double maxYValue = yValues.reduce(max);

    if (dailyGoal > maxYValue) maxYValue = dailyGoal;
    if (dailyGoal < minYValue && dailyGoal > 0) minYValue = dailyGoal;

    final minY = (minYValue * 0.9).floorToDouble();
    final maxY = (maxYValue * 1.1).ceilToDouble();

    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.nutrition_analytics_calorie_history, style: BldrText.cardTitle),
              Row(
                children: [
                  Container(width: 12, height: 2, color: BldrColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(l10n.nutrition_analytics_goal_label, style: BldrText.metaSm),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(color: BldrColors.borderSubtle, strokeWidth: 1);
                  },
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: dailyGoal,
                      color: BldrColors.textTertiary,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4, bottom: 2),
                        style: BldrText.metaSm.copyWith(fontWeight: FontWeight.w600),
                        labelResolver: (line) => '${dailyGoal.toInt()}',
                      ),
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: bottomInterval,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= calorieData.length) return const SizedBox();

                        final daysFromEnd = (calorieData.length - 1) - index;
                        final date = DateTime.now().subtract(Duration(days: daysFromEnd));
                        final text = (daysFromEnd == 0) ? l10n.nutrition_analytics_today : DateFormat('dd/MM').format(date);

                        if (value != meta.min && value != meta.max && value % bottomInterval != 0) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(text, style: BldrText.metaSm),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: (maxY - minY) > 0 ? (maxY - minY) / 3 : 100,
                      getTitlesWidget: (value, meta) {
                        if (value == minY || value == maxY) return const SizedBox();
                        return Text('${(value / 1000).toStringAsFixed(1)}k', style: BldrText.metaSm);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (calorieData.length - 1).toDouble(),
                minY: minY > 0 ? 0 : minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: calorieData,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: BldrColors.goldBright,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          BldrColors.goldBright.withOpacity(0.25),
                          BldrColors.goldBright.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PN4 — média de macros no período, com barras. Reaproveita
  // `_dailySummaries` (já buscado para o gráfico de calorias).
  Widget _buildMacroAverages() {
    final l10n = AppLocalizations.of(context)!;
    final loggedDays = _dailySummaries
        .where((s) => ((s['total_calories'] as num?) ?? 0) > 0)
        .toList();

    if (loggedDays.isEmpty) {
      return BldrGlassCard(
        child: BldrEmptyState(
          icon: Icons.pie_chart_outline,
          title: l10n.nutrition_analytics_no_meals,
        ),
      );
    }

    double sumP = 0, sumC = 0, sumF = 0;
    for (final s in loggedDays) {
      sumP += ((s['total_protein'] as num?) ?? 0).toDouble();
      sumC += ((s['total_carbs'] as num?) ?? 0).toDouble();
      sumF += ((s['total_fat'] as num?) ?? 0).toDouble();
    }
    final avgP = sumP / loggedDays.length;
    final avgC = sumC / loggedDays.length;
    final avgF = sumF / loggedDays.length;
    final maxVal = [avgP, avgC, avgF, 1.0].reduce(max);

    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.nutrition_analytics_macros_title, style: BldrText.cardTitle),
          const SizedBox(height: 2),
          Text(l10n.nutrition_analytics_avg_daily, style: BldrText.meta),
          const SizedBox(height: 16),
          _buildMacroBar(l10n.nutrition_analytics_protein, avgP, _proteinGoal.toDouble(), l10n),
          const SizedBox(height: 12),
          _buildMacroBar(l10n.nutrition_analytics_carbs, avgC, _carbsGoal.toDouble(), l10n),
          const SizedBox(height: 12),
          _buildMacroBar(l10n.nutrition_analytics_fat, avgF, _fatGoal.toDouble(), l10n),
        ],
      ),
    );
  }

  Widget _buildMacroBar(String label, double value, double goal, AppLocalizations l10n) {
    final pct = goal > 0 ? (value / goal * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: BldrText.meta),
            Text(
              '${value.round()}g  ·  $pct${l10n.nutrition_analytics_pct_of_goal}',
              style: BldrText.meta.copyWith(color: BldrColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        BldrProgressBar(value: goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0),
      ],
    );
  }

  // PN5 — evolução do IQD no período, em gráfico de linha. Reaproveita
  // `_dailySummaries` (fibra/sódio/açúcar já vêm no resumo diário) e
  // `IqdCalculatorService.calculate`, já usado em outras telas.
  Widget _buildIqdChart() {
    final l10n = AppLocalizations.of(context)!;
    if (_dailySummaries.isEmpty) {
      return BldrGlassCard(
        child: BldrEmptyState(
          icon: Icons.show_chart,
          title: l10n.nutrition_analytics_no_iqd,
        ),
      );
    }

    final spots = _dailySummaries.asMap().entries.map((entry) {
      final s = entry.value;
      final fiber = ((s['total_fiber'] as num?) ?? 0).toDouble();
      final sodium = ((s['total_sodium'] as num?) ?? 0).toDouble();
      final sugar = ((s['total_added_sugar'] as num?) ?? 0).toDouble();
      final score = IqdCalculatorService.calculate(
        fiberGrams: fiber,
        sodiumMg: sodium,
        addedSugarGrams: sugar,
      );
      return FlSpot(entry.key.toDouble(), score);
    }).toList();

    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.nutrition_analytics_iqd_title, style: BldrText.cardTitle),
          const SizedBox(height: 2),
          Text(l10n.nutrition_analytics_iqd_subtitle, style: BldrText.meta),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: BldrColors.borderSubtle, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: max(1.0, ((spots.length - 1) / 5).ceilToDouble()),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= spots.length) return const SizedBox();
                        final daysFromEnd = (spots.length - 1) - index;
                        final date = DateTime.now().subtract(Duration(days: daysFromEnd));
                        final text = daysFromEnd == 0 ? l10n.nutrition_analytics_today : DateFormat('dd/MM').format(date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(text, style: BldrText.metaSm),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 25,
                      getTitlesWidget: (value, meta) =>
                          Text(value.toInt().toString(), style: BldrText.metaSm),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: BldrColors.goldBright,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3,
                        color: BldrColors.goldBright,
                        strokeWidth: 2,
                        strokeColor: BldrColors.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          BldrColors.goldBright.withOpacity(0.2),
                          BldrColors.goldBright.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PN6 — 7 dias de refeições com section headers + tipos de refeição expansíveis.
  Widget _buildRecentMeals() {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final hasMeals = _mealsByDay.any((day) => day.isNotEmpty);

    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_outlined, color: BldrColors.goldBright, size: 16),
              const SizedBox(width: 8),
              Text(l10n.nutrition_analytics_meals_title, style: BldrText.cardTitle),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasMeals)
            BldrEmptyState(
              icon: Icons.restaurant_outlined,
              title: l10n.nutrition_analytics_no_meals_7d,
            )
          else
            Column(
              children: List.generate(7, (i) {
                final date = today.subtract(Duration(days: i));
                final meals = i < _mealsByDay.length ? _mealsByDay[i] : <Map<String, dynamic>>[];
                if (meals.isEmpty) return const SizedBox.shrink();
                return _buildDaySection(date, meals, i == 0, l10n);
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildDaySection(DateTime date, List<Map<String, dynamic>> meals, bool isToday, AppLocalizations l10n) {
    final dayLabel = isToday
        ? l10n.nutrition_analytics_today
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    final totalCal = meals.fold<int>(0, (s, m) => s + ((m['calories'] as num?)?.toInt() ?? 0));

    // Group by meal_type
    final byType = <String, List<Map<String, dynamic>>>{};
    for (final m in meals) {
      final type = (m['meal_type'] as String?) ?? 'outro';
      byType.putIfAbsent(type, () => []).add(m);
    }

    final typeOrder = ['cafe_da_manha', 'almoco', 'lanche', 'jantar', 'outro'];
    String _localMealType(String t) {
      switch (t) {
        case 'cafe_da_manha': return l10n.nutrition_meal_type_cafe;
        case 'almoco': return l10n.nutrition_meal_type_almoco;
        case 'lanche': return l10n.nutrition_meal_type_lanche;
        case 'jantar': return l10n.nutrition_meal_type_jantar;
        default: return l10n.nutrition_meal_type_outro;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dayLabel, style: BldrText.label),
              Text('$totalCal kcal', style: BldrText.meta.copyWith(color: BldrColors.goldBright)),
            ],
          ),
        ),
        ...typeOrder.where((t) => byType.containsKey(t)).map((type) {
          final items = byType[type]!;
          final typeCal = items.fold<int>(0, (s, m) => s + ((m['calories'] as num?)?.toInt() ?? 0));
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              collapsedIconColor: BldrColors.textTertiary,
              iconColor: BldrColors.goldBright,
              title: Row(
                children: [
                  Text(_localMealType(type), style: BldrText.meta),
                  const SizedBox(width: 8),
                  Text('$typeCal cal', style: BldrText.metaSm.copyWith(color: BldrColors.textTertiary)),
                ],
              ),
              children: items.map(_buildMealItem).toList(),
            ),
          );
        }),
        const Divider(color: BldrColors.borderSubtle, height: 1),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildMealItem(Map<String, dynamic> foodItem) {
    final name = foodItem['food_name'] ?? 'Alimento';
    final brand = foodItem['brand'] as String?;
    final calories = (foodItem['calories'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: BldrColors.surfaceInset,
          borderRadius: BldrRadius.all(BldrRadius.cardSm),
          border: Border.all(color: BldrColors.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: BldrText.body.copyWith(fontWeight: FontWeight.w500)),
                  if (brand != null && brand.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(brand, style: BldrText.meta),
                  ],
                ],
              ),
            ),
            Text('$calories cal',
                style: BldrText.body.copyWith(color: BldrColors.goldBright, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
