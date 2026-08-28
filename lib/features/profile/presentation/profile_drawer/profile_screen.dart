import 'package:fl_chart/fl_chart.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/features/progress/domain/entities/body_measurement.dart';
import 'package:bldr_fitness/features/progress/domain/usecases/progress_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart' as subUc;
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/models/subscription_plan.dart';
import 'package:bldr_fitness/models/user_profile.dart';
import 'package:bldr_fitness/services/profile_notifier.dart';
import 'package:bldr_fitness/services/push_notification_service.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/widgets/achievement_badge.dart';
import 'package:bldr_fitness/features/profile/presentation/profile_drawer/widgets/edit_profile_dialog_widget.dart';

/// PF9 — as seções de configurações (Editar Perfil, Plano/Assinatura,
/// Refazer Onboarding, Notificação, Compartilhar Perfil, Sair, Excluir
/// Conta) saíram desta tela e agora vivem em
/// `features/profile/presentation/settings/settings_screen.dart` (rota
/// `AppRoutes.settingsScreen`, acessada pelo ícone de engrenagem no header).
/// Os métodos de lógica correspondentes (`_showEditProfileDialog`,
/// `_showPlanUpgradeDialog`, `_toggleNotifications`,
/// `_showCancelSubscriptionDialog`, `_getCurrentPlanName`, `_isPremium`,
/// `_formatDate`) ficam aqui intactos e SEM CHAMADOR — a tela de
/// Configurações replica a mesma lógica (mesmos use cases/serviços), já que
/// esta tela não tem controller compartilhado (dívida do INVENTARIO.md).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  UserSubscription? _userSubscription;
  bool _isLoading = true;
  String? _error;

  late ProfileNotifier _profileNotifier;

  bool _notificationsEnabled = false;
  bool _isTogglingNotifications = false;

  // Gamification data
  int _totalXp = 0;
  int _currentLevel = 1;
  int _rankPosition = 0;
  int _totalWorkouts = 0;
  int _currentStreak = 0;
  int _horasTreinadas = 0;

  static int _levelFromXp(int xp) {
    const thresholds = {1: 0, 2: 1000, 3: 2500, 4: 5000, 5: 10000};
    int level = 1;
    for (final entry in thresholds.entries) {
      if (xp >= entry.value) level = entry.key;
    }
    return level;
  }
  int _totalAchievements = 0;
  bool _gamificationLoading = true;
  List<Map<String, dynamic>> _achievementCatalog = [];
  Set<String> _unlockedAchievementNames = {};
  int _badgesPage = 0;

  // Card "Seu progresso" — mesmos use cases que a tela de Progresso já usa
  // para o peso (GetMeasurements/GetMeasurementProgress), nenhuma fonte
  // de dado nova.
  List<double> _weightSeries = [];
  double? _weightLatest;
  double? _weightChange;
  bool _weightLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadWeightProgress();
  }

  Future<void> _loadWeightProgress() async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));

      final measurementsResult = await getIt<GetMeasurements>()(
        measurementType: 'weight',
        startDate: startDate,
        endDate: now,
        limit: 30,
      );
      final progressResult = await getIt<GetMeasurementProgress>()(
        measurementType: 'weight',
        daysPeriod: 30,
      );

      final measurements = measurementsResult.valueOrNull ?? const <BodyMeasurement>[];
      final progress = progressResult.valueOrNull ?? const MeasurementProgress();

      if (!mounted) return;
      setState(() {
        _weightSeries = measurements.reversed.map((m) => m.value).toList();
        _weightLatest = progress.latestValue;
        _weightChange = progress.change;
        _weightLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _weightLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    _profileNotifier.addListener(_handleProfileUpdate);
  }

  void _handleProfileUpdate() {
    if (mounted) _loadUserProfile();
  }

  @override
  void dispose() {
    _profileNotifier.removeListener(_handleProfileUpdate);
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await UserService.instance.getCurrentUserProfile();
      final subscription =
          (await getIt<subUc.GetCurrentSubscription>()()).valueOrNull;

      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _userSubscription = subscription;
        _notificationsEnabled = profile?.notificationsEnabled ?? false;
        _isLoading = false;
      });

      // Load gamification data in background
      _loadGamificationData(profile?.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar perfil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGamificationData(String? userId) async {
    if (userId == null) return;
    setState(() => _gamificationLoading = true);

    final supabase = Supabase.instance.client;

    // ── Bloco 1: XP, nível e ranking (crítico — não pode falhar silencioso) ──
    try {
      final rankData = await supabase
          .schema('bldr_club')
          .from('club_ranking')
          .select('xp_total, current_level')
          .eq('user_id', userId)
          .maybeSingle();

      final allRanking = await supabase
          .schema('bldr_club')
          .from('club_ranking')
          .select('user_id, xp_total')
          .eq('ranking_visible', true)
          .order('xp_total', ascending: false)
          .limit(200) as List<dynamic>;

      int pos = 0;
      for (int i = 0; i < allRanking.length; i++) {
        if (allRanking[i]['user_id'] == userId) { pos = i + 1; break; }
      }

      if (mounted) {
        setState(() {
          _totalXp      = (rankData?['xp_total'] as num?)?.toInt() ?? 0;
          _currentLevel = _levelFromXp(_totalXp);
          _rankPosition = pos;
          _gamificationLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro gamification core: $e');
      if (mounted) setState(() => _gamificationLoading = false);
    }

    // ── Bloco 2: stats dos cards (treinos, streak, horas, conquistas) ──
    try {
      final historyResult = await getIt<GetConsolidatedWorkoutHistory>()(
          userId: userId, completedOnly: true, limit: 1000);
      final streakResult = await getIt<GetCurrentStreak>()();
      final supabaseResults = await Future.wait([
        supabase.from('achievements').select('name, icon_name, category').order('category'),
        supabase.from('user_achievements').select('achievement_name').eq('user_id', userId),
      ]);

      final sessions      = historyResult.valueOrNull ?? [];
      final streak        = streakResult.valueOrNull ?? 0;
      final achievementsRaw = supabaseResults[1] as List;

      final totalWorkouts = sessions.length;

      int totalSeconds = 0;
      for (final s in sessions) {
        totalSeconds += s.totalDurationSeconds ?? 0;
      }
      final totalHours = totalSeconds ~/ 3600;

      final catalog = List<Map<String, dynamic>>.from(supabaseResults[0] as List);
      final unlockedNames = achievementsRaw
          .map((a) => a['achievement_name'] as String)
          .toSet();

      if (mounted) {
        setState(() {
          _totalWorkouts             = totalWorkouts;
          _currentStreak             = streak;
          _horasTreinadas            = totalHours;
          _totalAchievements         = achievementsRaw.length;
          _achievementCatalog        = catalog;
          _unlockedAchievementNames  = unlockedNames;
        });
      }
    } catch (e) {
      debugPrint('Erro gamification stats: $e');
    }
  }

  void _showEditProfileDialog() {
    if (_userProfile == null) return;

    showDialog(
      context: context,
      builder: (context) => EditProfileDialogWidget(
        currentName: _userProfile!.fullName,
        currentEmail: _userProfile!.email,
        currentPhone: '',
        onSave: (name, email, phone) async {
          try {
            final updatedProfile =
                await UserService.instance.updateCurrentUserProfile(
              updates: {'full_name': name},
            );

            if (updatedProfile != null) {
              setState(() => _userProfile = updatedProfile);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.profile_updated),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.profile_update_error('$e')),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        },
      ),
    );
  }

  void _showPlanUpgradeDialog() {
    ClubPaywallSheet.show(context);
  }

  void _navigateToCheckout(SubscriptionPlan plan) {
    Navigator.pushNamed(
      context,
      AppRoutes.checkoutScreen,
      arguments: {'plan': plan, 'billingPeriod': 'monthly'},
    );
  }

  void _showImagePickerDialog() {
    final hasPhoto = _userProfile?.avatarUrl != null &&
        _userProfile!.avatarUrl!.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.dialogDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.profile_photo_change_title,
                style:
                    AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _handleCameraCapture();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerGray),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt,
                                color: AppTheme.accentGold, size: 32),
                            SizedBox(height: 1.h),
                            Text(AppLocalizations.of(context)!.photo_option_camera,
                                style: AppTheme
                                    .darkTheme.textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _handleGallerySelection();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerGray),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_library,
                                color: AppTheme.accentGold, size: 32),
                            SizedBox(height: 1.h),
                            Text(AppLocalizations.of(context)!.photo_option_gallery,
                                style: AppTheme
                                    .darkTheme.textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (hasPhoto) ...[
                SizedBox(height: 2.h),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.errorRed.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline,
                            color: AppTheme.errorRed),
                        SizedBox(width: 2.w),
                        Text(
                          AppLocalizations.of(context)!.profile_photo_remove_btn,
                          style: AppTheme.darkTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 2.h),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.common_cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCameraCapture() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          imageQuality: 85);
      if (photo != null) await _uploadProfileImage(photo);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.profile_camera_error('$e')),
          backgroundColor: AppTheme.errorRed));
    }
  }

  Future<void> _handleGallerySelection() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 2048,
          imageQuality: 90);
      if (image != null) await _uploadProfileImage(image);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.profile_gallery_error('$e')),
          backgroundColor: AppTheme.errorRed));
    }
  }

  Future<void> _uploadProfileImage(XFile imageFile) async {
    if (_userProfile == null) return;
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Usuário não encontrado.');

      final file = File(imageFile.path);
      final fileExtension = imageFile.path.split('.').last;
      final storagePath = '$currentUserId/profile.$fileExtension';

      await supabase.storage.from('Images').upload(
            storagePath,
            file,
            fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: true,
                metadata: {'user_id': currentUserId}),
          );

      final publicUrl =
          supabase.storage.from('Images').getPublicUrl(storagePath);
      final updatedProfile =
          await UserService.instance.updateCurrentUserProfile(
        updates: {'avatar_url': publicUrl},
      );

      if (updatedProfile != null) {
        if (!mounted) return;
        setState(() => _userProfile = updatedProfile);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.profile_photo_updated),
            backgroundColor: AppTheme.successGreen));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.profile_photo_update_error('$e')),
          backgroundColor: AppTheme.errorRed));
    }
  }

  Future<void> _removeProfileImage() async {
    if (_userProfile == null) return;
    try {
      final updatedProfile =
          await UserService.instance.updateCurrentUserProfile(
        updates: {'avatar_url': null},
      );
      if (updatedProfile != null) {
        if (!mounted) return;
        setState(() => _userProfile = updatedProfile);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.profile_photo_removed),
            backgroundColor: AppTheme.successGreen));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.profile_photo_remove_error('$e')),
          backgroundColor: AppTheme.errorRed));
    }
  }

  Future<void> _toggleNotifications(bool newValue) async {
    if (_isTogglingNotifications) return;

    setState(() {
      _isTogglingNotifications = true;
      _notificationsEnabled = newValue;
    });

    try {
      if (newValue) {
        final currentSettings =
            await FirebaseMessaging.instance.getNotificationSettings();
        if (currentSettings.authorizationStatus ==
            AuthorizationStatus.denied) {
          if (mounted) await _showPermissionDeniedDialog();
          throw Exception('_settings_redirect');
        }
        final settings = await FirebaseMessaging.instance
            .requestPermission(alert: true, badge: true, sound: true);
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          throw Exception('Permissão de notificação negada pelo usuário.');
        }
      }

      await getIt<PushNotificationService>()
          .syncTokenToProfile(enabled: newValue);

      final updatedProfile =
          await UserService.instance.getCurrentUserProfile();
      if (updatedProfile != null && mounted) {
        setState(() {
          _userProfile = updatedProfile;
          _notificationsEnabled =
              updatedProfile.notificationsEnabled ?? newValue;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (!e.toString().contains('_settings_redirect')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.profile_notifications_error('$e')),
            backgroundColor: AppTheme.errorRed));
      }
      setState(() => _notificationsEnabled = !newValue);
    } finally {
      if (mounted) setState(() => _isTogglingNotifications = false);
    }
  }

  /// Exibido quando a permissão de notificação já foi negada no SO.
  /// Oferece atalho para as configurações de notificação do app.
  Future<void> _showPermissionDeniedDialog() {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.profile_permission_title,
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.profile_permission_body,
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.common_cancel,
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.primaryBlack,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AppLocalizations.of(context)!.profile_open_settings_btn,
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showMeasurementsDialog() {
    if (_userProfile == null) return;
    final heightController =
        TextEditingController(text: _userProfile!.heightCm?.toString() ?? '');
    final weightController = TextEditingController(
        text: _userProfile!.targetWeightKg?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.dialogDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.of(context)!.profile_measurements_title,
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
              SizedBox(height: 3.h),
              _buildMeasurementField(AppLocalizations.of(context)!.profile_measurements_height, heightController),
              SizedBox(height: 2.h),
              _buildMeasurementField(AppLocalizations.of(context)!.profile_measurements_target_weight, weightController),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.of(context)!.common_cancel)),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final updates = <String, dynamic>{};
                          if (heightController.text.isNotEmpty) {
                            final height =
                                int.tryParse(heightController.text);
                            if (height != null) updates['height_cm'] = height;
                          }
                          if (weightController.text.isNotEmpty) {
                            final weight =
                                double.tryParse(weightController.text);
                            if (weight != null) {
                              updates['target_weight_kg'] = weight;
                            }
                          }
                          if (updates.isNotEmpty) {
                            final updatedProfile = await UserService.instance
                                .updateCurrentUserProfile(updates: updates);
                            if (updatedProfile != null) {
                              setState(() => _userProfile = updatedProfile);
                            }
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(AppLocalizations.of(context)!.profile_measurements_saved),
                                  backgroundColor: AppTheme.successGreen));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Erro ao salvar: $e'),
                              backgroundColor: AppTheme.errorRed));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold),
                      child: Text(AppLocalizations.of(context)!.common_save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        backgroundColor: AppTheme.dialogDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(AppLocalizations.of(context)!.profile_cancel_subscription_title,
              style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        ),
        content: Text.rich(TextSpan(
          style: AppTheme.darkTheme.textTheme.bodyMedium
              ?.copyWith(color: AppTheme.textSecondary),
          children: [
            TextSpan(
                text:
                    AppLocalizations.of(context)!.profile_cancel_subscription_before),
            TextSpan(
                text: 'contato@bldrapp.com.br',
                style: TextStyle(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    AppLocalizations.of(context)!.profile_cancel_subscription_after),
          ],
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Entendi',
                  style: TextStyle(color: AppTheme.accentGold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.darkTheme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.textSecondary)),
        SizedBox(height: 1.h),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.cardDark,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            hintText: label,
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  String _getCurrentPlanName() {
    if (_userSubscription == null) return AppLocalizations.of(context)!.profile_plan_free;
    if (_userSubscription!.status != 'active') return AppLocalizations.of(context)!.profile_plan_free;
    switch (_userSubscription!.planId) {
      case 'ffa05840-0212-46eb-9f80-2dbab9c362a8':
        return 'BLDR CORE';
      case 'd082af8c-216a-4499-a1f6-1fb84ac08a5f':
        return 'BLDR CLUB';
      default:
        return AppLocalizations.of(context)!.profile_plan_premium;
    }
  }

  bool get _isPremium {
    if (_userSubscription == null) return false;
    return _userSubscription!.status == 'active';
  }

  bool get _isClubMember {
    if (_userSubscription == null) return false;
    return _userSubscription!.status == 'active' &&
        _userSubscription!.planId == 'd082af8c-216a-4499-a1f6-1fb84ac08a5f';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // ── Identity block helpers ──────────────────────────────────────────────

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// PF1 (e-mail removido) + PF2 (header horizontal) + PF3 (sem chip de
  /// nível duplicado — o nível já aparece no card de XP logo abaixo).
  Widget _buildIdentityBlock() {
    final profile = _userProfile!;
    final hasAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(BldrSpacing.pageX, 16, BldrSpacing.pageX, 0),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: _showImagePickerDialog,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: BldrColors.goldBright, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x4DE0B830), blurRadius: 12),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: BldrColors.surface,
                    backgroundImage:
                        hasAvatar ? NetworkImage(profile.avatarUrl!) : null,
                    child: !hasAvatar
                        ? Text(_initials(profile.fullName),
                            style: const TextStyle(
                                fontFamily: BldrText.family,
                                color: BldrColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 20))
                        : null,
                  ),
                ),
                if (_isClubMember)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: BldrColors.goldBright,
                        shape: BoxShape.circle,
                        border: Border.all(color: BldrColors.bgBase, width: 1.5),
                      ),
                      child: const Icon(Icons.verified,
                          color: Color(0xFF0A0A0A), size: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Nome + badges — horizontal ao lado do avatar, sem e-mail.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullName,
                    style: BldrText.cardTitleLg,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (_isClubMember) const BldrBadge(label: 'BLDR CLUB'),
                    if (_rankPosition > 0)
                      BldrChip(
                        label: '#$_rankPosition no ranking',
                        icon: Icons.emoji_events,
                        active: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpBar() {
    const Map<int, int> thresholds = {1: 0, 2: 1000, 3: 2500, 4: 5000, 5: 10000};
    final xpStart = thresholds[_currentLevel] ?? 0;
    final xpNext = thresholds[_currentLevel + 1] ?? (xpStart + 10000);
    final gained = _totalXp - xpStart;
    final needed = xpNext - xpStart;
    final progress = needed > 0 ? (gained / needed).clamp(0.0, 1.0) : 0.0;
    final toNext = xpNext - _totalXp;

    return Padding(
      padding: const EdgeInsets.fromLTRB(BldrSpacing.pageX, 16, BldrSpacing.pageX, 0),
      child: BldrGlassCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.profile_xp_bar_level(_currentLevel, _totalXp),
                    style: BldrText.body.copyWith(
                        color: BldrColors.goldBright, fontWeight: FontWeight.w600)),
                Text(AppLocalizations.of(context)!.profile_xp_bar_next_level(_currentLevel + 1, xpNext), style: BldrText.meta),
              ],
            ),
            const SizedBox(height: 10),
            BldrProgressBar(value: progress, gradient: true),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context)!.profile_xp_bar_to_next(toNext), style: BldrText.meta),
            ),
          ],
        ),
      ),
    );
  }

  /// PF4 — grid 2×2, ordem: Treinos totais, Horas treinadas, Streak atual,
  /// Conquistas.
  Widget _buildStatsGrid() {
    final horasLabel = _horasTreinadas > 0 ? '${_horasTreinadas}h' : '0h';
    final stats = [
      {'icon': Icons.fitness_center, 'value': '$_totalWorkouts', 'label': AppLocalizations.of(context)!.profile_stat_total_workouts},
      {'icon': Icons.timer_outlined, 'value': horasLabel, 'label': AppLocalizations.of(context)!.profile_stat_hours_trained},
      {'icon': Icons.local_fire_department, 'value': '$_currentStreak', 'label': AppLocalizations.of(context)!.profile_stat_current_streak},
      {'icon': Icons.military_tech, 'value': '$_totalAchievements', 'label': AppLocalizations.of(context)!.profile_stat_achievements},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(BldrSpacing.pageX, 12, BldrSpacing.pageX, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
        children: stats.map((s) {
          return BldrGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(s['icon'] as IconData, color: BldrColors.goldBright, size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s['value'] as String, style: BldrText.cardTitleLg),
                    Text(s['label'] as String, style: BldrText.meta),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// PF5 — carrossel de badges: todas as 34 conquistas do catálogo,
  /// 2 linhas × 5 colunas por página (10/página → 4 páginas para 34).
  Widget _buildBadgesGrid() {
    const kCols = 5;
    const kRows = 2;
    const kPerPage = kCols * kRows;

    final items = _achievementCatalog.isNotEmpty
        ? _achievementCatalog
        : List.generate(10, (_) => <String, dynamic>{});

    final pageCount = (items.length / kPerPage).ceil().clamp(1, 999);

    return Padding(
      padding: const EdgeInsets.fromLTRB(BldrSpacing.pageX, 12, BldrSpacing.pageX, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.profile_badges_section, style: BldrText.label),
              Text(
                '$_totalAchievements/${items.isEmpty ? '?' : items.length}',
                style: BldrText.metaSm.copyWith(color: BldrColors.goldBright),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const kSpacing = 8.0;
              final cellSize = (constraints.maxWidth - (kCols - 1) * kSpacing) / kCols;
              final pageHeight = cellSize * kRows + (kRows - 1) * kSpacing;
              return SizedBox(
                height: pageHeight,
                child: PageView.builder(
              itemCount: pageCount,
              onPageChanged: (p) => setState(() => _badgesPage = p),
              itemBuilder: (_, page) {
                final start = page * kPerPage;
                final end   = (start + kPerPage).clamp(0, items.length);
                final pageItems = items.sublist(start, end);

                return GridView.count(
                  crossAxisCount: kCols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: pageItems.map((b) {
                    final name     = b['name']      as String? ?? '';
                    final iconName = b['icon_name'] as String? ?? '';
                    final unlocked = _unlockedAchievementNames.contains(name);
                    return _buildBadgeCell(iconName, name, unlocked);
                  }).toList(),
                );
              },
            ),
              );
            },
          ),
          if (pageCount > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (i) {
                final active = i == _badgesPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  active ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: active ? BldrColors.goldBright : BldrColors.track,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  // F10 — "Próxima conquista": busca a conquista não obtida com maior %
  // de progresso usando dados já carregados na tela (sem nova query).
  Widget _buildNextAchievement() {
    final locked = _achievementCatalog
        .where((a) => !_unlockedAchievementNames.contains(a['name'] as String?))
        .toList();

    if (locked.isEmpty) return const SizedBox.shrink();

    // Calcula current_value para os critérios disponíveis nesta tela
    int _currentFor(String? type) => switch (type) {
          'workout_count' => _totalWorkouts,
          'consecutive_days' => _currentStreak,
          'bldr_streak_days' => _currentStreak,
          _ => 0,
        };

    String _criteriaLabel(String? type, num? value, int current) {
      final l10n = AppLocalizations.of(context)!;
      final remaining = (value?.toInt() ?? 1) - current;
      if (remaining <= 0) return l10n.profile_achievement_almost;
      return switch (type) {
        'workout_count' => remaining == 1
            ? l10n.profile_achievement_do_workout_singular(remaining)
            : l10n.profile_achievement_do_workout_plural(remaining),
        'consecutive_days' ||
        'bldr_streak_days' => remaining == 1
            ? l10n.profile_achievement_maintain_streak_singular(remaining)
            : l10n.profile_achievement_maintain_streak_plural(remaining),
        'calorie_goal_reached' ||
        'calorie_goal_reached_consecutive_days' => remaining == 1
            ? l10n.profile_achievement_calorie_goal_singular(remaining)
            : l10n.profile_achievement_calorie_goal_plural(remaining),
        'meal_logged' => remaining == 1
            ? l10n.profile_achievement_log_meal_singular(remaining)
            : l10n.profile_achievement_log_meal_plural(remaining),
        'total_xp' => l10n.profile_achievement_earn_xp(remaining),
        'club_level' => l10n.profile_achievement_reach_level(value?.toInt() ?? 0),
        'bldr_workout_total' => remaining == 1
            ? l10n.profile_achievement_complete_workout_singular(remaining)
            : l10n.profile_achievement_complete_workout_plural(remaining),
        _ => l10n.profile_achievement_keep_going,
      };
    }

    // Ordena por % de progresso descrescente — maior % = mais próxima
    Map<String, dynamic>? best;
    double bestRatio = -1;

    for (final a in locked) {
      final type = a['criteria_type'] as String?;
      final value = (a['criteria_value'] as num?)?.toDouble() ?? 1.0;
      final current = _currentFor(type).toDouble();
      // Só considera conquistas com critério mapeável
      if (current == 0 && type != 'workout_count' && type != 'consecutive_days' && type != 'bldr_streak_days') continue;
      final ratio = value > 0 ? (current / value).clamp(0.0, 0.99) : 0.0;
      if (ratio > bestRatio) {
        bestRatio = ratio;
        best = a;
      }
    }

    if (best == null) return const SizedBox.shrink();

    final name = best['name'] as String? ?? '';
    final type = best['criteria_type'] as String?;
    final value = best['criteria_value'] as num?;
    final current = _currentFor(type);
    final criteriaText = _criteriaLabel(type, value, current);
    final pct = (bestRatio * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: BldrGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.emoji_events_outlined,
                  color: BldrColors.goldBright, size: 15),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context)!.profile_next_achievement, style: BldrText.label),
              const Spacer(),
              Text('$pct%',
                  style: BldrText.metaSm
                      .copyWith(color: BldrColors.goldBright, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Text(name,
                style: BldrText.cardTitle
                    .copyWith(color: BldrColors.textPrimary)),
            const SizedBox(height: 2),
            Text(criteriaText, style: BldrText.meta),
            const SizedBox(height: 8),
            BldrProgressBar(value: bestRatio, gradient: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCell(String iconName, String label, bool unlocked) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? BldrColors.goldTint : BldrColors.surfaceInset,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: unlocked ? BldrColors.goldBorder : BldrColors.borderSubtle,
        ),
      ),
      child: unlocked
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AchievementBadge(iconName: iconName, unlocked: true, size: 22),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: BldrText.metaSm.copyWith(fontSize: 8),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : const Center(
              child: Icon(Icons.lock, color: BldrColors.textMuted, size: 18),
            ),
    );
  }

  // ── "Seu progresso" — teaser para a tela de Progresso completa ──────────

  Widget _buildProgressTeaser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.profile_progress_section, style: BldrText.label),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.progressScreen),
              behavior: HitTestBehavior.opaque,
              child: Text(AppLocalizations.of(context)!.profile_see_all, style: BldrText.buttonSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BldrGlassCard(
          onTap: () => Navigator.pushNamed(context, AppRoutes.progressScreen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.profile_weight_card_title, style: BldrText.meta),
                        const SizedBox(height: 4),
                        Text(
                          _weightLatest != null
                              ? '${_weightLatest!.toStringAsFixed(1)} kg'
                              : '—',
                          style: BldrText.kpiSm,
                        ),
                      ],
                    ),
                  ),
                  if (_weightChange != null && _weightChange != 0)
                    Text(
                      '${_weightChange! > 0 ? '+' : ''}${_weightChange!.toStringAsFixed(1)} kg',
                      style: BldrText.body.copyWith(
                          color: BldrColors.goldBright, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: _weightLoading
                    ? const SizedBox.shrink()
                    : (_weightSeries.length < 2
                        ? const SizedBox.shrink()
                        : _buildWeightSparkline()),
              ),
              const SizedBox(height: 16),
              const Divider(color: BldrColors.borderSubtle, height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _teaserStat('$_totalWorkouts', AppLocalizations.of(context)!.profile_stat_total_workouts),
                  ),
                  Expanded(
                    child: _teaserStat('${_horasTreinadas}h', AppLocalizations.of(context)!.profile_stat_total_time),
                  ),
                  Expanded(
                    child: _teaserStat('$_totalAchievements', AppLocalizations.of(context)!.profile_stat_achievements),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSparkline() {
    final spots = _weightSeries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final values = _weightSeries;
    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: BldrColors.goldBright,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _teaserStat(String value, String label) => Column(
        children: [
          Text(value, style: BldrText.cardTitle),
          const SizedBox(height: 2),
          Text(label, style: BldrText.metaSm, textAlign: TextAlign.center),
        ],
      );

  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: Center(child: CircularProgressIndicator(color: BldrColors.goldBright)),
      );
    }

    if (_error != null || _userProfile == null) {
      return Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: BldrColors.danger, size: 48),
              const SizedBox(height: 16),
              Text(_error ?? AppLocalizations.of(context)!.profile_error,
                  style: BldrText.body, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              BldrPrimaryButton(
                  label: AppLocalizations.of(context)!.common_retry, onPressed: _loadUserProfile),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      body: BldrBackground(
        child: SafeArea(
          child: Column(
            children: [
              // PF8 — engrenagem → Configurações + Compartilhar, ao lado do
              // título.
              Padding(
                padding: const EdgeInsets.fromLTRB(BldrSpacing.pageX, 8, BldrSpacing.pageX, 0),
                child: Row(
                  children: [
                    Text(AppLocalizations.of(context)!.profile_title, style: BldrText.screenTitle),
                    const Spacer(),
                    BldrCircleButton(
                      icon: Icons.settings_outlined,
                      size: 36,
                      filled: false,
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.settingsScreen),
                    ),
                    const SizedBox(width: 8),
                    BldrCircleButton(
                      icon: Icons.ios_share,
                      size: 36,
                      filled: false,
                      onPressed: () async {
                        try {
                          await Share.share(
                            '${AppLocalizations.of(context)!.profile_sign_in_message}\n\n'
                            '👤 ${_userProfile!.fullName}\n'
                            '⭐ Nível $_currentLevel • ${_totalXp} XP\n'
                            '🏆 #$_rankPosition no ranking',
                            subject: 'Perfil BLDR de ${_userProfile!.fullName}',
                          );
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildIdentityBlock(),
                      _buildXpBar(),
                      _buildStatsGrid(),
                      _buildBadgesGrid(),
                      _buildNextAchievement(),
                      const SizedBox(height: 22),
                      _buildProgressTeaser(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
