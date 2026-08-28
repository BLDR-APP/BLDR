import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:pinput/pinput.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await getIt<VerifyPasswordResetOtp>()(
      email: widget.email,
      token: _otpController.text,
    );

    result.fold(
      onSuccess: (_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
              context, AppRoutes.createNewPasswordScreen);
        }
      },
      onFailure: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context).otp_invalid_code_error),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating));
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defaultPinTheme = PinTheme(
      width: 13.w,
      height: 13.w,
      textStyle: AppTheme.darkTheme.textTheme.headlineMedium?.copyWith(
        color: AppTheme.textPrimary,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withValues(alpha: 0.6),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.otp_title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.password_rounded,
                color: AppTheme.accentGold,
                size: 20.w,
              ),
              SizedBox(height: 4.h),
              Text(
                l10n.otp_heading,
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.displaySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.otp_body,
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),

              Pinput(
                controller: _otpController,
                length: 6,
                autofocus: true,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppTheme.accentGold),
                  ),
                ),
                validator: (s) {
                  return s?.length == 6 ? null : l10n.otp_validator_error;
                },
              ),
              SizedBox(height: 6.h),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerifyOtp,
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
                  l10n.otp_verify_btn,
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
