import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
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
    final pct      = (progress * 100).round();

    // D5 — bloco do grid 2×2. O card inteiro é clicável (leva ao Progresso),
    // no lugar dos dois botões que ocupavam altura do card antigo.
    // Ordem (mockup): [label + badge %] → [valor + unidade] → [meta] → [barra].
    return BldrGlassCard(
      onTap: widget.onViewProgressPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: BldrText.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (target > 0) BldrBadge(label: '$pct%'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  _formatValue(current),
                  style: BldrText.kpiLg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: BldrText.unit),
              ],
            ],
          ),
          if (target > 0) ...[
            const SizedBox(height: 2),
            Text(AppLocalizations.of(context).dashboard_goal_target(_formatValue(target), unit), style: BldrText.meta),
            const SizedBox(height: 12),
            BldrProgressBar(value: progress, gradient: true),
          ],
        ],
      ),
    );
  }

  String _formatValue(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  String _toSentenceCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// Skeleton com o MESMO layout do card final (título, KPI, meta), só com
  /// "—" no lugar dos valores — nunca uma tela vazia enquanto carrega.
  Widget _buildSkeleton() {
    // context está disponível via State
    final l10n = AppLocalizations.of(context);
    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashboard_weight_goal_label, style: BldrText.meta),
          const SizedBox(height: 14),
          Text('—', style: BldrText.kpiLg),
          const SizedBox(height: 2),
          Text(l10n.dashboard_goal_target('—', ''), style: BldrText.meta),
          const SizedBox(height: 12),
          const BldrProgressBar(value: 0),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final l10n = AppLocalizations.of(context);
    return BldrGlassCard(
      onTap: widget.onViewProgressPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashboard_weight_goal_label, style: BldrText.meta),
          const SizedBox(height: 14),
          Text(l10n.dashboard_goal_empty_title, style: BldrText.body),
          const SizedBox(height: 6),
          Text(l10n.dashboard_goal_empty_subtitle, style: BldrText.meta),
        ],
      ),
    );
  }
}
