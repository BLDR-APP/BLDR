// BLDR — Componentes base
// Todas as telas devem ser compostas a partir destes widgets.
// Isso é o que garante que o resultado seja idêntico aos mockups: a fidelidade
// mora aqui, não na tela. Se um card ficou diferente, o ajuste é neste arquivo
// e propaga para todo o app.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_map.dart';

// ─────────────────────────────────────────────────────────────
// FUNDO DA TELA
// ─────────────────────────────────────────────────────────────

/// Fundo obrigatório de toda tela: base escura + glow radial dourado.
/// Sem o glow, os cards de vidro não têm o que refratar e ficam cinza.
class BldrBackground extends StatelessWidget {
  final Widget child;
  final bool secondaryGlow;

  const BldrBackground({
    super.key,
    required this.child,
    this.secondaryGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BldrColors.bgBase,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: BldrColors.glowPrimary),
            ),
          ),
          if (secondaryGlow)
            Positioned.fill(
              child: DecoratedBox(
                decoration:
                    const BoxDecoration(gradient: BldrColors.glowSecondary),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARDS
// ─────────────────────────────────────────────────────────────

/// Card de vidro padrão.
/// ClipRRect é obrigatório ao redor do BackdropFilter — sem ele o blur
/// vaza para fora dos cantos arredondados.
class BldrGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blurSigma;
  final Color? background;
  final Color? borderColor;
  final VoidCallback? onTap;

  const BldrGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = BldrRadius.card,
    this.blurSigma = BldrBlur.card,
    this.background,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BldrRadius.all(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(BldrSpacing.padCard),
          decoration: BoxDecoration(
            color: background ?? BldrColors.surface,
            border: Border.all(
              color: borderColor ?? BldrColors.border,
              width: 1,
            ),
            borderRadius: BldrRadius.all(radius),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

/// Card em destaque — hero, CTA principal.
/// Máximo UM por tela.
class BldrHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool cornerGlow;
  final VoidCallback? onTap;

  const BldrHeroCard({
    super.key,
    required this.child,
    this.padding,
    this.cornerGlow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BldrGlassCard(
      radius: BldrRadius.hero,
      blurSigma: BldrBlur.cardLg,
      background: BldrColors.goldTintStrong,
      borderColor: BldrColors.goldBorder,
      padding: padding ?? const EdgeInsets.all(BldrSpacing.padCardLg),
      onTap: onTap,
      child: cornerGlow
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -48,
                  right: -48,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x38E0B830), Color(0x00E0B830)],
                        stops: [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
                child,
              ],
            )
          : child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTÕES
// ─────────────────────────────────────────────────────────────

/// Botão primário — dourado sólido. Máximo UM por tela.
class BldrPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double radius;

  const BldrPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.radius = BldrRadius.button,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: BldrColors.goldSolid,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BldrRadius.all(radius)),
          minimumSize: const Size(0, 48),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: const Color(0xFF0A0A0A)),
              const SizedBox(width: 8),
            ],
            Text(label, style: BldrText.buttonPrimary),
          ],
        ),
      ),
    );
  }
}

/// Botão secundário — outline dourado sobre tint.
class BldrSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const BldrSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: BldrColors.goldTintChip,
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BldrRadius.all(13),
            side: const BorderSide(color: Color(0x40E0B830), width: 1),
          ),
          minimumSize: const Size(0, 44),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: BldrColors.goldBright),
              const SizedBox(width: 7),
            ],
            Text(label, style: BldrText.buttonSecondary),
          ],
        ),
      ),
    );
  }
}

/// Botão circular de ação — play, adicionar.
class BldrCircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool filled;
  final VoidCallback? onPressed;

  const BldrCircleButton({
    super.key,
    required this.icon,
    this.size = 44,
    this.filled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      // Garante área de toque de 44px mesmo em botões visualmente menores
      child: SizedBox(
        width: size < 44 ? 44 : size,
        height: size < 44 ? 44 : size,
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? BldrColors.goldSolid : BldrColors.goldTintChip,
            ),
            child: Icon(
              icon,
              size: size * 0.36,
              color: filled ? const Color(0xFF0A0A0A) : BldrColors.goldBright,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHIPS E SELETORES
// ─────────────────────────────────────────────────────────────

class BldrChip extends StatelessWidget {
  final String label;
  final bool active;
  final IconData? icon;
  final VoidCallback? onTap;

  const BldrChip({
    super.key,
    required this.label,
    this.active = false,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: active ? BldrColors.goldTintChip : BldrColors.surface,
          border: Border.all(
            color: active ? BldrColors.goldBorderChip : BldrColors.border,
            width: 1,
          ),
          borderRadius: BldrRadius.all(BldrRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 12,
                  color: active
                      ? BldrColors.goldBright
                      : BldrColors.textSecondary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: BldrText.family,
                fontSize: 11,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color:
                    active ? BldrColors.goldBright : BldrColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented control — abas internas (Geral/Corpo/Treinos/Nutrição,
/// Criados por mim/Do meu personal).
class BldrSegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  const BldrSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BldrColors.surfaceSubtle,
        border: Border.all(color: BldrColors.borderSubtle, width: 1),
        borderRadius: BldrRadius.all(14),
      ),
      child: Row(
        children: List.generate(segments.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged?.call(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? BldrColors.goldTintChip : Colors.transparent,
                  borderRadius: BldrRadius.all(11),
                ),
                child: Text(
                  segments[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: BldrText.family,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                    color: active
                        ? BldrColors.goldBright
                        : BldrColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROGRESSO
// ─────────────────────────────────────────────────────────────

class BldrProgressBar extends StatelessWidget {
  /// 0.0 a 1.0
  final double value;
  final double height;

  /// Gradiente para barras longas (peso, nível, XP); sólido para as curtas.
  final bool gradient;

  const BldrProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BldrRadius.all(BldrRadius.bar),
      child: Stack(
        children: [
          Container(height: height, color: BldrColors.track),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: gradient ? null : BldrColors.goldBright,
                gradient: gradient ? BldrColors.progressGradient : null,
                borderRadius: BldrRadius.all(BldrRadius.bar),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LINHA DE LISTA
// ─────────────────────────────────────────────────────────────

/// Use lista (não grid de cards) sempre que houver 4+ itens do mesmo tipo.
class BldrListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Substitui o `BldrIconBox` padrão (ex.: `BldrIndexBox` para listas
  /// ordenadas). Quando `null`, usa `BldrIconBox(icon: icon)`.
  final Widget? leading;

  const BldrListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return BldrGlassCard(
      radius: BldrRadius.cardSm,
      padding: const EdgeInsets.symmetric(
          horizontal: 15, vertical: BldrSpacing.padRow),
      onTap: onTap,
      child: Row(
        children: [
          leading ?? BldrIconBox(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: BldrText.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: BldrText.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Caixa de ícone dourada usada em linhas de lista e cabeçalhos de card.
class BldrIconBox extends StatelessWidget {
  final IconData icon;
  final double size;

  const BldrIconBox({super.key, required this.icon, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: BldrColors.goldTint,
        borderRadius: BldrRadius.all(BldrRadius.iconBox),
      ),
      child: Icon(icon, size: size * 0.45, color: BldrColors.goldBright),
    );
  }
}

/// Caixa numerada — mesma forma/tamanho de `BldrIconBox`, usada quando a
/// posição na lista importa mais que um ícone repetido (ex.: ordem dos
/// exercícios de um treino).
class BldrIndexBox extends StatelessWidget {
  final int index;
  final double size;

  const BldrIndexBox({super.key, required this.index, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BldrColors.goldTint,
        borderRadius: BldrRadius.all(BldrRadius.iconBox),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          fontFamily: BldrText.family,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: BldrColors.goldBright,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ESTADO VAZIO
// ─────────────────────────────────────────────────────────────

/// Borda tracejada é o que diferencia "espaço a preencher" de "conteúdo".
/// NUNCA empilhar mais de um estado vazio visível na mesma tela.
class BldrEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? instruction;

  const BldrEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return BldrDashedContainer(
      radius: BldrRadius.cardLg,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: const Color(0x33FFFFFF)),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: BldrText.family,
                fontSize: 13,
                color: Color(0x99FFFFFF),
              )),
          if (instruction != null) ...[
            const SizedBox(height: 3),
            Text(instruction!,
                textAlign: TextAlign.center, style: BldrText.metaSm),
          ],
        ],
      ),
    );
  }
}

/// Container com borda tracejada — "espaço a preencher", nunca "conteúdo".
/// Usado por `BldrEmptyState` e por qualquer card que precise do mesmo
/// tratamento (ex.: dia de descanso na timeline, P5).
class BldrDashedContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color background;

  const BldrDashedContainer({
    super.key,
    required this.child,
    this.radius = BldrRadius.cardLg,
    this.padding = const EdgeInsets.all(BldrSpacing.padCard),
    this.background = BldrColors.surfaceInset,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(radius: radius),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BldrRadius.all(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double radius;
  const _DashedBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    const dash = 5.0;
    const gap = 4.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.radius != radius;
}

// ─────────────────────────────────────────────────────────────
// BADGE
// ─────────────────────────────────────────────────────────────

class BldrBadge extends StatelessWidget {
  final String label;
  final bool gold;

  /// Badge sobre imagem (ex.: capa de programa) — fundo com blur em vez de
  /// cor sólida, para ficar legível sobre qualquer foto. `blur(8px)` do
  /// design system (7.6) — ver `BldrBlur.badge`.
  final bool blur;

  const BldrBadge(
      {super.key, required this.label, this.gold = true, this.blur = false});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: blur
            ? Colors.black.withOpacity(0.35)
            : (gold ? BldrColors.goldTintChip : BldrColors.surface),
        borderRadius: BldrRadius.all(7),
        border: blur ? Border.all(color: Colors.white.withOpacity(0.15)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: BldrText.family,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: blur
              ? BldrColors.textPrimary
              : (gold ? BldrColors.goldBright : BldrColors.textSecondary),
        ),
      ),
    );

    if (!blur) return content;
    return ClipRRect(
      borderRadius: BldrRadius.all(7),
      child: BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: BldrBlur.badge, sigmaY: BldrBlur.badge),
        child: content,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARROSSEL
// ─────────────────────────────────────────────────────────────

/// O último item deve ficar parcialmente cortado na borda direita — é o que
/// sinaliza que dá para arrastar. Por isso o padding fica no ListView e não
/// nos filhos.
class BldrCarousel extends StatelessWidget {
  final List<Widget> children;
  final double itemWidth;
  final double height;
  final double gap;

  const BldrCarousel({
    super.key,
    required this.children,
    required this.itemWidth,
    required this.height,
    this.gap = BldrSpacing.gapCard,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: BldrSpacing.pageInsets,
        physics: const BouncingScrollPhysics(),
        itemCount: children.length,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        itemBuilder: (_, i) => SizedBox(width: itemWidth, child: children[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NAVEGAÇÃO INFERIOR
// ─────────────────────────────────────────────────────────────

/// Pílula flutuante em glassmorphism, centrada horizontalmente, só ícones
/// (sem labels). O conteúdo da tela rola POR TRÁS — não reservar espaço
/// abaixo dela; usar `BldrSpacing.navClearance` como padding inferior do
/// scroll (110, folga suficiente para a pílula + margem).
///
/// ⚠️ O botão central usa a LOGO BLDR CLUB atual como asset. Não substituir
/// por texto nem alterar o tratamento.
///
/// Sem labels visíveis, cada item carrega `Semantics(label:, selected:,
/// button: true)` — sem isso um leitor de tela anunciaria só "botão".
class BldrNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onChanged;
  final VoidCallback? onClubTap;
  final Widget clubLogo;

  const BldrNavBar({
    super.key,
    required this.selectedIndex,
    required this.clubLogo,
    this.onChanged,
    this.onClubTap,
  });

  // Item comum 46px, botão central 54px, padding vertical 9 nos dois lados.
  static const double _pillHeight = 9 * 2 + 54;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (icon: TablerIcons.home, label: l10n.nav_tab_dashboard),
      (icon: TablerIcons.barbell, label: l10n.nav_tab_workouts),
      (icon: TablerIcons.users, label: l10n.nav_tab_community),
      (icon: TablerIcons.tools_kitchen_2, label: l10n.nav_tab_nutrition),
      (icon: TablerIcons.user, label: l10n.nav_tab_profile),
    ];
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final gap = 26 + bottomInset;

    // Como bottomNavigationBar, um Align/Center sem altura própria tentaria
    // preencher todo o espaço vertical dado pelo Scaffold (constraints soltas
    // = tão grande quanto possível) — vira uma área de toque invisível gigante
    // sobre o conteúdo. SizedBox força altura finita e definida.
    return SizedBox(
      height: gap + _pillHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x80000000), // black, 50%
                  blurRadius: 34,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0x8C141414), // rgba(20,20,20,0.55)
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                        color:
                            const Color(0x1FFFFFFF)), // rgba(255,255,255,0.12)
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _navItem(0, items),
                      const SizedBox(width: 4),
                      _navItem(1, items),
                      const SizedBox(width: 4),
                      _navItem(2, items),
                      // Acesso central ao BLDR CLUB temporariamente oculto.
                      // O Club permanece acessível por Treinos > Explorar.
                      // const SizedBox(width: 4),
                      // _clubButton(context),
                      const SizedBox(width: 4),
                      _navItem(3, items),
                      const SizedBox(width: 4),
                      _navItem(4, items),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Mantido para reativação futura do acesso central na navbar.
  // ignore: unused_element
  Widget _clubButton(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).nav_club_label,
      button: true,
      child: GestureDetector(
        onTap: onClubTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 54,
          height: 54,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(0, -0.3),
              colors: [Color(0x4DE0B830), Color(0x14E0B830)],
            ),
            border: Border.all(color: const Color(0x73E0B830), width: 1),
            boxShadow: const [
              BoxShadow(color: Color(0x40E0B830), blurRadius: 20),
            ],
          ),
          child: Center(child: clubLogo),
        ),
      ),
    );
  }

  Widget _navItem(int index, List<({IconData icon, String label})> items) {
    final item = items[index];
    final active = index == selectedIndex;

    return Semantics(
      label: item.label,
      selected: active,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged?.call(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0x29E0B830) : Colors.transparent,
          ),
          child: Icon(
            item.icon,
            size: 21,
            color: active ? BldrColors.goldBright : const Color(0x66FFFFFF),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SCAFFOLD DE TELA
// ─────────────────────────────────────────────────────────────

/// Monta a estrutura padrão: fundo com glow + conteúdo rolável + nav flutuante.
class BldrScreen extends StatelessWidget {
  final Widget body;
  final Widget? navBar;
  final bool secondaryGlow;

  const BldrScreen({
    super.key,
    required this.body,
    this.navBar,
    this.secondaryGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      extendBody: true,
      body: BldrBackground(
        secondaryGlow: secondaryGlow,
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: navBar != null ? BldrSpacing.navClearance : 30,
                  ),
                  child: body,
                ),
              ),
            ),
            if (navBar != null)
              Positioned(left: 0, right: 0, bottom: 0, child: navBar!),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CABEÇALHO DE SEÇÃO
// ─────────────────────────────────────────────────────────────

class BldrSectionHeader extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  const BldrSectionHeader({
    super.key,
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: BldrSpacing.pageInsets,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: BldrText.sectionTitle),
          if (trailingLabel != null)
            GestureDetector(
              onTap: onTrailingTap,
              behavior: HitTestBehavior.opaque,
              child: Text(trailingLabel!,
                  style: const TextStyle(
                    fontFamily: BldrText.family,
                    fontSize: 11,
                    color: BldrColors.textTertiary,
                  )),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SELETOR DE DIAS DA SEMANA (DESIGN_SYSTEM 7.13)
// ─────────────────────────────────────────────────────────────

/// Estado visual de um dia no seletor de semana. Sem vermelho: um dia não
/// feito é neutro (mesmo tratamento de `pending`), nunca punitivo.
enum BldrDayState { done, today, pending, rest }

/// Quadrado de estado de um dia da semana — substitui os pontinhos coloridos
/// antigos. `icon` é o ícone da atividade quando o estado for `done`/`today`
/// (ex.: TablerIcons.barbell); ignorado em `pending`/`rest`.
class BldrDaySquare extends StatelessWidget {
  final BldrDayState state;
  final IconData? icon;
  final VoidCallback? onTap;

  const BldrDaySquare({
    super.key,
    required this.state,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget square;
    switch (state) {
      case BldrDayState.done:
        square = _base(
          color: const Color(0x29E0B830), // rgba(224,184,48,0.16)
          child: icon != null
              ? Icon(icon, size: 16, color: BldrColors.goldBright)
              : null,
        );
        break;
      case BldrDayState.today:
        square = _base(
          color: BldrColors.goldBright,
          child: icon != null
              ? Icon(icon, size: 16, color: const Color(0xFF0A0A0A))
              : null,
        );
        break;
      case BldrDayState.pending:
        square = _base(
          color: BldrColors.surface,
          border: Border.all(color: BldrColors.borderSubtle),
        );
        break;
      case BldrDayState.rest:
        square = CustomPaint(
          painter: _DashedSquarePainter(radius: 10),
          child: _base(color: const Color(0x05FFFFFF)),
        );
        break;
    }

    if (onTap == null) return square;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: square,
    );
  }

  Widget _base({required Color color, Border? border, Widget? child}) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        child: child != null ? Center(child: child) : null,
      ),
    );
  }
}

class _DashedSquarePainter extends CustomPainter {
  final double radius;
  const _DashedSquarePainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1AFFFFFF) // rgba(255,255,255,0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    const dash = 4.0;
    const gap = 3.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedSquarePainter old) =>
      old.radius != radius;
}

// ─────────────────────────────────────────────────────────────
// BOTÃO QUADRADO DE AÇÃO
// ─────────────────────────────────────────────────────────────

/// Botão quadrado (aspect-ratio 1) — usado em pares lado a lado para ações
/// equivalentes ("Criar treino" / "A partir de foto").
class BldrSquareActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool emphasized;
  final bool loading;

  const BldrSquareActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.emphasized = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: loading ? null : onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: emphasized ? BldrColors.goldTintChip : BldrColors.surface,
            borderRadius: BldrRadius.all(BldrRadius.cardSm),
            border: Border.all(
              color: emphasized ? BldrColors.goldBorderChip : BldrColors.border,
            ),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: BldrColors.goldBright, strokeWidth: 2),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 22,
                          color: emphasized
                              ? BldrColors.goldBright
                              : BldrColors.textSecondary),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: BldrText.metaSm.copyWith(
                          color: emphasized
                              ? BldrColors.goldBright
                              : BldrColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD DE TREINO (com área de capa)
// ─────────────────────────────────────────────────────────────

/// Card vertical de treino para carrossel (biblioteca BLDR / meus treinos).
/// Área de capa com gradiente dourado — T5 (foto real da capa) é [F], ainda
/// sem dado; o placeholder de gradiente fica até lá.
///
/// `subtitle` é o detalhe (G10/T10): título curto + detalhe evita truncar
/// nomes longos. `onStart`, quando fornecido, mostra o botão "Iniciar".
class BldrWorkoutCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? metaLeft;
  final String? metaRight;
  final VoidCallback? onTap;
  final VoidCallback? onStart;

  /// Grupos musculares normalizados para exibir no slot da capa.
  /// `null` = exibe ícone de halter (comportamento legacy).
  /// `[]`   = exibe silhueta vazia (placeholder sem destaques).
  final Object? muscles;
  final BldrMuscleMapView view;

  const BldrWorkoutCard({
    super.key,
    required this.title,
    this.subtitle,
    this.metaLeft,
    this.metaRight,
    this.onTap,
    this.onStart,
    this.muscles,
    this.view = BldrMuscleMapView.front,
  });

  @override
  Widget build(BuildContext context) {
    return BldrGlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x40C9A227), Color(0x14C9A227)],
                ),
              ),
              child: muscles != null
                  ? Center(
                      child: BldrMuscleMap(
                        muscles: muscles!,
                        size: BldrMuscleMapSize.card,
                        view: view,
                      ),
                    )
                  : const Center(
                      child: Icon(TablerIcons.barbell,
                          size: 28, color: Color(0x59E0B830)),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(BldrSpacing.padCard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BldrText.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: BldrText.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (metaLeft != null || metaRight != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    [metaLeft, metaRight]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(' · '),
                    style: BldrText.metaSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (onStart != null) ...[
                  const SizedBox(height: 10),
                  BldrSecondaryButton(
                      label: AppLocalizations.of(context)
                          .component_workout_start_btn,
                      onPressed: onStart),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TIMELINE VERTICAL (Meu Plano / Club > Meu Plano)
// ─────────────────────────────────────────────────────────────

/// Estilo visual da bolinha de um item de timeline.
enum BldrTimelineDotStyle { done, next, pending, rest }

/// Um item de timeline vertical: bolinha conectada por linha à esquerda,
/// card livre à direita. `isFirst`/`isLast` controlam se a linha aparece
/// acima/abaixo da bolinha (para não vazar além do primeiro/último item).
///
/// Usa `IntrinsicHeight` para que a coluna da bolinha acompanhe a altura
/// real do card — NUNCA usar `CrossAxisAlignment.stretch` sem isso numa
/// Row dentro de uma Column/ScrollView de altura não-limitada (isso já
/// quebrou a renderização inteira do Dashboard uma vez).
class BldrTimelineItem extends StatelessWidget {
  final BldrTimelineDotStyle dotStyle;
  final bool isFirst;
  final bool isLast;
  final Widget child;
  final double dotSize;

  const BldrTimelineItem({
    super.key,
    required this.dotStyle,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    double? dotSize,
  }) : dotSize = dotSize ?? (dotStyle == BldrTimelineDotStyle.next ? 11 : 9);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Expanded(child: isFirst ? const SizedBox() : _line()),
                _dot(),
                Expanded(child: isLast ? const SizedBox() : _line()),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _line() => Center(
        child: Container(width: 1, color: BldrColors.borderSubtle),
      );

  Widget _dot() {
    switch (dotStyle) {
      case BldrTimelineDotStyle.done:
        return _circle(BldrColors.goldBright);
      case BldrTimelineDotStyle.next:
        return Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: BldrColors.goldBright,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Color(0x2EE0B830), spreadRadius: 4),
            ],
          ),
        );
      case BldrTimelineDotStyle.pending:
        return _circle(const Color(0x26FFFFFF)); // rgba(255,255,255,0.15)
      case BldrTimelineDotStyle.rest:
        return SizedBox(
          width: dotSize,
          height: dotSize,
          child: CustomPaint(painter: _DashedCircleTimelinePainter()),
        );
    }
  }

  Widget _circle(Color color) => Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ─────────────────────────────────────────────────────────────
// LINHA DE SÉRIE (treino ativo)
// ─────────────────────────────────────────────────────────────

/// Estado de uma série na lista do exercício em andamento.
enum BldrSetRowState { done, current, pending }

/// Linha compacta de série — usada abaixo dos steppers de carga/reps na
/// tela de treino ativo (pessoal e Club, mesmo padrão nas duas).
class BldrSetRow extends StatelessWidget {
  final int index;
  final BldrSetRowState state;

  /// Só para `done` — ex.: "40 kg · 12 reps". `null` omite o trailing.
  final String? valueLabel;

  const BldrSetRow({
    super.key,
    required this.index,
    required this.state,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = state == BldrSetRowState.done;
    final isCurrent = state == BldrSetRowState.current;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDone
            ? BldrColors.goldTint
            : isCurrent
                ? BldrColors.surface
                : BldrColors.surfaceInset,
        borderRadius: BldrRadius.all(BldrRadius.cardSm),
        border: Border.all(
          color: isCurrent ? BldrColors.goldBorder : BldrColors.borderSubtle,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: isDone
                ? const Icon(Icons.check_circle_rounded,
                    color: BldrColors.goldBright, size: 20)
                : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? BldrColors.goldTintChip
                          : BldrColors.surface,
                      border: Border.all(
                        color: isCurrent
                            ? BldrColors.goldBorderChip
                            : BldrColors.borderSubtle,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          fontFamily: BldrText.family,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? BldrColors.goldBright
                              : BldrColors.textMuted,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).component_series_label(index),
              style: BldrText.body.copyWith(
                color: isCurrent
                    ? BldrColors.textPrimary
                    : BldrColors.textSecondary,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (isDone && valueLabel != null)
            Text(valueLabel!, style: BldrText.meta)
          else if (isCurrent)
            BldrBadge(
                label: AppLocalizations.of(context).component_current_badge),
        ],
      ),
    );
  }
}

class _DashedCircleTimelinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x40FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashCount = 8;
    const dashAngle = 2 * 3.1415926535 / dashCount;
    final r = size.width / 2 - 0.5;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        i * dashAngle,
        dashAngle * 0.5,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// ANEL E GAUGE DE PROGRESSO
// ─────────────────────────────────────────────────────────────

/// Anel circular de progresso — dourado sólido sobre trilho neutro, sem
/// gradiente. Uso: resumo de calorias, metas circulares.
class BldrRingProgress extends StatelessWidget {
  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final Widget? center;

  const BldrRingProgress({
    super.key,
    required this.progress,
    this.size = 96,
    this.strokeWidth = 9,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _RingProgressPainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
            ),
          ),
          if (center != null) Center(child: center),
        ],
      ),
    );
  }
}

class _RingProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  const _RingProgressPainter(
      {required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = BldrColors.track
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.1415926535 / 2,
        2 * 3.1415926535 * progress,
        false,
        Paint()
          ..color = BldrColors.goldBright
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingProgressPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}

/// Arco semicircular (velocímetro) — preenchimento dourado sólido, sem
/// gradiente arco-íris e sem ponteiro. O preenchimento já comunica a
/// posição. Uso: IQD e outros scores 0-100.
class BldrGaugeArc extends StatelessWidget {
  final double progress; // 0..1
  final double width;
  final double strokeWidth;
  final Widget? center;

  const BldrGaugeArc({
    super.key,
    required this.progress,
    this.width = 200,
    this.strokeWidth = 11,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final height = width / 2 + strokeWidth / 2;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: _GaugeArcPainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
            ),
          ),
          if (center != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(child: center),
            ),
        ],
      ),
    );
  }
}

class _GaugeArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  const _GaugeArcPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const pi = 3.1415926535;

    canvas.drawArc(
      rect,
      pi,
      pi,
      false,
      Paint()
        ..color = BldrColors.track
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        pi,
        pi * progress,
        false,
        Paint()
          ..color = BldrColors.goldBright
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugeArcPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────────────────────
// ITEM DE ALIMENTO (busca / catálogo / recentes / favoritos)
// ─────────────────────────────────────────────────────────────

/// Linha de resultado de alimento — nome + kcal na mesma linha, macros e
/// porção de referência embaixo em cor única, botão "+" circular à direita.
/// Sem ícone por item (a categoria já se identifica uma vez no cabeçalho da
/// lista) — ver N13/N14/N15.
class BldrFoodItemRow extends StatelessWidget {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String portion;
  final VoidCallback? onTap;

  const BldrFoodItemRow({
    super.key,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.portion = '100g',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BldrGlassCard(
      radius: BldrRadius.cardSm,
      padding: const EdgeInsets.symmetric(
          horizontal: 15, vertical: BldrSpacing.padRow),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: BldrText.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        AppLocalizations.of(context)
                            .component_kcal_label(calories),
                        style: TextStyle(
                            fontFamily: BldrText.family,
                            color: BldrColors.goldBright,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    AppLocalizations.of(context).component_macro_detail(
                        protein.toString(),
                        carbs.toString(),
                        fat.toString(),
                        portion),
                    style: BldrText.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          BldrCircleButton(
              icon: Icons.add, size: 32, filled: false, onPressed: onTap),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LINHA DE STATS COM DIVISÓRIAS
// ─────────────────────────────────────────────────────────────

class BldrStatItem {
  final String value;
  final String label;
  const BldrStatItem({required this.value, required this.label});
}

/// Substitui N cards de stat soltos por um único card com divisórias
/// internas — padrão usado nos grids de 3 colunas do app.
class BldrStatDividerRow extends StatelessWidget {
  final List<BldrStatItem> items;

  const BldrStatDividerRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return BldrGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const SizedBox(
                height: 32,
                child:
                    VerticalDivider(color: BldrColors.borderSubtle, width: 1),
              ),
            Expanded(
              child: Column(
                children: [
                  Text(items[i].value, style: BldrText.kpiSm),
                  const SizedBox(height: 2),
                  Text(items[i].label,
                      style: BldrText.meta, textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GRUPO DE CONFIGURAÇÕES (DESIGN_SYSTEM 7.8)
// ─────────────────────────────────────────────────────────────

/// Container único com divisórias internas — padrão iOS. Envolve uma lista
/// de `BldrSettingsRow`. Não usar cards individuais por linha.
class BldrSettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const BldrSettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BldrColors.surface,
        border: Border.all(color: BldrColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Container(height: 1, color: BldrColors.borderSubtle),
              ),
          ],
        ],
      ),
    );
  }
}

/// Uma linha dentro de `BldrSettingsGroup`. `iconColor`/`titleColor`
/// permitem os dois desvios do dourado padrão previstos em S2: neutro
/// (rgba(255,255,255,0.55), ex. "Sair") e `BldrColors.danger` (só
/// "Excluir conta"). `disabled` é para itens [F] sem tela por trás ainda.
class BldrSettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final bool disabled;

  const BldrSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final iColor = iconColor ?? BldrColors.goldBright;
    final tColor = titleColor ?? BldrColors.textPrimary;

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iColor.withOpacity(0.13),
                  borderRadius: BldrRadius.all(BldrRadius.iconBox),
                ),
                child: Icon(icon, size: 16, color: iColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: BldrText.cardTitle.copyWith(color: tColor)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: BldrText.meta),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null)
                trailing!
              else if (onTap != null && !disabled)
                const Icon(Icons.chevron_right,
                    color: BldrColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD DE PLANO SELECIONÁVEL (paywall)
// ─────────────────────────────────────────────────────────────

/// Card de plano de assinatura selecionável — badge flutuante no topo, radio,
/// nome, preço grande e linha secundária opcional (preço riscado / equivalente
/// mensal). Estado selecionado: borda dourada 2px + tint + glow sutil.
class BldrSelectablePlanCard extends StatelessWidget {
  final String? badge;
  final bool badgeGold;
  final bool selected;
  final String planName;
  final String price;
  final String? priceUnit;
  final String? strikethroughPrice;
  final String? secondaryLine;
  final VoidCallback onTap;

  const BldrSelectablePlanCard({
    super.key,
    this.badge,
    this.badgeGold = false,
    required this.selected,
    required this.planName,
    required this.price,
    this.priceUnit,
    this.strikethroughPrice,
    this.secondaryLine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        BldrColors.goldTintStrong,
                        BldrColors.goldTint.withOpacity(0.4),
                      ],
                    )
                  : null,
              color: selected ? null : BldrColors.surface,
              borderRadius: BldrRadius.all(BldrRadius.cardLg),
              border: Border.all(
                color: selected ? BldrColors.goldBright : BldrColors.border,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: BldrColors.goldBright.withOpacity(0.18),
                        blurRadius: 18,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                  color:
                      selected ? BldrColors.goldBright : BldrColors.textMuted,
                ),
                const SizedBox(height: 14),
                Text(planName, style: BldrText.cardTitle),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: price,
                    style: BldrText.kpiMd,
                    children: priceUnit != null
                        ? [TextSpan(text: priceUnit, style: BldrText.unit)]
                        : null,
                  ),
                ),
                if (strikethroughPrice != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    strikethroughPrice!,
                    style: BldrText.metaSm.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: BldrColors.textMuted,
                    ),
                  ),
                ],
                if (secondaryLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    secondaryLine!,
                    style: BldrText.metaSm.copyWith(
                      color: BldrColors.goldBright,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(child: BldrBadge(label: badge!, gold: badgeGold)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HAVOK — CARD DE INSIGHT
// ─────────────────────────────────────────────────────────────

/// Card proativo do HAVOK (DESIGN_SYSTEM 7.16 / HAVOK_SPEC §3.1).
/// Máximo um por tela; só renderiza quando há algo relevante a dizer.
/// Estrutura: título → explicação → ação executável. Dismissível.
class BldrInsightCard extends StatelessWidget {
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  const BldrInsightCard({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BldrRadius.all(BldrRadius.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: BldrBlur.card, sigmaY: BldrBlur.card),
        child: Container(
          decoration: BoxDecoration(
            color: BldrColors.surface,
            border: Border.all(color: BldrColors.border),
            borderRadius: BldrRadius.all(BldrRadius.card),
          ),
          child: IntrinsicHeight(
            // Sem isso, o stretch abaixo tenta esticar a barra dourada para
            // a altura do Column/ScrollView do Dashboard, que é
            // não-limitada — quebra a renderização do frame inteiro sem
            // lançar exceção (mesmo bug documentado em dashboard.dart).
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra dourada vertical à esquerda.
                Container(
                  width: 2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [BldrColors.goldBright, Color(0x1AE0B830)],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(BldrSpacing.padCard),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: BldrColors.goldTint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(TablerIcons.paw_filled,
                                  color: BldrColors.goldBright, size: 13),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'HAVOK',
                              style: TextStyle(
                                fontFamily: BldrText.family,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: BldrColors.goldBright,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: onDismiss,
                              child: const Icon(Icons.close,
                                  color: BldrColors.textMuted, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(title, style: BldrText.cardTitle),
                        const SizedBox(height: 4),
                        Text(body, style: BldrText.description),
                        const SizedBox(height: 12),
                        BldrSecondaryButton(
                            label: actionLabel, onPressed: onAction),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ponto de entrada do HAVOK no header de uma tela (HAVOK_SPEC.md §3.2).
/// Abre o `HavokSheet` sobre a tela atual. Ponto dourado no canto quando há
/// insight novo ainda não visto.
class HavokEntryIcon extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasNewInsight;

  const HavokEntryIcon({
    super.key,
    required this.onTap,
    this.hasNewInsight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Área de toque mínima 44×44px mesmo com alvo visual de 36px
      // (DESIGN_SYSTEM.md §11), mesmo padrão de BldrCircleButton.
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(color: BldrColors.goldBorderChip),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: SvgPicture.asset(
                    'assets/images/havok_vector.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (hasNewInsight)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BldrColors.goldBright,
                      border: Border.all(color: BldrColors.bgBase, width: 1.5),
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
