import 'assistant_plan_action.dart';

class AssistantPlanExecution {
  const AssistantPlanExecution(this._undoActions);

  final List<AssistantPlanUndo> _undoActions;

  bool get canUndo => _undoActions.isNotEmpty;

  Future<void> undo() async {
    for (final action in _undoActions.reversed) {
      await action.undo();
    }
  }
}
