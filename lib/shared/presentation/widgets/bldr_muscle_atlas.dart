import 'package:flutter/material.dart';
import 'package:flutter_muscle_anatomy/flutter_muscle_anatomy.dart';

// Mapeamento muscle_groups[] do Supabase → Muscle enum
// Aliases são static get (não const) — mapa precisa ser final
final Map<String, Muscle> _muscleMap = {
  'chest':       Muscle.chest,          // pectoralisMajor — front
  'shoulders':   Muscle.deltoid,        // front
  'triceps':     Muscle.triceps,        // back
  'biceps':      Muscle.biceps,         // front
  'back':        Muscle.lats,           // latissimusDorsi — both
  'lats':        Muscle.lats,           // both
  'upper back':  Muscle.traps,          // trapezius — back
  'traps':       Muscle.traps,          // back
  'abs':         Muscle.abs,            // rectusAbdominis — front
  'quads':       Muscle.quads,          // rectusFemoris — front
  'hamstrings':  Muscle.hamstrings,     // bicepsFemoris — back
  'glutes':      Muscle.glutes,         // gluteusMaximus — back
  'calves':      Muscle.calves,         // gastrocnemius — both
  // TODO: 'lower back' — sem equivalente direto no enum (erectorSpinae ausente)
  // TODO: 'forearms' — brachioradialis existe mas não é comum no banco
};

const _goldPrimary   = Color(0xFFC9A227);
const _goldSecondary = Color(0xFFC9A227);
const _baseColor     = Color(0xFF1A1A1A);
const _strokeColor   = Color(0xFF3A3A3A);

class BLDRMuscleAtlas extends StatelessWidget {
  final List<String> muscleGroups;

  const BLDRMuscleAtlas({super.key, required this.muscleGroups});

  @override
  Widget build(BuildContext context) {
    final muscles = muscleGroups
        .map((g) => _muscleMap[g.toLowerCase()])
        .whereType<Muscle>()
        .toList();

    debugPrint('[Atlas] muscleGroups recebidos: $muscleGroups');
    debugPrint('[Atlas] muscles resolvidos: ${muscles.map((m) => m.name).toList()}');

    if (muscles.isEmpty) {
      return const SizedBox(width: 160, height: 220);
    }

    // Detectar se precisa de frente, costas, ou ambos
    final hasFront = muscles.any((m) =>
        m.view == BodyView.front || m.view == BodyView.both);
    final hasBack = muscles.any((m) =>
        m.view == BodyView.back || m.view == BodyView.both);

    debugPrint('[Atlas] hasFront: $hasFront, hasBack: $hasBack');

    if (hasFront && hasBack) {
      // Mostrar frente + costas lado a lado
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _atlasView(
            Anatomy('male').front(),
            muscles,
            const Size(90, 160),
          ),
          const SizedBox(width: 8),
          _atlasView(
            Anatomy('male').back(),
            muscles,
            const Size(90, 160),
          ),
        ],
      );
    }

    // Somente frente ou somente costas
    final anatomy = hasBack
        ? Anatomy('male').back()
        : Anatomy('male').front();
    return _atlasView(anatomy, muscles, const Size(120, 200));
  }

  Widget _atlasView(
    MuscleAnatomy anatomy,
    List<Muscle> muscles,
    Size size,
  ) {
    anatomy.setDefaultFill(color: _baseColor, opacity: 1.0);
    anatomy.setDefaultStroke(color: _strokeColor, width: 0.5);

    if (muscles.isNotEmpty) {
      anatomy.highlight(
        muscles.first,
        color: _goldPrimary,
        opacity: 0.9,
      );
    }
    if (muscles.length > 1) {
      anatomy.highlightAll(
        muscles.skip(1).toList(),
        color: _goldSecondary,
        opacity: 0.45,
      );
    }

    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        size: size,
        painter: anatomy.customPainter(size),
      ),
    );
  }
}
