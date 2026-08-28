import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/auth/presentation/sign_up_screen/widgets/password_strength_indicator.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class SignUpForm extends StatefulWidget {
  final VoidCallback? onSignUpSuccess;

  const SignUpForm({Key? key, this.onSignUpSuccess}) : super(key: key);

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _showEmailConfirmation = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Erro ao abrir $urlString');
    }
  }

  Future<void> _handleSignUp() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.signup_must_agree_terms_error),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _isLoading = true);

    final result = await getIt<SignUp>()(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      emailRedirectTo: 'bldr://email-confirmation',
    );

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        setState(() {
          _showEmailConfirmation = true;
          _isLoading = false;
        });
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.signup_error(failure.message)),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating));
        setState(() => _isLoading = false);
      },
    );
  }

  Future<void> _handleResendConfirmation() async {
    final l10n = AppLocalizations.of(context);
    final result = await getIt<ResendConfirmationEmail>()(
      email: _emailController.text.trim(),
      emailRedirectTo: 'bldr://email-confirmation',
    );

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.login_email_confirmation_resent),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating));
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.login_resend_email_error(failure.message)),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showEmailConfirmation) {
      return _buildEmailConfirmationView();
    }

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
                  Text(l10n.signup_form_title,
                      style: AppTheme.darkTheme.textTheme.headlineSmall
                          ?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  SizedBox(height: 1.h),
                  Text(l10n.signup_form_subtitle,
                      style: AppTheme.darkTheme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center),
                  SizedBox(height: 4.h),

                  // Full Name Field
                  TextFormField(
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      style: AppTheme.darkTheme.textTheme.bodyLarge
                          ?.copyWith(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                          labelText: l10n.signup_full_name_label,
                          hintText: l10n.signup_full_name_hint,
                          prefixIcon: Icon(Icons.person_outline,
                              color: AppTheme.accentGold)),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return l10n.signup_full_name_required_error;
                        }
                        if (value!.trim().length < 2) {
                          return l10n.signup_full_name_min_length_error;
                        }
                        return null;
                      }),
                  SizedBox(height: 2.h),

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
                        if (value!.length < 8) {
                          return l10n.signup_password_min_length_error;
                        }
                        if (!value.contains(RegExp(r'[A-Z]'))) {
                          return l10n.signup_password_uppercase_error;
                        }
                        if (!value.contains(RegExp(r'[0-9]'))) {
                          return l10n.signup_password_number_error;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {});
                      }),
                  SizedBox(height: 1.h),

                  // Password Strength Indicator
                  if (_passwordController.text.isNotEmpty)
                    PasswordStrengthIndicator(
                        password: _passwordController.text),

                  SizedBox(height: 2.h),

                  // Confirm Password Field
                  TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      style: AppTheme.darkTheme.textTheme.bodyLarge
                          ?.copyWith(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                          labelText: l10n.signup_confirm_password_label,
                          hintText: l10n.signup_confirm_password_hint,
                          prefixIcon: Icon(Icons.lock_outline,
                              color: AppTheme.accentGold),
                          suffixIcon: IconButton(
                              icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppTheme.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                                });
                              })),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return l10n.signup_confirm_password_required_error;
                        }
                        if (value != _passwordController.text) {
                          return l10n.signup_passwords_mismatch_error;
                        }
                        return null;
                      }),
                  SizedBox(height: 3.h),

                  // Checkbox com links
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeToTerms = value ?? false;
                                });
                              },
                              activeColor: AppTheme.accentGold,
                              checkColor: AppTheme.primaryBlack,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: RichText(
                                text: TextSpan(
                                    style: AppTheme.darkTheme.textTheme.bodySmall
                                        ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        height: 1.5),
                                    children: [
                                      TextSpan(
                                        text: l10n.signup_agree_terms_prefix,
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            setState(() {
                                              _agreeToTerms = !_agreeToTerms;
                                            });
                                          },
                                      ),
                                      TextSpan(
                                        text: l10n.signup_terms_of_service,
                                        style: const TextStyle(
                                          color: AppTheme.accentGold,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => _launchUrl(
                                              'https://www.bldrapp.com.br/termos'),
                                      ),
                                      TextSpan(
                                        text: ' e ',
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            setState(() {
                                              _agreeToTerms = !_agreeToTerms;
                                            });
                                          },
                                      ),
                                      TextSpan(
                                        text: l10n.signup_privacy_policy,
                                        style: const TextStyle(
                                          color: AppTheme.accentGold,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => _launchUrl(
                                              'https://www.bldrapp.com.br/privacidade'),
                                      ),
                                    ])))
                      ]),

                  SizedBox(height: 3.h),

                  // Sign Up Button
                  ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: AppTheme.primaryBlack,
                          padding: EdgeInsets.symmetric(vertical: 4.w),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: _isLoading
                          ? SizedBox(
                          height: 5.w,
                          width: 5.w,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlack)))
                          : Text(l10n.signup_create_account_btn,
                          style: AppTheme.darkTheme.textTheme.titleMedium
                              ?.copyWith(
                              color: AppTheme.primaryBlack,
                              fontWeight: FontWeight.w600))),
                  SizedBox(height: 3.h),

                  Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(l10n.signup_already_have_account,
                            style: AppTheme.darkTheme.textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary)),
                        GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(l10n.login_btn,
                                style: AppTheme.darkTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                    color: AppTheme.accentGold,
                                    fontWeight: FontWeight.w600))),
                      ]),
                ])));
  }

  Widget _buildEmailConfirmationView() {
    final l10n = AppLocalizations.of(context);
    return Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
            color: AppTheme.cardDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.3), width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              child: Icon(Icons.email_outlined,
                  color: AppTheme.accentGold, size: 8.w)),
          SizedBox(height: 4.h),

          Text(l10n.signup_confirm_email_title,
              style: AppTheme.darkTheme.textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          SizedBox(height: 2.h),

          Text(l10n.signup_confirm_email_sent_to,
              style: AppTheme.darkTheme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          SizedBox(height: 1.h),

          Text(_emailController.text,
              style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.accentGold, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          SizedBox(height: 3.h),

          Text(l10n.signup_confirm_email_instruction,
              style: AppTheme.darkTheme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          SizedBox(height: 4.h),

          TextButton(
              onPressed: _handleResendConfirmation,
              child: Text(l10n.signup_resend_email_btn,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600))),
          SizedBox(height: 2.h),

          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardDark,
                  foregroundColor: AppTheme.textPrimary,
                  padding: EdgeInsets.symmetric(vertical: 3.w, horizontal: 8.w),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: AppTheme.accentGold.withValues(alpha: 0.3)))),
              child: Text(l10n.signup_back_to_login_btn,
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600))),
        ]));
  }
}
