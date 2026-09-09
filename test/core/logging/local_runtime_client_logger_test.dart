import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/logging/local_runtime_client_logger.dart';
import 'package:syscat2/core/network/local_runtime_api_client.dart';

void main() {
  test('sends structured client information to the local runtime', () async {
    final client = _RecordingLocalRuntimeApiClient();
    final logger = LocalRuntimeClientLogger(client);

    logger.info('Lokale Anwendung gestartet.', name: 'flutter');
    await logger.flush();

    expect(client.path, '/v1/application-logs');
    expect(client.body, {
      'level': 'info',
      'event': 'client.flutter',
      'message': 'Lokale Anwendung gestartet.',
      'data': <String, Object?>{},
    });
  });

  test(
    'records exception details without propagating transport failures',
    () async {
      final client = _RecordingLocalRuntimeApiClient(throwsOnPost: true);
      final logger = LocalRuntimeClientLogger(client);

      logger.exception(
        message: 'Unbehandelter Flutter-Fehler.',
        error: StateError('fehlender Zustand'),
        stackTrace: StackTrace.fromString('stack trace'),
      );
      await logger.flush();

      expect(client.body?['level'], 'error');
      expect(client.body?['event'], 'client.novooa');
      expect(client.body?['data'], {
        'error': 'Bad state: fehlender Zustand',
        'stackTrace': 'stack trace',
      });
    },
  );
}

class _RecordingLocalRuntimeApiClient implements LocalRuntimeApiClient {
  _RecordingLocalRuntimeApiClient({this.throwsOnPost = false});

  final bool throwsOnPost;
  String? path;
  Map<String, Object?>? body;

  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> get(String path) async => const {};

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async {
    this.path = path;
    this.body = body;
    if (throwsOnPost) {
      throw const LocalRuntimeConnectionException('nicht erreichbar');
    }
    return const {};
  }

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => const {};
}
