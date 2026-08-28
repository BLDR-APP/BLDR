import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/whoop_entities.dart';
import 'package:bldr_fitness/features/integrations/domain/usecases/whoop_usecases.dart';
import 'package:bldr_fitness/features/integrations/presentation/widgets/bldr_whoop_card.dart';

class WhoopDashboardWidget extends StatefulWidget {
  const WhoopDashboardWidget({super.key});

  @override
  State<WhoopDashboardWidget> createState() => _WhoopDashboardWidgetState();
}

class _WhoopDashboardWidgetState extends State<WhoopDashboardWidget> {
  static const _throttleMinutes = 30;

  bool _checked = false;
  bool _connected = false;
  bool _syncing = false;
  WhoopDailyData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final connResult = await getIt<GetWhoopConnection>()();
    final conn = connResult.valueOrNull;

    if (!mounted) return;
    if (conn == null || !conn.isConnected) {
      setState(() => _checked = true);
      return;
    }

    setState(() {
      _checked = true;
      _connected = true;
      _syncing = true;
    });

    final localResult = await getIt<GetTodayWhoopData>()();
    final local = localResult.valueOrNull;

    if (!mounted) return;

    if (local != null && _hasMeaningfulData(local)) {
      final age = DateTime.now().difference(local.syncedAt).inMinutes;
      if (age < _throttleMinutes) {
        setState(() {
          _data = local;
          _syncing = false;
        });
        return;
      }
    }

    // Dado ausente, antigo ou sem valores reais — sincroniza
    final syncResult = await getIt<SyncWhoopData>()();
    if (!mounted) return;
    final synced = syncResult.valueOrNull;
    debugPrint('WHOOP sync result: $synced, failure: ${syncResult.isFailure ? (syncResult as dynamic).failure : null}');
    setState(() {
      _data = (_hasMeaningfulData(synced) ? synced : null) ?? (_hasMeaningfulData(local) ? local : null);
      _syncing = false;
    });
  }

  bool _hasMeaningfulData(WhoopDailyData? d) =>
      d != null && (d.recoveryScore != null || d.strainScore != null || d.sleepScore != null);

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const SizedBox.shrink();
    if (!_connected) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: BldrWhoopCard(data: null, isConnected: false),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BldrWhoopCard(
        data: _data,
        isConnected: true,
        isSyncing: _syncing,
      ),
    );
  }
}
