import '../../domain/entities/assistant_context.dart';
import '../../domain/entities/assistant_message.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/assistant_datasource.dart';
import '../models/assistant_action_suggestion_parser.dart';
import '../models/assistant_generated_response.dart';

/// Wählt zwischen den zwei bereichsspezifischen Datasources.
class RoutedAssistantRepository implements AssistantRepository {
  const RoutedAssistantRepository(
    this._taskBuilderDatasource,
    this._knowledgeBaseDatasource, {
    this.parser = const AssistantActionSuggestionParser(),
  });

  final AssistantDatasource _taskBuilderDatasource;
  final AssistantDatasource _knowledgeBaseDatasource;
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
      return _knowledgeBaseDatasource.ask(
        history: history,
        question: question,
        languageCode: context.languageCode,
      );
    }
    return _taskBuilderDatasource.ask(
      history: history,
      question: question,
      languageCode: context.languageCode,
    );
  }
}
