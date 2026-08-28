import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/core/providers/locale_provider.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
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
class HavokInsightWidget extends StatefulWidget {
  final VoidCallback onAction;

  const HavokInsightWidget({super.key, required this.onAction});

  @override
  State<HavokInsightWidget> createState() => _HavokInsightWidgetState();
}

class _HavokInsightWidgetState extends State<HavokInsightWidget> {
  bool _dismissed = true;
  bool _checked = false;
  String? _insightText;

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissKey, true);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || _dismissed) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: BldrSpacing.pageInsets,
      child: BldrInsightCard(
        title: l10n.dashboard_havok_insight_title,
        body: _insightText ?? l10n.dashboard_havok_insight_body,
        actionLabel: l10n.dashboard_havok_insight_action_btn,
        onAction: widget.onAction,
        onDismiss: _dismiss,
      ),
    );
  }
}
