import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/session_aware_workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/runtime/runtime_session_events.dart';

void main() {
  test(
    'meldet ein Sitzungsende bei session_required und wirft weiter',
    () async {
      final events = RuntimeSessionEvents();
      var reported = 0;
      final subscription = events.sessionEnded.listen((_) => reported++);
      final client = SessionAwareWorkspaceApiClient(
        _FailingClient(
          WorkspaceHttpException(
            401,
            workspaceApiErrorFrom(
              '{"error":"Anmeldung erforderlich.","code":"session_required"}',
            ),
          ),
        ),
        events,
      );

      await expectLater(
        client.get('/v1/tasks'),
        throwsA(isA<WorkspaceHttpException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(reported, 1);
      await subscription.cancel();
      await events.close();
    },
  );

  test(
    'andere 401 wie ein abgelehnter Lizenz-Token lösen nichts aus',
    () async {
      final events = RuntimeSessionEvents();
      var reported = 0;
      final subscription = events.sessionEnded.listen((_) => reported++);
      final client = SessionAwareWorkspaceApiClient(
        _FailingClient(
          WorkspaceHttpException(
            401,
            workspaceApiErrorFrom(
              '{"error":"Token unbekannt.","code":"license_rejected"}',
            ),
          ),
        ),
        events,
      );

      await expectLater(
        client.post('/v1/license/activate', const {}),
        throwsA(isA<WorkspaceHttpException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(reported, 0);
      await subscription.cancel();
      await events.close();
    },
  );

  test('liest den Fehlercode auch aus {error, code}', () {
    final error = workspaceApiErrorFrom(
      '{"error":"x","code":"session_required"}',
    );
    expect(error.code, 'session_required');
  });
}

class _FailingClient implements WorkspaceApiClient {
  _FailingClient(this.error);

  final Object error;

  @override
  Future<Map<String, Object?>> delete(String path) async => throw error;

  @override
  Future<Map<String, Object?>> get(String path) async => throw error;

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async => throw error;

  @override
  Future<Map<String, Object?>> postWithTimeout(
    String path,
    Map<String, Object?> body, {
    required Duration timeout,
  }) async => throw error;

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => throw error;

  @override
  Future<Map<String, Object?>> putStream(
    String path, {
    required Stream<List<int>> body,
    required int contentLength,
    required String contentType,
    Duration? timeout,
  }) async => throw error;
}
