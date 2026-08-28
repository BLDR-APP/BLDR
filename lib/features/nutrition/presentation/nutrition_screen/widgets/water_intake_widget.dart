import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/progress/domain/entities/body_measurement.dart';
import 'package:bldr_fitness/features/progress/domain/usecases/progress_usecases.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class WaterIntakeWidget extends StatelessWidget {
  final double intake;
  final VoidCallback onIncrement;

  const WaterIntakeWidget({
    Key? key,
    required this.intake,
    required this.onIncrement,
  }) : super(key: key);

  Future<List<dynamic>> _fetchWaterData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Future.wait([
      getIt<GetDailyWaterIntake>()(DateTime.now()).then((r) {
        final w = r.valueOrNull ?? const DailyWaterIntake();
        return {
          'total_amount_ml': w.totalAmountMl,
          'total_amount_liters': w.totalAmountLiters,
        };
      }),
      userId != null
          ? Supabase.instance.client
              .from('user_profiles')
              .select('onboarding_data')
              .eq('id', userId)
              .maybeSingle()
          : Future.value(null),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchWaterData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(context);
        }

        int targetMl = 2500;

        if (snapshot.hasData && !snapshot.hasError) {
          final profileResult = snapshot.data?[1];
          if (profileResult != null && profileResult is Map) {
            var rawOnboarding = profileResult['onboarding_data'];
            Map<String, dynamic> onboardingMap = {};
            if (rawOnboarding is String) {
              try { onboardingMap = jsonDecode(rawOnboarding); } catch (_) {}
            } else if (rawOnboarding is Map) {
              onboardingMap = Map<String, dynamic>.from(rawOnboarding);
            }
            if (onboardingMap.containsKey('target_hydration_liters')) {
              final val = onboardingMap['target_hydration_liters'];
              final double? litersVal = double.tryParse(val.toString());
              if (litersVal != null) targetMl = (litersVal * 1000).toInt();
            }
          }
        }

        final waterData = snapshot.data?[0] as Map<String, dynamic>?;
        return _buildWaterIntakeCard(context, waterData, targetMl);
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return BldrGlassCard(
      child: Row(
        children: [
          BldrRingProgress(
            progress: 0,
            size: 88,
            strokeWidth: 8,
            center: const Icon(TablerIcons.droplet, color: BldrColors.textMuted, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).hydration_title, style: BldrText.cardTitleLg),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).hydration_loading, style: BldrText.description),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntakeCard(BuildContext context, Map<String, dynamic>? waterData, int targetMl) {
    final int totalAmountMl = waterData?['total_amount_ml'] ?? 0;
    final totalAmountLiters = waterData?['total_amount_liters'] ?? '0.0';
    final int logCount = waterData?['log_count'] ?? 0;
    final targetLitersDisplay =
        (targetMl / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    final double progress = (totalAmountMl / targetMl).clamp(0.0, 1.0);
    final int percentDisplay = (progress * 100).round();
    final int remainingMl = (targetMl - totalAmountMl).clamp(0, targetMl);
    final remainingLitersDisplay =
        (remainingMl / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Text(AppLocalizations.of(context).hydration_title, style: BldrText.cardTitleLg),
          const SizedBox(height: 16),

          // Item 1 — anel de progresso + valores.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BldrRingProgress(
                progress: progress,
                size: 88,
                strokeWidth: 8,
                center: totalAmountMl == 0
                    ? const Icon(TablerIcons.droplet, color: BldrColors.textMuted, size: 28)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).hydration_consumed, style: BldrText.meta),
                    const SizedBox(height: 4),
                    Text('${totalAmountLiters}L de ${targetLitersDisplay}L',
                        style: BldrText.kpiMd),
                    const SizedBox(height: 4),
                    Text(AppLocalizations.of(context).hydration_remaining(remainingLitersDisplay),
                        style: BldrText.body.copyWith(
                            fontSize: 12, color: BldrColors.goldBright, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Item 3 — stats unificados com divisórias.
          BldrStatDividerRow(items: [
            BldrStatItem(value: '${totalAmountMl}ml', label: AppLocalizations.of(context).hydration_total_today),
            BldrStatItem(value: '$logCount', label: AppLocalizations.of(context).hydration_entries),
            BldrStatItem(value: '$percentDisplay%', label: AppLocalizations.of(context).hydration_goal_percent),
          ]),
          const SizedBox(height: 16),

          // Item 2 — chips sem azul, gota dourada crescente, sugestão com tint.
          Row(
            children: [
              _buildQuickAddButton(context, 150, 15),
              const SizedBox(width: 8),
              _buildQuickAddButton(context, 250, 16, suggested: true),
              const SizedBox(width: 8),
              _buildQuickAddButton(context, 350, 17),
              const SizedBox(width: 8),
              _buildQuickAddButton(context, 500, 18),
            ],
          ),
          const SizedBox(height: 10),

          // Item 4 — quantidade personalizada. [F novo, aprovado] mesmo
          // use case (LogWater) dos atalhos acima, só com valor digitado.
          GestureDetector(
            onTap: () => _showCustomAmountDialog(context),
            behavior: HitTestBehavior.opaque,
            child: BldrDashedContainer(
              radius: BldrRadius.cardSm,
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: BldrColors.textSecondary, size: 16),
                  const SizedBox(width: 6),
                  Text(AppLocalizations.of(context).hydration_custom_amount, style: BldrText.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Item 5 — ação reversível, neutra (não é BldrColors.danger).
          GestureDetector(
            onTap: () => _showRemoveWaterDialog(context, totalAmountMl),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(TablerIcons.arrow_back_up, color: Color(0x66FFFFFF), size: 15),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).hydration_remove_last,
                      style: TextStyle(
                          fontFamily: BldrText.family,
                          color: const Color(0x66FFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(BuildContext context, int ml, double dropletSize, {bool suggested = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          try {
            final r = await getIt<LogWater>()(ml);
            if (r.isFailure) throw Exception(r.failureOrNull?.message);
            onIncrement();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('+${ml}ml registrado'),
                backgroundColor: BldrColors.goldSolid,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ));
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(AppLocalizations.of(context).hydration_log_error),
                backgroundColor: BldrColors.danger,
                behavior: SnackBarBehavior.floating,
              ));
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: suggested ? BldrColors.goldTintChip : BldrColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: suggested ? BldrColors.goldBorderChip : BldrColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(TablerIcons.droplet,
                  color: BldrColors.goldBright, size: dropletSize),
              const SizedBox(height: 4),
              Text('+${ml}ml',
                  style: TextStyle(
                      fontFamily: BldrText.family,
                      color: suggested ? BldrColors.goldBright : BldrColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomAmountDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BldrColors.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BldrRadius.all(BldrRadius.card)),
        title: Text(AppLocalizations.of(ctx).hydration_custom_amount, style: BldrText.cardTitleLg),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: BldrText.body,
          decoration: InputDecoration(
            suffixText: 'ml',
            suffixStyle: BldrText.description,
            filled: true,
            fillColor: BldrColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: BldrColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: BldrColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: BldrColors.goldBright, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).common_cancel, style: BldrText.description),
          ),
          TextButton(
            onPressed: () async {
              final ml = int.tryParse(controller.text);
              if (ml == null || ml <= 0) return;
              Navigator.pop(ctx);
              try {
                final r = await getIt<LogWater>()(ml);
                if (r.isFailure) throw Exception(r.failureOrNull?.message);
                onIncrement();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('+${ml}ml registrado'),
                    backgroundColor: BldrColors.goldSolid,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ));
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppLocalizations.of(context).hydration_log_error),
                    backgroundColor: BldrColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: Text(AppLocalizations.of(ctx).hydration_add_btn, style: BldrText.buttonSecondary),
          ),
        ],
      ),
    );
  }

  void _showRemoveWaterDialog(BuildContext context, int currentTotal) {
    if (currentTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).hydration_no_data),
        backgroundColor: BldrColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final amounts = [150, 250, 350, 500].where((a) => a <= currentTotal).toList();
        return AlertDialog(
          backgroundColor: BldrColors.sheetBg,
          shape: RoundedRectangleBorder(borderRadius: BldrRadius.all(BldrRadius.card)),
          title: Text(AppLocalizations.of(context).hydration_remove_title, style: BldrText.cardTitleLg),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (amounts.isEmpty)
                Text(AppLocalizations.of(context).hydration_too_small,
                    style: BldrText.description)
              else
                ...amounts.map((amount) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          final r = await getIt<RemoveWater>()(amount);
                          if (r.isFailure) throw Exception(r.failureOrNull?.message);
                          if (context.mounted) Navigator.pop(context);
                          onIncrement();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context).hydration_removed(amount)),
                              backgroundColor: BldrColors.surface,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context).hydration_remove_error),
                              backgroundColor: BldrColors.danger,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BldrColors.textSecondary,
                        side: const BorderSide(color: BldrColors.border),
                      ),
                      child: Text('- ${amount}ml', style: BldrText.body),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
