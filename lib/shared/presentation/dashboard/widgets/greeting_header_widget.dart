import 'package:flutter/material.dart';

import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/models/user_profile.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
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

  /// Header v2 (Figma 57:388 · "01 — HEADER"): saudação 13/500, nome do
  /// usuário 31/700 (o "BLDR" do mockup simula o `fullName`) e avatar de 36.
  /// O ícone do HAVOK saiu daqui e foi para a navbar v2 (decisão 3).
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authenticated = getIt<AuthRepository>().isAuthenticated;
    final avatarUrl = userProfile?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final pageX = BldrSpacingV2.pageX(MediaQuery.sizeOf(context).width);

    return Padding(
      padding: EdgeInsets.fromLTRB(pageX, 4, pageX, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dinâmico: hora do dispositivo.
                Text(_getGreeting(l10n), style: BldrTextV2.greeting),
                const SizedBox(height: 7),
                Text(
                  _getDisplayName(l10n),
                  style: BldrTextV2.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BldrColorsV2.avatarBg,
                border: Border.all(color: BldrColorsV2.avatarBorder),
                image: hasAvatar
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: hasAvatar
                  ? null
                  : Text(
                      authenticated ? _getInitials() : 'G',
                      style: BldrTextV2.avatarInitial,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
