abstract interface class AssistantPlanAction {
  String get label;

  Future<AssistantPlanUndo?> execute();
}

abstract interface class AssistantPlanUndo {
  Future<void> undo();
}
