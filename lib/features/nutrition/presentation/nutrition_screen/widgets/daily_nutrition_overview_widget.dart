import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/services/iqd_calculator_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

/// ⚠️ `nutritionSummary` ainda é `Map<String, dynamic>` vindo de
/// `presentation/mappers/legacy_ui_maps.dart` (dívida técnica registrada em
/// ARCHITECTURE.md). Contrato de chaves não alterado nesta tarefa — apenas
/// apresentação.
class DailyNutritionOverviewWidget extends StatefulWidget {
  final Map<String, dynamic> nutritionSummary;
  final DateTime selectedDate;
  final NutritionGoals goals;
  final bool isClub;

  const DailyNutritionOverviewWidget({
    Key? key,
    required this.nutritionSummary,
    required this.selectedDate,
    required this.goals,
    this.isClub = false,
  }) : super(key: key);

  @override
  State<DailyNutritionOverviewWidget> createState() =>
      _DailyNutritionOverviewWidgetState();
}

class _DailyNutritionOverviewWidgetState
    extends State<DailyNutritionOverviewWidget> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) setState(() => _currentPage = page);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Valores consumidos ── (lógica intacta)
    final int totalCalories = (widget.nutritionSummary['total_calories'] as num?)?.round() ?? 0;
    final int totalProtein  = (widget.nutritionSummary['total_protein']  as num?)?.round() ?? 0;
    final int totalCarbs    = (widget.nutritionSummary['total_carbs']    as num?)?.round() ?? 0;
    final int totalFat      = (widget.nutritionSummary['total_fat']      as num?)?.round() ?? 0;
    final double totalFiber      = (widget.nutritionSummary['total_fiber']       as num?)?.toDouble() ?? 0.0;
    final double totalSodium     = (widget.nutritionSummary['total_sodium']      as num?)?.toDouble() ?? 0.0;
    final double totalAddedSugar = (widget.nutritionSummary['total_added_sugar'] as num?)?.toDouble() ?? 0.0;

    // ── Metas ──
    final int calorieTarget = widget.goals.calories;
    final int proteinTarget = widget.goals.protein;
    final int carbsTarget   = widget.goals.carbs;
    final int fatTarget     = widget.goals.fat;

    // ── IQD ── (lógica intacta — gerador de mensagem não muda, ver N4)
    final double iqdScore = IqdCalculatorService.calculate(
      fiberGrams: totalFiber,
      sodiumMg: totalSodium,
      addedSugarGrams: totalAddedSugar,
    );
    final scoreInfo = IqdCalculatorService.getScoreLabel(iqdScore);

    final List<String> tips = [];
    if (totalSodium > 2000)   tips.add('Sódio Alto');
    if (totalFiber < 15)      tips.add('Fibras Baixas');
    if (totalAddedSugar > 50) tips.add('Açúcar Alto');
    final String feedbackTip = tips.isEmpty
        ? 'IQD ${iqdScore.toInt()}/100: ${scoreInfo['label']}! Dieta Equilibrada.'
        : 'IQD ${iqdScore.toInt()}/100: ${scoreInfo['label']}. ${tips.join('. ')}.';

    // N4 — a MENSAGEM (feedbackTip) não muda; só removemos, na exibição, o
    // prefixo "IQD NN/100:" que já aparece dentro do gauge (N3).
    final String displayTip =
        feedbackTip.replaceFirst(RegExp(r'^IQD \d+/100:\s*'), '');
    final bool hasTip = tips.isNotEmpty;

    final double calProgress = calorieTarget > 0
        ? math.min(totalCalories / calorieTarget, 1.0)
        : 0.0;
    final int remainingCalories = math.max(calorieTarget - totalCalories, 0);
    final bool overCalories = totalCalories > calorieTarget;

    return BldrGlassCard(
      padding: const EdgeInsets.all(BldrSpacing.padCardLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cabeçalho ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(AppLocalizations.of(context).nutrition_daily_summary, style: BldrText.sectionTitle),
                  const SizedBox(width: 6),
                  const Icon(Icons.info_outline,
                      color: BldrColors.textTertiary, size: 16),
                ],
              ),
              _buildCalorieBadge(totalCalories, calorieTarget),
            ],
          ),
          const SizedBox(height: 18),

          // N2 — carrossel arrastável, scroll-snap horizontal + dots.
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: _currentPage == 0 ? 190 : 460,
            child: PageView(
              controller: _pageController,
              children: [
                // ── Página 1 — N1: anel + macros lado a lado ──
                _buildSummaryPage(
                  calProgress: calProgress,
                  totalCalories: totalCalories,
                  calorieTarget: calorieTarget,
                  totalProtein: totalProtein, proteinTarget: proteinTarget,
                  totalCarbs: totalCarbs, carbsTarget: carbsTarget,
                  totalFat: totalFat, fatTarget: fatTarget,
                  remainingCalories: remainingCalories,
                  overCalories: overCalories,
                ),

                // ── Página 2 — N3/N4/N5: IQD ──
                _buildQualityPage(
                  iqdScore: iqdScore,
                  scoreLabel: scoreInfo['label'] as String,
                  displayTip: displayTip,
                  hasTip: hasTip,
                  totalFiber: totalFiber,
                  totalSodium: totalSodium,
                  totalAddedSugar: totalAddedSugar,
                  totalFat: totalFat, fatTarget: fatTarget,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Dots indicadores ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              final bool active = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? BldrColors.goldBright : BldrColors.track,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── N1 — resumo diário compacto ─────────────────────────────────────────

  Widget _buildSummaryPage({
    required double calProgress,
    required int totalCalories,
    required int calorieTarget,
    required int totalProtein, required int proteinTarget,
    required int totalCarbs, required int carbsTarget,
    required int totalFat, required int fatTarget,
    required int remainingCalories,
    required bool overCalories,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BldrRingProgress(
              progress: calProgress,
              size: 96,
              strokeWidth: 9,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$totalCalories', style: BldrText.kpiMd),
                  Text('de $calorieTarget',
                      style: BldrText.metaSm),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMacroBar(AppLocalizations.of(context).nutrition_protein, totalProtein, proteinTarget, 'g'),
                  const SizedBox(height: 12),
                  _buildMacroBar(AppLocalizations.of(context).nutrition_carbs, totalCarbs, carbsTarget, 'g'),
                  const SizedBox(height: 12),
                  _buildMacroBar(AppLocalizations.of(context).nutrition_fat, totalFat, fatTarget, 'g'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: BldrColors.borderSubtle, height: 1),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context).nutrition_remaining_today, style: BldrText.meta),
            Text(
              overCalories ? AppLocalizations.of(context).nutrition_goal_exceeded : '$remainingCalories kcal',
              style: BldrText.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: overCalories ? BldrColors.danger : BldrColors.goldBright,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroBar(String name, int current, int target, String unit) {
    final double progress = (target > 0) ? math.min(current / target, 1.0) : 0.0;
    final bool over = target > 0 && current > target * 1.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: BldrText.meta),
            Text('$current/$target$unit',
                style: BldrText.metaSm.copyWith(
                  color: over ? BldrColors.danger : BldrColors.textSecondary,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
        const SizedBox(height: 6),
        BldrProgressBar(value: progress),
      ],
    );
  }

  // ── N3/N4/N5 — qualidade da dieta (IQD) ─────────────────────────────────

  Widget _buildQualityPage({
    required double iqdScore,
    required String scoreLabel,
    required String displayTip,
    required bool hasTip,
    required double totalFiber,
    required double totalSodium,
    required double totalAddedSugar,
    required int totalFat, required int fatTarget,
  }) {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // N3 — arco dourado sólido, sem gradiente e sem ponteiro.
              BldrGaugeArc(
                progress: iqdScore / 100,
                width: 220,
                strokeWidth: 11,
                center: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${iqdScore.toInt()}',
                          style: const TextStyle(
                            fontFamily: BldrText.family,
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: BldrColors.textPrimary,
                            height: 1.0,
                          )),
                      Text(AppLocalizations.of(context).nutrition_iqd_gauge_label, style: BldrText.metaSm),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              BldrBadge(label: scoreLabel),

              // N4 — dica acionável (lâmpada, não alerta).
              if (hasTip) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: BldrColors.goldTint,
                    borderRadius: BldrRadius.all(BldrRadius.cardSm),
                    border: Border.all(color: BldrColors.goldBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: BldrColors.goldBright, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(displayTip,
                            style: BldrText.description.copyWith(
                                color: BldrColors.textPrimary, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // N5 — nutrientes do IQD, grid 2×2, sem bolinhas coloridas.
              Row(children: [
                Expanded(child: _buildNutrientCard(AppLocalizations.of(context).nutrition_fiber, totalFiber.round(), 25, 'g')),
                const SizedBox(width: 10),
                Expanded(child: _buildNutrientCard(AppLocalizations.of(context).nutrition_sodium, totalSodium.round(), 2000, 'mg')),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _buildNutrientCard(AppLocalizations.of(context).nutrition_sugars, totalAddedSugar.round(), 50, 'g')),
                const SizedBox(width: 10),
                Expanded(child: _buildNutrientCard(AppLocalizations.of(context).nutrition_fat, totalFat, fatTarget, 'g')),
              ]),
            ],
          ),
        ),

        // Máscara Premium (apenas para não-club) — lógica intacta.
        if (!widget.isClub)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => print('Abrir Paywall'),
              child: ClipRRect(
                borderRadius: BldrRadius.all(BldrRadius.card),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: BldrColors.bgBase.withOpacity(0.6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded,
                            color: BldrColors.goldBright, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).nutrition_iqd_premium_msg,
                          style: BldrText.body.copyWith(
                              fontWeight: FontWeight.w600, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.checkoutScreen),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: BldrColors.goldSolid,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              AppLocalizations.of(context).nutrition_iqd_premium_btn,
                              style: const TextStyle(
                                fontFamily: BldrText.family,
                                color: Color(0xFF0A0A0A),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNutrientCard(String name, int current, int target, String unit) {
    final double progress = (target > 0) ? math.min(current / target, 1.0) : 0.0;
    final bool over = target > 0 && current > target * 1.1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: BldrColors.surfaceInset,
        borderRadius: BldrRadius.all(BldrRadius.cardSm),
        border: Border.all(color: BldrColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(name, style: BldrText.meta)),
              Text(
                '$current/$target$unit',
                style: BldrText.metaSm.copyWith(
                  color: over ? BldrColors.danger : BldrColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BldrProgressBar(value: progress, height: 4),
        ],
      ),
    );
  }

  // ── Badge de calorias ────────────────────────────────────────────────────

  Widget _buildCalorieBadge(int current, int target) {
    final bool over = current > target;
    final Color badgeColor = over ? BldrColors.danger : BldrColors.goldBright;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Text('$current / $target kcal',
              style: TextStyle(
                  fontFamily: BldrText.family,
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ],
      ),
    );
  }
}
