import 'dart:convert';

import 'package:http/http.dart' as http;

import 'local_genkit_task_client.dart';

class LocalGenkitReflectionTaskClient implements LocalGenkitTaskClient {
  const LocalGenkitReflectionTaskClient({
    this.endpoints = const [
      'http://127.0.0.1:3100/api/runAction',
      'http://127.0.0.1:3101/api/runAction',
    ],
    this.actionKey = '/flow/runTaskDefinitionFlow',
  });

  final List<String> endpoints;
  final String actionKey;

  @override
  Future<Map<String, Object?>> runTaskDefinition(
    Map<String, Object?> request,
  ) async {
    for (final endpoint in endpoints) {
      final response = await _tryRun(endpoint, request);
      if (response != null) return response;
    }
    throw const LocalGenkitConnectionException();
  }

  Future<Map<String, Object?>?> _tryRun(
    String endpoint,
    Map<String, Object?> request,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'key': actionKey, 'input': request}),
      );
      if (response.statusCode == 404) return null;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const LocalGenkitExecutionException();
      }
      return _resultFrom(response.body);
    } on http.ClientException {
      return null;
    } on FormatException {
      throw const LocalGenkitExecutionException();
    }
  }

  Map<String, Object?> _resultFrom(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['error'] != null) throw const LocalGenkitExecutionException();
    final result = json['result'];
    if (result is! Map<String, dynamic>) {
      throw const LocalGenkitExecutionException();
    }
    return result.cast<String, Object?>();
  }
}
