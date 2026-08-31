import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/app_version/domain/app_version_repository.dart';
import 'package:bldr_fitness/features/auth/presentation/login_screen/login_screen.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/dashboard.dart';
import 'package:bldr_fitness/shared/presentation/onboarding_flow/onboarding_flow.dart';
import 'package:bldr_fitness/widgets/force_update_dialog.dart';

/// Resolves the first app destination after the startup video has completed
/// the asynchronous bootstrap. The visual splash itself lives in
/// [StartupVideoSplash], which is displayed by AppLoader before this route.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openNextScreen());
  }

  Future<void> _openNextScreen() async {
    try {
      final needsUpdate =
          (await getIt<ShouldForceUpdate>()()).valueOrNull ?? false;
      if (!mounted) return;

      if (needsUpdate) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const ForceUpdateDialog(),
        );
        return;
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        _replaceWith(const LoginScreen());
        return;
      }

      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select('onboarding_completed')
          .eq('id', session.user.id)
          .maybeSingle();
      if (!mounted) return;
      _replaceWith(
        profile?['onboarding_completed'] == true
            ? const Dashboard()
            : const OnboardingFlow(),
      );
    } catch (_) {
      if (mounted) _replaceWith(const LoginScreen());
    }
  }

  void _replaceWith(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    // This route can be visible for only a frame while the first destination
    // resolves. Keeping it pure black prevents a visual interruption after
    // the video splash and never introduces an intermediate spinner.
    return const Scaffold(backgroundColor: Colors.black);
  }
}
