import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/design_system/bldr_nutrition_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Rascunho do cadastro manual (passo 1 → passo 2 → volta).
class CreateFoodDraft {
  final String name;
  final String brand;
  final Map<String, String> values; // chave do campo → texto digitado
  const CreateFoodDraft(
      {this.name = '', this.brand = '', this.values = const {}});

  CreateFoodDraft copyWith(
          {String? name, String? brand, Map<String, String>? values}) =>
      CreateFoodDraft(
          name: name ?? this.name,
          brand: brand ?? this.brand,
          values: values ?? this.values);

  static double? _num(String? t) {
    final s = (t ?? '').trim().replaceAll(',', '.');
    return s.isEmpty ? null : double.tryParse(s);
  }

  /// Valores por 100 g. Sem calorias digitadas, calcula por 4/4/9 (mesma
  /// regra do formulário antigo). `null` se não houver nenhum valor.
  FoodItem? toFoodItem() {
    final p = _num(values['p']), c = _num(values['c']), f = _num(values['f']);
    var kcal = _num(values['kcal']);
    if (kcal == null && p == null && c == null && f == null) return null;
    kcal ??= (p ?? 0) * 4 + (c ?? 0) * 4 + (f ?? 0) * 9;
    return FoodItem(
      name: name.trim(),
      brand: brand.trim().isEmpty ? null : brand.trim(),
      caloriesPer100g: kcal,
      proteinPer100g: p ?? 0,
      carbsPer100g: c ?? 0,
      fatPer100g: f ?? 0,
      fiberPer100g: _num(values['fiber']) ?? 0,
      sodiumPer100g: _num(values['sodium']) ?? 0,
      addedSugarPer100g: _num(values['sugar']) ?? 0,
    );
  }
}

/// Resultado do passo 2: salvar com o alimento pronto ou voltar ao passo 1.
class CreateFoodStep2Result {
  final FoodItem? food;
  final CreateFoodDraft draft;
  const CreateFoodStep2Result.save(FoodItem this.food, this.draft);
  const CreateFoodStep2Result.back(this.draft) : food = null;
}

class _Field extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool numeric;
  final String? suffix;
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.numeric = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrNutritionTextV2.fieldLabel),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BldrNutritionColorsV2.summaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: BldrNutritionColorsV2.summaryBorder, width: 0.8),
            ),
            child: TextField(
              controller: controller,
              textAlign: numeric ? TextAlign.center : TextAlign.start,
              keyboardType: numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              textCapitalization: numeric
                  ? TextCapitalization.none
                  : TextCapitalization.sentences,
              inputFormatters: numeric
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                  : null,
              style: BldrNutritionTextV2.inputValue,
              cursorColor: BldrNutritionColorsV2.gold,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint ?? (numeric ? '0' : null),
                hintStyle: BldrNutritionTextV2.inputHint,
                suffixText: suffix,
                suffixStyle: BldrNutritionTextV2.inputHint,
              ),
            ),
          ),
        ],
      );
}

Widget _pill(String label, bool on, {bool enabled = true}) => Semantics(
      selected: on,
      enabled: enabled,
      child: Opacity(
        opacity: enabled || on ? 1 : 0.45,
        child: Container(
          constraints: const BoxConstraints(minHeight: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: on
                ? BldrNutritionColorsV2.chipActiveBg
                : BldrNutritionColorsV2.summaryBg,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
                color: on
                    ? BldrNutritionColorsV2.gold
                    : BldrNutritionColorsV2.summaryBorder,
                width: on ? 1 : 0.8),
          ),
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: on
                  ? BldrNutritionTextV2.segmentOn
                  : BldrNutritionTextV2.segment),
        ),
      ),
    );

/// Cadastro manual (Figma 102:296 → 102:167), base fixa de 100 g.
abstract final class NutritionCreateFoodSheets {
  static Future<CreateFoodDraft?> step1(BuildContext context,
      {required CreateFoodDraft draft}) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<CreateFoodDraft>(
      context,
      eyebrow: l.nutri2_eyebrow,
      title: l.nutri2_create_title,
      subtitle: l.nutri2_create_basic,
      closeLabel: l.nutri2_close,
      child: _Step1(draft: draft),
    );
  }

  static Future<CreateFoodStep2Result?> step2(BuildContext context,
      {required CreateFoodDraft draft}) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<CreateFoodStep2Result>(
      context,
      eyebrow: l.nutri2_eyebrow,
      title: l.nutri2_create_info_title,
      subtitle: l.nutri2_create_info_sub(draft.name.trim()),
      closeLabel: l.nutri2_close,
      child: _Step2(draft: draft),
    );
  }
}

class _StepTag extends StatelessWidget {
  final int n;
  const _StepTag(this.n);
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Text(AppLocalizations.of(context).nutri2_step(n),
            style: BldrNutritionTextV2.step),
      );
}

class _Step1 extends StatefulWidget {
  final CreateFoodDraft draft;
  const _Step1({required this.draft});
  @override
  State<_Step1> createState() => _Step1State();
}

class _Step1State extends State<_Step1> {
  late final _name = TextEditingController(text: widget.draft.name);
  late final _brand = TextEditingController(text: widget.draft.brand);
  bool _missingName = false;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepTag(1),
        const SizedBox(height: 12),
        _Field(
            label: l.nutri2_create_name,
            hint: l.nutri2_create_name_hint,
            controller: _name),
        if (_missingName) ...[
          const SizedBox(height: 4),
          Text(l.nutri2_create_need_name, style: BldrNutritionTextV2.removeCta),
        ],
        const SizedBox(height: 14),
        _Field(
            label: l.nutri2_create_brand,
            hint: l.nutri2_create_brand_hint,
            controller: _brand),
        const SizedBox(height: 16),
        Text(l.nutri2_portion_type, style: BldrNutritionTextV2.fieldLabel),
        const SizedBox(height: 6),
        // "Por unidade" desabilitado até haver campo para o peso da unidade.
        Row(children: [
          Expanded(child: _pill(l.nutri2_create_standard, true)),
          const SizedBox(width: 8),
          Expanded(
              child: _pill(l.nutri2_create_per_unit, false, enabled: false)),
        ]),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final base = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.nutri2_create_base, style: BldrNutritionTextV2.fieldLabel),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: BldrNutritionColorsV2.lockedBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: BldrNutritionColorsV2.lockedBorder, width: 0.8),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(l.nutri2_create_base_value,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: BldrNutritionTextV2.locked),
                  ),
                  const Icon(TablerIcons.lock,
                      size: 14, color: BldrNutritionColorsV2.lockedText),
                ]),
              ),
            ],
          );
          // Líquido (ml) desabilitado: a base guarda só gramas.
          final type = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.nutri2_create_type, style: BldrNutritionTextV2.fieldLabel),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: _pill(l.nutri2_create_solid, true)),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        _pill(l.nutri2_create_liquid, false, enabled: false)),
              ]),
            ],
          );
          if (c.maxWidth < 360 * scale) {
            return Column(children: [base, const SizedBox(height: 14), type]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: base),
            const SizedBox(width: 8),
            Expanded(child: type),
          ]);
        }),
        const SizedBox(height: 12),
        Text(l.nutri2_create_help, style: BldrNutritionTextV2.hint),
        const SizedBox(height: 40),
        BldrNutritionCta(
          label: l.nutri2_create_continue,
          onTap: () {
            if (_name.text.trim().isEmpty) {
              setState(() => _missingName = true);
              return;
            }
            Navigator.pop(context,
                widget.draft.copyWith(name: _name.text, brand: _brand.text));
          },
        ),
      ],
    );
  }
}

class _Step2 extends StatefulWidget {
  final CreateFoodDraft draft;
  const _Step2({required this.draft});
  @override
  State<_Step2> createState() => _Step2State();
}

class _Step2State extends State<_Step2> {
  static const _keys = ['kcal', 'p', 'c', 'f', 'fiber', 'sodium', 'sugar'];
  late final Map<String, TextEditingController> _c = {
    for (final k in _keys)
      k: TextEditingController(text: widget.draft.values[k] ?? ''),
  };
  bool _missing = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  CreateFoodDraft get _draft =>
      widget.draft.copyWith(values: {for (final k in _keys) k: _c[k]!.text});

  Widget _pair(Widget a, Widget b) => LayoutBuilder(builder: (context, c) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        if (c.maxWidth < 300 * scale) {
          return Column(children: [a, const SizedBox(height: 12), b]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: a),
          const SizedBox(width: 8),
          Expanded(child: b),
        ]);
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    _Field f(String label, String key, String suffix) => _Field(
        label: label, controller: _c[key]!, numeric: true, suffix: suffix);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepTag(2),
        const SizedBox(height: 12),
        f(l.nutri2_create_kcal, 'kcal', 'kcal'),
        const SizedBox(height: 12),
        _pair(f(l.nutri2_create_protein, 'p', 'g'),
            f(l.nutri2_create_carbs, 'c', 'g')),
        const SizedBox(height: 12),
        _pair(f(l.nutri2_create_fat, 'f', 'g'),
            f(l.nutri2_create_fiber, 'fiber', 'g')),
        const SizedBox(height: 12),
        _pair(f(l.nutri2_create_sodium, 'sodium', 'mg'),
            f(l.nutri2_create_sugar, 'sugar', 'g')),
        const SizedBox(height: 14),
        Text(l.nutri2_create_note, style: BldrNutritionTextV2.hint),
        if (_missing) ...[
          const SizedBox(height: 8),
          Text(l.nutri2_create_need_value,
              style: BldrNutritionTextV2.removeCta),
        ],
        const SizedBox(height: 28),
        BldrNutritionCta(
          label: l.nutri2_create_save,
          onTap: () {
            final draft = _draft;
            final food = draft.toFoodItem();
            if (food == null) {
              setState(() => _missing = true);
              return;
            }
            Navigator.pop(context, CreateFoodStep2Result.save(food, draft));
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                Navigator.pop(context, CreateFoodStep2Result.back(_draft)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(TablerIcons.arrow_left,
                    size: 13, color: BldrNutritionColorsV2.labelMuted),
                const SizedBox(width: 6),
                Text(l.nutri2_create_back,
                    style: BldrNutritionTextV2.fieldLabel),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
