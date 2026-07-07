import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'local_genkit_log.dart';
import 'local_genkit_task_client.dart';

class FirebaseFunctionsTaskClient implements LocalGenkitTaskClient {
  FirebaseFunctionsTaskClient({
    String? endpoint,
    this.timeout = const Duration(seconds: 180),
  }) : endpoint = endpoint ?? _defaultEndpoint;

  static const _projectId = 'syscat-90bff';
  static const _region = 'us-central1';
  static const _functionName = 'runTaskDefinitionFlow';
  static const _port = 5001;
  static const _configuredHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
  );

  final String endpoint;
  final Duration timeout;

  static String get _defaultEndpoint {
    return 'http://$_host:$_port/$_projectId/$_region/$_functionName';
  }

  static String get _host {
    if (_configuredHost.isNotEmpty) return _configuredHost;
    if (kIsWeb) return '127.0.0.1';
    return defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
  }

  @override
  Future<Map<String, Object?>> runTaskDefinition(
    Map<String, Object?> request,
  ) async {
    logLocalGenkitInfo('Starte Firebase Functions Emulator: $endpoint');
    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'data': request}),
          )
          .timeout(timeout);
      return _resultFrom(response);
    } on TimeoutException catch (error, stackTrace) {
      _throwTimeout(error, stackTrace);
    } on http.ClientException catch (error, stackTrace) {
      _throwConnection(error, stackTrace);
    } on FormatException catch (error, stackTrace) {
      _throwExecution(error, stackTrace);
    }
  }

  Map<String, Object?> _resultFrom(http.Response response) {
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const LocalGenkitExecutionException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LocalGenkitExecutionException(
        endpoint: endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
    final result = json['result'];
    if (result is! Map<String, dynamic>) {
      throw LocalGenkitExecutionException(
        endpoint: endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
    return result.cast<String, Object?>();
  }

  Never _throwConnection(Object error, StackTrace stackTrace) {
    final exception = LocalGenkitConnectionException(
      endpoint: endpoint,
      cause: error,
    );
    logLocalGenkitException(
      message: 'Firebase Functions Emulator nicht erreichbar.',
      error: exception,
      stackTrace: stackTrace,
    );
    throw exception;
  }

  Never _throwExecution(Object error, StackTrace stackTrace) {
    final exception = LocalGenkitExecutionException(
      endpoint: endpoint,
      cause: error,
    );
    logLocalGenkitException(
      message: 'Firebase Functions Emulator meldet einen Fehler.',
      error: exception,
      stackTrace: stackTrace,
    );
    throw exception;
  }

  Never _throwTimeout(Object error, StackTrace stackTrace) {
    final exception = LocalGenkitTimeoutException(
      endpoint: endpoint,
      timeout: timeout,
      cause: error,
    );
    logLocalGenkitException(
      message: 'Firebase Functions Emulator hat nicht rechtzeitig geantwortet.',
      error: exception,
      stackTrace: stackTrace,
    );
    throw exception;
  }
}
