import '../../domain/entities/assistant_context.dart';
import '../../domain/entities/assistant_message.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/firebase_ai_assistant_datasource.dart';
import '../models/assistant_action_suggestion_parser.dart';

class FirebaseAiAssistantRepository implements AssistantRepository {
  const FirebaseAiAssistantRepository(
    this._datasource, {
    this.parser = const AssistantActionSuggestionParser(),
  });

  final FirebaseAiAssistantDatasource _datasource;
  final AssistantActionSuggestionParser parser;

  @override
  Future<AssistantMessage> ask({
    required AssistantContext context,
    required List<AssistantMessage> history,
    required String question,
  }) async {
    final generatedAnswer = await _datasource.ask(
      context: context,
      history: history,
      question: question,
    );
    final parsedAnswer = parser.parse(generatedAnswer.text);
    return AssistantMessage.agent(
      parsedAnswer.text,
      actionSuggestions: parsedAnswer.actionSuggestions,
      urlSources: generatedAnswer.urlSources,
    );
  }
}
