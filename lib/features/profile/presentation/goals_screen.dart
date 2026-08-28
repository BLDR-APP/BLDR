import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/user_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _cardBg = Color(0xFF111111);

  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Peso
  double? _currentWeight;
  final _targetWeightCtrl = TextEditingController();

  // Ritmo
  String _pace = 'Moderado';
  static const _paces = ['Leve', 'Moderado', 'Agressivo'];

  // Calorias
  bool _customCalories = false;
  int _calculatedCalories = 0;
  final _caloriesCtrl = TextEditingController();

  // Macros
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    for (final c in [_caloriesCtrl, _proteinCtrl, _carbsCtrl, _fatCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _targetWeightCtrl,
      _caloriesCtrl,
      _proteinCtrl,
      _carbsCtrl,
      _fatCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final uid = getIt<GetCurrentUser>()()?.id;
    if (uid == null) return;

    final result = await getIt<GetUserGoals>()(uid);
    result.fold(
      onFailure: (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      onSuccess: (goals) => setState(() {
        _loading = false;
        _currentWeight = goals.currentWeightKg;
        _targetWeightCtrl.text =
            goals.targetWeightKg?.toStringAsFixed(1) ?? '';
        _pace = goals.goalPace;
        _customCalories = goals.customCalories;
        _calculatedCalories = goals.calories;
        _caloriesCtrl.text = goals.calories.toString();
        _proteinCtrl.text = goals.protein.toString();
        _carbsCtrl.text = goals.carbs.toString();
        _fatCtrl.text = goals.fat.toString();
      }),
    );
  }

  int get _cal => int.tryParse(_caloriesCtrl.text) ?? 0;
  int get _prot => int.tryParse(_proteinCtrl.text) ?? 0;
  int get _carb => int.tryParse(_carbsCtrl.text) ?? 0;
  int get _fat => int.tryParse(_fatCtrl.text) ?? 0;

  int get _macroCalories => _prot * 4 + _carb * 4 + _fat * 9;

  double _macroPercent(int grams, int calPerGram) {
    if (_cal == 0) return 0;
    return (grams * calPerGram) / _cal;
  }

  bool get _macrosValid => _macroCalories <= _cal + 50; // tolerância de 50 kcal

  Future<void> _save() async {
    if (!_macrosValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.goals_macros_exceed),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() => _saving = true);
    final uid = getIt<GetCurrentUser>()()?.id;
    if (uid == null) return;

    final goals = UserGoals(
      calories: _cal,
      protein: _prot,
      carbs: _carb,
      fat: _fat,
      targetWeightKg: double.tryParse(_targetWeightCtrl.text),
      goalPace: _pace,
      customCalories: _customCalories,
    );

    final result = await getIt<SaveUserGoals>()(uid, goals);
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      onFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(f.message),
        backgroundColor: Colors.redAccent,
      )),
      onSuccess: (_) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.goals_saved),
        backgroundColor: Colors.green,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(l10n.goals_screen_title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _gold)),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(l10n.goals_save_btn,
                  style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.white54)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionHeader(l10n.goals_section_weight),
                    _card([
                      _readOnlyRow(
                        label: l10n.goals_current_weight_label,
                        value: _currentWeight != null
                            ? '${_currentWeight!.toStringAsFixed(1)} kg'
                            : '—',
                        note: l10n.goals_editable_in_progress,
                      ),
                      const Divider(color: Colors.white10),
                      _inputRow(
                        label: l10n.goals_target_weight_label,
                        suffix: 'kg',
                        controller: _targetWeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _paceChips(l10n),
                    const SizedBox(height: 24),
                    _sectionHeader(l10n.goals_section_nutrition),
                    _calorieRow(l10n),
                    const SizedBox(height: 12),
                    _macroCard(l10n),
                    const SizedBox(height: 32),
                    _footerNote(),
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: const TextStyle(
                color: _gold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _readOnlyRow(
      {required String label, required String value, String? note}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  if (note != null)
                    Text(note,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Text(value,
                style: const TextStyle(
                    color: Colors.white54, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _inputRow({
    required String label,
    required String suffix,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.number,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              width: 90,
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixText: suffix,
                  suffixStyle:
                      const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _paceChips(AppLocalizations l10n) => _card([
        Text(l10n.goals_pace_title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        const SizedBox(height: 4),
        Text(l10n.goals_pace_subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: _paces.map((p) {
            final selected = p == _pace;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _pace = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _gold : Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(p,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: selected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
            );
          }).toList(),
        ),
      ]);

  Widget _calorieRow(AppLocalizations l10n) => _card([
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.goals_calorie_goal_label,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  if (!_customCalories)
                    Text(l10n.goals_calorie_calculated,
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            if (_customCalories)
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _caloriesCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixText: 'kcal',
                    suffixStyle:
                        const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              )
            else
              Text('$_calculatedCalories kcal',
                  style: const TextStyle(
                      color: Colors.white54, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _customCalories = !_customCalories;
                  if (!_customCalories) {
                    _caloriesCtrl.text =
                        _calculatedCalories.toString();
                  }
                });
              },
              child: Text(
                _customCalories ? l10n.goals_use_calculated : l10n.goals_customize,
                style: const TextStyle(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ]);

  Widget _macroCard(AppLocalizations l10n) {
    final valid = _macrosValid;
    return _card([
      Row(
        children: [
          Expanded(
              child: Text(l10n.goals_macros_title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600))),
          Text(
            '$_macroCalories / $_cal kcal',
            style: TextStyle(
                color: valid ? Colors.white38 : Colors.redAccent,
                fontSize: 12),
          ),
        ],
      ),
      if (!valid)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.goals_macros_exceed,
            style: const TextStyle(color: Colors.redAccent, fontSize: 11),
          ),
        ),
      const SizedBox(height: 12),
      _macroRow(l10n.goals_macro_protein, _proteinCtrl, 4, l10n),
      const Divider(color: Colors.white10),
      _macroRow(l10n.goals_macro_carbs, _carbsCtrl, 4, l10n),
      const Divider(color: Colors.white10),
      _macroRow(l10n.goals_macro_fat, _fatCtrl, 9, l10n),
    ]);
  }

  Widget _macroRow(
      String label, TextEditingController ctrl, int calPerGram, AppLocalizations l10n) {
    final grams = int.tryParse(ctrl.text) ?? 0;
    final pct = _macroPercent(grams, calPerGram);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                Text(l10n.goals_macro_pct_calories((pct * 100).toStringAsFixed(0)),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixText: 'g',
                suffixStyle:
                    const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerNote() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _gold.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gold.withOpacity(0.2)),
        ),
        child: Text(
          AppLocalizations.of(context)!.goals_footer_note,
          style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
        ),
      );
}
