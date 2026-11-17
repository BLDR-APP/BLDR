import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Sheet v2 reutilizável (Figma 179:1401 / 179:1496): fundo preto .95,
/// borda dourada 2 px, raio 46, alça, título centralizado e fundo da tela
/// escurecido por trás.
abstract final class BldrV2Sheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: BldrSheetV2Colors.scrim,
      elevation: 0,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: BldrV2SheetFrame(title: title, child: child),
      ),
    );
  }
}

/// Moldura visual do [BldrV2Sheet] (separada para testes e prévias).
class BldrV2SheetFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const BldrV2SheetFrame({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      decoration: BoxDecoration(
        color: BldrSheetV2Colors.bg,
        borderRadius: BorderRadius.circular(46),
        border: Border.all(color: BldrSheetV2Colors.border, width: 2),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 4,
                decoration: BoxDecoration(
                  color: BldrSheetV2Colors.grabber,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 32),
              Text(title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BldrSheetV2Text.title),
              const SizedBox(height: 28),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Controle − valor + dos sheets de carga e reps. Tocar no número abre a
/// digitação; segurar − / + repete o ajuste. [onChanged] a cada mudança
/// (salvamento automático, como no mockup).
class BldrV2Stepper extends StatefulWidget {
  final double initial;
  final double step;
  final double min;
  final double max;
  final bool decimal;
  final String? unit;
  final ValueChanged<double> onChanged;
  final String decreaseLabel;
  final String increaseLabel;

  const BldrV2Stepper({
    super.key,
    required this.initial,
    required this.step,
    required this.onChanged,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.min = 0,
    this.max = 999,
    this.decimal = false,
    this.unit,
  });

  /// "32,5" / "30" — vírgula decimal, sem zeros sobrando.
  static String format(double v, {bool decimal = false}) {
    if (!decimal || v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1).replaceAll('.', ',');
  }

  /// Aceita "32,5" ou "32.5"; null quando inválido.
  static double? parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  @override
  State<BldrV2Stepper> createState() => _BldrV2StepperState();
}

class _BldrV2StepperState extends State<BldrV2Stepper> {
  late double _value = widget.initial;
  bool _editing = false;
  late final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _repeat;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commitText();
    });
  }

  @override
  void dispose() {
    _repeat?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _set(double v) {
    final clamped = v.clamp(widget.min, widget.max).toDouble();
    if (clamped == _value) return;
    setState(() => _value = clamped);
    widget.onChanged(clamped);
  }

  void _bump(double delta) {
    HapticFeedback.selectionClick();
    _set(_value + delta);
  }

  void _startRepeat(double delta) {
    _repeat?.cancel();
    _repeat =
        Timer.periodic(const Duration(milliseconds: 110), (_) => _bump(delta));
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  void _startEditing() {
    _ctrl.text = BldrV2Stepper.format(_value, decimal: widget.decimal);
    _ctrl.selection =
        TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _commitText() {
    final parsed = BldrV2Stepper.parse(_ctrl.text);
    setState(() => _editing = false);
    if (parsed != null) {
      _set(widget.decimal ? parsed : parsed.roundToDouble());
    }
  }

  Widget _circle({
    required IconData icon,
    required bool accent,
    required double delta,
    required String label,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () => _bump(delta),
        onLongPressStart: (_) => _startRepeat(delta),
        onLongPressEnd: (_) => _stopRepeat(),
        onLongPressCancel: _stopRepeat,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BldrSheetV2Colors.button,
            border: Border.all(
                color: accent
                    ? BldrSheetV2Colors.border
                    : BldrSheetV2Colors.buttonBorder),
          ),
          child: Icon(icon,
              size: 24,
              color:
                  accent ? BldrSheetV2Colors.border : BldrSheetV2Colors.text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valueText = BldrV2Stepper.format(_value, decimal: widget.decimal);
    return Row(
      children: [
        const SizedBox(width: 26),
        _circle(
            icon: TablerIcons.minus,
            accent: false,
            delta: -widget.step,
            label: widget.decreaseLabel),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _editing ? null : _startEditing,
                child: SizedBox(
                  height: 48,
                  child: _editing
                      ? TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.numberWithOptions(
                              decimal: widget.decimal),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(widget.decimal ? r'[0-9.,]' : r'[0-9]')),
                          ],
                          style: BldrSheetV2Text.value,
                          cursorColor: BldrSheetV2Colors.border,
                          onSubmitted: (_) => _commitText(),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(valueText,
                              maxLines: 1, style: BldrSheetV2Text.value),
                        ),
                ),
              ),
              if (widget.unit != null)
                Text(widget.unit!, style: BldrSheetV2Text.unit),
              const SizedBox(height: 8),
              Container(
                  width: widget.unit != null ? 54 : 38,
                  height: 1,
                  color: BldrSheetV2Colors.indicator),
            ],
          ),
        ),
        _circle(
            icon: TablerIcons.plus,
            accent: true,
            delta: widget.step,
            label: widget.increaseLabel),
        const SizedBox(width: 26),
      ],
    );
  }
}

/// Linha de opção dentro de um [BldrV2Sheet] (ícone Tabler + rótulo).
class BldrV2SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;

  /// Ação exclusiva do BLDR CLUB para quem não tem acesso (cadeado).
  final bool locked;
  final VoidCallback onTap;
  const BldrV2SheetOption(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap,
      this.subtitle,
      this.locked = false});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: BldrSheetV2Colors.button,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BldrSheetV2Colors.buttonBorder),
            ),
            child: Row(children: [
              Icon(icon, size: 22, color: BldrSheetV2Colors.border),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BldrSheetV2Text.option),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: BldrSheetV2Text.label),
                      ],
                    ],
                  ),
                ),
              ),
              Icon(locked ? TablerIcons.lock : TablerIcons.chevron_right,
                  size: 18,
                  color: locked
                      ? BldrSheetV2Colors.border
                      : BldrSheetV2Colors.unit),
            ]),
          ),
        ),
      );
}

/// Botão principal de um [BldrV2Sheet] (borda dourada).
class BldrV2SheetButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const BldrV2SheetButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: BldrSheetV2Colors.border),
            ),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrConfirmV2Text.primary),
          ),
        ),
      );
}

/// Confirmação v2 (Figma 320:214): fundo `#050505`, borda dourada, raio 22,
/// título, mensagem, "Cancelar" neutro e ação principal; [destructive]
/// pinta a ação de vermelho (exclusões). Retorna true só ao confirmar.
abstract final class BldrV2ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: BldrConfirmV2Colors.scrim,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          decoration: BoxDecoration(
            color: BldrConfirmV2Colors.bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BldrSheetV2Colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: BldrConfirmV2Text.title),
              const SizedBox(height: 14),
              Text(message, style: BldrConfirmV2Text.message),
              const SizedBox(height: 40),
              Row(children: [
                Expanded(
                  child: _DialogButton(
                    label: cancelLabel,
                    filled: true,
                    color: BldrConfirmV2Colors.cancelText,
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _DialogButton(
                    label: confirmLabel,
                    color: destructive
                        ? BldrConfirmV2Colors.destructive
                        : BldrSheetV2Colors.border,
                    onTap: () => Navigator.pop(ctx, true),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    return ok ?? false;
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _DialogButton(
      {required this.label,
      required this.color,
      required this.onTap,
      this.filled = false});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? BldrConfirmV2Colors.cancelBg : null,
              borderRadius: BorderRadius.circular(14),
              border: filled ? null : Border.all(color: color),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BldrConfirmV2Text.button.copyWith(color: color)),
          ),
        ),
      );
}
