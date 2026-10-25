import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'workspace_api_client.dart';

/// Binäre Anfragen an die lokale Runtime (z.B. ZIP-Exporte). Getrennt vom
/// JSON-[WorkspaceApiClient], damit dessen Nutzer nichts davon kennen müssen.
abstract interface class WorkspaceBinaryClient {
  Future<Uint8List> postForBytes(String path, Map<String, Object?> body);

  Future<Map<String, Object?>> postBytes(
    String path, {
    required Uint8List body,
    required String contentType,
  });
}

class HttpWorkspaceBinaryClient implements WorkspaceBinaryClient {
  HttpWorkspaceBinaryClient({
    required Uri baseUri,
    http.Client? client,
    this.timeout = const Duration(minutes: 10),
    this.authHeaderProvider,
  }) : _baseUri = validatedWorkspaceBaseUri(baseUri),
       _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final Duration timeout;
  final AuthHeaderProvider? authHeaderProvider;

  @override
  Future<Uint8List> postForBytes(String path, Map<String, Object?> body) async {
    final request = http.Request('POST', _baseUri.resolve(path))
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode(body);
    return (await _send(request)).bodyBytes;
  }

  @override
  Future<Map<String, Object?>> postBytes(
    String path, {
    required Uint8List body,
    required String contentType,
  }) async {
    final request = http.Request('POST', _baseUri.resolve(path))
      ..headers['accept'] = 'application/json'
      ..headers['content-type'] = contentType
      ..bodyBytes = body;
    final response = await _send(request);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Die Runtime lieferte kein JSON-Objekt.');
    }
    return decoded.cast<String, Object?>();
  }

  Future<http.Response> _send(http.BaseRequest request) async {
    try {
      final header = await authHeaderProvider?.call();
      if (header != null) request.headers['authorization'] = header;
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WorkspaceHttpException(
          response.statusCode,
          workspaceApiErrorFrom(response.body),
        );
      }
      return response;
    } on TimeoutException {
      rethrow;
    } on WorkspaceHttpException {
      rethrow;
    } on Object catch (error) {
      throw WorkspaceConnectionException(error);
    }
  }
}
