import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

/// ⚠️ Consome `Map<String, dynamic>` vindo de
/// `presentation/mappers/legacy_ui_maps.dart` (dívida técnica registrada em
/// ARCHITECTURE.md). Contrato de chaves não alterado nesta tarefa — apenas
/// apresentação.
class MealTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  final Function(String) onAddMeal;
  final Function(Map<String, dynamic>) onEditMeal;
  final Function(String) onDeleteFoodLog;

  const MealTimelineWidget({
    Key? key,
    required this.meals,
    required this.onAddMeal,
    required this.onEditMeal,
    required this.onDeleteFoodLog,
  }) : super(key: key);

  // N6 — ordem de exibição das refeições.
  static const _mealTypes = [
    'café da manhã',
    'lanche',
    'almoço',
    'pré-treino',
    'pós-treino',
    'jantar',
  ];

  String _getDatabaseKey(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'café da manhã':
        return 'breakfast';
      case 'almoço':
        return 'lunch';
      case 'jantar':
        return 'dinner';
      case 'lanche':
        return 'snack';
      case 'pré-treino':
        return 'pre_workout';
      case 'pós-treino':
        return 'post_workout';
      default:
        return mealType; // Fallback
    }
  }

  // N7 — diferenciação por ícone, não por cor; tudo dourado (G4).
  IconData _mealIcon(String mealType) {
    switch (mealType) {
      case 'café da manhã': return TablerIcons.sunrise;
      case 'lanche':        return TablerIcons.coffee;
      case 'almoço':        return TablerIcons.sun;
      case 'pré-treino':    return TablerIcons.bolt;
      case 'pós-treino':    return TablerIcons.barbell;
      case 'jantar':        return TablerIcons.moon;
      default:              return Icons.restaurant_rounded;
    }
  }

  String _formatMealType(String mealType) {
    return mealType[0].toUpperCase() + mealType.substring(1);
  }

  String _mealDisplayName(String mealType, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (mealType) {
      case 'café da manhã': return l10n.nutrition_breakfast;
      case 'lanche':        return l10n.nutrition_snack;
      case 'almoço':        return l10n.nutrition_lunch;
      case 'pré-treino':    return l10n.nutrition_pre_workout;
      case 'pós-treino':    return l10n.nutrition_post_workout;
      case 'jantar':        return l10n.nutrition_dinner;
      default:              return _formatMealType(mealType);
    }
  }

  int _calculateTotalCalories(List<Map<String, dynamic>> mealsOfType) {
    int total = 0;
    for (final meal in mealsOfType) {
      total += (meal['calories'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  /// N8 — resumo dos alimentos já registrados ("Ovos, aveia, banana ·
  /// 430 kcal"). O dado (nome + calorias por item) já está disponível em
  /// `meals` (mapeado de `MealEntry`) — sem precisar de novo campo.
  String _mealSummary(List<Map<String, dynamic>> mealsOfType) {
    final names = mealsOfType
        .map((m) => (m['food_name'] as String?)?.trim())
        .where((n) => n != null && n.isNotEmpty)
        .cast<String>()
        .toList();
    final kcal = _calculateTotalCalories(mealsOfType);
    if (names.isEmpty) return '$kcal kcal';
    return '${names.join(', ')} · $kcal kcal';
  }

  /// N9 — sugestão de refeição para os atalhos do rodapé (sem dedicated
  /// entry point de câmera funcional hoje — ver conversa).
  String _suggestedMealType() {
    final h = DateTime.now().hour;
    if (h < 10) return 'breakfast';
    if (h < 14) return 'lunch';
    if (h < 18) return 'snack';
    return 'dinner';
  }

  @override
  Widget build(BuildContext context) {
    final int totalItems = meals.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context).nutrition_meals_section, style: BldrText.sectionTitle),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: BldrColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$totalItems', style: BldrText.metaSm),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // N6 — linhas horizontais, não cards grandes.
        ..._mealTypes.map((mealType) {
          final dbKey = _getDatabaseKey(mealType);
          final mealsOfType = meals.where((m) => m['meal_type'] == dbKey).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildMealRow(context, mealType, mealsOfType),
          );
        }),

        const SizedBox(height: 8),

        // N9 — atalhos no rodapé da lista.
        Row(
          children: [
            Expanded(
              child: BldrSquareActionButton(
                icon: Icons.camera_alt_outlined,
                label: AppLocalizations.of(context).nutrition_photo_meal_btn,
                onPressed: () => onAddMeal(_suggestedMealType()),
              ),
            ),
            const SizedBox(width: BldrSpacing.gapCard),
            Expanded(
              child: BldrSquareActionButton(
                icon: Icons.search_rounded,
                label: AppLocalizations.of(context).nutrition_search_btn,
                emphasized: true,
                onPressed: () => onAddMeal(_suggestedMealType()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMealRow(
      BuildContext context, String mealType, List<Map<String, dynamic>> mealsOfType) {
    final bool hasItems = mealsOfType.isNotEmpty;

    return BldrListRow(
      icon: _mealIcon(mealType),
      title: _mealDisplayName(mealType, context),
      subtitle: hasItems ? _mealSummary(mealsOfType) : AppLocalizations.of(context).nutrition_no_food,
      trailing: hasItems
          ? const Icon(Icons.chevron_right, color: BldrColors.textMuted, size: 18)
          : Icon(Icons.add_circle_outline, color: BldrColors.goldBright, size: 20),
      onTap: hasItems
          ? () => _showMealDetailModal(context, mealType, mealsOfType)
          : () => onAddMeal(mealType),
    );
  }

  // ── modal de detalhe da refeição ─────────────────────────────────────────

  void _showMealDetailModal(
      BuildContext context, String mealType, List<Map<String, dynamic>> mealsOfType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (sheetContext, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: BldrColors.textMuted, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(children: [
                Text(_mealDisplayName(mealType, ctx), style: BldrText.cardTitleLg),
                const Spacer(),
                GestureDetector(
                  onTap: () { Navigator.pop(ctx); onAddMeal(mealType); },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: BldrColors.goldTintChip,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.add_rounded, color: BldrColors.goldBright, size: 16),
                      const SizedBox(width: 4),
                      Text(AppLocalizations.of(ctx).nutrition_add_btn, style: BldrText.buttonSecondary),
                    ]),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: mealsOfType.map((meal) => _buildMealCard(ctx, meal)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, Map<String, dynamic> meal) {
    final totalCalories = (meal['calories'] as num?)?.toInt() ?? 0;
    final foodName = (meal['food_name'] as String?) ?? AppLocalizations.of(context).nutrition_unnamed_food;
    final quantity = (meal['quantity_grams'] as num?)?.toInt() ?? 0;
    final protein = (meal['protein'] as num?)?.toInt() ?? 0;
    final carbs = (meal['carbs'] as num?)?.toInt() ?? 0;
    final fat = (meal['fat'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BldrColors.surface,
        borderRadius: BldrRadius.all(BldrRadius.cardSm),
        border: Border.all(color: BldrColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  foodName,
                  style: BldrText.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditOrDeleteModal(context, meal),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: BldrColors.surfaceInset,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: BldrColors.border),
                  ),
                  child: const Icon(Icons.edit_rounded, color: BldrColors.textMuted, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('$totalCalories cal',
                  style: BldrText.description.copyWith(
                      color: BldrColors.goldBright, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('·', style: BldrText.description),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${quantity}g · P:${protein}g · C:${carbs}g · G:${fat}g',
                  style: BldrText.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditOrDeleteModal(BuildContext context, Map<String, dynamic> meal) {
    final foodLogId = meal['id'] as String?;
    if (foodLogId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).nutrition_item_id_missing)));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: BldrColors.textMuted, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text((meal['food_name'] as String?) ?? AppLocalizations.of(context).nutrition_unnamed_food, style: BldrText.cardTitleLg),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(ctx).nutrition_item_action_question, style: BldrText.description),
              const SizedBox(height: 18),
              BldrPrimaryButton(
                label: AppLocalizations.of(ctx).nutrition_edit_quantity,
                icon: Icons.edit_outlined,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  onEditMeal(meal);
                },
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  onDeleteFoodLog(foodLogId);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: BldrColors.danger.withOpacity(0.08),
                    borderRadius: BldrRadius.all(BldrRadius.button),
                    border: Border.all(color: BldrColors.danger.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(AppLocalizations.of(ctx).nutrition_remove_item,
                        style: TextStyle(
                            fontFamily: BldrText.family,
                            color: BldrColors.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
