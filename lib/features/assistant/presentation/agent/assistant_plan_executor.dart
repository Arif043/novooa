import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_performer.dart';

import 'assistant_plan_action.dart';
import 'assistant_plan_execution.dart';

typedef AssistantPlanStepChanged = void Function(int index);

class AssistantPlanExecutor {
  const AssistantPlanExecutor({
    this.stepDelay = const Duration(milliseconds: 220),
  });

  final Duration stepDelay;

  Future<AssistantPlanExecution> execute(
    List<AssistantPlanAction> actions, {
    AssistantPlanStepChanged? onStepChanged,
    AgentCursorPerformer? cursor,
  }) async {
    final undoActions = <AssistantPlanUndo>[];
    try {
      for (var index = 0; index < actions.length; index++) {
        onStepChanged?.call(index);
        final undoAction = await _run(actions[index], cursor);
        if (undoAction != null) undoActions.add(undoAction);
        await Future<void>.delayed(stepDelay);
      }
      return AssistantPlanExecution(undoActions);
    } catch (_) {
      await AssistantPlanExecution(undoActions).undo();
      rethrow;
    } finally {
      cursor?.hide();
    }
  }

  Future<AssistantPlanUndo?> _run(
    AssistantPlanAction action,
    AgentCursorPerformer? cursor,
  ) {
    if (cursor != null && action is CursorAwarePlanAction) {
      return action.executeWithCursor(cursor);
    }
    return action.execute();
  }
}
