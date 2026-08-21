import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/Firebase/firebase_add_food_modal_widget.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class FoodCategoriesModal extends StatelessWidget {
  final String mealType;
  final VoidCallback onFoodAdded;
  final DateTime selectedDate;
  final bool isClub;

  const FoodCategoriesModal({
    Key? key,
    required this.mealType,
    required this.onFoodAdded,
    required this.selectedDate,
    this.isClub = false,
  }) : super(key: key);

  // N11 — emojis mantidos por decisão do usuário.
  static const List<_FoodCategory> _categories = [
    _FoodCategory(label: 'Carnes & Aves',          emoji: '🥩', firestoreValue: 'CARNES E AVES'),
    _FoodCategory(label: 'Peixes & Frutos do Mar',  emoji: '🐟', firestoreValue: 'PEIXES E FRUTOS DO MAR'),
    _FoodCategory(label: 'Ovos',                    emoji: '🥚', firestoreValue: 'OVOS'),
    _FoodCategory(label: 'Laticínios',              emoji: '🥛', firestoreValue: 'LATICÍNIOS'),
    _FoodCategory(label: 'Frutas',                  emoji: '🍓', firestoreValue: 'FRUTAS'),
    _FoodCategory(label: 'Legumes & Verduras',      emoji: '🥦', firestoreValue: 'LEGUMES E VERDURAS (HORTALIÇAS)'),
    _FoodCategory(label: 'Grãos & Cereais',         emoji: '🌾', firestoreValue: 'GRÃOS E CEREAIS'),
    _FoodCategory(label: 'Gorduras & Óleos',        emoji: '🫒', firestoreValue: 'GORDURAS E ÓLEOS'),
    _FoodCategory(label: 'Oleaginosas',             emoji: '🥜', firestoreValue: 'OLEAGINOSAS E SEMENTES'),
    _FoodCategory(label: 'Doces & Sobremesas',      emoji: '🍰', firestoreValue: 'DOCES E SOBREMESAS'),
    _FoodCategory(label: 'Bebidas',                 emoji: '🥤', firestoreValue: 'BEBIDAS'),
    _FoodCategory(label: 'Fast Food',               emoji: '🍔', firestoreValue: 'ITENS DE FAST FOOD (MÉDIA DE MERCADO)'),
    _FoodCategory(label: 'Industrializados',        emoji: '📦', firestoreValue: 'PRODUTOS INDUSTRIALIZADOS (COMUNS)'),
    _FoodCategory(label: 'Refeições Prontas',       emoji: '🍱', firestoreValue: 'REFEIÇÕES PRONTAS'),
    _FoodCategory(label: 'Molhos & Temperos',       emoji: '🧂', firestoreValue: 'MOLHOS, TEMPEROS E CONDIMENTOS'),
    _FoodCategory(label: 'Suplementos',             emoji: '💊', firestoreValue: 'SUPLEMENTOS'),
  ];

  String _formatMealType(String type) {
    if (type.isEmpty) return type;
    return type[0].toUpperCase() + type.substring(1);
  }

  String _getCategoryLabel(String firestoreValue, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (firestoreValue) {
      case 'CARNES E AVES':                         return l10n.nutrition_cat_meat;
      case 'PEIXES E FRUTOS DO MAR':                return l10n.nutrition_cat_fish;
      case 'OVOS':                                  return l10n.nutrition_cat_eggs;
      case 'LATICÍNIOS':                            return l10n.nutrition_cat_dairy;
      case 'FRUTAS':                                return l10n.nutrition_cat_fruits;
      case 'LEGUMES E VERDURAS (HORTALIÇAS)':       return l10n.nutrition_cat_vegetables;
      case 'GRÃOS E CEREAIS':                       return l10n.nutrition_cat_grains;
      case 'GORDURAS E ÓLEOS':                      return l10n.nutrition_cat_fats;
      case 'OLEAGINOSAS E SEMENTES':                return l10n.nutrition_cat_nuts;
      case 'DOCES E SOBREMESAS':                    return l10n.nutrition_cat_sweets;
      case 'BEBIDAS':                               return l10n.nutrition_cat_drinks;
      case 'ITENS DE FAST FOOD (MÉDIA DE MERCADO)': return l10n.nutrition_cat_fastfood;
      case 'PRODUTOS INDUSTRIALIZADOS (COMUNS)':    return l10n.nutrition_cat_processed;
      case 'REFEIÇÕES PRONTAS':                     return l10n.nutrition_cat_readymeals;
      case 'MOLHOS, TEMPEROS E CONDIMENTOS':        return l10n.nutrition_cat_sauces;
      case 'SUPLEMENTOS':                           return l10n.nutrition_cat_supplements;
      default:                                      return firestoreValue;
    }
  }

  void _openFoodModal(BuildContext context, {String? category}) {
    Navigator.pop(context); // Fecha o modal de categorias
    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FirebaseAddFoodModalWidget(
        mealType: mealType,
        onFoodAdded: onFoodAdded,
        selectedDate: selectedDate,
        isClub: isClub,
        selectedCategory: category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Alça ---
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: BldrColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // N10 — cabeçalho indicando a refeição de destino.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
            child: Text(AppLocalizations.of(context).nutrition_add_to_meal(_formatMealType(mealType)),
                style: BldrText.cardTitleLg),
          ),
          const SizedBox(height: 16),

          // --- Campo de Busca ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
            child: GestureDetector(
              onTap: () => _openFoodModal(context, category: null),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).nutrition_search_db_hint,
                    hintStyle: BldrText.description,
                    prefixIcon: const Icon(Icons.search, color: BldrColors.goldBright, size: 20),
                    filled: true,
                    fillColor: BldrColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BldrColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BldrColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BldrColors.goldBright, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // N16 — atalho de foto do prato. [F] sem identificação automática
          // implementada ainda (câmera é um stub em FirebaseAddFoodModalWidget)
          // — card presente, com tint dourado, mas desabilitado.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
            child: Opacity(
              opacity: 0.55,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  color: BldrColors.goldTint,
                  borderRadius: BldrRadius.all(BldrRadius.cardSm),
                  border: Border.all(color: BldrColors.goldBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt_outlined, color: BldrColors.goldBright, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(AppLocalizations.of(context).nutrition_photo_auto_label,
                          style: BldrText.body.copyWith(fontSize: 13)),
                    ),
                    BldrBadge(label: AppLocalizations.of(context).nutrition_coming_soon, gold: false),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Subtítulo ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
            child: Text(AppLocalizations.of(context).nutrition_select_category, style: BldrText.description),
          ),

          const SizedBox(height: 10),

          // N11 — categorias em linhas horizontais (emoji + texto), 8
          // visíveis sem rolar.
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return BldrListRow(
                  icon: Icons.restaurant_menu, // sobrescrito por `leading`
                  leading: SizedBox(
                    width: 34,
                    height: 34,
                    child: Center(
                      child: Text(category.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  title: _getCategoryLabel(category.firestoreValue, context),
                  trailing: const Icon(Icons.chevron_right, color: BldrColors.textMuted, size: 18),
                  onTap: () => _openFoodModal(context, category: category.firestoreValue),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Model de Categoria
// ─────────────────────────────────────────
class _FoodCategory {
  final String label;
  final String emoji;
  final String firestoreValue;

  const _FoodCategory({required this.label, required this.emoji, required this.firestoreValue});
}
