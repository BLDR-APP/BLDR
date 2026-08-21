import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RulerPickerWidget extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final double step;
  final double initialValue;
  final String unit;
  final int decimals;
  final double majorTickEvery;
  final ValueChanged<double> onValueChanged;

  const RulerPickerWidget({
    Key? key,
    required this.minValue,
    required this.maxValue,
    required this.step,
    required this.initialValue,
    required this.unit,
    this.decimals = 0,
    required this.majorTickEvery,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  State<RulerPickerWidget> createState() => _RulerPickerWidgetState();
}

class _RulerPickerWidgetState extends State<RulerPickerWidget> {
  late double _currentValue;
  double _dragStartX = 0;
  double _valueAtDragStart = 0;
  double? _lastHapticValue;

  // Major ticks are always spaced 64px apart for consistent visual
  double get _pixelsPerStep => 64.0 / (widget.majorTickEvery / widget.step);

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(widget.minValue, widget.maxValue);
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _valueAtDragStart = _currentValue;
    _lastHapticValue = _currentValue;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final double deltaX = _dragStartX - details.globalPosition.dx;
    final double rawDelta = (deltaX / _pixelsPerStep) * widget.step;
    double newValue = _valueAtDragStart + rawDelta;
    // Snap to step
    newValue = (newValue / widget.step).round() * widget.step;
    newValue = double.parse(newValue.toStringAsFixed(widget.decimals > 0 ? widget.decimals + 1 : 1));
    newValue = newValue.clamp(widget.minValue, widget.maxValue);

    if (newValue != _currentValue) {
      if (_lastHapticValue == null || (newValue - _lastHapticValue!).abs() >= widget.step) {
        HapticFeedback.selectionClick();
        _lastHapticValue = newValue;
      }
      setState(() => _currentValue = newValue);
      widget.onValueChanged(newValue);
    }
  }

  String get _displayValue => widget.decimals > 0
      ? _currentValue.toStringAsFixed(widget.decimals)
      : _currentValue.toInt().toString();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_displayValue ${widget.unit}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(
              painter: _RulerPainter(
                currentValue: _currentValue,
                minValue: widget.minValue,
                maxValue: widget.maxValue,
                step: widget.step,
                majorTickEvery: widget.majorTickEvery,
                pixelsPerStep: _pixelsPerStep,
                decimals: widget.decimals,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double currentValue;
  final double minValue;
  final double maxValue;
  final double step;
  final double majorTickEvery;
  final double pixelsPerStep;
  final int decimals;

  static const Color _gold = Color(0xFFD4AF37);

  const _RulerPainter({
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.step,
    required this.majorTickEvery,
    required this.pixelsPerStep,
    required this.decimals,
  });

  bool _isMajor(double value) {
    final double ratio = value / majorTickEvery;
    return (ratio - ratio.round()).abs() < 0.01;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double tickTop = size.height * 0.08;
    final int visibleSteps = (cx / pixelsPerStep).ceil() + 3;

    for (int i = -visibleSteps; i <= visibleSteps; i++) {
      final double rawValue = currentValue + i * step;
      final double tickValue = double.parse(rawValue.toStringAsFixed(decimals > 0 ? decimals + 1 : 1));
      if (tickValue < minValue || tickValue > maxValue) continue;

      final double x = cx + i * pixelsPerStep;
      final bool isCenter = i == 0;
      final bool isMajor = _isMajor(tickValue);
      final double opacity = math.max(0.0, 1.0 - (i.abs() / (visibleSteps + 1)));

      final double tickHeight = isCenter
          ? size.height * 0.62
          : isMajor
              ? size.height * 0.42
              : size.height * 0.22;

      final Color tickColor = isCenter
          ? _gold
          : Colors.white.withOpacity(opacity * (isMajor ? 0.65 : 0.35));

      final double strokeWidth = isCenter ? 2.5 : (isMajor ? 1.5 : 1.0);

      canvas.drawLine(
        Offset(x, tickTop),
        Offset(x, tickTop + tickHeight),
        Paint()
          ..color = tickColor
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      if (isMajor && opacity > 0.12) {
        final String label = decimals > 0
            ? tickValue.toStringAsFixed(decimals)
            : tickValue.toInt().toString();

        final TextPainter tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: isCenter ? _gold : Colors.white.withOpacity(opacity * 0.7),
              fontSize: isCenter ? 12 : 10,
              fontWeight: isCenter ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(x - tp.width / 2, tickTop + tickHeight + 4));
      }
    }

    // Center indicator triangle above ticks
    final Paint triPaint = Paint()..color = _gold;
    final Path triangle = Path()
      ..moveTo(cx - 5, tickTop - 2)
      ..lineTo(cx + 5, tickTop - 2)
      ..lineTo(cx, tickTop + 5)
      ..close();
    canvas.drawPath(triangle, triPaint);
  }

  @override
  bool shouldRepaint(_RulerPainter old) => old.currentValue != currentValue;
}
