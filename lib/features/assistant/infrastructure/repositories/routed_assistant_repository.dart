import '../../domain/entities/assistant_context.dart';
import '../../domain/entities/assistant_message.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/firebase_ai_assistant_datasource.dart';
import '../datasources/firebase_functions_knowledge_base_assistant_datasource.dart';
import '../models/assistant_action_suggestion_parser.dart';
import '../models/assistant_generated_response.dart';

class RoutedAssistantRepository implements AssistantRepository {
  const RoutedAssistantRepository(
    this._firebaseAiDatasource,
    this._knowledgeBaseDatasource, {
    this.parser = const AssistantActionSuggestionParser(),
  });

  final FirebaseAiAssistantDatasource _firebaseAiDatasource;
  final FirebaseFunctionsKnowledgeBaseAssistantDatasource
  _knowledgeBaseDatasource;
  final AssistantActionSuggestionParser parser;

  @override
  Future<AssistantMessage> ask({
    required AssistantContext context,
    required List<AssistantMessage> history,
    required String question,
  }) async {
    final generatedAnswer = await _answerFor(context, history, question);
    final parsedAnswer = parser.parse(generatedAnswer.text);
    return AssistantMessage.agent(
      parsedAnswer.text,
      actionSuggestions: parsedAnswer.actionSuggestions,
      urlSources: generatedAnswer.urlSources,
    );
  }

  Future<AssistantGeneratedResponse> _answerFor(
    AssistantContext context,
    List<AssistantMessage> history,
    String question,
  ) {
    if (context.area == AssistantArea.knowledgeBase) {
      return _knowledgeBaseDatasource.ask(history: history, question: question);
    }
    return _firebaseAiDatasource.ask(
      context: context,
      history: history,
      question: question,
    );
  }
}
