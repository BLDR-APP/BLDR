import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/core/providers/locale_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_sheet.dart';
import 'package:bldr_fitness/features/club/domain/usecases/generate_havok_insight.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Card de insight do HAVOK no Dashboard (HAVOK_SPEC.md §3.1).
///
/// Ordem de operações no initState:
/// 1. Verifica chave dismiss de HOJE → some se dispensado.
/// 2. Se não dispensado: tenta cache local do insight (chave por data).
/// 3. Se sem cache: chama GenerateHavokInsight (edge function + Claude Haiku).
/// 4. Falha de rede → exibe texto fallback do ARB sem travar o Dashboard.
///
/// Apresentação v2 (Figma 57:390 / 57:389): banner flutuante fixo no topo da
/// área segura; tocar expande para o card; tocar fora ou arrastar para cima
/// recolhe; "×" dispensa pelo resto do dia (mesma chave de antes).
/// Deve ser posicionado com `Positioned.fill` sobre a Home: só o banner/card
/// recebe toques (o barreira de fora só existe com o card expandido).
class HavokInsightWidget extends StatefulWidget {
  const HavokInsightWidget({super.key});

  @override
  State<HavokInsightWidget> createState() => _HavokInsightWidgetState();
}

class _HavokInsightWidgetState extends State<HavokInsightWidget> {
  bool _dismissed = true;
  bool _checked = false;
  String? _insightText;
  bool _expanded = false;
  bool _leaving = false;

  static String get _dismissKey {
    final now = DateTime.now();
    final d = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return 'havok_insight_dismissed_$d';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_dismissKey) ?? false;

    if (dismissed) {
      if (mounted) setState(() => _checked = true);
      return;
    }

    // Não dispensado: gerar/carregar insight.
    final locale = mounted
        ? context.read<LocaleProvider>().locale.languageCode
        : 'pt';

    final result = await getIt<GenerateHavokInsight>()(locale: locale);

    if (mounted) {
      setState(() {
        _dismissed = false;
        _insightText = result.valueOrNull; // null → fallback do ARB
        _checked = true;
      });
    }
  }

  Future<void> _dismiss() async {
    // Anima a saída (sobe + some) antes de gravar a dispensa do dia.
    setState(() => _leaving = true);
    await Future<void>.delayed(BldrHavokV2.transition);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissKey, true);
    if (mounted) setState(() => _dismissed = true);
  }

  void _openChat() {
    showHavokSheet(context, originScreen: 'dashboard');
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || _dismissed) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    // Headline: a edge function ainda devolve um texto único (BACKLOG).
    // Fallback aprovado: título fixo do .arb na pílula e no card.
    final headline = l10n.dashboard_havok_insight_title;
    final body = _insightText ?? l10n.dashboard_havok_insight_body;

    final width = MediaQuery.sizeOf(context).width;
    final pageX = BldrSpacingV2.pageX(width);
    final scale = (width / BldrSpacingV2.frameWidth).clamp(0.0, 1.0);
    final bannerW = BldrHavokV2.bannerWidth * scale;
    final expandedW =
        (BldrHavokV2.expandedWidth * scale).clamp(0.0, width - 2 * pageX + 16);

    final card = AnimatedContainer(
      duration: BldrHavokV2.transition,
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(top: _expanded ? 4 : 7),
      width: _expanded ? expandedW : bannerW,
      height: _expanded ? BldrHavokV2.expandedHeight : BldrHavokV2.bannerHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: BldrHavokColorsV2.surface,
        borderRadius: BorderRadius.circular(_expanded
            ? BldrHavokV2.expandedRadius
            : BldrHavokV2.bannerRadius),
        border: Border.all(
          color: _expanded
              ? BldrHavokColorsV2.expandedBorder
              : BldrHavokColorsV2.bannerBorder,
          width: _expanded ? 1 : BldrHavokV2.bannerBorderWidth,
        ),
      ),
      child: AnimatedSwitcher(
        duration: BldrHavokV2.transition,
        switchInCurve: const Interval(0.35, 1, curve: Curves.easeOut),
        switchOutCurve: const Interval(0, 0.5, curve: Curves.easeIn),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          children: [...previous, if (current != null) current],
        ),
        child: _expanded
            ? _Expanded(
                key: const ValueKey('expanded'),
                headline: headline,
                body: body,
                onClose: _dismiss,
                onChat: _openChat,
              )
            : _Banner(
                key: const ValueKey('banner'),
                headline: headline,
                onTap: () => setState(() => _expanded = true),
              ),
      ),
    );

    return Stack(
      children: [
        if (_expanded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = false),
            ),
          ),
        Align(
          alignment: Alignment.topCenter,
          child: AnimatedSlide(
            duration: BldrHavokV2.transition,
            curve: Curves.easeInCubic,
            offset: _leaving ? const Offset(0, -0.6) : Offset.zero,
            child: AnimatedOpacity(
              duration: BldrHavokV2.transition,
              opacity: _leaving ? 0 : 1,
              child: GestureDetector(
                onVerticalDragEnd: (d) {
                  if (_expanded && (d.primaryVelocity ?? 0) < -200) {
                    setState(() => _expanded = false);
                  }
                },
                child: card,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pantera do HAVOK num círculo (mesmo vetor da navbar e do HavokEntryIcon).
class _HavokIcon extends StatelessWidget {
  final double size;
  const _HavokIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: BldrHavokColorsV2.surface,
      ),
      child: SvgPicture.asset('assets/images/havok_vector.svg',
          fit: BoxFit.contain),
    );
  }
}

/// Banner 279 × 45 (57:390): ícone 31,4 · "HAVOK · INSIGHT" · headline · ›
class _Banner extends StatelessWidget {
  final String headline;
  final VoidCallback onTap;

  const _Banner({super.key, required this.headline, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: BldrHavokV2.bannerHeight - 2,
        child: Row(
          children: [
            const SizedBox(width: 7),
            const _HavokIcon(size: 31.388),
            const SizedBox(width: 8.7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.havok_insight_label,
                      maxLines: 1, style: BldrTextV2.havokBannerLabel),
                  const SizedBox(height: 2.5),
                  Text(headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrTextV2.havokBannerText),
                ],
              ),
            ),
            Text('›', style: BldrTextV2.havokBannerChevron),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// Card expandido 370 × 205 (57:389).
class _Expanded extends StatelessWidget {
  final String headline;
  final String body;
  final VoidCallback onClose;
  final VoidCallback onChat;

  const _Expanded({
    super.key,
    required this.headline,
    required this.body,
    required this.onClose,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: BldrHavokV2.expandedHeight - 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _HavokIcon(size: 36),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(l10n.havok_insight_label,
                      maxLines: 1, style: BldrTextV2.havokLabel),
                ),
                Semantics(
                  button: true,
                  label: l10n.havok_insight_dismiss_semantics,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: Text('×', style: BldrTextV2.havokClose),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrTextV2.havokTitle),
            const SizedBox(height: 9),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BldrTextV2.havokBody),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onChat,
                  child: Container(
                    width: 202,
                    height: 33,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22.955),
                      border:
                          Border.all(color: BldrColorsV2.gold, width: 1.148),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.havok_insight_chat_cta,
                            style: BldrTextV2.havokCta),
                        const SizedBox(width: 8),
                        const Icon(Icons.north_east,
                            size: 13, color: BldrColorsV2.gold),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
