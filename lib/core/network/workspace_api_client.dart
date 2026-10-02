import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class WorkspaceApiClient {
  Future<Map<String, Object?>> delete(String path);
  Future<Map<String, Object?>> get(String path);
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body);
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body);
  Future<Map<String, Object?>> putStream(
    String path, {
    required Stream<List<int>> body,
    required int contentLength,
    required String contentType,
    Duration? timeout,
  }) => throw UnsupportedError(
    'Stream-Uploads werden von diesem Client nicht unterstützt.',
  );
}

/// Liefert den Wert des `Authorization`-Headers (z.B. `Bearer <token>`) oder
/// `null`, falls (noch) keine Session besteht. Wird vor jedem Request neu
/// abgefragt, damit ein nach dem Verbindungsaufbau erhaltenes Token sofort
/// wirkt, ohne den Client neu zu bauen.
typedef AuthHeaderProvider = Future<String?> Function();

class HttpWorkspaceApiClient implements WorkspaceApiClient {
  HttpWorkspaceApiClient({
    required Uri baseUri,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    AuthHeaderProvider? authHeaderProvider,
  }) : _baseUri = validatedWorkspaceBaseUri(baseUri),
       _client = client ?? http.Client(),
       _authHeaderProvider = authHeaderProvider;

  final Uri _baseUri;
  final http.Client _client;
  final Duration timeout;
  final AuthHeaderProvider? _authHeaderProvider;

  @override
  Future<Map<String, Object?>> delete(String path) => _request('DELETE', path);

  @override
  Future<Map<String, Object?>> get(String path) => _request('GET', path);

  @override
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body) {
    return _request('POST', path, body: body);
  }

  @override
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body) {
    return _request('PUT', path, body: body);
  }

  @override
  Future<Map<String, Object?>> putStream(
    String path, {
    required Stream<List<int>> body,
    required int contentLength,
    required String contentType,
    Duration? timeout,
  }) async {
    try {
      final request = http.StreamedRequest('PUT', _baseUri.resolve(path));
      request.headers['accept'] = 'application/json';
      request.headers['content-type'] = contentType;
      request.contentLength = contentLength;
      await _applyAuthHeader(request);
      final response = _client.send(request);
      try {
        await request.sink.addStream(body);
      } finally {
        await request.sink.close();
      }
      return _responseFor(await response.timeout(timeout ?? this.timeout));
    } on TimeoutException {
      rethrow;
    } on WorkspaceHttpException {
      rethrow;
    } on Object catch (error) {
      throw WorkspaceConnectionException(error);
    }
  }

  Future<Map<String, Object?>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    try {
      final request = http.Request(method, _baseUri.resolve(path));
      request.headers['accept'] = 'application/json';
      if (body != null) {
        request.headers['content-type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      await _applyAuthHeader(request);
      final response = await _client.send(request).timeout(timeout);
      return _responseFor(response);
    } on TimeoutException {
      rethrow;
    } on WorkspaceHttpException {
      rethrow;
    } on Object catch (error) {
      throw WorkspaceConnectionException(error);
    }
  }

  Future<void> _applyAuthHeader(http.BaseRequest request) async {
    final header = await _authHeaderProvider?.call();
    if (header != null) request.headers['authorization'] = header;
  }
}

Future<Map<String, Object?>> _responseFor(
  http.StreamedResponse response,
) async {
  final text = await response.stream.bytesToString();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw WorkspaceHttpException(
      response.statusCode,
      workspaceApiErrorFrom(text),
    );
  }
  if (text.trim().isEmpty) return const {};
  return _objectFrom(jsonDecode(text));
}

class WorkspaceConnectionException implements Exception {
  const WorkspaceConnectionException(this.cause);

  final Object cause;

  @override
  String toString() => 'Runtime nicht erreichbar: $cause';
}

class WorkspaceHttpException implements Exception {
  WorkspaceHttpException(this.statusCode, WorkspaceApiError error)
    : message = error.message,
      errorCode = error.code;

  final int statusCode;
  final String message;
  final String? errorCode;

  @override
  String toString() => 'Runtime antwortete mit $statusCode: $message';
}

/// Fragt [load] alle [interval] erneut ab. Ein einzelner fehlgeschlagener
/// Tick beendet den Stream bewusst nicht dauerhaft — sonst würde z.B. ein
/// abgelaufenes Runtime-Passwort (401, etwa direkt nach `signOut()`) oder ein
/// kurzer Netzwerkaussetzer jede weitere Aktualisierung für die Lebensdauer
/// dieses Streams verhindern, obwohl der nächste Tick (nach erneuter
/// Anmeldung bzw. wiederhergestellter Verbindung) wieder funktionieren
/// würde. Der Fehler wird trotzdem als Stream-Error weitergereicht — an
/// [StreamSubscription.onError] hängende Cubits (z.B. `ActivityCubit`)
/// zeigen ihn also weiterhin an, statt ihn stillschweigend zu verschlucken.
Stream<T> pollWorkspace<T>(
  Future<T> Function() load, {
  Duration interval = const Duration(seconds: 2),
}) {
  late final StreamController<T> controller;
  Timer? timer;
  var isTicking = false;

  Future<void> tick() async {
    if (isTicking) return;
    isTicking = true;
    try {
      controller.add(await load());
    } on Object catch (error, stackTrace) {
      controller.addError(error, stackTrace);
    } finally {
      isTicking = false;
    }
  }

  controller = StreamController<T>(
    onListen: () {
      unawaited(tick());
      timer = Timer.periodic(interval, (_) => unawaited(tick()));
    },
    onCancel: () => timer?.cancel(),
  );
  return controller.stream;
}

/// Welche Adresse gültig ist und ob sie über `http` (IP im vertrauenswürdigen
/// Netz) oder `https` (Domain hinter einem Reverse Proxy mit Zertifikat)
/// angesprochen wird, entscheidet `RuntimeEndpoint`. Hier wird nur
/// sichergestellt, dass überhaupt ein HTTP-Schema vorliegt.
Uri validatedWorkspaceBaseUri(Uri value) {
  if (value.scheme != 'http' && value.scheme != 'https') {
    throw ArgumentError.value(
      value,
      'baseUri',
      'Die Runtime-Adresse muss http oder https verwenden.',
    );
  }
  return value.replace(
    path: value.path.endsWith('/') ? value.path : '${value.path}/',
  );
}

Map<String, Object?> _objectFrom(Object? value) {
  if (value is! Map) {
    throw const FormatException('Die Runtime lieferte kein JSON-Objekt.');
  }
  return {for (final entry in value.entries) entry.key.toString(): entry.value};
}

class WorkspaceApiError {
  const WorkspaceApiError({required this.message, this.code});

  final String message;
  final String? code;
}

WorkspaceApiError workspaceApiErrorFrom(String response) {
  try {
    final json = _objectFrom(jsonDecode(response));
    final failure = json['failure'];
    if (failure is Map) {
      final message = failure['message'];
      final code = failure['code'];
      if (message is String) {
        return WorkspaceApiError(
          message: message,
          code: code is String ? code : null,
        );
      }
    }
    final message = json['error'];
    if (message is String) return WorkspaceApiError(message: message);
  } catch (_) {
    // The HTTP status remains available to callers.
  }
  return const WorkspaceApiError(
    message: 'Die Runtime konnte die Anfrage nicht verarbeiten.',
  );
}
