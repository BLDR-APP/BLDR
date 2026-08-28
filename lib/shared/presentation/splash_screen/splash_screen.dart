import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/features/app_version/domain/app_version_repository.dart';
import 'package:bldr_fitness/widgets/force_update_dialog.dart';
import 'package:bldr_fitness/features/auth/presentation/login_screen/login_screen.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/dashboard.dart';
import 'package:bldr_fitness/shared/presentation/onboarding_flow/onboarding_flow.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _screenFadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // 1. Entrada da Logo
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 2. Pulso de "Respiração" (Loop)
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // 1.5s por ciclo completo
      vsync: this,
    );

    // 3. Saída da Tela
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Animação de 0.0 a 1.0 para controlar a intensidade da cor
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _screenFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _logoAnimationController.forward();
    // Inicia o loop de pulso (vai e volta)
    _pulseAnimationController.repeat(reverse: true);
  }

  Future<void> _initializeApp() async {
    try {
      final initTasks = Future.wait([
        _checkAuthenticationStatus(),
        _loadUserPreferences(),
        _fetchEssentialConfig(),
        _prepareCachedData(),
      ]);

      // Tempo mínimo para transição suave.
      await Future.wait([
        initTasks,
        Future.delayed(const Duration(milliseconds: 300)),
      ]);

      setState(() {
        _isInitialized = true;
      });

      if (!mounted) return;

      final needsUpdate =
          (await getIt<ShouldForceUpdate>()()).valueOrNull ?? false;
      if (!mounted) return;

      if (needsUpdate) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const ForceUpdateDialog(),
        );
        return;
      }

      await _navigateToNextScreen();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'init_error';
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _hasError) {
          _showRetryOption();
        }
      });
    }
  }

  // --- MÉTODOS SIMULADOS MANTIDOS ---
  Future<void> _checkAuthenticationStatus() async { await Future.delayed(const Duration(milliseconds: 500)); }
  Future<void> _loadUserPreferences() async { await Future.delayed(const Duration(milliseconds: 300)); }
  Future<void> _fetchEssentialConfig() async { await Future.delayed(const Duration(milliseconds: 400)); }
  Future<void> _prepareCachedData() async { await Future.delayed(const Duration(milliseconds: 600)); }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      await _fadeAnimationController.forward();
      if (!mounted) return;
      _pushFade(const LoginScreen());
      return;
    }

    try {
      final client = Supabase.instance.client;
      final userProfile = await client
          .from('user_profiles')
          .select('onboarding_completed')
          .eq('id', session.user.id)
          .maybeSingle();

      await _fadeAnimationController.forward();
      if (!mounted) return;

      if (userProfile != null && userProfile['onboarding_completed'] == true) {
        _pushFade(const Dashboard());
      } else {
        _pushFade(const OnboardingFlow());
      }
    } catch (e) {
      if (!mounted) return;
      _pushFade(const LoginScreen());
    }
  }

  void _pushFade(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _showRetryOption() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkTheme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Text(AppLocalizations.of(context).splash_connection_error_title, style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary)),
          content: Text(AppLocalizations.of(context).splash_init_error_msg, style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryInitialization();
              },
              child: Text(AppLocalizations.of(context).splash_retry_btn, style: TextStyle(color: AppTheme.accentGold)),
            ),
          ],
        );
      },
    );
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _isInitialized = false;
      _errorMessage = '';
    });
    _logoAnimationController.reset();
    _pulseAnimationController.reset();
    _fadeAnimationController.reset();
    _logoAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
    _initializeApp();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: FadeTransition(
        opacity: _screenFadeAnimation,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.surfaceDark,
                      AppTheme.primaryBlack,
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _logoAnimationController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _logoFadeAnimation,
                            child: ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: _buildInternalPulseLogo(),
                            ),
                          );
                        },
                      ),
                      if (_hasError) ...[
                        SizedBox(height: 8.h),
                        _buildErrorState(),
                      ],
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

  // 👇 NOVA FUNÇÃO: Pulso Interno Estrito (Sem Blur, Sem Cores Externas)
  Widget _buildInternalPulseLogo() {
    // 1. A Cor Exata da Marca
    final Color brandGold = const Color(0xFFD4AF37);

    // 2. A Cor da Marca "Ofuscada" (Misturada com preto, 40% mais escura)
    // Isso cria o efeito de "apagar" sem mudar a tonalidade original
    final Color dimmedGold = Color.lerp(brandGold, Colors.black, 0.45)!;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Text(
          'BLDR',
          style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: Color.lerp(dimmedGold, brandGold, _pulseAnimation.value),
            shadows: [],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        CustomIconWidget(iconName: 'error_outline', color: AppTheme.errorRed, size: 8.w),
        SizedBox(height: 2.h),
        Text(AppLocalizations.of(context).splash_connection_failed, style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(color: AppTheme.errorRed, fontWeight: FontWeight.w500)),
        SizedBox(height: 1.h),
        Text(AppLocalizations.of(context).splash_retry_shortly, style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }
}