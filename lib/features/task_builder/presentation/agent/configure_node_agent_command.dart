import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_performer.dart';
import 'package:syscat2/features/task_builder/presentation/agent/agent_node_refs.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_key.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_player.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

/// Befüllt die Eingabemaske eines bestehenden oder zuvor geplanten Bausteins.
final class ConfigureNodeAgentCommand extends TaskBuilderAgentCommand {
  ConfigureNodeAgentCommand({
    required String label,
    required this.nodeRef,
    required Map<NodeFieldKey, String> fields,
    required this.refs,
    this.waitForFrame = waitForNextFrame,
  }) : fields = Map.unmodifiable(fields),
       super(label);

  final String nodeRef;
  final Map<NodeFieldKey, String> fields;
  final AgentNodeRefs refs;
  final FrameWaiter waitForFrame;

  @override
  Future<void> perform(TaskBuilderCubit cubit) {
    return NodeFieldPlayer(
      cubit,
      waitForFrame: waitForFrame,
    ).fill(refs.resolve(nodeRef), fields);
  }

  @override
  Future<void> performWithCursor(
    TaskBuilderCubit cubit,
    AgentCursorPerformer cursor,
  ) {
    return NodeFieldPlayer(
      cubit,
      waitForFrame: waitForFrame,
    ).fill(refs.resolve(nodeRef), fields, cursor: cursor);
  }
}
