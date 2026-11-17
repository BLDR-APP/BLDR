import 'package:flutter/material.dart';

/// Logo oficial BL/DR dourado (`assets/images/launch/bldr_launch.png`, o
/// mesmo do splash), recortado ao desenho. O PNG tem 2000 px com o logo
/// ocupando ~500 px no centro; [height] é a altura do desenho.
class BldrLogoMark extends StatelessWidget {
  final double height;
  const BldrLogoMark({super.key, required this.height});

  static const _asset = 'assets/images/launch/bldr_launch.png';
  // Caixa do desenho no PNG de 2000 px.
  static const _logoLeft = 720.0, _logoTop = 694.0;
  static const _logoW = 512.0, _logoH = 516.0;
  static const _png = 2000.0;

  @override
  Widget build(BuildContext context) {
    final k = height / _logoH;
    final width = _logoW * k;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: _png * k,
          maxWidth: _png * k,
          minHeight: _png * k,
          maxHeight: _png * k,
          child: Transform.translate(
            offset: Offset(-_logoLeft * k, -_logoTop * k),
            child: Image.asset(_asset,
                width: _png * k,
                height: _png * k,
                filterQuality: FilterQuality.high),
          ),
        ),
      ),
    );
  }
}
