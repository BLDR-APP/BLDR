import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <<< ESSENCIAL PARA PUSH

// Importe suas outras dependências
import './services/notification_service.dart';
import './services/supabase_service.dart';
import './services/profile_notifier.dart';
import 'core/app_export.dart';
import 'firebase_options.dart';

// Função Handler de Background exigida pelo Firebase Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
  // Você pode adicionar lógica aqui para notificar o usuário (ex: usando flutter_local_notifications)
}

late final Map<String, dynamic> appConfig;

void main() async {
  // Garante que o Flutter esteja pronto
  WidgetsFlutterBinding.ensureInitialized();

  // REGISTRAR O HANDLER DE BACKGROUND (Obrigatório para PUSH em background/app fechado)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    // 1. CARREGA SUA CONFIGURAÇÃO
    final configString = await rootBundle.loadString('dart_defines.dev.json');
    appConfig = json.decode(configString);

    // 2. INICIALIZA O FIREBASE (ÚNICO E PADRÃO!)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. INICIALIZAÇÃO DE SERVIÇOS
    await SupabaseService.initialize();

    Stripe.publishableKey = appConfig['STRIPE_PUBLISHABLE_KEY'] ?? '';
    await Stripe.instance.applySettings();

    // Inicialização de Notificações Locais (A lógica PUSH está no ProfileDrawer)
    await NotificationService().initialize();

    // 4. RODA O APP
    runApp(
      ChangeNotifierProvider(
        create: (context) => ProfileNotifier(),
        child: const MyApp(),
      ),
    );

  } catch (e) {
    if (kDebugMode) {
      print('Falha crítica na inicialização do App: $e');
    }
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Erro ao iniciar o aplicativo. Detalhes: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'BLDR App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          // Define o idioma padrão do app como Português (Brasil)
          locale: const Locale('pt', 'BR'),

          // Informa ao Flutter quais são os "tradutores"
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Lista os idiomas que seu app suporta
          supportedLocales: const [
            Locale('pt', 'BR'), // Português (Brasil)
            Locale('en', 'US'), // Inglês (como reserva, caso necessário)
          ],
          initialRoute: AppRoutes.splashScreen,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}