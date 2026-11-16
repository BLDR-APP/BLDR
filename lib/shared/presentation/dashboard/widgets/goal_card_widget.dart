import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/services/profile_notifier.dart';

class GoalCardWidget extends StatefulWidget {
  final VoidCallback onViewProgressPressed;
  final VoidCallback onUpdateProgressPressed;

  const GoalCardWidget({
    Key? key,
    required this.onViewProgressPressed,
    required this.onUpdateProgressPressed,
  }) : super(key: key);

  @override
  State<GoalCardWidget> createState() => _GoalCardWidgetState();
}

class _GoalCardWidgetState extends State<GoalCardWidget> {
  Map<String, dynamic>? _goal;
  bool _isLoading = true;

  ProfileNotifier? _profileNotifier;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.read<ProfileNotifier>();
    if (_profileNotifier != notifier) {
      _profileNotifier?.removeListener(_load);
      _profileNotifier = notifier;
      notifier.addListener(_load);
    }
  }

  @override
  void dispose() {
    _profileNotifier?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!AuthService.instance.isAuthenticated) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final userId = AuthService.instance.currentUser!.id;
      final result = await Supabase.instance.client
          .from('user_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      final goals = (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (mounted) {
        setState(() {
          _goal = goals.isNotEmpty ? goals.first : null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();
    if (_goal == null) return _buildEmpty();

    // G8 — sentence case. O título vem de dado (categoria da meta), não é
    // string fixa; a transformação é só de apresentação.
    final title = _toSentenceCase(
        _goal!['title'] as String? ?? 'Meu objetivo');
    final current = (_goal!['current_value'] as num?)?.toDouble() ?? 0;
    final target  = (_goal!['target_value']  as num?)?.toDouble() ?? 0;
    final unit    = _goal!['unit']           as String? ?? '';
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    // Tile v2 (Figma "Peso alvo"): label → valor + unidade → meta → barra.
    // O selo de % saiu da Home v2 (decisão 4). O card inteiro leva ao
    // Progresso.
    return BldrTileV2(
      onTap: widget.onViewProgressPressed,
      label: title,
      value: unit.isEmpty ? _formatValue(current) : '${_formatValue(current)} $unit',
      caption: target > 0
          ? AppLocalizations.of(context)
              .dashboard_goal_target(_formatValue(target), unit)
          : null,
      progress: target > 0 ? progress.toDouble() : null,
    );
  }

  String _formatValue(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  String _toSentenceCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// Skeleton com o MESMO layout do tile final, só com "—" nos valores.
  Widget _buildSkeleton() {
    final l10n = AppLocalizations.of(context);
    return BldrTileV2(
      label: l10n.dashboard_weight_goal_label,
      value: '—',
      caption: l10n.dashboard_goal_target('—', ''),
      progress: 0,
    );
  }

  Widget _buildEmpty() {
    final l10n = AppLocalizations.of(context);
    return BldrTileV2(
      onTap: widget.onViewProgressPressed,
      label: l10n.dashboard_weight_goal_label,
      value: l10n.dashboard_goal_empty_title,
      valueStyle: BldrTextV2.macroValue.copyWith(fontSize: 13),
      caption: l10n.dashboard_goal_empty_subtitle,
    );
  }
}
