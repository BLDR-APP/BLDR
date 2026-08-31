import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

import 'package:bldr_fitness/core/providers/locale_provider.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const LanguageSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final current = localeProvider.locale.languageCode;

    return Container(
      decoration: const BoxDecoration(
        color: BldrColors.sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: BldrColors.textSecondary.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.language_sheet_title, style: BldrText.sectionTitle),
                const SizedBox(height: 20),
                _LanguageCard(
                  flag: '🇧🇷',
                  name: 'Português',
                  region: l10n.language_pt_region,
                  selected: current == 'pt',
                  onTap: () => context
                      .read<LocaleProvider>()
                      .setLocale(const Locale('pt')),
                ),
                const SizedBox(height: 10),
                _LanguageCard(
                  flag: '🇺🇸',
                  name: 'English',
                  region: l10n.language_en_region,
                  selected: current == 'en',
                  onTap: () => context
                      .read<LocaleProvider>()
                      .setLocale(const Locale('en')),
                ),
                const SizedBox(height: 10),
                _LanguageCard(
                  flag: '🇮🇹',
                  name: 'Italiano',
                  region: l10n.language_it_region,
                  selected: false,
                  unavailableLabel: l10n.language_soon_badge,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.language_havok_note,
                  style:
                      BldrText.meta.copyWith(color: BldrColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String name;
  final String region;
  final bool selected;
  final VoidCallback? onTap;
  final String? unavailableLabel;

  const _LanguageCard({
    required this.flag,
    required this.name,
    required this.region,
    required this.selected,
    this.onTap,
    this.unavailableLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: unavailableLabel != null
              ? BldrColors.surface.withOpacity(0.6)
              : selected
                  ? BldrColors.goldBright.withOpacity(0.08)
                  : BldrColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? BldrColors.goldBright : BldrColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: BldrText.cardTitle),
                  Text(region,
                      style: BldrText.meta
                          .copyWith(color: BldrColors.textSecondary)),
                ],
              ),
            ),
            if (unavailableLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: BldrColors.goldBright.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: BldrColors.goldBright.withOpacity(0.45),
                  ),
                ),
                child: Text(
                  unavailableLabel!,
                  style: BldrText.meta.copyWith(
                    color: BldrColors.goldBright,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: BldrColors.goldBright, size: 20)
            else
              const Icon(Icons.radio_button_unchecked,
                  color: BldrColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
