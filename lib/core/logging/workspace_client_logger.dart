import '../network/workspace_api_client.dart';
import 'client_logger.dart';

class WorkspaceClientLogger implements ClientLogger {
  WorkspaceClientLogger(this._client);

  final WorkspaceApiClient _client;
  Future<void> _pending = Future.value();

  @override
  void info(String message, {String name = 'novooa'}) {
    _enqueue(level: 'info', message: message, name: name);
  }

  @override
  void exception({
    required String message,
    required Object error,
    StackTrace? stackTrace,
    String name = 'novooa',
  }) {
    _enqueue(
      level: 'error',
      message: message,
      name: name,
      data: {
        'error': _truncate(error.toString(), 4000),
        if (stackTrace != null)
          'stackTrace': _truncate(stackTrace.toString(), 8000),
      },
    );
  }

  Future<void> flush() => _pending;

  void _enqueue({
    required String level,
    required String message,
    required String name,
    Map<String, Object?> data = const {},
  }) {
    final body = <String, Object?>{
      'level': level,
      'event': _eventFrom(name),
      'message': _truncate(message, 4000),
      'data': data,
    };
    _pending = _pending.then((_) async {
      try {
        await _client.post('/v1/application-logs', body);
      } on Object {
        // Logging must never change the application's control flow.
      }
    });
  }

  String _eventFrom(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9._-]'), '_')
        .replaceAll(RegExp('_+'), '_');
    return 'client.${normalized.isEmpty ? 'novooa' : normalized}';
  }

  String _truncate(String value, int maximumLength) =>
      value.length <= maximumLength ? value : value.substring(0, maximumLength);
}
