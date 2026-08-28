import 'dart:io';
import 'package:bldr_fitness/l10n/app_localizations.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart' as subUc;
import 'package:bldr_fitness/models/subscription_plan.dart';
import 'package:bldr_fitness/models/user_profile.dart';
import 'package:bldr_fitness/services/auth_service.dart';
import 'package:bldr_fitness/services/push_notification_service.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/features/integrations/data/health_kit_service.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/whoop_entities.dart';
import 'package:bldr_fitness/features/integrations/domain/usecases/whoop_usecases.dart';
import 'package:bldr_fitness/features/integrations/presentation/whoop_connect_screen.dart';
import 'package:bldr_fitness/features/profile/presentation/profile_drawer/widgets/confirmation_dialog_widget.dart';
import 'package:bldr_fitness/features/profile/presentation/profile_drawer/widgets/edit_profile_dialog_widget.dart';
import 'package:bldr_fitness/features/profile/presentation/goals_screen.dart';
import 'package:bldr_fitness/features/profile/presentation/privacy_screen.dart';
import 'package:bldr_fitness/features/profile/presentation/widgets/language_selector_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bldr_fitness/routes/app_routes.dart';

/// Tela de Configurações — recebe o conteúdo que saiu do Perfil (PF9):
/// Editar Perfil, Plano/Assinatura, Refazer Onboarding, Notificação, Sair,
/// Excluir Conta. Mesma funcionalidade de `profile_screen.dart`, só
/// reorganizada visualmente em grupos (DESIGN_SYSTEM 7.8) — este arquivo não
/// tem controller compartilhado com o Perfil (dívida já registrada no
/// INVENTARIO.md), então a lógica de carregamento/ação é replicada aqui com
/// as mesmas chamadas de use case/serviço, não reinventada.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _userProfile;
  UserSubscription? _userSubscription;
  bool _isLoading = true;

  bool _notificationsEnabled = false;
  bool _isTogglingNotifications = false;

  String? _appVersion;

  WhoopConnection? _whoopConnection;
  bool _whoopLoading = false;

  bool _healthKitAuthorized = false;
  bool _healthKitLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAppVersion();
    _loadWhoopConnection();
    _loadHealthKitStatus();
  }

  Future<void> _loadHealthKitStatus() async {
    if (!Platform.isIOS) return;
    final authorized = await getIt<HealthKitService>().isAuthorized();
    if (mounted) setState(() => _healthKitAuthorized = authorized);
  }

  Future<void> _connectHealthKit() async {
    setState(() => _healthKitLoading = true);
    final granted = await getIt<HealthKitService>().requestPermission();
    if (mounted) setState(() {
      _healthKitAuthorized = granted;
      _healthKitLoading = false;
    });
  }

  Future<void> _loadWhoopConnection() async {
    final result = await getIt<GetWhoopConnection>()();
    if (mounted) setState(() => _whoopConnection = result.valueOrNull);
  }

  Future<void> _disconnectWhoop() async {
    setState(() => _whoopLoading = true);
    await getIt<DisconnectWhoop>()();
    if (mounted) setState(() {
      _whoopConnection = null;
      _whoopLoading = false;
    });
  }

  Future<void> _openWhoopConnect() async {
    final connected = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WhoopConnectScreen()),
    );
    if (connected == true) _loadWhoopConnection();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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

  // ── Editar perfil (mesma lógica de profile_screen.dart) ─────────────────

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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Perfil atualizado com sucesso!'),
                  backgroundColor: AppTheme.successGreen));
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(AppLocalizations.of(context)!.profile_update_error('$e')),
                backgroundColor: AppTheme.errorRed));
          }
        },
      ),
    );
  }

  void _shareProfile() async {
    try {
      final name = _userProfile?.fullName ?? '';
      await Share.share(
        'Confira meu perfil do BLDR!\n\nJunte-se à comunidade BLDR CLUB!',
        subject: 'Perfil BLDR de $name',
      );
    } catch (_) {}
  }

  // ── Plano e assinatura (mesma lógica de profile_screen.dart) ────────────

  void _navigateToCheckout(SubscriptionPlan plan) {
    Navigator.pushNamed(
      context,
      AppRoutes.checkoutScreen,
      arguments: {'plan': plan, 'billingPeriod': 'monthly'},
    );
  }

  void _showPlanUpgradeDialog() async {
    try {
      final plans = (await getIt<subUc.GetSubscriptionPlans>()())
          .fold(onSuccess: (p) => p, onFailure: (f) => throw Exception(f.message));

      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.dialogDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 2.h),
                Text('Escolha seu Plano',
                    style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                SizedBox(height: 1.h),
                Text('Desbloqueie todo o potencial do BLDR',
                    style: AppTheme.darkTheme.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center),
                SizedBox(height: 3.h),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      final isCurrentPlan = _userSubscription?.planId == plan.id;
                      return Container(
                        margin: EdgeInsets.only(bottom: 3.h),
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: plan.isPopular
                                ? AppTheme.accentGold
                                : AppTheme.dividerGray,
                            width: plan.isPopular ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(plan.name,
                                    style: AppTheme.darkTheme.textTheme.titleLarge
                                        ?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w700)),
                                if (plan.isPopular)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 3.w, vertical: 0.5.h),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('POPULAR',
                                        style: AppTheme
                                            .darkTheme.textTheme.labelSmall
                                            ?.copyWith(
                                                color: AppTheme.primaryBlack,
                                                fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            Text(plan.description,
                                style: AppTheme.darkTheme.textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary)),
                            SizedBox(height: 2.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(plan.monthlyPriceText,
                                    style: AppTheme
                                        .darkTheme.textTheme.headlineSmall
                                        ?.copyWith(
                                            color: AppTheme.accentGold,
                                            fontWeight: FontWeight.w700)),
                                SizedBox(width: 2.w),
                                Text('ou ${plan.annualPriceText}',
                                    style: AppTheme.darkTheme.textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.textSecondary)),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            ...plan.features.map((feature) => Padding(
                                  padding: EdgeInsets.only(bottom: 1.h),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: AppTheme.successGreen, size: 4.w),
                                      SizedBox(width: 2.w),
                                      Expanded(
                                        child: Text(feature,
                                            style: AppTheme
                                                .darkTheme.textTheme.bodyMedium
                                                ?.copyWith(
                                                    color: AppTheme.textPrimary)),
                                      ),
                                    ],
                                  ),
                                )),
                            SizedBox(height: 2.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isCurrentPlan
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                        _navigateToCheckout(plan);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCurrentPlan
                                      ? AppTheme.inactiveGray
                                      : AppTheme.accentGold,
                                  padding: EdgeInsets.symmetric(vertical: 2.h),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  isCurrentPlan ? AppLocalizations.of(context)!.profile_plan_current : AppLocalizations.of(context)!.profile_plan_choose_btn,
                                  style: AppTheme.darkTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: isCurrentPlan
                                        ? AppTheme.textSecondary
                                        : AppTheme.primaryBlack,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.settings_cancel_sub_error('$e')),
          backgroundColor: AppTheme.errorRed));
    }
  }

  void _showCancelSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        backgroundColor: AppTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const TextSpan(
                text: 'contato@bldrapp.com.br',
                style: TextStyle(
                    color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    AppLocalizations.of(context)!.profile_cancel_subscription_after),
          ],
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child:
                  Text(AppLocalizations.of(context)!.common_got_it_btn, style: const TextStyle(color: AppTheme.accentGold)),
            ),
          ),
        ],
      ),
    );
  }

  /// S3 — "Cancelar assinatura" migrou para dentro de "Gerenciar
  /// assinatura", não é mais uma linha própria em destaque.
  void _showManageSubscriptionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: BldrColors.textMuted,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.settings_manage_sub_sheet_title, style: BldrText.cardTitleLg),
              const SizedBox(height: 4),
              Text(_getCurrentPlanName(), style: BldrText.description),
              const SizedBox(height: 18),
              BldrSettingsGroup(children: [
                if (!_isPremium)
                  BldrSettingsRow(
                    icon: Icons.arrow_upward,
                    title: AppLocalizations.of(context)!.settings_upgrade_btn,
                    subtitle: AppLocalizations.of(context)!.settings_upgrade_subtitle,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showPlanUpgradeDialog();
                    },
                  ),
                if (_isClubMember)
                  BldrSettingsRow(
                    icon: Icons.cancel_outlined,
                    title: AppLocalizations.of(context)!.settings_cancel_sub_btn,
                    subtitle: AppLocalizations.of(context)!.settings_cancel_sub_subtitle,
                    // S2 — neutro, não vermelho (não é "excluir conta").
                    iconColor: const Color(0x8CFFFFFF),
                    titleColor: const Color(0x8CFFFFFF),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCancelSubscriptionDialog();
                    },
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Notificações ──────────────────────────────────────────────────────────

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

      await getIt<PushNotificationService>().syncTokenToProfile(enabled: newValue);

      final updatedProfile = await UserService.instance.getCurrentUserProfile();
      if (updatedProfile != null && mounted) {
        setState(() {
          _userProfile = updatedProfile;
          _notificationsEnabled = updatedProfile.notificationsEnabled ?? newValue;
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

  Future<void> _showPermissionDeniedDialog() {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.profile_permission_title,
            style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        content: Text(
          AppLocalizations.of(context)!.profile_permission_body,
          style: AppTheme.darkTheme.textTheme.bodyMedium
              ?.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.common_cancel, style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.primaryBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AppLocalizations.of(context)!.profile_open_settings_btn,
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Conta: sair / excluir (mesmos serviços de profile_screen.dart) ──────

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialogWidget(
        title: AppLocalizations.of(context)!.settings_sign_out_dialog_title,
        message: AppLocalizations.of(context)!.settings_sign_out_dialog_message,
        confirmText: AppLocalizations.of(context)!.settings_sign_out_dialog_confirm,
        // S2 — não é destrutivo, é só logout.
        isDestructive: false,
        onConfirm: () async {
          final navigator = Navigator.of(context, rootNavigator: true);
          Navigator.of(dialogContext).pop();
          try {
            await AuthService.instance.signOut();
            navigator.pushNamedAndRemoveUntil(AppRoutes.loginScreen, (route) => false);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AppLocalizations.of(context)!.settings_sign_out_error('$e')),
                  backgroundColor: AppTheme.errorRed));
            }
          }
        },
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialogWidget(
        title: AppLocalizations.of(context)!.settings_delete_account_dialog_title,
        message: AppLocalizations.of(context)!.settings_delete_account_dialog_message,
        confirmText: AppLocalizations.of(context)!.settings_delete_account_dialog_confirm,
        isDestructive: true,
        onConfirm: () async {
          final navigator = Navigator.of(context, rootNavigator: true);
          Navigator.of(dialogContext).pop();
          try {
            await AuthService.instance.deleteUserAccount();
            navigator.pushNamedAndRemoveUntil(AppRoutes.loginScreen, (route) => false);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AppLocalizations.of(context)!.settings_delete_account_error('$e')),
                  backgroundColor: AppTheme.errorRed));
            }
          }
        },
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      body: BldrBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: BldrColors.goldBright))
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: BldrSpacing.pageX),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _sectionLabel(l10n.settings_section_account),
                            BldrSettingsGroup(children: [
                              BldrSettingsRow(
                                icon: Icons.edit_outlined,
                                title: l10n.settings_edit_profile,
                                subtitle: l10n.settings_edit_profile_subtitle,
                                onTap: _showEditProfileDialog,
                              ),
                              BldrSettingsRow(
                                icon: Icons.ios_share,
                                title: l10n.settings_share_profile,
                                onTap: _shareProfile,
                              ),
                            ]),
                            const SizedBox(height: 22),

                            _sectionLabel(l10n.settings_section_plan),
                            BldrSettingsGroup(children: [
                              BldrSettingsRow(
                                icon: Icons.workspace_premium_outlined,
                                title: l10n.settings_current_plan_row,
                                subtitle: _getCurrentPlanName(),
                                trailing:
                                    _isClubMember ? const BldrBadge(label: 'BLDR CLUB') : null,
                              ),
                              BldrSettingsRow(
                                icon: Icons.credit_card_outlined,
                                title: l10n.settings_manage_subscription,
                                subtitle: l10n.settings_manage_subscription_subtitle,
                                onTap: _showManageSubscriptionSheet,
                              ),
                            ]),
                            const SizedBox(height: 22),

                            _sectionLabel(l10n.settings_section_workout),
                            BldrSettingsGroup(children: [
                              BldrSettingsRow(
                                icon: Icons.checklist_outlined,
                                title: l10n.settings_workout_preferences,
                                subtitle: l10n.settings_workout_preferences_subtitle,
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.onboardingFlow),
                              ),
                              BldrSettingsRow(
                                icon: Icons.flag_outlined,
                                title: l10n.settings_goals_row,
                                subtitle: l10n.settings_goals_subtitle,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const GoalsScreen())),
                              ),
                            ]),
                            const SizedBox(height: 22),

                            _sectionLabel(l10n.settings_section_app),
                            BldrSettingsGroup(children: [
                              BldrSettingsRow(
                                icon: Icons.notifications_outlined,
                                title: l10n.settings_notifications_row,
                                subtitle:
                                    _notificationsEnabled ? l10n.settings_notifications_enabled : l10n.settings_notifications_disabled,
                                trailing: _isTogglingNotifications
                                    ? const SizedBox(
                                        width: 40,
                                        height: 24,
                                        child: Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: BldrColors.goldBright),
                                          ),
                                        ),
                                      )
                                    : Switch(
                                        value: _notificationsEnabled,
                                        onChanged: _toggleNotifications,
                                        activeColor: BldrColors.goldBright,
                                      ),
                                onTap: _isTogglingNotifications
                                    ? null
                                    : () => _toggleNotifications(!_notificationsEnabled),
                              ),
                              BldrSettingsRow(
                                icon: Icons.language_outlined,
                                title: l10n.settings_language_row,
                                subtitle: l10n.settings_language_subtitle,
                                onTap: () => LanguageSelectorSheet.show(context),
                              ),
                              BldrSettingsRow(
                                icon: Icons.lock_outline,
                                title: l10n.settings_privacy_row,
                                subtitle: l10n.settings_privacy_subtitle,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                              ),
                            ]),
                            const SizedBox(height: 22),

                            // F12 — Integrações
                            _sectionLabel(l10n.settings_section_integrations),
                            BldrSettingsGroup(children: [
                              if (_whoopLoading)
                                const BldrSettingsRow(
                                  icon: Icons.watch_outlined,
                                  title: 'Whoop',
                                  trailing: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              else if (_whoopConnection?.isConnected == true)
                                BldrSettingsRow(
                                  icon: Icons.watch_outlined,
                                  title: 'Whoop',
                                  subtitle: l10n.settings_whoop_synced,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      BldrBadge(label: l10n.settings_whoop_connected_badge, gold: true),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: _disconnectWhoop,
                                        style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                        child: Text(
                                          l10n.settings_whoop_disconnect_btn,
                                          style: BldrText.meta.copyWith(
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                BldrSettingsRow(
                                  icon: Icons.watch_outlined,
                                  title: 'Whoop',
                                  subtitle: l10n.settings_whoop_connect_subtitle,
                                  onTap: _openWhoopConnect,
                                ),
                              if (Platform.isIOS)
                                if (_healthKitLoading)
                                  const BldrSettingsRow(
                                    icon: Icons.favorite_outline,
                                    title: 'Apple Health',
                                    trailing: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                else if (_healthKitAuthorized)
                                  BldrSettingsRow(
                                    icon: Icons.favorite_outline,
                                    title: 'Apple Health',
                                    subtitle: 'FC, calorias e treinos sincronizados',
                                    trailing: BldrBadge(label: l10n.settings_whoop_connected_badge, gold: true),
                                  )
                                else
                                  BldrSettingsRow(
                                    icon: Icons.favorite_outline,
                                    title: 'Apple Health',
                                    subtitle: 'Conecte para sincronizar FC e calorias',
                                    onTap: _connectHealthKit,
                                  ),
                              BldrSettingsRow(
                                icon: Icons.watch_rounded,
                                title: l10n.settings_watchables,
                                subtitle: l10n.settings_soon_badge,
                                disabled: true,
                                trailing: BldrBadge(label: l10n.settings_soon_badge, gold: false),
                              ),
                            ]),
                            const SizedBox(height: 22),

                            // F14 — Suporte e legal
                            _sectionLabel(l10n.settings_section_support),
                            BldrSettingsGroup(children: [
                              BldrSettingsRow(
                                icon: Icons.bug_report_outlined,
                                title: l10n.feedback_report_bug,
                                onTap: () => Navigator.of(context).pushNamed(
                                  AppRoutes.feedbackScreen,
                                  arguments: {'tipoInicial': 'bug'},
                                ),
                              ),
                              BldrSettingsRow(
                                icon: Icons.lightbulb_outline,
                                title: l10n.feedback_send_suggestion,
                                onTap: () => Navigator.of(context).pushNamed(
                                  AppRoutes.feedbackScreen,
                                  arguments: {'tipoInicial': 'sugestao'},
                                ),
                              ),
                              BldrSettingsRow(
                                icon: Icons.help_outline,
                                title: l10n.settings_help_center,
                                subtitle: 'suporte@bldrapp.com.br',
                                onTap: () async {
                                  final uri = Uri.parse('mailto:suporte@bldrapp.com.br');
                                  if (await canLaunchUrl(uri)) launchUrl(uri);
                                },
                              ),
                              BldrSettingsRow(
                                icon: Icons.description_outlined,
                                title: l10n.settings_terms,
                                onTap: () async {
                                  final uri = Uri.parse('https://www.bldrapp.com.br/termos');
                                  if (await canLaunchUrl(uri)) {
                                    launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                              BldrSettingsRow(
                                icon: Icons.privacy_tip_outlined,
                                title: l10n.settings_privacy_policy_row,
                                onTap: () async {
                                  final uri = Uri.parse('https://www.bldrapp.com.br/privacidade');
                                  if (await canLaunchUrl(uri)) {
                                    launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ]),
                            const SizedBox(height: 22),

                            _sectionLabel(l10n.settings_section_about),
                            BldrSettingsGroup(children: [
                              BldrSettingsRow(
                                icon: Icons.info_outline,
                                title: l10n.settings_version_row,
                                subtitle: _appVersion ?? '—',
                                onTap: null,
                              ),
                              const BldrSettingsRow(
                                icon: Icons.bolt,
                                title: 'BLDR',
                                subtitle: '© ${2026} BLDR Fitness. Todos os direitos reservados.',
                                onTap: null,
                              ),
                            ]),
                            const SizedBox(height: 22),

                            // Grupo final sem título — Sair/Excluir conta.
                            BldrSettingsGroup(children: [
                              BldrSettingsRow(
                                icon: Icons.logout,
                                title: l10n.settings_sign_out_row,
                                // S2 — neutro, não vermelho.
                                iconColor: const Color(0x8CFFFFFF),
                                titleColor: const Color(0x8CFFFFFF),
                                onTap: _confirmSignOut,
                              ),
                              BldrSettingsRow(
                                icon: Icons.delete_outline,
                                title: l10n.settings_delete_account_row,
                                // S2 — a ÚNICA linha da tela com danger.
                                iconColor: BldrColors.danger,
                                titleColor: BldrColors.danger,
                                onTap: _confirmDeleteAccount,
                              ),
                            ]),

                            const SizedBox(height: 28),
                            Center(
                              child: Text(
                                _appVersion != null
                                    ? l10n.settings_version_footer(_appVersion!)
                                    : 'BLDR',
                                style: BldrText.metaSm,
                              ),
                            ),
                            const SizedBox(height: 32),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(BldrSpacing.pageX, 12, BldrSpacing.pageX, 4),
      child: Row(
        children: [
          BldrCircleButton(
            icon: Icons.chevron_left,
            size: 36,
            filled: false,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(AppLocalizations.of(context)!.settings_title, style: BldrText.cardTitleLg),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label, style: BldrText.label),
      );
}
