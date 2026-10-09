import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_performer.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/agent/agent_node_refs.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_key.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_player.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

final class AddNodeAgentCommand extends TaskBuilderAgentCommand {
  AddNodeAgentCommand({
    required String label,
    required this.primitive,
    required this.channelKind,
    Map<NodeFieldKey, String> fields = const {},
    this.ref,
    AgentNodeRefs? refs,
    this.waitForFrame = waitForNextFrame,
  }) : fields = Map.unmodifiable(fields),
       refs = refs ?? AgentNodeRefs(),
       super(label);

  final WorkflowPrimitive primitive;
  final ChannelEventKind channelKind;
  final Map<NodeFieldKey, String> fields;
  final String? ref;
  final AgentNodeRefs refs;
  final FrameWaiter waitForFrame;

  @override
  Future<void> perform(TaskBuilderCubit cubit) => _add(cubit, null);

  @override
  Future<void> performWithCursor(
    TaskBuilderCubit cubit,
    AgentCursorPerformer cursor,
  ) => _add(cubit, cursor);

  Future<void> _add(
    TaskBuilderCubit cubit,
    AgentCursorPerformer? cursor,
  ) async {
    await _addPrimitive(cubit);
    final nodeId = cubit.loadedTaskOrNull()?.selectedNodeOrNull?.id;
    if (nodeId == null) return;
    refs.bind(ref, nodeId);
    await NodeFieldPlayer(
      cubit,
      waitForFrame: waitForFrame,
    ).fill(nodeId, fields, cursor: cursor);
  }

  Future<void> _addPrimitive(TaskBuilderCubit cubit) {
    return switch (primitive) {
      WorkflowPrimitive.readChannelEvent =>
        cubit.addChannelEventNodeToMainGraph(channelKind),
      WorkflowPrimitive.sendChannelMessage =>
        cubit.addSendMessageNodeToMainGraph(channelKind),
      _ => cubit.addNodeToMainGraph(primitive),
    };
  }
}
