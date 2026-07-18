import '../entities/assistant_context.dart';
import '../entities/assistant_message.dart';
import '../repositories/assistant_repository.dart';

class AskAssistant {
  const AskAssistant(this._repository);

  final AssistantRepository _repository;

  Future<AssistantMessage> call({
    required AssistantContext context,
    required List<AssistantMessage> history,
    required String question,
  }) {
    return _repository.ask(
      context: context,
      history: history,
      question: question,
    );
  }
}
