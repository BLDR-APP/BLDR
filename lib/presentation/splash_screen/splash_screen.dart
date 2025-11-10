import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <<< ADICIONADO: Import do Supabase

import '../../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _screenFadeAnimation;

  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo scale and fade animation
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Screen fade animation for transition
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _screenFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start logo animation immediately
    _logoAnimationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate critical app initialization tasks
      // O Supabase já é inicializado no main.dart,
      // então esta função apenas garante que os dados carreguem
      await Future.wait([
        _checkAuthenticationStatus(),
        _loadUserPreferences(),
        _fetchEssentialConfig(),
        _prepareCachedData(),
      ]);

      setState(() {
        _isInitialized = true;
      });

      // Wait for minimum splash duration
      await Future.delayed(const Duration(milliseconds: 3000));

      if (mounted) {
        await _navigateToNextScreen();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize app. Please try again.';
      });

      // Show retry option after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _hasError) {
          _showRetryOption();
        }
      });
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    // 💡 IMPORTANTE: Esta função é mantida, mas é aqui que o Supabase lê a sessão
    // Atraso para dar tempo ao Supabase de ler o token cacheado
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _loadUserPreferences() async {
    // Simulate loading user preferences
    await Future.delayed(const Duration(milliseconds: 300));
    // In real implementation, load from SharedPreferences
  }

  Future<void> _fetchEssentialConfig() async {
    // Simulate fetching essential configuration
    await Future.delayed(const Duration(milliseconds: 400));
    // In real implementation, make API call for app config
  }

  Future<void> _prepareCachedData() async {
    // Simulate preparing cached data
    await Future.delayed(const Duration(milliseconds: 600));
    // In real implementation, prepare local database or cache
  }

  Future<void> _navigateToNextScreen() async {
    // Mantém o delay para que a tela de splash seja visível
    await Future.delayed(const Duration(seconds: 2));

    final session = Supabase.instance.client.auth.currentSession;
    final isAuthenticated = session != null;

    if (!mounted) return;

    if (!isAuthenticated) {
      // 1. Não Autenticado: Redireciona para o Login
      Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
      return;
    }

    // 2. Autenticado: Checa se o Perfil de Usuário existe (Se o Onboarding foi concluído)
    try {
      final client = Supabase.instance.client;
      final userId = session!.user.id;

      // Adapte o nome da tabela ('user_profiles') e o campo de ID conforme seu projeto
      final userProfile = await client
          .from('user_profiles')
          .select('id') // Buscamos apenas o ID para checar a existência
          .eq('id', userId)
          .maybeSingle(); // Retorna o primeiro registro ou nulo

      if (userProfile == null) {
        // Perfil não encontrado -> Redireciona para o Onboarding/Configuração de Perfil
        Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
      } else {
        // Perfil encontrado -> Redireciona para o Dashboard
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } catch (e) {
      // Em caso de erro (ex: falha de rede), faz um fallback para o Onboarding
      print('Erro ao verificar perfil: $e');
      Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
    }
  }

  void _showRetryOption() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Connection Error',
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            _errorMessage,
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryInitialization();
              },
              child: Text(
                'Retry',
                style: TextStyle(color: AppTheme.accentGold),
              ),
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

    // Reset animations
    _logoAnimationController.reset();
    _fadeAnimationController.reset();

    // Restart initialization
    _logoAnimationController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide status bar on Android, match brand color on iOS
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
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // Background with subtle gradient
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        AppTheme.primaryBlack,
                        AppTheme.surfaceDark,
                        AppTheme.primaryBlack,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated logo section
                      AnimatedBuilder(
                        animation: _logoAnimationController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _logoFadeAnimation,
                            child: ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: _buildLogo(),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 8.h),

                      // Loading indicator or error state
                      _hasError ? _buildErrorState() : _buildLoadingIndicator(),
                    ],
                  ),
                ),

                // Gold accent elements
                Positioned(
                  top: 15.h,
                  right: 10.w,
                  child: Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  bottom: 20.h,
                  left: 8.w,
                  child: Container(
                    width: 2.w,
                    height: 2.w,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // BLDR logo container with gold accent border
        Container(
          padding: EdgeInsets.all(16), // espaço interno
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            shape: BoxShape.circle,
          ),
          child: Text(
            'BLDR',
            style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.accentGold,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
        ),

        SizedBox(height: 3.h),

        // App subtitle
        Text(
          'CONSTRUA SUA MELHOR VERSÃO',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w300,
            letterSpacing: 4.0,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        // Native platform loading indicator
        SizedBox(
          width: 6.w,
          height: 6.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.accentGold.withValues(alpha: 0.8),
            ),
            backgroundColor: AppTheme.dividerGray,
          ),
        ),

        SizedBox(height: 3.h),

        // Loading text
        // Text(
        //   _isInitialized ? 'Ready to build...' : 'Initializing...',
        //   style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
        //     color: AppTheme.textSecondary,
        //     fontWeight: FontWeight.w400,
        //   ),
        // ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        CustomIconWidget(
          iconName: 'error_outline',
          color: AppTheme.errorRed,
          size: 8.w,
        ),
        SizedBox(height: 2.h),
        Text(
          'Connection Failed',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.errorRed,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Retry option will appear shortly',
          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}