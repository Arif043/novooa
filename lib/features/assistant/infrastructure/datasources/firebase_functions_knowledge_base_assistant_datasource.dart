import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/firebase/firebase_region.dart';
import '../../domain/entities/assistant_message.dart';
import '../models/assistant_generated_response.dart';

class FirebaseFunctionsKnowledgeBaseAssistantDatasource {
  FirebaseFunctionsKnowledgeBaseAssistantDatasource({
    FirebaseFunctions? functions,
    this.timeout = const Duration(seconds: 90),
  }) : _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);

  static const _functionName = 'askKnowledgeBaseAssistant';

  final FirebaseFunctions _functions;
  final Duration timeout;

  Future<AssistantGeneratedResponse> ask({
    required List<AssistantMessage> history,
    required String question,
  }) async {
    final callable = _functions.httpsCallable(
      _functionName,
      options: HttpsCallableOptions(timeout: timeout),
    );
    final response = await callable
        .call<Map<dynamic, dynamic>>(_request(history, question))
        .timeout(timeout);
    return AssistantGeneratedResponse(
      text: jsonEncode(_responseMap(response.data)),
    );
  }

  Map<String, Object?> _request(
    List<AssistantMessage> history,
    String question,
  ) {
    final priorMessages = history.length > 1
        ? history.sublist(0, history.length - 1)
        : const <AssistantMessage>[];
    return {
      'question': question,
      'history': priorMessages.take(8).map(_messageMap).toList(growable: false),
    };
  }

  Map<String, Object?> _messageMap(AssistantMessage message) {
    return {
      'role': message.role == AssistantMessageRole.agent ? 'agent' : 'user',
      'text': message.text,
    };
  }

  Map<String, Object?> _responseMap(Map<dynamic, dynamic> response) {
    final value = response.cast<String, Object?>();
    if (value['answer'] is! String) {
      throw StateError('Die Wissensbasis-Antwort ist ungültig.');
    }
    return value;
  }
}
