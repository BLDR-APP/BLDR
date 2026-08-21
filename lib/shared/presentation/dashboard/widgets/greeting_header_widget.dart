import 'package:flutter/material.dart';

import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/models/user_profile.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_sheet.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/services/user_service.dart';

class GreetingHeaderWidget extends StatefulWidget {
  const GreetingHeaderWidget({Key? key}) : super(key: key);

  @override
  State<GreetingHeaderWidget> createState() => _GreetingHeaderWidgetState();
}

class _GreetingHeaderWidgetState extends State<GreetingHeaderWidget> {
  UserProfile? userProfile;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      if (!getIt<AuthRepository>().isAuthenticated) {
        if (mounted) setState(() { isLoading = false; hasError = false; });
        return;
      }
      final profile = await UserService.instance.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          userProfile = profile;
          isLoading = false;
          hasError = false;
        });
      }
    } catch (error) {
      debugPrint('Error loading user profile: $error');
      if (mounted) setState(() { isLoading = false; hasError = true; });
    }
  }

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.dashboard_greeting_morning;
    if (hour < 17) return l10n.dashboard_greeting_afternoon;
    return l10n.dashboard_greeting_evening;
  }

  // Preservada: D1 não tem slot para a frase, mas a lógica continua aqui
  // para quando um slot voltar. Não é dado — é string gerada localmente.
  // ignore: unused_element
  String _getMotivationalMessage() {
    final messages = [
      'Pronto para bater suas metas?',
      'Faça o dia de hoje valer!',
      'Hora de construir sua melhor versão!',
      'Pronto para mais um dia de força total?',
    ];
    return messages[DateTime.now().day % messages.length];
  }

  String _getDisplayName(AppLocalizations l10n) {
    if (isLoading) return l10n.common_loading;
    if (!getIt<AuthRepository>().isAuthenticated) return l10n.dashboard_guest_user;
    if (hasError || userProfile == null) {
      return getIt<AuthRepository>().currentUser?.email?.split('@')[0] ?? 'User';
    }
    return userProfile!.fullName.isNotEmpty
        ? userProfile!.fullName
        : getIt<AuthRepository>().currentUser?.email?.split('@')[0] ?? 'User';
  }

  String _getInitials() {
    if (isLoading) return '...';
    if (!getIt<AuthRepository>().isAuthenticated) return 'G';
    if (hasError || userProfile == null) {
      return getIt<AuthRepository>().currentUser?.email?[0].toUpperCase() ?? 'U';
    }
    return userProfile!.fullName.isNotEmpty
        ? userProfile!.fullName[0].toUpperCase()
        : getIt<AuthRepository>().currentUser?.email?[0].toUpperCase() ?? 'U';
  }

  /// D1 — header compacto: saudação + nome + avatar circular.
  ///
  /// A mensagem motivacional e o chip de streak saíram daqui: o streak virou
  /// chip da fileira D3 (TodayMetricsWidget), com a mesma consulta.
  /// `_getMotivationalMessage()` continua aqui, sem slot no D1.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authenticated = getIt<AuthRepository>().isAuthenticated;
    final avatarUrl = userProfile?.avatarUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BldrSpacing.pageX,
        18,
        BldrSpacing.pageX,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dinâmico: hora do dispositivo.
                Text(_getGreeting(l10n), style: BldrText.label),
                const SizedBox(height: 3),
                Text(
                  _getDisplayName(l10n),
                  style: BldrText.screenTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          HavokEntryIcon(onTap: () => showHavokSheet(context, originScreen: 'dashboard')),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BldrColors.goldTint,
              border: Border.all(color: BldrColors.goldBorder, width: 1),
              image: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    authenticated ? _getInitials() : 'G',
                    style: BldrText.cardTitle.copyWith(
                      color: BldrColors.goldBright,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
