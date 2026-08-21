import 'dart:async';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/profile/domain/entities/feedback_result.dart';
import 'package:bldr_fitness/features/profile/domain/repositories/feedback_repository.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final SupabaseClient _client;

  FeedbackRepositoryImpl(this._client);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on Failure catch (f) {
      return Result.failure(f);
    } on FunctionException catch (e) {
      return Result.failure(ServerFailure('Falha ao enviar feedback: ${e.reasonPhrase}', cause: e));
    } on SocketException catch (e) {
      return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
    } on TimeoutException catch (e) {
      return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
    } catch (e) {
      return Result.failure(UnexpectedFailure('Ocorreu um erro inesperado.', e));
    }
  }

  @override
  Future<Result<FeedbackResult>> sendFeedback({
    required String tipo,
    required String mensagem,
    String? screenshotUrl,
  }) =>
      _guard(() async {
        final user = _client.auth.currentUser;
        final userEmail = user?.email;
        final userMeta = user?.userMetadata;
        final userName = userMeta?['full_name'] as String? ??
            userMeta?['name'] as String?;

        String? appVersion;
        try {
          final info = await PackageInfo.fromPlatform();
          appVersion = info.version;
        } catch (_) {}

        final platform = Platform.isIOS ? 'iOS' : 'Android';

        final response = await _client.functions.invoke(
          'send-feedback',
          body: {
            'tipo': tipo,
            'mensagem': mensagem,
            if (screenshotUrl != null) 'screenshot_url': screenshotUrl,
            if (userEmail != null) 'user_email': userEmail,
            if (userName != null) 'user_name': userName,
            if (appVersion != null) 'app_version': appVersion,
            'platform': platform,
          },
        );

        if (response.status != 200) {
          final msg = (response.data is Map)
              ? (response.data as Map)['error'] ?? 'Falha ao enviar feedback'
              : 'Falha ao enviar feedback';
          throw ServerFailure(msg.toString());
        }

        final data = response.data as Map<String, dynamic>;
        return FeedbackResult(protocolo: data['protocolo'] as String);
      });
}
