import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Importe suas outras dependências
import 'package:bldr_fitness/services/notification_service.dart';
import 'package:bldr_fitness/services/push_notification_service.dart';
import 'package:bldr_fitness/services/supabase_service.dart';
import 'package:bldr_fitness/services/profile_notifier.dart';
import 'package:bldr_fitness/services/payment_service.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_provider.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_overlay.dart';
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/integrations/data/live_activity_service.dart';
import 'package:bldr_fitness/features/integrations/data/watch_service.dart';
import 'package:bldr_fitness/features/integrations/data/widget_data_service.dart';
import 'package:bldr_fitness/firebase_options.dart';
import 'package:bldr_fitness/core/providers/locale_provider.dart';
import 'package:bldr_fitness/shared/providers/workout_session_provider.dart';

// Handler de background — delegado ao PushNotificationService para evitar duplicação

late final Map<String, dynamic> appConfig;
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 1. Binding obrigatoriamente primeiro.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Background handler após o binding, antes do Firebase.initializeApp.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Mínimo absoluto antes de runApp: config + Firebase.
  final configString = await rootBundle.loadString('dart_defines.dev.json');
  appConfig = json.decode(configString);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // runApp imediatamente — elimina tela branca entre splash nativa e Flutter.
  runApp(const AppLoader());
}

// ── AppLoader — inicializações pesadas pós-runApp ────────────────────────────

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});
  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _ready = false;
  AchievementProvider? _achievementProvider;
  LocaleProvider? _localeProvider;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await SupabaseService.initialize();
      setupInjection();

      Stripe.publishableKey = PaymentService.isTestMode
          ? (appConfig['STRIPE_TEST_PUBLISHABLE_KEY'] ?? '')
          : (appConfig['STRIPE_PUBLISHABLE_KEY'] ?? '');
      await Stripe.instance.applySettings();

      await getIt<NotificationService>().initialize();
      await getIt<PushNotificationService>()
          .initialize(navigatorKey: appNavigatorKey);

      // Não-críticos: não bloquear o runApp com await.
      unawaited(WidgetDataService.init());
      unawaited(LiveActivityService.init());
      unawaited(getIt<WatchService>().initialize());

      final achievementProvider = AchievementProvider();
      await achievementProvider.init();

      final localeProvider = getIt<LocaleProvider>();
      await localeProvider.load();

      if (mounted) {
        setState(() {
          _achievementProvider = achievementProvider;
          _localeProvider = localeProvider;
          _ready = true;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Falha crítica na inicialização: $e');
      if (mounted) {
        setState(() => _ready = true); // mostra tela de erro no MyApp
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // Mesma cor da splash nativa — zero flash.
      return const ColoredBox(color: Color(0xFF050505));
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileNotifier()),
        ChangeNotifierProvider(create: (_) => WorkoutSessionProvider()),
        ChangeNotifierProvider.value(
            value: _achievementProvider ?? AchievementProvider()),
        ChangeNotifierProvider.value(
            value: _localeProvider ?? getIt<LocaleProvider>()),
      ],
      child: const MyApp(),
    );
  }
}

// ── Deep link handler ────────────────────────────────────────────────────────
// Trata bldr://workout/start/{templateId} e bldr://workout/confirm.
// bldr://whoop/callback é capturado pelo flutter_web_auth_2 antes de chegar aqui.
class _DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const _DeepLinkHandler({required this.child});

  @override
  State<_DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<_DeepLinkHandler> {
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initLinks();
  }

  Future<void> _initLinks() async {
    final appLinks = AppLinks();
    // Link inicial (app fechado)
    final initial = await appLinks.getInitialLink();
    if (initial != null) _handleLink(initial);
    // Links enquanto app está aberto
    _sub = appLinks.uriLinkStream.listen(_handleLink, onError: (_) {});
  }

  void _handleLink(Uri uri) {
    if (uri.scheme != 'bldr') return;
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    // bldr://workout/start/{templateId}
    if (uri.host == 'workout' && uri.pathSegments.length == 2
        && uri.pathSegments[0] == 'start') {
      final templateId = uri.pathSegments[1];
      nav.pushNamed(
        AppRoutes.activeWorkoutScreen,
        arguments: {'workoutId': templateId, 'workoutName': 'Treino'},
      );
      return;
    }

    // bldr://workout/confirm — confirma série na tela de treino ativa.
    // Usa Stream broadcast em vez de popUntil/route-name para suportar tanto
    // o modo grátis (rota nomeada) quanto o Club (MaterialPageRoute sem nome).
    if (uri.host == 'workout' && uri.pathSegments.firstOrNull == 'confirm') {
      LiveActivityService.triggerConfirmSet();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    return Sizer(
      builder: (context, orientation, deviceType) {
        return _DeepLinkHandler(
          child: MaterialApp(
            title: 'BLDR App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt'),
              Locale('en'),
              Locale('it'),
            ],
            navigatorKey: appNavigatorKey,
            initialRoute: AppRoutes.splashScreen,
            routes: AppRoutes.routes,
            builder: (context, child) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: AchievementOverlay(child: child ?? const SizedBox.shrink()),
              );
            },
          ),
        );
      },
    );
  }
}