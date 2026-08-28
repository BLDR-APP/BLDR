import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/integrations/domain/usecases/whoop_usecases.dart';
import 'package:bldr_fitness/features/integrations/data/widget_data_service.dart';
import 'package:bldr_fitness/main.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class WhoopConnectScreen extends StatefulWidget {
  const WhoopConnectScreen({super.key});

  @override
  State<WhoopConnectScreen> createState() => _WhoopConnectScreenState();
}

class _WhoopConnectScreenState extends State<WhoopConnectScreen> {
  bool _loading = false;
  String? _error;
  String? _pendingState;

  String _generateState() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(16, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _openAuthUrl() async {
    final clientId = appConfig['WHOOP_CLIENT_ID'] as String? ?? '';
    assert(clientId.isNotEmpty,
        'WHOOP_CLIENT_ID não está configurado. Verifique dart_defines.dev.json.');

    if (clientId.isEmpty) {
      setState(() => _error = 'Configuração ausente: WHOOP_CLIENT_ID.');
      return;
    }

    _pendingState = _generateState();

    const redirectUri = 'bldr://whoop/callback';
    // 'offline' necessário para receber refresh_token e renovar sessão após 1h
    const scopes =
        'offline read:recovery read:cycles read:sleep read:workout read:profile read:body_measurement';

    final authUrl = Uri.https('api.prod.whoop.com', '/oauth/oauth2/auth', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scopes,
      'state': _pendingState!,
    }).toString();

    debugPrint('WHOOP OAuth URL: $authUrl');

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ASWebAuthenticationSession — captura o callback internamente,
      // funciona em simulador e device real. callbackUrlScheme = só o scheme.
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'bldr',
        options: const FlutterWebAuth2Options(
          preferEphemeral: true,
        ),
      );

      debugPrint('WHOOP callback URL: $result');

      // Cancelamento silencioso
      if (result.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final uri = Uri.parse(result);

      // Erro retornado pela Whoop
      final error = uri.queryParameters['error'];
      if (error != null) {
        final description = uri.queryParameters['error_description'] ?? error;
        throw Exception('Whoop: $description');
      }

      // Validação CSRF — state deve bater com o gerado antes do redirect
      final returnedState = uri.queryParameters['state'];
      if (returnedState != _pendingState) {
        throw Exception('State inválido — possível CSRF. Tente novamente.');
      }

      // Sucesso
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw Exception('Código ausente na callback: $result');
      }

      await _exchangeCode(code);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Autorização cancelada ou falhou. Tente novamente.';
      });
      debugPrint('WHOOP auth error: $e');
    }
  }

  Future<void> _exchangeCode(String code) async {
    final result = await getIt<ConnectWhoop>()(code);
    if (!mounted) return;
    result.fold(
      onSuccess: (_) {
        unawaited(WidgetDataService.updateAll());
        Navigator.pop(context, true);
      },
      onFailure: (f) => setState(() {
        _loading = false;
        _error = f.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      body: BldrBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _WhoopLogo(),
                const SizedBox(height: 24),
                const Text(
                  'Conectar Whoop',
                  textAlign: TextAlign.center,
                  style: BldrText.screenTitle,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Autorize o BLDR a ler seus dados de Recovery, Strain e Sleep. '
                  'Você será redirecionado ao Whoop e voltará automaticamente.',
                  textAlign: TextAlign.center,
                  style: BldrText.description,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: BldrText.meta.copyWith(color: Colors.redAccent)),
                ],
                const SizedBox(height: 32),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(BldrColors.goldBright),
                    ),
                  )
                else ...[
                  BldrPrimaryButton(
                    label: 'Autorizar com Whoop',
                    onPressed: _openAuthUrl,
                  ),
                  const SizedBox(height: 12),
                  BldrSecondaryButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Puck oficial WHOOP (branco) — logo guidelines: min 30px, branco ou preto.
class _WhoopLogo extends StatelessWidget {
  const _WhoopLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/whoop/whoop_puck_white.png',
        width: 72,
        height: 72,
        fit: BoxFit.contain,
      ),
    );
  }
}
