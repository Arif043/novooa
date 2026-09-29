import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/firebase/firebase_region.dart';
import '../../domain/entities/assistant_message.dart';
import '../models/assistant_generated_response.dart';
import 'assistant_datasource.dart';

class FirebaseFunctionsAssistantDatasource implements AssistantDatasource {
  FirebaseFunctionsAssistantDatasource({
    required this.functionName,
    FirebaseFunctions? functions,
    this.timeout = const Duration(seconds: 90),
  }) : _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);

  final String functionName;
  final FirebaseFunctions _functions;
  final Duration timeout;

  @override
  Future<AssistantGeneratedResponse> ask({
    required List<AssistantMessage> history,
    required String question,
  }) async {
    final callable = _functions.httpsCallable(
      functionName,
      options: HttpsCallableOptions(timeout: timeout),
    );
    final response = await callable
        .call<Map<dynamic, dynamic>>(
          assistantRequestBody(history: history, question: question),
        )
        .timeout(timeout);
    return AssistantGeneratedResponse(
      text: jsonEncode(assistantResponseMapFrom(response.data)),
    );
  }
}
