import '../runtime/runtime_session_events.dart';
import 'workspace_api_client.dart';

/// Fehlercode der Runtime, wenn eine Sitzung fehlt, abgelaufen oder beendet ist.
const sessionRequiredErrorCode = 'session_required';

/// Meldet ein Sitzungsende, sobald die Runtime eine Anfrage mit
/// `session_required` abweist, und reicht den Fehler danach unverändert
/// weiter. Andere `401` — etwa ein abgelehnter Lizenz-Token — lösen nichts aus.
class SessionAwareWorkspaceApiClient implements WorkspaceApiClient {
  SessionAwareWorkspaceApiClient(this._inner, this._events);

  final WorkspaceApiClient _inner;
  final RuntimeSessionEvents _events;

  @override
  Future<Map<String, Object?>> delete(String path) =>
      _observe(() => _inner.delete(path));

  @override
  Future<Map<String, Object?>> get(String path) =>
      _observe(() => _inner.get(path));

  @override
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body) =>
      _observe(() => _inner.post(path, body));

  @override
  Future<Map<String, Object?>> postWithTimeout(
    String path,
    Map<String, Object?> body, {
    required Duration timeout,
  }) => _observe(() => _inner.postWithTimeout(path, body, timeout: timeout));

  @override
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body) =>
      _observe(() => _inner.put(path, body));

  @override
  Future<Map<String, Object?>> putStream(
    String path, {
    required Stream<List<int>> body,
    required int contentLength,
    required String contentType,
    Duration? timeout,
  }) => _observe(
    () => _inner.putStream(
      path,
      body: body,
      contentLength: contentLength,
      contentType: contentType,
      timeout: timeout,
    ),
  );

  Future<Map<String, Object?>> _observe(
    Future<Map<String, Object?>> Function() request,
  ) async {
    try {
      return await request();
    } on WorkspaceHttpException catch (error) {
      if (error.statusCode == 401 &&
          error.errorCode == sessionRequiredErrorCode) {
        _events.reportSessionEnded();
      }
      rethrow;
    }
  }
}
