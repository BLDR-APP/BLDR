import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class WaitForConfirmationScreen extends StatefulWidget {
  const WaitForConfirmationScreen({Key? key}) : super(key: key);

  @override
  State<WaitForConfirmationScreen> createState() => _WaitForConfirmationScreenState();
}

class _WaitForConfirmationScreenState extends State<WaitForConfirmationScreen> {
  bool _isResending = false;

  Future<void> _resendEmail() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isResending = true);

    final email = getIt<GetCurrentUser>()()?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.wait_confirm_no_email_error)),
      );
      setState(() => _isResending = false);
      return;
    }

    final result = await getIt<ResendConfirmationEmail>()(
      email: email,
      emailRedirectTo: 'bldr://email-confirmation',
    );

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.wait_confirm_email_resent_success),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.login_resend_email_error(failure.message))),
        );
      },
    );

    setState(() => _isResending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              color: AppTheme.accentGold,
              size: 20.w,
            ),
            SizedBox(height: 4.h),
            Text(
              l10n.signup_confirm_email_title,
              textAlign: TextAlign.center,
              style: AppTheme.darkTheme.textTheme.displaySmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.wait_confirm_email_body,
              textAlign: TextAlign.center,
              style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 6.h),
            ElevatedButton(
              onPressed: _isResending ? null : _resendEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
              child: _isResending
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryBlack,
                ),
              )
                  : Text(
                l10n.signup_resend_email_btn,
                style: const TextStyle(color: AppTheme.primaryBlack),
              ),
            ),
            SizedBox(height: 2.h),
            TextButton(
              onPressed: () {
                getIt<SignOut>()();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.loginScreen,
                      (route) => false,
                );
              },
              child: Text(
                l10n.wait_confirm_back_to_login_btn,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
