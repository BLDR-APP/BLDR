import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/auth_failures.dart';
import 'package:bldr_fitness/features/auth/domain/entities/auth_user.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/services/user_service.dart';

const String _kRememberMeEmailKey = 'rememberMeEmail';

class LoginFormWidget extends StatefulWidget {
  final Function(String, String)? onLogin;
  final bool isLoading;

  const LoginFormWidget({
    Key? key,
    this.onLogin,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  bool _isSocialLogin = false;
  late final StreamSubscription<AuthUser?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authSubscription.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    _authSubscription =
        getIt<AuthRepository>().authStateChanges.listen((user) {
      if (user != null && _isSocialLogin) {
        if (mounted) {
          _checkProfileAndNavigate();
          _isSocialLogin = false;
        }
      }
    });
  }

  Future<void> _checkProfileAndNavigate() async {
    try {
      final completed = await getIt<UserService>().hasCompletedOnboarding();

      if (!mounted) return;

      if (completed) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
      }
    } catch (e) {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.onboardingFlow);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_kRememberMeEmailKey);

    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveRememberMeState(bool value, String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setString(_kRememberMeEmailKey, email);
    } else {
      await prefs.remove(_kRememberMeEmailKey);
    }
    setState(() {
      _rememberMe = value;
    });
  }

  Future<void> _handleSignIn() async {
    _isSocialLogin = false;

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await _saveRememberMeState(_rememberMe, email);

    if (widget.onLogin != null) {
      widget.onLogin!(email, password);
      return;
    }

    setState(() => _isLoading = true);

    final result = await getIt<SignIn>()(email: email, password: password);

    result.fold(
      onSuccess: (_) => _checkProfileAndNavigate(),
      onFailure: (failure) {
        if (failure is EmailNotConfirmedFailure) {
          _showEmailConfirmationDialog();
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(failure.message),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating));
        }
      },
    );

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleSignInWithApple() async {
    _isSocialLogin = true;
    setState(() => _isLoading = true);

    final result = await getIt<SignInWithApple>()();

    result.fold(
      onSuccess: (_) {},
      onFailure: (failure) {
        _isSocialLogin = false;
        if (mounted) {
          setState(() => _isLoading = false);

          final displayError = failure is SignInCanceledFailure
              ? 'Login com Apple cancelado pelo usuário.'
              : failure.message;

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Erro ao entrar com Apple: $displayError'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating));
        }
      },
    );
  }

  Future<void> _handleSignInWithGoogle() async {
    _isSocialLogin = true;
    setState(() => _isLoading = true);

    final result = await getIt<SignInWithGoogle>()();

    result.fold(
      onSuccess: (_) {},
      onFailure: (failure) {
        _isSocialLogin = false;
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Erro ao entrar com Google: ${failure.message}'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating));
        }
      },
    );
  }

  void _showEmailConfirmationDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              Icon(Icons.email_outlined,
                  color: AppTheme.accentGold, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                  child: Text(l10n.login_email_not_confirmed_title,
                      style: AppTheme.darkTheme.textTheme.titleLarge
                          ?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600))),
            ]),
            content: Text(
                l10n.login_email_not_confirmed_body,
                style: AppTheme.darkTheme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () async {
                    final result = await getIt<ResendConfirmationEmail>()(
                      email: _emailController.text.trim(),
                      emailRedirectTo: 'bldr://email-confirmation',
                    );

                    if (mounted) Navigator.of(context).pop();

                    result.fold(
                      onSuccess: (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(l10n.login_email_confirmation_resent),
                              backgroundColor: AppTheme.successGreen,
                              behavior: SnackBarBehavior.floating));
                        }
                      },
                      onFailure: (failure) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  l10n.login_resend_email_error(failure.message)),
                              backgroundColor: AppTheme.errorRed,
                              behavior: SnackBarBehavior.floating));
                        }
                      },
                    );
                  },
                  child: Text(l10n.common_resend,
                      style: TextStyle(color: AppTheme.accentGold))),
              ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryBlack),
                  child: Text(l10n.common_ok)),
            ]));
  }

  void _showForgotPasswordDialog() {
    final l10n = AppLocalizations.of(context);
    final emailController = TextEditingController();
    emailController.text = _emailController.text.trim();

    showDialog(
        context: context,
        builder: (context) {
          final dialogL10n = AppLocalizations.of(context);
          return AlertDialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(dialogL10n.login_recover_password_title,
                style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                  dialogL10n.login_recover_password_body,
                  style: AppTheme.darkTheme.textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary)),
              SizedBox(height: 2.h),
              TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTheme.darkTheme.textTheme.bodyLarge
                      ?.copyWith(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                      labelText: dialogL10n.login_email_label,
                      hintText: dialogL10n.login_enter_email_hint,
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppTheme.accentGold))),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(dialogL10n.common_cancel,
                      style: TextStyle(color: AppTheme.textSecondary))),
              ElevatedButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(dialogL10n.login_enter_email_error),
                          backgroundColor: AppTheme.errorRed,
                          behavior: SnackBarBehavior.floating));
                      return;
                    }

                    final result =
                        await getIt<SendPasswordResetOtp>()(email);

                    if (mounted) Navigator.of(context).pop();

                    result.fold(
                      onSuccess: (_) {
                        if (mounted) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.verifyOtpScreen,
                            arguments: email,
                          );
                        }
                      },
                      onFailure: (failure) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  dialogL10n.login_send_code_error(failure.message)),
                              backgroundColor: AppTheme.errorRed,
                              behavior: SnackBarBehavior.floating));
                        }
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryBlack),
                  child: Text(dialogL10n.login_send_code_btn)),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
            color: AppTheme.cardDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.3), width: 1)),
        child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.login_title,
                      style: AppTheme.darkTheme.textTheme.headlineSmall
                          ?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  SizedBox(height: 1.h),
                  Text(l10n.login_subtitle,
                      style: AppTheme.darkTheme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center),
                  SizedBox(height: 4.h),

                  // Email Field
                  TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTheme.darkTheme.textTheme.bodyLarge
                          ?.copyWith(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                          labelText: l10n.login_email_label,
                          hintText: l10n.login_email_hint,
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppTheme.accentGold)),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return l10n.login_email_required_error;
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value!)) {
                          return l10n.login_email_invalid_error;
                        }
                        return null;
                      }),
                  SizedBox(height: 2.h),

                  // Password Field
                  TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: AppTheme.darkTheme.textTheme.bodyLarge
                          ?.copyWith(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                          labelText: l10n.login_password_label,
                          hintText: l10n.login_password_hint,
                          prefixIcon: Icon(Icons.lock_outline,
                              color: AppTheme.accentGold),
                          suffixIcon: IconButton(
                              icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppTheme.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              })),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return l10n.login_password_required_error;
                        }
                        return null;
                      }),
                  SizedBox(height: 2.h),

                  // Remember Me and Forgot Password
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                    Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            _saveRememberMeState(value ?? false, _emailController.text.trim());
                          },
                          activeColor: AppTheme.accentGold,
                          checkColor: AppTheme.primaryBlack),
                      Text(l10n.login_remember_me,
                          style: AppTheme.darkTheme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary)),
                    ],
                  ),
                  GestureDetector(
                      onTap: () {
                        _showForgotPasswordDialog();
                      },
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          child: Text(l10n.login_forgot_password,
                              style: AppTheme.darkTheme.textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.accentGold)),
                      )),
                    ],
                  ),
                  SizedBox(height: 3.h),

                  // Sign In Button
                  ElevatedButton(
                      onPressed: widget.isLoading || _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: AppTheme.primaryBlack,
                          padding: EdgeInsets.symmetric(vertical: 4.w),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: widget.isLoading || _isLoading
                          ? SizedBox(
                          height: 5.w,
                          width: 5.w,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlack)))
                          : Text(l10n.login_btn,
                          style: AppTheme.darkTheme.textTheme.titleMedium
                              ?.copyWith(
                              color: AppTheme.primaryBlack,
                              fontWeight: FontWeight.w600))),

                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.accentGold.withValues(alpha: 0.3))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          l10n.common_or,
                          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.accentGold.withValues(alpha: 0.3))),
                    ],
                  ),
                  SizedBox(height: 3.h),

                  // Botão "Continuar com a Apple"
                  OutlinedButton.icon(
                    icon: Icon(Icons.apple, size: 5.w),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l10n.login_apple_btn,
                        style: AppTheme.darkTheme.textTheme.titleMedium
                            ?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    onPressed: widget.isLoading || _isLoading ? null : _handleSignInWithApple,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      padding: EdgeInsets.symmetric(vertical: 4.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.3)),
                    ),
                  ),

                  // Botão "Continuar com o Google"
                  SizedBox(height: 2.h),
                  OutlinedButton.icon(
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 4.5.w,
                      width: 4.5.w,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l10n.login_google_btn,
                        style: AppTheme.darkTheme.textTheme.titleMedium
                            ?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    onPressed: widget.isLoading || _isLoading ? null : _handleSignInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      padding: EdgeInsets.symmetric(vertical: 4.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.3)),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(l10n.login_no_account,
                            style: AppTheme.darkTheme.textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary)),
                        GestureDetector(
                            onTap: () {
                              if (mounted) Navigator.pushNamed(context, AppRoutes.signUpScreen);
                            },
                            child: Text(l10n.login_create_account_link,
                                style: AppTheme.darkTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                    color: AppTheme.accentGold,
                                    fontWeight: FontWeight.w600))),
                  ]),
                ])));
  }
}
