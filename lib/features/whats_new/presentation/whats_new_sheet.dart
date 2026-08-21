import 'package:flutter/material.dart';
import 'package:bldr_fitness/features/whats_new/domain/entities/whats_new_entity.dart';

const _kGold = Color(0xFFE0B830);
const _kGoldTint = Color(0x21E0B830);
const _kGoldBorder = Color(0x47C9A227);
const _kSurface = Color(0x0DFFFFFF);
const _kBorder = Color(0x14FFFFFF);
const _kText = Colors.white;
const _kTextMuted = Color(0x73FFFFFF);

// Mapeamento icon-name → IconData (nomes vindos do JSON do Gestão)
IconData _icon(String name) {
  switch (name) {
    case 'sparkles':      return Icons.auto_awesome;
    case 'figure.run':   return Icons.directions_run;
    case 'heart.fill':   return Icons.favorite;
    case 'bell.fill':    return Icons.notifications;
    case 'bubble.left.fill': return Icons.chat_bubble;
    case 'trophy':       return Icons.emoji_events;
    case 'applewatch':   return Icons.watch;
    case 'lock':         return Icons.lock;
    case 'chart':        return Icons.show_chart;
    default:             return Icons.star;
  }
}

Future<void> showWhatsNewSheet(
  BuildContext context,
  WhatsNewData data, {
  required VoidCallback onDismiss,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WhatsNewSheet(data: data, onDismiss: onDismiss),
  );
}

class _WhatsNewSheet extends StatefulWidget {
  final WhatsNewData data;
  final VoidCallback onDismiss;
  const _WhatsNewSheet({required this.data, required this.onDismiss});

  @override
  State<_WhatsNewSheet> createState() => _WhatsNewSheetState();
}

class _WhatsNewSheetState extends State<_WhatsNewSheet> {
  int _current = 0;
  final PageController _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    setState(() => _current = i);
    _pageCtrl.animateToPage(i,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut);
  }

  void _dismiss() {
    Navigator.of(context).pop();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.data.slides;
    final totalPages = (slides.length / 3).ceil();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xF70E0E0E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 38, height: 4,
            margin: const EdgeInsets.only(top: 11),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge "NOVIDADES"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGoldTint,
                    border: Border.all(color: _kGoldBorder),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 11, color: _kGold),
                      const SizedBox(width: 5),
                      Text('NOVIDADES',
                          style: TextStyle(
                            color: _kGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(widget.data.title,
                    style: const TextStyle(
                        color: _kText, fontSize: 22, fontWeight: FontWeight.w500, height: 1.2)),
                const SizedBox(height: 4),
                Text(widget.data.subtitle,
                    style: const TextStyle(color: _kTextMuted, fontSize: 13)),
              ],
            ),
          ),

          // Carrossel
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: totalPages,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, pageIdx) {
                final start = pageIdx * 3;
                final end = (start + 3).clamp(0, slides.length);
                final pageSlides = slides.sublist(start, end);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                  child: Column(
                    children: pageSlides
                        .map((s) => _SlideCard(slide: s))
                        .toList(),
                  ),
                );
              },
            ),
          ),

          // Dots
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (i) {
                  final active = i == _current;
                  return GestureDetector(
                    onTap: () => _goTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 5,
                      width: active ? 18 : 5,
                      decoration: BoxDecoration(
                        color: active ? _kGold : Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _dismiss,
                    style: TextButton.styleFrom(
                      backgroundColor: _kSurface,
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: _kBorder),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check, size: 15),
                        SizedBox(width: 6),
                        Text('Entendido', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Novidades são exibidas uma vez',
                    style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  final WhatsNewSlide slide;
  const _SlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: slide.featured ? const Color(0x1AC9A227) : _kSurface,
        border: Border.all(
          color: slide.featured ? _kGoldBorder : _kBorder,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: slide.featured ? 48 : 40,
            height: slide.featured ? 48 : 40,
            decoration: BoxDecoration(
              color: slide.featured
                  ? const Color(0x33E0B830)
                  : _kGoldTint,
              borderRadius: BorderRadius.circular(slide.featured ? 15 : 13),
            ),
            child: Icon(_icon(slide.icon),
                size: slide.featured ? 24 : 20, color: _kGold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slide.tag.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: _kGold)),
                const SizedBox(height: 4),
                Text(slide.title,
                    style: const TextStyle(
                        color: _kText, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(slide.description,
                    style: const TextStyle(
                        color: _kTextMuted, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
