import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_provider.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/widgets/achievement_badge.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/achievements/domain/usecases/achievement_usecases.dart';
import 'package:bldr_fitness/features/achievements/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';

class AchievementsWidget extends StatefulWidget {
  final VoidCallback onViewAllPressed;

  const AchievementsWidget({
    Key? key,
    required this.onViewAllPressed,
  }) : super(key: key);

  @override
  State<AchievementsWidget> createState() => _AchievementsWidgetState();
}

class _AchievementsWidgetState extends State<AchievementsWidget> {
  int _total = 0;
  int _unlocked = 0;
  Map<String, dynamic>? _lastAchievement;
  bool _loaded = false;
  bool _listenerAdded = false;
  // Saved reference so dispose() doesn't need to look up the tree
  AchievementProvider? _provider;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerAdded) {
      _listenerAdded = true;
      _provider = Provider.of<AchievementProvider>(context, listen: false);
      _provider!.addListener(_onProviderChange);
    }
  }

  void _onProviderChange() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChange);
    super.dispose();
  }

  Future<void> _load() async {
    final userId = getIt<AuthRepository>().currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    try {
      final catalogResult  = await getIt<GetAchievementCatalog>()();
      final unlockedResult = await getIt<GetUserAchievements>()(userId);
      final catalog = (catalogResult.valueOrNull ?? [])
          .map(achievementToLegacyMap)
          .toList();
      final unlocked = unlockedResult.valueOrNull ?? [];

      Map<String, dynamic>? last;
      if (unlocked.isNotEmpty) {
        final catalogMap = {for (var a in catalog) a['name'] as String: a};
        final sorted = [...unlocked]..sort((a, b) =>
            (b.achievedAt ?? DateTime(0)).compareTo(a.achievedAt ?? DateTime(0)));
        last = catalogMap[sorted.first.achievementName];
      }

      if (mounted) {
        setState(() {
          _total          = catalog.length;
          _unlocked       = unlocked.length;
          _lastAchievement = last;
          _loaded         = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerGray, width: 1),
      ),
      child: !_loaded
          ? const SizedBox(
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: AppTheme.accentGold,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          : Row(
              children: [
                if (_lastAchievement != null)
                  AchievementBadge(
                    iconName: _lastAchievement!['icon_name'] as String? ??
                        'emoji_events',
                    unlocked: true,
                    size: 36,
                  )
                else
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'emoji_events',
                      color: AppTheme.accentGold,
                      size: 5.w,
                    ),
                  ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _unlocked == 0
                            ? 'Nenhuma conquista ainda'
                            : '$_unlocked de $_total desbloqueadas',
                        style:
                            AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_lastAchievement != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          'Última: ${_lastAchievement!['name'] as String? ?? ''}',
                          style:
                              AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: widget.onViewAllPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Ver todas →',
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
