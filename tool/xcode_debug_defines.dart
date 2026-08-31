import 'dart:convert';
import 'dart:io';

const _requiredKeys = <String>{
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
};

const _forbiddenKeys = <String>{
  'SUPABASE_SERVICE_ROLE_KEY',
  'STRIPE_SECRET_KEY',
  'FATSECRET_CLIENT_SECRET',
  'REVENUECAT_SECRET_API_KEY',
  'REVENUECAT_WEBHOOK_AUTH',
  'REVENUECAT_WEBHOOK_SIGNING_SECRET',
};

Never _fail(String message) {
  stderr.writeln('error: $message');
  exit(1);
}

void main(List<String> arguments) {
  if (arguments.length != 1) {
    _fail('Usage: xcode_debug_defines.dart <dart-defines-json-path>');
  }

  final file = File(arguments.single);
  if (!file.existsSync()) {
    _fail(
      'Debug configuration is missing. Create dart_defines.dev.json from '
      'dart_defines.example.json and keep it local.',
    );
  }

  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    _fail('Debug configuration must be a JSON object.');
  }

  final forbidden = decoded.keys.where(_forbiddenKeys.contains).toList();
  if (forbidden.isNotEmpty) {
    _fail('Debug configuration contains forbidden server-side key(s): '
        '${forbidden.join(', ')}.');
  }

  final missing = _requiredKeys.where((key) {
    final value = decoded[key];
    return value is! String || value.trim().isEmpty;
  }).toList();
  if (missing.isNotEmpty) {
    _fail('Debug configuration is missing required non-empty key(s): '
        '${missing.join(', ')}.');
  }

  final defines = decoded.entries.map((entry) {
    final value = entry.value;
    if (value is! String && value is! bool && value is! num) {
      _fail('Debug define ${entry.key} must be a string, boolean, or number.');
    }
    return base64.encode(utf8.encode('${entry.key}=$value'));
  });

  stdout.write(defines.join(','));
}
