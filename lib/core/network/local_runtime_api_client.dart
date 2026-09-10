import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

abstract interface class LocalRuntimeApiClient {
  Future<Map<String, Object?>> delete(String path);
  Future<Map<String, Object?>> get(String path);
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body);
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body);
}

class HttpLocalRuntimeApiClient implements LocalRuntimeApiClient {
  HttpLocalRuntimeApiClient({
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
      final text = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw LocalRuntimeHttpException(response.statusCode, _errorFrom(text));
      }
      if (text.trim().isEmpty) return const {};
      return _objectFrom(jsonDecode(text));
    } on TimeoutException {
      rethrow;
    } on LocalRuntimeHttpException {
      rethrow;
    } on Object catch (error) {
      throw LocalRuntimeConnectionException(error);
    }
  }
}

class LocalRuntimeConnectionException implements Exception {
  const LocalRuntimeConnectionException(this.cause);

  final Object cause;

  @override
  String toString() => 'Lokale Runtime nicht erreichbar: $cause';
}

class LocalRuntimeHttpException implements Exception {
  LocalRuntimeHttpException(this.statusCode, LocalRuntimeError error)
    : message = error.message,
      errorCode = error.code;

  final int statusCode;
  final String message;
  final String? errorCode;

  @override
  String toString() => 'Lokale Runtime antwortete mit $statusCode: $message';
}

Stream<T> pollLocalRuntime<T>(
  Future<T> Function() load, {
  Duration interval = const Duration(seconds: 2),
}) async* {
  while (true) {
    yield await load();
    await Future<void>.delayed(interval);
  }
}

Uri _validatedBaseUri(Uri value) {
  const loopbackHosts = {'127.0.0.1', 'localhost', '::1'};
  if (value.scheme != 'http' || !loopbackHosts.contains(value.host)) {
    throw ArgumentError.value(
      value,
      'baseUri',
      'Die lokale Runtime muss auf Loopback laufen.',
    );
  }
  return value.replace(
    path: value.path.endsWith('/') ? value.path : '${value.path}/',
  );
}

Map<String, Object?> _objectFrom(Object? value) {
  if (value is! Map) {
    throw const FormatException(
      'Die lokale Runtime lieferte kein JSON-Objekt.',
    );
  }
  return {for (final entry in value.entries) entry.key.toString(): entry.value};
}

class LocalRuntimeError {
  const LocalRuntimeError({required this.message, this.code});

  final String message;
  final String? code;
}

LocalRuntimeError _errorFrom(String response) {
  try {
    final json = _objectFrom(jsonDecode(response));
    final failure = json['failure'];
    if (failure is Map) {
      final message = failure['message'];
      final code = failure['code'];
      if (message is String) {
        return LocalRuntimeError(
          message: message,
          code: code is String ? code : null,
        );
      }
    }
    final message = json['error'];
    if (message is String) return LocalRuntimeError(message: message);
  } catch (_) {
    // The HTTP status remains available to callers.
  }
  return const LocalRuntimeError(
    message: 'Die lokale Runtime konnte die Anfrage nicht verarbeiten.',
  );
}
