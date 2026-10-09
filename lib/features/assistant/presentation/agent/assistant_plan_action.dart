import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_performer.dart';

abstract interface class AssistantPlanAction {
  String get label;

  Future<AssistantPlanUndo?> execute();
}

/// Aktion, die ihre Änderung sichtbar über den Agent-Cursor ausführen kann.
abstract interface class CursorAwarePlanAction implements AssistantPlanAction {
  Future<AssistantPlanUndo?> executeWithCursor(AgentCursorPerformer cursor);
}

abstract interface class AssistantPlanUndo {
  Future<void> undo();
}
