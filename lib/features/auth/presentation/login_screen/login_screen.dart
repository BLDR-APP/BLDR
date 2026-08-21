import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/auth_failures.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/services/user_service.dart'; // <<< Import Mantido
// -- INÍCIO DA ALTERAÇÃO: NOVOS IMPORTS --
import 'package:bldr_fitness/features/professional_portal/presentation/screens/professional_login_screen.dart';
import 'package:bldr_fitness/features/professional_portal/presentation/screens/professional_register_screen.dart';
// -- FIM DA ALTERAÇÃO --
import 'package:bldr_fitness/features/auth/presentation/login_screen/widgets/login_form_widget.dart';
import 'package:bldr_fitness/features/auth/presentation/login_screen/widgets/video_background_widget.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String _errorMessage = '';

  // --- MODIFICADO: Função _handleLogin (Ajuste no try/catch) ---
  Future<void> _handleLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 1. Tenta fazer login (o repository já traduz os erros para pt-BR)
    final result = await getIt<SignIn>()(email: email, password: password);
    final failure = result.failureOrNull;

    if (failure != null) {
      if (!mounted) return;

      // E-mail não confirmado -> tela de espera (a próxima tela explica)
      if (failure is EmailNotConfirmedFailure) {
        Navigator.pushReplacementNamed(
            context, AppRoutes.waitForConfirmationScreen);
        setState(() => _isLoading = false);
        HapticFeedback.lightImpact();
        return;
      }

      setState(() {
        _errorMessage = AppLocalizations.of(context).login_error(failure.message);
        _isLoading = false;
      });
      HapticFeedback.lightImpact();
      return;
    }

    HapticFeedback.mediumImpact();

    // 2. Verifica se o onboarding JÁ foi completado (lógica original)
    final bool hasCompletedOnboarding =
        await getIt<UserService>().hasCompletedOnboarding();

    if (!mounted) return;

    if (hasCompletedOnboarding) {
      // --- Verifica a VERSÃO se já completou ---
      // A versão esperada vem de kCurrentOnboardingVersion (onboarding_constants.dart).
      // shouldRedoOnboarding() redireciona se a versão salva for menor que a atual.
      final savedVersion = await getIt<UserService>().getOnboardingVersion();

      if (!mounted) return;

      // Navega baseado na versão
      if (!shouldRedoOnboarding(savedVersion)) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
      }
    } else {
      // Se onboarding NÃO foi completado, vai para o onboarding (lógica original)
      Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
    }
  }
  // --- FIM DA MODIFICAÇÃO ---


  void _navigateToSignUp() {
    Navigator.pushNamed(context, AppRoutes.signUpScreen); // Ajustado para usar AppRoutes
  }

  // --- NOVO MÉTODO PARA O DIÁLOGO ---
  void _showProfessionalOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Acesso Profissional'),
          content: const Text('Você já possui uma conta profissional?'),
          actions: <Widget>[
            TextButton(child: const Text('Cadastrar'), onPressed: () { Navigator.of(dialogContext).pop(); Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfessionalRegisterScreen())); }),
            TextButton(child: const Text('Entrar'), onPressed: () { Navigator.of(dialogContext).pop(); Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfessionalLoginScreen())); }),
          ],
        );
      },
    );
  }
  // --- FIM ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: VideoBackgroundWidget(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min, // Ajustado para evitar overflow
                      children: [
                        SizedBox(height: 15.h), // Reduzido espaço superior
                        // Mensagem de erro (se houver)
                        if (_errorMessage.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
                            margin: EdgeInsets.only(bottom: 2.h),
                            decoration: BoxDecoration(
                                color: AppTheme.errorRed.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.errorRed.withOpacity(0.5))
                            ),
                            child: Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.errorRed, fontWeight: FontWeight.w500),
                            ),
                          ),
                        // Formulário de Login
                        LoginFormWidget(
                          onLogin: _handleLogin,
                          isLoading: _isLoading,
                        ),
                        SizedBox(height: 3.h), // Espaço ajustado
                      /*
                        // Botões "Sou Personal" / "Sou Nutricionista"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () => _showProfessionalOptions(context),
                              child: Text('Sou Personal', style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: Colors.white70, decoration: TextDecoration.underline, decorationColor: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () => _showProfessionalOptions(context),
                              child: Text('Sou Nutricionista', style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: Colors.white70, decoration: TextDecoration.underline, decorationColor: Colors.white70)),
                            ),
                          ],
                        ),
                        */
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}