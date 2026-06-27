import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'local_genkit_task_client.dart';

class LocalGenkitProxyTaskClient implements LocalGenkitTaskClient {
  const LocalGenkitProxyTaskClient({
    this.endpoint = 'http://127.0.0.1:3400/runTaskDefinitionFlow',
    this.timeout = const Duration(seconds: 30),
  });

  final String endpoint;
  final Duration timeout;

  @override
  Future<Map<String, Object?>> runTaskDefinition(
    Map<String, Object?> request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(request),
          )
          .timeout(timeout);
      return _resultFrom(response);
    } on TimeoutException {
      throw const LocalGenkitConnectionException();
    } on http.ClientException {
      throw const LocalGenkitConnectionException();
    } on FormatException {
      throw const LocalGenkitExecutionException();
    }
  }

  Map<String, Object?> _resultFrom(http.Response response) {
    if (response.statusCode == 503) {
      throw const LocalGenkitConnectionException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const LocalGenkitExecutionException();
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const LocalGenkitExecutionException();
    }
    return json.cast<String, Object?>();
  }
}
