import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({Key? key}) : super(key: key);

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await getIt<UpdatePassword>()(_passwordController.text);

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    result.fold(
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.new_password_success),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.loginScreen,
              (route) => false,
        );
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.new_password_error(failure.message)),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.new_password_title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_reset_outlined,
                color: AppTheme.accentGold,
                size: 20.w,
              ),
              SizedBox(height: 4.h),
              Text(
                l10n.new_password_heading,
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.displaySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.new_password_body,
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 6.h),

              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.new_password_field_label,
                  hintText: l10n.new_password_field_hint,
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.accentGold),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return l10n.login_password_required_error;
                  }
                  if (value!.length < 8) {
                    return l10n.new_password_min_length_error;
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.new_password_confirm_label,
                  hintText: l10n.new_password_confirm_hint,
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.accentGold),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                    },
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return l10n.new_password_confirm_required_error;
                  }
                  if (value != _passwordController.text) {
                    return l10n.new_password_passwords_mismatch_error;
                  }
                  return null;
                },
              ),
              SizedBox(height: 6.h),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryBlack,
                  ),
                )
                    : Text(
                  l10n.new_password_save_btn,
                  style: const TextStyle(color: AppTheme.primaryBlack),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
