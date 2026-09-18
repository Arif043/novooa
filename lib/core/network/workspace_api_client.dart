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

class HttpWorkspaceApiClient implements WorkspaceApiClient {
  HttpWorkspaceApiClient({
    required Uri baseUri,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _baseUri = _validatedBaseUri(baseUri),
       _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final Duration timeout;

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
}

Future<Map<String, Object?>> _responseFor(
  http.StreamedResponse response,
) async {
  final text = await response.stream.bytesToString();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw WorkspaceHttpException(response.statusCode, _errorFrom(text));
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

Stream<T> pollWorkspace<T>(
  Future<T> Function() load, {
  Duration interval = const Duration(seconds: 2),
}) async* {
  while (true) {
    yield await load();
    await Future<void>.delayed(interval);
  }
}

Uri _validatedBaseUri(Uri value) {
  if (value.scheme != 'http' || !_isPrivateRuntimeHost(value.host)) {
    throw ArgumentError.value(
      value,
      'baseUri',
      'Die Runtime-Adresse muss eine private IPv4-Adresse sein.',
    );
  }
  return value.replace(
    path: value.path.endsWith('/') ? value.path : '${value.path}/',
  );
}

bool _isPrivateRuntimeHost(String host) {
  final octets = host.split('.');
  if (octets.length != 4) return false;
  final values = octets.map(int.tryParse).toList(growable: false);
  if (values.any((value) => value == null || value < 0 || value > 255)) {
    return false;
  }
  final first = values[0]!;
  final second = values[1]!;
  return first == 127 ||
      first == 10 ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168);
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

WorkspaceApiError _errorFrom(String response) {
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
