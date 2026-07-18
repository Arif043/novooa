import '../../domain/entities/assistant_context.dart';
import '../../domain/entities/assistant_message.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/firebase_ai_assistant_datasource.dart';

class FirebaseAiAssistantRepository implements AssistantRepository {
  const FirebaseAiAssistantRepository(this._datasource);

  final FirebaseAiAssistantDatasource _datasource;

  @override
  Future<AssistantMessage> ask({
    required AssistantContext context,
    required List<AssistantMessage> history,
    required String question,
  }) async {
    final text = await _datasource.ask(
      context: context,
      history: history,
      question: question,
    );
    return AssistantMessage.agent(text);
  }
}
