import 'package:flutter/material.dart';
import '../../domain/entities/workflow_node.dart';

class WorkflowEditorScope extends InheritedWidget {
  const WorkflowEditorScope({
    super.key,
    required this.onSelect,
    required super.child,
  });
  final ValueChanged<WorkflowNode> onSelect;
  static WorkflowEditorScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkflowEditorScope>();
  @override
  bool updateShouldNotify(WorkflowEditorScope oldWidget) =>
      onSelect != oldWidget.onSelect;
}
