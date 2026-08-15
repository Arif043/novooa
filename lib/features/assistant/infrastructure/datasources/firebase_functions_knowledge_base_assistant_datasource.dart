import 'firebase_functions_assistant_datasource.dart';

class FirebaseFunctionsKnowledgeBaseAssistantDatasource
    extends FirebaseFunctionsAssistantDatasource {
  FirebaseFunctionsKnowledgeBaseAssistantDatasource({
    super.functions,
    super.timeout = const Duration(seconds: 90),
  }) : super(functionName: 'askKnowledgeBaseAssistant');
}
