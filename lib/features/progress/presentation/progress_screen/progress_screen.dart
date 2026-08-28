import 'package:flutter/material.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_sheet.dart';
import 'package:bldr_fitness/features/progress/presentation/progress_screen/widgets/achievements_gallery_widget.dart';
import 'package:bldr_fitness/features/progress/presentation/progress_screen/widgets/export_progress_widget.dart';
import 'package:bldr_fitness/features/progress/presentation/progress_screen/widgets/goal_tracking_widget.dart';
import 'package:bldr_fitness/features/progress/presentation/progress_screen/widgets/measurements_chart_widget.dart';
import 'package:bldr_fitness/features/progress/presentation/progress_screen/widgets/nutrition_analytics_widget.dart';
import 'package:bldr_fitness/features/progress/presentation/progress_screen/widgets/photo_progress_widget.dart';
import 'package:bldr_fitness/features/progress/presentation/progress_screen/widgets/progress_overview_widget.dart';
import 'package:bldr_fitness/features/progress/presentation/progress_screen/widgets/workout_progress_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORTS DOS SERVIÇOS ---
import 'package:bldr_fitness/services/export_service.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/progress/domain/usecases/progress_usecases.dart';

// ADIÇÕES ↓↓↓
//import 'package:bldr_fitness/services/oura_api_service.dart'; // Comentado - Sono
//import 'package:bldr_fitness/features/progress/presentation/progress_screen/widgets/daily_sleep_overview_widget.dart'; // Comentado - Sono
// ADIÇÕES ↑↑↑

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String _selectedPeriod = '30';
  late TabController _tabController;

  // ===== Sono (Oura) ===== // Comentado - Sono
  //DateTime _sleepDate = DateTime.now(); // Comentado - Sono
  //Map<String, dynamic>? _sleep; // daily_sleep[0] do Oura // Comentado - Sono
  //bool _sleepLoading = false; // Comentado - Sono

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    Future.wait([
      _loadProgressData(),
      //_loadSleep(),//oura // Comentado - Sono
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);

    try {
      // Simulação de carregamento inicial da tela (os widgets filhos carregam seus próprios dados)
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.progress_load_error),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Lógica do Sono mantida (comentada)
  /*
  Future<void> _loadSleep() async { ... }
  */

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadProgressData(),
      //_loadSleep(), // Comentado - Sono
    ]);
  }

  /*
  Future<void> _pickSleepDate() async { ... }
  */

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(l10n.progress_title),
              backgroundColor: AppTheme.primaryBlack,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Center(
                    child: HavokEntryIcon(
                      onTap: () => showHavokSheet(context, originScreen: 'progress'),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showExportOptions,
                  icon: Icon(
                    Icons.file_download_outlined,
                    color: AppTheme.textPrimary,
                  ),
                ),
                // Seletor de período
                PopupMenuButton<String>(
                  onSelected: _onPeriodChanged,
                  itemBuilder: (context) => [
                    PopupMenuItem(value: '7', child: Text(l10n.progress_period_7d)),
                    PopupMenuItem(value: '30', child: Text(l10n.progress_period_30d)),
                    PopupMenuItem(value: '90', child: Text(l10n.progress_period_3m)),
                    PopupMenuItem(value: '365', child: Text(l10n.progress_period_1y)),
                  ],
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                    margin: EdgeInsets.only(right: 4.w),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerGray),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selectedPeriod}D',
                          style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 1.w),
                        CustomIconWidget(
                          iconName: 'keyboard_arrow_down',
                          color: AppTheme.textSecondary,
                          size: 4.w,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(6.h),
                child: Container(
                  color: AppTheme.primaryBlack,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorColor: AppTheme.accentGold,
                    labelColor: AppTheme.accentGold,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    indicatorWeight: 3,
                    tabs: [
                      Tab(text: l10n.progress_tab_general),
                      Tab(text: l10n.progress_tab_body),
                      Tab(text: l10n.progress_tab_workouts),
                      Tab(text: l10n.progress_tab_nutrition),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? _buildLoadingState()
            : TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralTab(),
            _buildBodyTab(),
            _buildWorkoutTab(),
            _buildNutritionTab(),
          ],
        ),
      ),
    );
  }

  // 1. Aba Geral
  Widget _buildGeneralTab() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.accentGold,
      backgroundColor: AppTheme.cardDark,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        children: [
          ProgressOverviewWidget(
            selectedPeriod: int.parse(_selectedPeriod),
          ),
          SizedBox(height: 3.h),
          GoalTrackingWidget(
            selectedPeriod: int.parse(_selectedPeriod),
          ),
          SizedBox(height: 3.h),
          AchievementsGalleryWidget(),
          SizedBox(height: 5.h),
        ],
      ),
    );
  }

  // 2. Aba Corpo
  // PC3 — ordem: seletor de métrica → gráfico → registro rápido → fotos
  // (tudo dentro de MeasurementsChartWidget, exceto fotos) → fotos por
  // último, para não empilhar o empty state de fotos com o de métricas.
  Widget _buildBodyTab() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.accentGold,
      backgroundColor: AppTheme.cardDark,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        children: [
          /*
          _buildSleepSection(),
          SizedBox(height: 3.h),
          */
          MeasurementsChartWidget(
            selectedPeriod: int.parse(_selectedPeriod),
          ),
          SizedBox(height: 3.h),
          PhotoProgressWidget(),
          SizedBox(height: 5.h),
        ],
      ),
    );
  }

  // 3. Aba Treinos
  Widget _buildWorkoutTab() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.accentGold,
      backgroundColor: AppTheme.cardDark,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        children: [
          WorkoutProgressWidget(selectedPeriod: int.parse(_selectedPeriod)),
          SizedBox(height: 5.h),
        ],
      ),
    );
  }

  // 4. Aba Nutrição
  Widget _buildNutritionTab() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.accentGold,
      backgroundColor: AppTheme.cardDark,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        children: [
          NutritionAnalyticsWidget(
            selectedPeriod: int.parse(_selectedPeriod),
          ),
          SizedBox(height: 5.h),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.accentGold, strokeWidth: 3),
          SizedBox(height: 3.h),
          Text(
            AppLocalizations.of(context)!.progress_loading,
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // --- LÓGICA DE EXPORTAÇÃO REAL ---
  void _showExportOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ExportProgressWidget(
        onExport: (format) async {
          Navigator.pop(context); // Fecha o modal

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.progress_export_compiling),
              backgroundColor: AppTheme.accentGold,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );

          try {
            final client = Supabase.instance.client;
            final userId = client.auth.currentUser?.id;

            if (userId == null) return;

            // 1. Define datas
            final days = int.tryParse(_selectedPeriod) ?? 30;
            final startDate = DateTime.now().subtract(Duration(days: days));
            final endDate = DateTime.now().add(const Duration(days: 1)); // +1 para garantir o dia de hoje

            List<Map<String, dynamic>> fullReportData = [];

            // ====================================================
            // A. BUSCAR MEDIDAS DO CORPO (Peso, Gordura, Músculo)
            // ====================================================
            final types = ['weight', 'body_fat', 'muscle_mass'];
            for (var type in types) {
              // Reutilizando seu serviço existente
              final result = await getIt<GetMeasurements>()(
                measurementType: type,
                startDate: startDate,
                endDate: endDate,
                limit: 50,
              );

              fullReportData.addAll((result.valueOrNull ?? []).map((m) => {
                    'measurement_type': m.measurementType,
                    'value': m.value,
                    'unit': m.unit,
                    'measured_at': m.measuredAt?.toIso8601String(),
                    'notes': m.notes,
                    'type': type, // Garante que o tipo está preenchido
                  }));
            }

            // ====================================================
            // B. BUSCAR NUTRIÇÃO (Ex: Calorias e Proteínas)
            // ====================================================
            // * Ajuste o nome da tabela 'daily_nutrition' se for diferente no seu banco
            try {
              final nutritionResponse = await client
                  .from('daily_nutrition')
                  .select()
                  .eq('user_id', userId)
                  .gte('date', startDate.toIso8601String())
                  .lte('date', endDate.toIso8601String())
                  .order('date', ascending: false);

              for (var row in nutritionResponse) {
                // Adiciona Calorias
                if (row['calories'] != null) {
                  fullReportData.add({
                    'measured_at': row['date'], // ou row['created_at']
                    'type': 'calories',
                    'value': row['calories'],
                    'unit': 'kcal',
                    'notes': 'Meta: ${row['target_calories'] ?? '-'}'
                  });
                }
                // Adiciona Proteínas (opcional, pode remover se poluir muito)
                if (row['protein'] != null) {
                  fullReportData.add({
                    'measured_at': row['date'],
                    'type': 'protein',
                    'value': row['protein'],
                    'unit': 'g',
                    'notes': ''
                  });
                }
              }
            } catch (e) {
              debugPrint('Erro ao buscar nutrição (pode não existir a tabela): $e');
            }

            // ====================================================
            // C. BUSCAR TREINOS REALIZADOS
            // ====================================================
            // * Ajuste o nome da tabela 'workout_sessions' se for diferente
            try {
              final workoutsResponse = await client
                  .from('workout_sessions')
                  .select()
                  .eq('user_id', userId)
                  .gte('finished_at', startDate.toIso8601String())
                  .order('finished_at', ascending: false);

              for (var row in workoutsResponse) {
                fullReportData.add({
                  'measured_at': row['finished_at'], // Data do treino
                  'type': 'workout',
                  'value': row['duration_minutes'] ?? 0, // Valor numérico (ex: duração)
                  'unit': 'min',
                  'notes': row['workout_name'] ?? 'Treino sem nome' // Nome do treino nas notas
                });
              }
            } catch (e) {
              debugPrint('Erro ao buscar treinos: $e');
            }

            // ====================================================
            // D. FINALIZAÇÃO
            // ====================================================

            // Ordena tudo por data (do mais recente para o mais antigo)
            fullReportData.sort((a, b) {
              final dateA = DateTime.tryParse(a['measured_at'] ?? '') ?? DateTime(2000);
              final dateB = DateTime.tryParse(b['measured_at'] ?? '') ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });

            if (fullReportData.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.progress_no_data_period)),
                );
              }
              return;
            }

            // Gera o arquivo
            if (format == 'PDF') {
              await ExportService.instance.exportToPdf(fullReportData);
            } else if (format == 'CSV') {
              await ExportService.instance.exportToCsv(fullReportData);
            } else if (format == 'Share') {
              // ... lógica de share simplificada ...
              await ExportService.instance.shareSummary(0, 0);
            }

          } catch (e) {
            debugPrint('Erro crítico na exportação: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.progress_export_error),
                  backgroundColor: AppTheme.errorRed,
                ),
              );
            }
          }
        },
      ),
    );
  }
}