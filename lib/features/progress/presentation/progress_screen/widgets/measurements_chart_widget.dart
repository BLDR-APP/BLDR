import 'package:fl_chart/fl_chart.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/progress/domain/entities/body_measurement.dart';
import 'package:bldr_fitness/features/progress/domain/usecases/progress_usecases.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class MeasurementsChartWidget extends StatefulWidget {
  final int selectedPeriod;

  const MeasurementsChartWidget({
    Key? key,
    required this.selectedPeriod,
  }) : super(key: key);

  @override
  State<MeasurementsChartWidget> createState() =>
      _MeasurementsChartWidgetState();
}

class _MeasurementsChartWidgetState extends State<MeasurementsChartWidget> {
  String _selectedMeasurement = 'weight';
  List<Map<String, dynamic>> _measurements = [];
  bool _isLoading = true;
  Map<String, dynamic>? _progressData;

  final Map<String, Map<String, dynamic>> measurementTypes = {
    'weight': {
      'label': 'Peso',
      'unit': 'kg',
      'icon': Icons.monitor_weight_outlined,
    },
    'body_fat': {
      'label': 'Gordura Corporal',
      'unit': '%',
      'icon': Icons.fitness_center,
    },
    'muscle_mass': {
      'label': 'Massa Muscular',
      'unit': 'kg',
      'icon': Icons.accessibility_new_outlined,
    },
  };

  String _localizedLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'weight': return l10n.measurements_label_weight;
      case 'body_fat': return l10n.measurements_label_body_fat;
      case 'muscle_mass': return l10n.measurements_label_muscle_mass;
      default: return measurementTypes[type]?['label'] as String? ?? type;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  @override
  void didUpdateWidget(MeasurementsChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _loadMeasurements();
    }
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: widget.selectedPeriod));

      final measurementsResult = await getIt<GetMeasurements>()(
        measurementType: _selectedMeasurement,
        startDate: startDate,
        endDate: endDate,
        limit: 30,
      );
      final measurementsData = measurementsResult.fold(
        onSuccess: (items) => items
            .map((m) => {
                  'id': m.id,
                  'measurement_type': m.measurementType,
                  'value': m.value,
                  'unit': m.unit,
                  'measured_at': m.measuredAt?.toIso8601String(),
                  'notes': m.notes,
                })
            .toList(),
        onFailure: (failure) => throw Exception(failure.message),
      );

      final progressResult = await getIt<GetMeasurementProgress>()(
        measurementType: _selectedMeasurement,
        daysPeriod: widget.selectedPeriod,
      );
      final p = progressResult.valueOrNull ?? const MeasurementProgress();
      final progressData = {
        'has_data': p.hasData,
        'latest_value': p.latestValue,
        'previous_value': p.previousValue,
        'change': p.change,
        'change_percentage': p.changePercentage,
      };

      if (mounted) {
        setState(() {
          _measurements = measurementsData;
          _progressData = progressData;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onMeasurementTypeChanged(String type) {
    setState(() => _selectedMeasurement = type);
    _loadMeasurements();
  }

  void _showAddMeasurementDialog() {
    final TextEditingController valueController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
        backgroundColor: BldrColors.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BldrRadius.all(BldrRadius.card)),
        title: Text(
          l10n.measurements_add_dialog_title(_localizedLabel(_selectedMeasurement, l10n)),
          style: BldrText.cardTitleLg,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: BldrText.body,
              decoration: InputDecoration(
                labelText: l10n.measurements_value_field(measurementTypes[_selectedMeasurement]!['unit'] as String),
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
              controller: notesController,
              style: BldrText.body,
              decoration: InputDecoration(
                labelText: l10n.measurements_notes_field,
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
              maxLines: 3,
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
              final value = double.tryParse(valueController.text);
              if (value != null) {
                try {
                  final result = await getIt<RecordMeasurement>()(
                    BodyMeasurement(
                      measurementType: _selectedMeasurement,
                      value: value,
                      unit: measurementTypes[_selectedMeasurement]!['unit'],
                      notes: notesController.text.isNotEmpty
                          ? notesController.text
                          : null,
                    ),
                  );
                  final failure = result.failureOrNull;
                  if (failure != null) throw Exception(failure.message);

                  Navigator.pop(context);
                  _loadMeasurements();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.measurements_save_success),
                      backgroundColor: BldrColors.goldSolid,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.measurements_save_error),
                      backgroundColor: BldrColors.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.common_save, style: BldrText.buttonSecondary),
          ),
        ],
      );
      },
    );
  }

  double _safeInterval(double diff, {double fallback = 1}) {
    final v = diff / 4;
    return v > 0 ? v : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasData = _measurements.isNotEmpty;
    final measurement = measurementTypes[_selectedMeasurement]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PC2 — chips horizontais roláveis, mesma cor para todos.
        _buildMeasurementSelector(),
        const SizedBox(height: 18),
        if (_isLoading)
          const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(color: BldrColors.goldBright)),
          )
        // PC3 — UM único empty state para todo o bloco de métrica
        // (some o "Nenhum dado disponível" repetido do resumo + gráfico).
        else if (!hasData)
          BldrEmptyState(
            icon: Icons.show_chart,
            title: l10n.measurements_empty_title(_localizedLabel(_selectedMeasurement, l10n)),
            instruction: l10n.measurements_empty_instruction,
          )
        else ...[
          // PC4 — valor atual + variação no período.
          _buildProgressSummary(l10n),
          const SizedBox(height: 14),
          _buildChart(),
          const SizedBox(height: 22),
          // PC7 — últimos registros em grupo com divisórias.
          _buildRecentMeasurements(l10n),
        ],
        const SizedBox(height: 18),
        // "Registro rápido" — sempre visível, seletor → gráfico → aqui → fotos.
        BldrSecondaryButton(
          label: l10n.measurements_register_btn(_localizedLabel(_selectedMeasurement, l10n)),
          icon: Icons.add,
          onPressed: _showAddMeasurementDialog,
        ),
      ],
    );
  }

  Widget _buildMeasurementSelector() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: measurementTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final l10n = AppLocalizations.of(context)!;
          final key = measurementTypes.keys.elementAt(index);
          final measurement = measurementTypes[key]!;
          final isSelected = key == _selectedMeasurement;
          return BldrChip(
            label: _localizedLabel(key, l10n),
            icon: measurement['icon'] as IconData,
            active: isSelected,
            onTap: () => _onMeasurementTypeChanged(key),
          );
        },
      ),
    );
  }

  Widget _buildProgressSummary(AppLocalizations l10n) {
    final latestValue = (_progressData?['latest_value'] as num?) ?? 0;
    final change = (_progressData?['change'] as num?) ?? 0;
    final isPositive = change > 0;
    final measurement = measurementTypes[_selectedMeasurement]!;

    return BldrGlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.measurements_current_label(_localizedLabel(_selectedMeasurement, l10n)), style: BldrText.meta),
              const SizedBox(height: 4),
              Text('${latestValue.toStringAsFixed(1)} ${measurement['unit']}',
                  style: BldrText.kpiMd),
            ],
          ),
          if (change != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: BldrColors.goldTint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                      color: BldrColors.goldBright, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}${change.toStringAsFixed(1)} ${measurement['unit']}',
                    style: BldrText.meta.copyWith(
                        color: BldrColors.goldBright, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final spots = _measurements.reversed.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final measurement = entry.value;
      final value = (measurement['value'] as num).toDouble();
      return FlSpot(index.toDouble(), value);
    }).toList();

    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    final range = maxY - minY;
    final padding = range * 0.1;

    return BldrGlassCard(
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _safeInterval(range, fallback: 1),
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: BldrColors.borderSubtle,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: spots.length > 5 ? (spots.length / 5).ceilToDouble() : 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    final invertedMeasurements = _measurements.reversed.toList();
                    if (index >= 0 && index < invertedMeasurements.length) {
                      final date = DateTime.parse(invertedMeasurements[index]['measured_at']);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${date.day}/${date.month}', style: BldrText.metaSm),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: 1.0,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max || value == meta.min) {
                      return const Text('');
                    }
                    return Text(value.toStringAsFixed(1), style: BldrText.metaSm);
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: spots.length.toDouble() - 1,
            minY: minY - padding,
            maxY: maxY + padding,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => BldrColors.sheetBg,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final invertedMeasurements = _measurements.reversed.toList();
                    final index = spot.x.toInt();
                    final unit = measurementTypes[_selectedMeasurement]!['unit'] as String;
                    String dateStr = '';
                    if (index >= 0 && index < invertedMeasurements.length) {
                      final date = DateTime.parse(invertedMeasurements[index]['measured_at']);
                      dateStr = '${date.day}/${date.month}  ';
                    }
                    return LineTooltipItem(
                      '$dateStr${spot.y.toStringAsFixed(1)} $unit',
                      BldrText.meta.copyWith(color: BldrColors.goldBright),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: BldrColors.goldBright,
                barWidth: 3,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      BldrColors.goldBright.withOpacity(0.15),
                      BldrColors.goldBright.withOpacity(0.0),
                    ],
                  ),
                ),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: BldrColors.goldBright,
                      strokeWidth: 2,
                      strokeColor: BldrColors.surface,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PC7 — lista com delta vs anterior + swipe-to-delete.
  Widget _buildRecentMeasurements(AppLocalizations l10n) {
    final recentMeasurements = _measurements.take(5).toList();
    final measurement = measurementTypes[_selectedMeasurement]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.measurements_recent_title, style: BldrText.label),
        const SizedBox(height: 10),
        Column(
          children: recentMeasurements.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            final value = (m['value'] as num).toDouble();
            final measuredAt = DateTime.parse(m['measured_at']);
            final notes = m['notes'] as String?;
            // delta = current - previous (index i+1 is older)
            final prevValue = i + 1 < recentMeasurements.length
                ? (recentMeasurements[i + 1]['value'] as num).toDouble()
                : null;
            final delta = prevValue != null ? value - prevValue : null;

            Widget deltaWidget = const SizedBox.shrink();
            if (delta != null) {
              final isUp = delta > 0;
              deltaWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: BldrColors.textTertiary,
                  ),
                  Text(
                    '${delta.abs().toStringAsFixed(1)}',
                    style: BldrText.metaSm.copyWith(color: BldrColors.textTertiary),
                  ),
                ],
              );
            }

            return Dismissible(
              key: Key(m['id']?.toString() ?? '$i'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: BldrColors.danger.withOpacity(0.15),
                  borderRadius: BldrRadius.all(BldrRadius.cardSm),
                ),
                child: const Icon(Icons.delete_outline, color: BldrColors.danger, size: 20),
              ),
              confirmDismiss: (_) async {
                final id = m['id'] as String?;
                if (id == null) return false;
                final result = await getIt<DeleteMeasurement>()(id);
                return result.failureOrNull == null;
              },
              onDismissed: (_) {
                setState(() => _measurements.removeWhere((x) => x['id'] == m['id']));
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BldrSettingsRow(
                  icon: measurement['icon'] as IconData,
                  title: '${value.toStringAsFixed(1)} ${measurement['unit']}',
                  subtitle: notes != null && notes.isNotEmpty ? notes : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      deltaWidget,
                      const SizedBox(width: 4),
                      Text(_getTimeAgo(measuredAt, l10n), style: BldrText.metaSm),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return l10n.measurements_time_days_ago(difference.inDays);
    } else if (difference.inHours > 0) {
      return l10n.measurements_time_hours_ago(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return l10n.measurements_time_minutes_ago(difference.inMinutes);
    } else {
      return l10n.measurements_time_now;
    }
  }
}
