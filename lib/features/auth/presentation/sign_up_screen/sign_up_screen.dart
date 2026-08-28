import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/auth/presentation/sign_up_screen/widgets/sign_up_form.dart';
import 'package:bldr_fitness/features/auth/presentation/sign_up_screen/widgets/video_background.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();

  Future<void> _handleSignUp(
      String email, String password, String fullName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await getIt<SignUp>()(
      email: email,
      password: password,
      fullName: fullName,
      emailRedirectTo: 'bldr://email-confirmation',
    );

    result.fold(
      onSuccess: (_) {
        HapticFeedback.mediumImpact();

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/wait-for-confirmation');
        }
      },
      onFailure: (failure) {
        setState(() {
          _errorMessage = 'Falha no cadastro: ${failure.message}';
          _isLoading = false;
        });
        HapticFeedback.lightImpact();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.primaryBlack,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: VideoBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: _scrollController,
                physics: ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4.h),
                          _buildHeader(), // Cabeçalho atualizado
                          SizedBox(height: 6.h),
                          _buildSignUpForm(),
                          SizedBox(height: 4.h),
                        ],
                      ),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          margin: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlack.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  // --- CABEÇALHO ATUALIZADO ---
  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo BLDR (Estilo igual da Splash Screen)
          Text(
            'BLDR',
            style: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.accentGold,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),

          SizedBox(height: 4.h),

          // Título Centralizado
          Text(
            AppLocalizations.of(context).signup_title,
            textAlign: TextAlign.center,
            style: AppTheme.darkTheme.textTheme.displaySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 28.sp,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: 1.h),

          // Subtítulo Centralizado
          Text(
            AppLocalizations.of(context).signup_subtitle,
            textAlign: TextAlign.center,
            style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 13.sp,
              height: 1.4,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
  // ---------------------------

  Widget _buildSignUpForm() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowBlack,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SignUpForm(
        onSignUpSuccess: _handleSignUpSuccess,
      ),
    );
  }

  void _handleSignUpSuccess() {
    Navigator.pushReplacementNamed(context, '/wait-for-confirmation');
  }
}