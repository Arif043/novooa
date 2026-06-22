import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_definition.dart';
import '../../domain/entities/workflow_node.dart';
import 'add_node_button.dart';
import 'builder_footer.dart';
import 'canvas_header.dart';
import 'node_inspector.dart';
import 'workflow_canvas.dart';

/// 2-Spalten-Layout für den Builder-Body.
///
/// Linke Spalte: Header (Titel + Objective) + scrollbarer Flow +
/// Add-Button. Rechte Spalte: Inspector. Unten: Footer mit Status +
/// Aktionen.
///
/// Auf schmalen Screens (< 860 px) stapelt sich alles vertikal in
/// einem scrollbaren [ListView], beginnend mit dem Footer.
class WorkflowBuilderView extends StatelessWidget {
  const WorkflowBuilderView({
    super.key,
    required this.taskDefinition,
    required this.activePrimitive,
    required this.onPrimitiveAdded,
    required this.onNodeSelected,
    required this.onNodeDeleted,
    required this.onTitleChanged,
    required this.onObjectiveChanged,
    required this.onDescriptionChanged,
    required this.onLogicModeChanged,
    required this.onConditionChanged,
    required this.onSave,
    required this.onDiscard,
  });

  final TaskDefinition taskDefinition;
  final WorkflowPrimitive? activePrimitive;
  final ValueChanged<WorkflowPrimitive> onPrimitiveAdded;
  final ValueChanged<NodeId> onNodeSelected;
  final ValueChanged<NodeId> onNodeDeleted;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onObjectiveChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<LogicMode> onLogicModeChanged;
  final ValueChanged<({NodeId from, NodeId to, String? label})> onConditionChanged;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return _NarrowLayout(
            taskDefinition: taskDefinition,
            onPrimitiveAdded: onPrimitiveAdded,
            onNodeSelected: onNodeSelected,
            onNodeDeleted: onNodeDeleted,
            onTitleChanged: onTitleChanged,
            onObjectiveChanged: onObjectiveChanged,
            onDescriptionChanged: onDescriptionChanged,
            onLogicModeChanged: onLogicModeChanged,
            onConditionChanged: onConditionChanged,
            onSave: onSave,
            onDiscard: onDiscard,
          );
        }
        return _WideLayout(
          taskDefinition: taskDefinition,
          onPrimitiveAdded: onPrimitiveAdded,
          onNodeSelected: onNodeSelected,
          onNodeDeleted: onNodeDeleted,
          onTitleChanged: onTitleChanged,
          onObjectiveChanged: onObjectiveChanged,
          onDescriptionChanged: onDescriptionChanged,
          onLogicModeChanged: onLogicModeChanged,
          onConditionChanged: onConditionChanged,
          onSave: onSave,
          onDiscard: onDiscard,
        );
      },
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.taskDefinition,
    required this.onPrimitiveAdded,
    required this.onNodeSelected,
    required this.onNodeDeleted,
    required this.onTitleChanged,
    required this.onObjectiveChanged,
    required this.onDescriptionChanged,
    required this.onLogicModeChanged,
    required this.onConditionChanged,
    required this.onSave,
    required this.onDiscard,
  });

  final TaskDefinition taskDefinition;
  final ValueChanged<WorkflowPrimitive> onPrimitiveAdded;
  final ValueChanged<NodeId> onNodeSelected;
  final ValueChanged<NodeId> onNodeDeleted;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onObjectiveChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<LogicMode> onLogicModeChanged;
  final ValueChanged<({NodeId from, NodeId to, String? label})> onConditionChanged;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CanvasHeader(
                      title: taskDefinition.title,
                      objective: taskDefinition.objective,
                      onTitleChanged: onTitleChanged,
                      onObjectiveChanged: onObjectiveChanged,
                    ),
                    Expanded(
                      child: WorkflowCanvas(
                        taskDefinition: taskDefinition,
                        onNodeSelected: onNodeSelected,
                        onNodeDeleted: onNodeDeleted,
                      ),
                    ),
                    AddNodeButton(onPrimitiveAdded: onPrimitiveAdded),
                  ],
                ),
              ),
              SizedBox(
                width: 320,
                child: NodeInspector(
                  taskDefinition: taskDefinition,
                  onDescriptionChanged: onDescriptionChanged,
                  onLogicModeChanged: onLogicModeChanged,
                  onConditionChanged: (edit) => onConditionChanged((
                    from: edit.from,
                    to: edit.to,
                    label: edit.label,
                  )),
                ),
              ),
            ],
          ),
        ),
        BuilderFooter(
          nodeCount: taskDefinition.nodes.length,
          onSave: onSave,
          onDiscard: onDiscard,
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.taskDefinition,
    required this.onPrimitiveAdded,
    required this.onNodeSelected,
    required this.onNodeDeleted,
    required this.onTitleChanged,
    required this.onObjectiveChanged,
    required this.onDescriptionChanged,
    required this.onLogicModeChanged,
    required this.onConditionChanged,
    required this.onSave,
    required this.onDiscard,
  });

  final TaskDefinition taskDefinition;
  final ValueChanged<WorkflowPrimitive> onPrimitiveAdded;
  final ValueChanged<NodeId> onNodeSelected;
  final ValueChanged<NodeId> onNodeDeleted;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onObjectiveChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<LogicMode> onLogicModeChanged;
  final ValueChanged<({NodeId from, NodeId to, String? label})> onConditionChanged;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        CanvasHeader(
          title: taskDefinition.title,
          objective: taskDefinition.objective,
          onTitleChanged: onTitleChanged,
          onObjectiveChanged: onObjectiveChanged,
        ),
        SizedBox(
          height: 420,
          child: WorkflowCanvas(
            taskDefinition: taskDefinition,
            onNodeSelected: onNodeSelected,
            onNodeDeleted: onNodeDeleted,
          ),
        ),
        AddNodeButton(onPrimitiveAdded: onPrimitiveAdded),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 480,
          child: NodeInspector(
            taskDefinition: taskDefinition,
            onDescriptionChanged: onDescriptionChanged,
            onLogicModeChanged: onLogicModeChanged,
            onConditionChanged: (edit) => onConditionChanged((
              from: edit.from,
              to: edit.to,
              label: edit.label,
            )),
          ),
        ),
        BuilderFooter(
          nodeCount: taskDefinition.nodes.length,
          onSave: onSave,
          onDiscard: onDiscard,
        ),
      ],
    );
  }
}