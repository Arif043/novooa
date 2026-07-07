import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'local_genkit_log.dart';
import 'task_client.dart';

class LocalGenkitProxyTaskClient implements TaskClient {
  LocalGenkitProxyTaskClient({
    String endpoint = 'http://127.0.0.1:3400/runTaskDefinitionFlow',
    List<String>? fallbackEndpoints,
    this.timeout = const Duration(seconds: 180),
  }) : endpoints = [endpoint, ...?fallbackEndpoints, 'http://10.0.2.2:3400/runTaskDefinitionFlow'];

  final List<String> endpoints;
  final Duration timeout;

  @override
  Future<Map<String, Object?>> runTaskDefinition(Map<String, Object?> request) async {
    logLocalGenkitInfo('Starte lokale Genkit-Ausführung mit ${endpoints.length} Endpoint(s).');
    LocalGenkitConnectionException? lastConnectionFailure;
    for (final endpoint in endpoints) {
      try {
        return await _runAt(endpoint, request);
      } on LocalGenkitConnectionException catch (failure) {
        logLocalGenkitException(message: 'Lokaler Genkit-Endpunkt nicht erreichbar: $endpoint', error: failure);
        lastConnectionFailure = failure;
      } on LocalGenkitTimeoutException {
        rethrow;
      }
    }
    throw lastConnectionFailure ?? const LocalGenkitConnectionException();
  }

  Future<Map<String, Object?>> _runAt(String endpoint, Map<String, Object?> request) async {
    logLocalGenkitInfo('Versuche lokalen Genkit-Endpunkt: $endpoint');
    try {
      final response = await http
          .post(Uri.parse(endpoint), headers: {'content-type': 'application/json'}, body: jsonEncode(request))
          .timeout(timeout);
      logLocalGenkitInfo(
        'Antwort vom lokalen Genkit-Endpunkt $endpoint: '
        'HTTP ${response.statusCode}',
      );
      return _resultFrom(endpoint, response);
    } on TimeoutException catch (error, stackTrace) {
      _throwTimeoutException(
        LocalGenkitTimeoutException(endpoint: endpoint, timeout: timeout, cause: error),
        stackTrace,
      );
    } on http.ClientException catch (error, stackTrace) {
      _throwConnectionException(LocalGenkitConnectionException(endpoint: endpoint, cause: error), stackTrace);
    } on FormatException catch (error, stackTrace) {
      _throwExecutionException(LocalGenkitExecutionException(endpoint: endpoint, cause: error), stackTrace);
    }
  }

  Never _throwConnectionException(LocalGenkitConnectionException error, StackTrace stackTrace) {
    logLocalGenkitException(message: 'Lokale Genkit-Verbindung fehlgeschlagen.', error: error, stackTrace: stackTrace);
    throw error;
  }

  Never _throwExecutionException(LocalGenkitExecutionException error, StackTrace stackTrace) {
    logLocalGenkitException(message: 'Lokale Genkit-Ausführung fehlgeschlagen.', error: error, stackTrace: stackTrace);
    throw error;
  }

  Never _throwTimeoutException(LocalGenkitTimeoutException error, StackTrace stackTrace) {
    logLocalGenkitException(
      message: 'Lokale Genkit-Ausführung hat das Zeitlimit überschritten.',
      error: error,
      stackTrace: stackTrace,
    );
    throw error;
  }

  Map<String, Object?> _resultFrom(String endpoint, http.Response response) {
    if (response.statusCode == 503) {
      logLocalGenkitException(
        message: 'Lokaler Genkit-Endpunkt meldet nicht erreichbar.',
        error: 'Endpoint: $endpoint\nHTTP 503\nBody: ${response.body}',
      );
      throw LocalGenkitConnectionException(endpoint: endpoint, cause: 'HTTP 503: ${response.body}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      logLocalGenkitException(
        message: 'Lokaler Genkit-Endpunkt meldet Ausführungsfehler.',
        error:
            'Endpoint: $endpoint\nHTTP ${response.statusCode}\n'
            'Body: ${response.body}',
      );
      throw LocalGenkitExecutionException(
        endpoint: endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      logLocalGenkitException(
        message: 'Lokaler Genkit-Endpunkt lieferte ungültiges JSON.',
        error: 'Endpoint: $endpoint\nBody: ${response.body}',
      );
      throw LocalGenkitExecutionException(
        endpoint: endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
        cause: 'Antwort ist kein JSON-Objekt.',
      );
    }
    return json.cast<String, Object?>();
  }
}
