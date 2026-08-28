import 'package:flutter/material.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:intl/intl.dart'; // Importante para manipulação de datas

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/services/progress_service.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart' as clubUc;
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart' as uc;
import 'package:bldr_fitness/features/workouts/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class WorkoutProgressWidget extends StatefulWidget {
  final int selectedPeriod;

  const WorkoutProgressWidget({Key? key, required this.selectedPeriod})
      : super(key: key);

  @override
  State<WorkoutProgressWidget> createState() => _WorkoutProgressWidgetState();
}

class _WorkoutProgressWidgetState extends State<WorkoutProgressWidget> {
  Map<String, dynamic>? _workoutProgress;
  List<Map<String, dynamic>> _recentWorkouts = [];

  // Alterado para um Map para busca rápida no Heatmap: 'yyyy-MM-dd' -> quantidade
  Map<String, int> _heatmapData = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  @override
  void didUpdateWidget(WorkoutProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _loadWorkoutData();
    }
  }

  Future<void> _loadWorkoutData() async {
    setState(() => _isLoading = true);

    try {
      final workoutProgressData = await ProgressService.instance
          .getWorkoutProgress(daysPeriod: widget.selectedPeriod);

      // Aumentei um pouco o limit para garantir histórico
      final historyResult = await getIt<uc.GetWorkoutHistory>()(limit: 100);
      final clubWorkouts =
          ((await getIt<clubUc.GetClubWorkoutHistory>()(limit: 100)).valueOrNull ??
                  [])
              .map(sessionToLegacyMap)
              .toList();

      final regularWorkouts =
          (historyResult.valueOrNull ?? []).map(sessionToLegacyMap).toList();

      final allWorkouts = [...regularWorkouts, ...clubWorkouts];

      // Ordenação para "Treinos Recentes"
      allWorkouts.sort((a, b) {
        final dateAString = a['completed_at'] ?? a['started_at'];
        final dateBString = b['completed_at'] ?? b['started_at'];
        final dateA = dateAString != null ? DateTime.tryParse(dateAString) : null;
        final dateB = dateBString != null ? DateTime.tryParse(dateBString) : null;

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });

      final recentWorkoutsData = allWorkouts.take(5).toList();

      // Processamento para o Heatmap
      final heatmapData = _generateHeatmapData(allWorkouts);

      if (mounted) {
        setState(() {
          _workoutProgress = workoutProgressData;
          _recentWorkouts = recentWorkoutsData;
          _heatmapData = heatmapData;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Erro ao carregar dados dos treinos: $error');
      }
    }
  }

  // Gera o Mapa de 'yyyy-MM-dd' -> Quantidade de treinos
  Map<String, int> _generateHeatmapData(List<Map<String, dynamic>> allWorkouts) {
    final Map<String, int> data = {};

    for (var workout in allWorkouts) {
      final dateString = workout['completed_at'] ?? workout['started_at'];
      // Considera apenas treinos completados
      final isCompleted = workout['is_completed'] ?? false;

      if (dateString != null && isCompleted) {
        final date = DateTime.parse(dateString).toLocal();
        final key = DateFormat('yyyy-MM-dd').format(date);

        data[key] = (data[key] ?? 0) + 1;
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: BldrColors.goldBright),
      );
    }

    final completedWorkouts = _workoutProgress?['completed_workouts'] ?? 0;
    final avgDuration =
        _workoutProgress?['average_workout_duration_minutes'] ?? 0;
    final totalTime = _workoutProgress?['total_workout_time_hours'] ?? '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConsistencyHeatmap(l10n),
        const SizedBox(height: 18),
        // PT2 — 3 cards neutros em grid 3 colunas (era 2 cards
        // verde/laranja).
        _buildStatsGrid(l10n, completedWorkouts, avgDuration, totalTime),
        const SizedBox(height: 18),
        _buildRecentWorkouts(l10n),
      ],
    );
  }

  // --- HEATMAP DE CONSISTÊNCIA (PT1 — componente 7.14) ---
  Widget _buildConsistencyHeatmap(AppLocalizations l10n) {
    // Lógica para alinhar o calendário:
    // Queremos mostrar as últimas 5 semanas (35 dias) terminando na semana atual.
    // O Grid tem 7 colunas (Segunda a Domingo).

    final now = DateTime.now();
    // Encontra a Segunda-feira desta semana
    final currentWeekMonday = now.subtract(Duration(days: now.weekday - 1));
    // Volta 4 semanas para pegar a data de início do grid
    final startDate = currentWeekMonday.subtract(const Duration(days: 28)); // 4 semanas * 7 dias

    final weekDays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: BldrColors.goldBright, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.workout_progress_consistency, style: BldrText.cardTitle),
                ],
              ),
              // PT1 — legenda no cabeçalho, não abaixo do grid.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.workout_progress_less, style: BldrText.metaSm),
                  const SizedBox(width: 3),
                  _buildLegendDot(const Color(0x0DFFFFFF)),
                  const SizedBox(width: 3),
                  _buildLegendDot(const Color(0x66E0B830)),
                  const SizedBox(width: 3),
                  _buildLegendDot(BldrColors.goldBright),
                  const SizedBox(width: 3),
                  Text(l10n.workout_progress_more, style: BldrText.metaSm),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cabeçalho dos Dias da Semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays
                .map((day) => Expanded(
                      child: Center(child: Text(day, style: BldrText.metaSm)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),

          // PT1 — células menores: aspect-ratio 1, raio 6px, gap 6px.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 35, // 5 semanas
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final date = startDate.add(Duration(days: index));
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final count = _heatmapData[dateKey] ?? 0;

              // Verifica se o dia é hoje para destacar a borda
              final isToday = DateFormat('yyyy-MM-dd').format(now) == dateKey;

              // Verifica se é dia futuro (apenas visual, opcional)
              final isFuture = date.isAfter(now);

              return Tooltip(
                message: l10n.workout_progress_tooltip(count, DateFormat('dd/MM').format(date)),
                triggerMode: TooltipTriggerMode.tap,
                child: Container(
                  decoration: BoxDecoration(
                    color: isFuture ? Colors.transparent : _getColorForCount(count),
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(color: const Color(0x80FFFFFF), width: 1.5)
                        : isFuture
                            ? Border.all(color: BldrColors.borderSubtle)
                            : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Intensidade — DESIGN_SYSTEM 7.14: nenhum → 0.4 → 0.55 → 0.7 → máximo.
  Color _getColorForCount(int count) {
    switch (count) {
      case 0:
        return const Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
      case 1:
        return const Color(0x66E0B830); // 0.4
      case 2:
        return const Color(0x8CE0B830); // 0.55
      case 3:
        return const Color(0xB3E0B830); // 0.7
      default:
        return BldrColors.goldBright; // máximo
    }
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }

  // --- ESTATÍSTICAS E LISTA ---

  // PT2 — 3 cards neutros (era 2 cards verde/laranja). "Tempo total" usa
  // total_workout_time_hours, que já era buscado mas não exibido.
  Widget _buildStatsGrid(AppLocalizations l10n, int completed, int avgDuration, String totalTime) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(l10n.workout_progress_completed, completed.toString(), Icons.check_circle_outline),
        ),
        const SizedBox(width: BldrSpacing.gapCard),
        Expanded(
          // PT3 [F] — "Duração Média: 0m" é bug de cálculo conhecido
          // (B1/PT3, BACKLOG_FUNCIONAL.md). Valor exibido tal como vem do
          // serviço, sem correção.
          child: _buildStatCard(l10n.workout_progress_avg_duration, '${avgDuration}m', Icons.schedule_outlined),
        ),
        const SizedBox(width: BldrSpacing.gapCard),
        Expanded(
          child: _buildStatCard(l10n.workout_progress_total_time, '${totalTime}h', Icons.timelapse_outlined),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return BldrGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: BldrColors.goldBright, size: 20),
          const SizedBox(height: 10),
          Text(value, style: BldrText.cardTitleLg, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(title,
              style: BldrText.metaSm, textAlign: TextAlign.center, maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildRecentWorkouts(AppLocalizations l10n) {
    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: BldrColors.goldBright, size: 16),
              const SizedBox(width: 8),
              Text(l10n.workout_progress_recent_title, style: BldrText.cardTitle),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentWorkouts.isEmpty)
            BldrEmptyState(
              icon: Icons.fitness_center,
              title: l10n.workout_progress_empty,
            )
          else
            Column(
              children: _recentWorkouts
                  .take(3)
                  .map((workout) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildWorkoutItem(l10n, workout),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // PT4 — título curto + detalhe no subtítulo (em vez do nome em CAIXA
  // ALTA quebrando em duas linhas), ícone dourado no lugar do check verde.
  Widget _buildWorkoutItem(AppLocalizations l10n, Map<String, dynamic> workout) {
    final rawName = workout['name'] as String? ?? 'Treino';
    final completedAt = workout['completed_at'];
    final duration = workout['total_duration_seconds'];

    final (title, detail) = _splitWorkoutName(rawName);

    String timeAgo = l10n.workout_progress_recently;
    if (completedAt != null) {
      final date = DateTime.parse(completedAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays == 0) {
        timeAgo = l10n.workout_progress_today;
      } else if (difference.inDays == 1) {
        timeAgo = l10n.workout_progress_yesterday;
      } else {
        timeAgo = l10n.workout_progress_days_ago(difference.inDays);
      }
    }

    String? durationText;
    if (duration != null) {
      final minutes = (duration / 60).round();
      durationText = '${minutes}min';
    }

    final subtitleParts = [
      if (detail != null && detail.isNotEmpty) detail,
      if (durationText != null) durationText,
    ];

    return BldrListRow(
      icon: Icons.check_circle_outline,
      title: title,
      subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' · '),
      trailing: Text(timeAgo, style: BldrText.metaSm),
    );
  }

  /// Nomes vêm em CAIXA ALTA, às vezes com "|" separando o grupo muscular
  /// (ex.: "LEGS A | QUADS, GLUTE, PANTURRILHA"). Divide em título curto +
  /// detalhe e normaliza a capitalização — só formatação de exibição, o
  /// dado (`workout['name']`) continua o mesmo.
  (String, String?) _splitWorkoutName(String raw) {
    final parts = raw.split('|');
    final title = _titleCase(parts.first.trim());
    if (parts.length < 2) return (title, null);
    final detail = _titleCase(parts.sublist(1).join('|').trim());
    return (title, detail);
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
