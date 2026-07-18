import '../entities/assistant_context.dart';
import '../entities/assistant_message.dart';

abstract class AssistantRepository {
  Future<AssistantMessage> ask({
    required AssistantContext context,
    required List<AssistantMessage> history,
    required String question,
  });
}
