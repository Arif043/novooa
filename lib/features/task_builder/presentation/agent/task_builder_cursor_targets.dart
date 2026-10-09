import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_target.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_key.dart';

abstract final class TaskBuilderCursorTargets {
  static AgentCursorTarget node(NodeId id) =>
      AgentCursorTarget('node:${id.value}');

  static AgentCursorTarget field(NodeId id, NodeFieldKey key) =>
      AgentCursorTarget('field:${id.value}:${key.name}');
}
