import 'package:flutter/material.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:provider/provider.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_provider.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class GoalTrackingWidget extends StatefulWidget {
  final int selectedPeriod;

  const GoalTrackingWidget({
    Key? key,
    required this.selectedPeriod,
  }) : super(key: key);

  @override
  State<GoalTrackingWidget> createState() => _GoalTrackingWidgetState();
}

class _GoalTrackingWidgetState extends State<GoalTrackingWidget> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _goals = [];
          _isLoading = false;
        });
        return;
      }

      // ⬇️ Removido o genérico de select<List<Map<String, dynamic>>>()
      final result = await _client
          .from('user_goals')
          .select() // sem tipo aqui
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // result vem como List<dynamic>; normalizamos abaixo
      final rows = (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final list = rows.map<Map<String, dynamic>>((r) => _mapRow(r)).toList();

      if (mounted) {
        setState(() {
          _goals = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _mapRow(Map<String, dynamic> r) {
    final colorStr = (r['color'] as String?) ?? '';
    final color = _parseColorOr(colorStr, BldrColors.goldBright);

    return {
      'id': r['id'],
      'title': r['title'] ?? 'Objetivo',
      'description': r['description'] ?? '',
      'target_value': (r['target_value'] as num?)?.toDouble() ?? 0.0,
      'current_value': (r['current_value'] as num?)?.toDouble() ?? 0.0,
      'unit': r['unit'] ?? '',
      'category': r['category'] ?? 'general',
      'color': color,
      'icon': r['icon'] ?? 'track_changes',
      'deadline': r['deadline']?.toString(),
      'is_active': r['is_active'] ?? true,
      'created_at': r['created_at'],
    };
  }

  Color _parseColorOr(String hex, Color fallback) {
    try {
      if (hex.isEmpty) return fallback;
      var v = hex.replaceAll('#', '');
      if (v.length == 6) v = 'FF$v';
      final value = int.parse(v, radix: 16);
      return Color(value);
    } catch (_) {
      return fallback;
    }
  }

  String _colorToHex(Color c) {
    final r = c.red.toRadixString(16).padLeft(2, '0');
    final g = c.green.toRadixString(16).padLeft(2, '0');
    final b = c.blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  Future<void> _createGoal({
    required String title,
    required String description,
    required double target,
    required String unit,
    required String category,
    Color? color,
    String icon = 'track_changes',
    DateTime? deadline,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final payload = {
      'user_id': userId,
      'title': title,
      'description': description,
      'target_value': target,
      'current_value': 0,
      'unit': unit,
      'category': category,
      'color': _colorToHex(color ?? BldrColors.goldBright),
      'icon': icon,
      'deadline': deadline?.toIso8601String(),
      'is_active': true,
    };

    await _client.from('user_goals').insert(payload);
    if (mounted) {
      context.read<AchievementProvider>().checkAchievements('profile');
    }
    await _loadGoals();
  }

  Future<void> _updateProgress(Map<String, dynamic> goal, double newValue) async {
    final id = goal['id'];
    if (id == null) return;

    await _client.from('user_goals').update({
      'current_value': newValue,
    }).eq('id', id);

    await _loadGoals();
  }

  Future<void> _pauseGoal(Map<String, dynamic> goal) async {
    final id = goal['id'];
    if (id == null) return;

    await _client.from('user_goals').update({
      'is_active': false,
    }).eq('id', id);

    await _loadGoals();
  }

  Future<void> _deleteGoal(Map<String, dynamic> goal) async {
    final id = goal['id'];
    if (id == null) return;

    await _client.from('user_goals').delete().eq('id', id);
    await _loadGoals();
  }

  void _showCreateGoalDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController targetController = TextEditingController();
    final TextEditingController unitController = TextEditingController();
    String selectedCategory = 'weight';
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: BldrColors.sheetBg,
          shape: RoundedRectangleBorder(borderRadius: BldrRadius.all(BldrRadius.card)),
          title: Text(l10n.goals_create_dialog_title, style: BldrText.cardTitleLg),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: BldrText.body,
                  decoration: InputDecoration(
                    labelText: l10n.goals_title_field,
                    labelStyle: BldrText.description,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BldrColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BldrColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BldrColors.goldBright, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: BldrText.body,
                  decoration: InputDecoration(
                    labelText: l10n.goals_description_field,
                    labelStyle: BldrText.description,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BldrColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BldrColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BldrColors.goldBright, width: 2),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: targetController,
                        style: BldrText.body,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.goals_target_value_field,
                          labelStyle: BldrText.description,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: BldrColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: BldrColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: BldrColors.goldBright, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        style: BldrText.body,
                        decoration: InputDecoration(
                          labelText: l10n.goals_unit_field,
                          labelStyle: BldrText.description,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: BldrColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: BldrColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: BldrColors.goldBright, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value!);
                  },
                  dropdownColor: BldrColors.sheetBg,
                  style: BldrText.body,
                  decoration: InputDecoration(
                    labelText: l10n.goals_category_field,
                    labelStyle: BldrText.description,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BldrColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: BldrColors.border),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'weight', child: Text(l10n.goals_category_weight)),
                    DropdownMenuItem(value: 'workout', child: Text(l10n.goals_category_workout)),
                    DropdownMenuItem(value: 'strength', child: Text(l10n.goals_category_strength)),
                    DropdownMenuItem(value: 'endurance', child: Text(l10n.goals_category_endurance)),
                    DropdownMenuItem(value: 'general', child: Text(l10n.goals_category_general)),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: BldrColors.goldBright,
                                surface: Color(0xFF1a1a1a),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setDialogState(() => selectedDeadline = date);
                      }
                    },
                    icon: const Icon(Icons.event, color: BldrColors.goldBright),
                    label: Text(
                      selectedDeadline == null
                          ? l10n.goals_set_deadline
                          : l10n.goals_deadline_set('${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'),
                      style: BldrText.buttonSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel, style: BldrText.description),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final desc = descriptionController.text.trim();
                final unit = unitController.text.trim();
                final target = double.tryParse(targetController.text.trim()) ?? 0;

                if (title.isEmpty || target <= 0 || unit.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.goals_fill_required),
                      backgroundColor: BldrColors.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _createGoal(
                  title: title,
                  description: desc,
                  target: target,
                  unit: unit,
                  category: selectedCategory,
                  deadline: selectedDeadline,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.goals_create_success),
                      backgroundColor: BldrColors.goldSolid,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(l10n.goals_create_btn, style: BldrText.buttonSecondary),
            ),
          ],
        ),
      );
      },
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'weight':
        return Icons.monitor_weight_outlined;
      case 'workout':
        return Icons.fitness_center;
      case 'strength':
        return Icons.bolt;
      case 'endurance':
        return Icons.timer_outlined;
      default:
        return Icons.track_changes_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeGoals = _goals.where((goal) => goal['is_active'] == true).toList();

    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BldrIconBox(icon: Icons.track_changes_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.goals_section_title, style: BldrText.cardTitleLg)),
              Semantics(
                label: l10n.goals_create_btn,
                button: true,
                child: BldrCircleButton(
                  icon: Icons.add,
                  size: 36,
                  filled: false,
                  onPressed: _showCreateGoalDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: BldrColors.goldBright))
          else if (activeGoals.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: activeGoals
                  .map((goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildGoalCard(l10n, goal),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        BldrEmptyState(
          icon: Icons.track_changes_outlined,
          title: l10n.goals_empty_title,
          instruction: l10n.goals_empty_instruction,
        ),
        const SizedBox(height: 14),
        BldrSecondaryButton(
          label: l10n.goals_create_first_btn,
          icon: Icons.add,
          onPressed: _showCreateGoalDialog,
        ),
      ],
    );
  }

  Widget _buildGoalCard(AppLocalizations l10n, Map<String, dynamic> goal) {
    final title = goal['title'] ?? 'Objetivo';
    final description = goal['description'] ?? '';
    final targetValue = (goal['target_value'] as num?)?.toDouble() ?? 0.0;
    final currentValue = (goal['current_value'] as num?)?.toDouble() ?? 0.0;
    final unit = goal['unit'] ?? '';
    final category = goal['category'] ?? 'general';
    final deadline = goal['deadline'];

    final progress =
        targetValue != 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
    final progressPercentage = (progress * 100).round();

    String deadlineText = '';
    if (deadline != null) {
      final deadlineDate = DateTime.tryParse(deadline) ?? DateTime.now();
      final now = DateTime.now();
      final daysLeft = deadlineDate.difference(now).inDays;

      if (daysLeft < 0) {
        deadlineText = l10n.goals_overdue;
      } else if (daysLeft == 0) {
        deadlineText = l10n.goals_due_today;
      } else {
        deadlineText = l10n.goals_days_remaining(daysLeft);
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BldrColors.surfaceInset,
        borderRadius: BldrRadius.all(BldrRadius.cardSm),
        border: Border.all(color: BldrColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BldrIconBox(icon: _categoryIcon(category), size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: BldrText.cardTitle),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(description,
                          style: BldrText.meta, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BldrBadge(label: '$progressPercentage%'),
                  if (deadlineText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(deadlineText, style: BldrText.metaSm),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${currentValue.toStringAsFixed(1)} $unit',
                  style: BldrText.body.copyWith(fontWeight: FontWeight.w500)),
              Text('${targetValue.toStringAsFixed(1)} $unit', style: BldrText.meta),
            ],
          ),
          const SizedBox(height: 8),
          BldrProgressBar(value: progress, gradient: true),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: BldrSecondaryButton(
                  label: l10n.goals_update_progress_btn,
                  icon: Icons.edit_outlined,
                  onPressed: () => _showUpdateProgressDialog(goal),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: l10n.goals_more_options,
                button: true,
                child: BldrCircleButton(
                  icon: Icons.more_vert,
                  size: 36,
                  filled: false,
                  onPressed: () => _showGoalOptions(goal),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog(Map<String, dynamic> goal) {
    final TextEditingController progressController = TextEditingController();
    progressController.text = (goal['current_value'] ?? 0).toString();

    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
        backgroundColor: BldrColors.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BldrRadius.all(BldrRadius.card)),
        title: Text(l10n.goals_update_progress_title, style: BldrText.cardTitleLg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(goal['title'] ?? '', style: BldrText.description),
            const SizedBox(height: 16),
            TextField(
              controller: progressController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: BldrText.body,
              decoration: InputDecoration(
                labelText: l10n.goals_current_value_field(goal['unit'] ?? ''),
                labelStyle: BldrText.description,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: BldrColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: BldrColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: BldrColors.goldBright, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel, style: BldrText.description),
          ),
          TextButton(
            onPressed: () async {
              final newValue = double.tryParse(progressController.text);
              if (newValue != null) {
                Navigator.pop(context);
                await _updateProgress(goal, newValue);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.goals_update_success),
                      backgroundColor: BldrColors.goldSolid,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.goals_update_btn, style: BldrText.buttonSecondary),
          ),
        ],
      );
      },
    );
  }

  void _showGoalOptions(Map<String, dynamic> goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: BldrColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(goal['title'] ?? '', style: BldrText.cardTitleLg),
              const SizedBox(height: 16),
              BldrSettingsGroup(children: [
                BldrSettingsRow(
                  icon: Icons.pause_outlined,
                  title: l10n.goals_pause,
                  onTap: () async {
                    Navigator.pop(context);
                    await _pauseGoal(goal);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.goals_paused),
                          backgroundColor: BldrColors.surface,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                BldrSettingsRow(
                  icon: Icons.delete_outline,
                  title: l10n.goals_delete,
                  iconColor: BldrColors.danger,
                  titleColor: BldrColors.danger,
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteGoal(goal);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.goals_deleted),
                          backgroundColor: BldrColors.surface,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ]),
            ],
          ),
        ),
      );
      },
    );
  }
}
