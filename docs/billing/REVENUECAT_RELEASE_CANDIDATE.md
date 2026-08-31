# RevenueCat release candidate

## Configuração de build

Os arquivos locais `dart_defines.dev.json` e `dart_defines.release.json` não
devem ser versionados nem são assets do Flutter. Para desenvolvimento, crie o
primeiro a partir de `dart_defines.example.json`; para um release candidate,
crie o segundo a partir de `dart_defines.release.example.json`. Preencha
somente valores públicos de cliente:
Supabase URL/anon key, Stripe publishable keys, WHOOP client ID/redirect URI e
as Public SDK Keys iOS/Android do RevenueCat.

O modelo de release já define `REVENUECAT_BILLING_ENABLED` como `true` para
TestFlight, Google Play testing e o release público. A mesma base de código
deve ser promovida; a flag `false` é apenas mecanismo temporário de
compatibilidade para builds legados.

Nunca coloque no arquivo ou no bundle: service-role Supabase, Stripe `sk_`,
segredos RevenueCat, credenciais de webhook, credenciais FatSecret ou qualquer
segredo server-side.

### Comandos de build

```bash
flutter build ipa --release \
  --dart-define-from-file=dart_defines.release.json

flutter build appbundle --release \
  --dart-define-from-file=dart_defines.release.json
```

Os defines são incorporados pelo compilador; o arquivo JSON não é incluído no
IPA, APK ou AAB.

## Gate de publicação

1. Executar os roteiros [iOS](../REVENUECAT_TESTFLIGHT_E2E.md) e
   [Android](../REVENUECAT_GOOGLE_PLAY_E2E.md) em lojas reais.
2. Confirmar UUID Supabase como App User ID em login, troca de usuário e
   relogin; não aceitar identidade anônima ou CustomerInfo de outro usuário.
3. Confirmar que Offering `default` disponibiliza packages e preços reais da
   loja, e que apenas `bldr_club` decide acesso.
4. Confirmar HMAC/Authorization do webhook, idempotência do ledger e mirror
   server-side sem alterar o client.
5. Rotacionar/revogar quaisquer segredos que já tenham sido rastreados em
   configuração de build antes de distribuir novo release. Isso é uma ação
   externa obrigatória: remover o arquivo do índice impede nova exposição, mas
   não revoga segredos já publicados no histórico.
