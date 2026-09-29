import 'dart:convert';

import '../../../../core/network/workspace_api_client.dart';
import '../../domain/entities/assistant_message.dart';
import '../models/assistant_generated_response.dart';
import 'assistant_datasource.dart';

/// Standalone-Pendant zu `FirebaseFunctionsAssistantDatasource` — spricht
/// denselben Anfrage-/Antwort-Vertrag über die lokale Runtime statt über
/// eine Firebase Callable Function an.
class HttpRuntimeAssistantDatasource implements AssistantDatasource {
  const HttpRuntimeAssistantDatasource(this._client, this._path);

  final WorkspaceApiClient _client;
  final String _path;

  @override
  Future<AssistantGeneratedResponse> ask({
    required List<AssistantMessage> history,
    required String question,
  }) async {
    final response = await _client.post(
      _path,
      assistantRequestBody(history: history, question: question),
    );
    return AssistantGeneratedResponse(
      text: jsonEncode(assistantResponseMapFrom(response)),
    );
  }
}

class HttpRuntimeTaskBuilderAssistantDatasource
    extends HttpRuntimeAssistantDatasource {
  const HttpRuntimeTaskBuilderAssistantDatasource(WorkspaceApiClient client)
    : super(client, '/v1/assistant/task-builder');
}

class HttpRuntimeKnowledgeBaseAssistantDatasource
    extends HttpRuntimeAssistantDatasource {
  const HttpRuntimeKnowledgeBaseAssistantDatasource(WorkspaceApiClient client)
    : super(client, '/v1/assistant/knowledge-base');
}
