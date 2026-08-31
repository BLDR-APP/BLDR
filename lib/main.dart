import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
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
import 'package:bldr_fitness/features/subscription/data/revenue_cat_lifecycle.dart';
import 'package:bldr_fitness/features/profile/data/user_timezone_sync_lifecycle.dart';
import 'package:bldr_fitness/features/subscription/data/revenue_cat_config.dart';
import 'package:bldr_fitness/firebase_options.dart';
import 'package:bldr_fitness/core/providers/locale_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:bldr_fitness/shared/providers/workout_session_provider.dart';
import 'package:bldr_fitness/shared/presentation/splash_screen/startup_video_splash.dart';
import 'package:flutter_muscle_anatomy/flutter_muscle_anatomy.dart';

// Handler de background — delegado ao PushNotificationService para evitar duplicação

/// Configuração exclusivamente de build time. Arquivos locais de defines não
/// são assets e devem ser passados ao Flutter com `--dart-define-from-file`.
const Map<String, dynamic> appConfig = {
  'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
  'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
  'STRIPE_PUBLISHABLE_KEY': String.fromEnvironment('STRIPE_PUBLISHABLE_KEY'),
  'STRIPE_TEST_PUBLISHABLE_KEY':
      String.fromEnvironment('STRIPE_TEST_PUBLISHABLE_KEY'),
  'WHOOP_CLIENT_ID': String.fromEnvironment('WHOOP_CLIENT_ID'),
  'REVENUECAT_BILLING_ENABLED':
      String.fromEnvironment('REVENUECAT_BILLING_ENABLED'),
  'REVENUECAT_IOS_PUBLIC_SDK_KEY':
      String.fromEnvironment('REVENUECAT_IOS_PUBLIC_SDK_KEY'),
  'REVENUECAT_ANDROID_PUBLIC_SDK_KEY':
      String.fromEnvironment('REVENUECAT_ANDROID_PUBLIC_SDK_KEY'),
};
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

bool _isValidStripePublishableKey(String key) => key.startsWith('pk_');

Future<void> _initializeLegacyStripeIfNeeded() async {
  // RevenueCat é o checkout canônico após o cutover. O cliente Stripe só é
  // necessário quando uma build legada desliga explicitamente o RevenueCat.
  if (RevenueCatConfig.fromMap(appConfig).billingEnabled) return;

  final configuredKey = PaymentService.isTestMode
      ? (appConfig['STRIPE_TEST_PUBLISHABLE_KEY'] as String? ?? '')
      : (appConfig['STRIPE_PUBLISHABLE_KEY'] as String? ?? '');
  final stripeKey = configuredKey.trim();

  // Nunca entregue uma chave vazia/privada ao SDK nativo: isso causa fatal
  // error no iOS antes de qualquer tela Flutter poder recuperar o app.
  if (!_isValidStripePublishableKey(stripeKey)) {
    if (kDebugMode) {
      debugPrint(
          'Stripe legado indisponível: publishable key ausente ou inválida.');
    }
    return;
  }

  Stripe.publishableKey = stripeKey;
  await Stripe.instance.applySettings();
}

void main() {
  // O Flutter precisa renderizar uma frame antes de qualquer inicialização
  // externa. Assim, uma falha de configuração nunca mantém a splash nativa
  // presa em Debug ou Release.
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // O handler pode ser registrado antes do Firebase ser inicializado.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Renderiza imediatamente; AppLoader conclui o bootstrap em segundo plano.
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
  bool _initializationFailed = false;
  bool _startupVideoCompleted = false;
  AchievementProvider? _achievementProvider;
  LocaleProvider? _localeProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _initialize();
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _ready = false;
        _initializationFailed = false;
      });
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await SupabaseService.initialize();
      await FlutterMuscleAnatomy.initialize();
      setupInjection(config: appConfig);

      // Não bloqueia o bootstrap: usuários legados ficam em UTC até a primeira
      // sincronização bem-sucedida do timezone IANA do dispositivo.
      unawaited(getIt<UserTimezoneSyncLifecycle>().start());

      // Fundação RevenueCat em paralelo. A flag permanece OFF por padrão e,
      // portanto, não substitui nem interfere no billing Apple/Stripe atual.
      unawaited(getIt<RevenueCatLifecycle>().start());

      await _initializeLegacyStripeIfNeeded();

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
          _initializationFailed = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Falha crítica na inicialização: $e');
      if (mounted) {
        setState(() {
          _ready = true;
          _initializationFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_startupVideoCompleted && !_initializationFailed) {
      // Mantém a mesma superfície visual até vídeo e bootstrap terminarem.
      // O vídeo nunca é descartado somente porque o bootstrap foi mais rápido.
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: StartupVideoSplash(
          bootstrapReady: _ready,
          onCompleted: () {
            if (mounted) setState(() => _startupVideoCompleted = true);
          },
        ),
      );
    }
    if (_initializationFailed) {
      return _BootstrapFailureScreen(onRetry: _initialize);
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

class _BootstrapFailureScreen extends StatelessWidget {
  const _BootstrapFailureScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt'), Locale('en'), Locale('it')],
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            backgroundColor: const Color(0xFF050505),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.bootstrap_init_failed_title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.bootstrap_init_failed_body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFB8B8B8)),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE8C12E),
                        foregroundColor: Colors.black,
                      ),
                      child: Text(l10n.common_retry),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
    if (uri.host == 'workout' &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments[0] == 'start') {
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
                child:
                    AchievementOverlay(child: child ?? const SizedBox.shrink()),
              );
            },
          ),
        );
      },
    );
  }
}
