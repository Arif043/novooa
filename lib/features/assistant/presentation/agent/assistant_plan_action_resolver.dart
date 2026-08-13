import '../../domain/entities/assistant_message.dart';
import 'assistant_plan_action.dart';

abstract interface class AssistantPlanActionResolver {
  List<AssistantPlanAction> actionsFor(AssistantMessage message);
}
