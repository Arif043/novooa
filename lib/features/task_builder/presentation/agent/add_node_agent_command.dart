import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_performer.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_target.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_cursor_targets.dart';
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
    final nodeId = await _addNode(cubit, cursor);
    if (nodeId == null) return;
    refs.bind(ref, nodeId);
    await NodeFieldPlayer(
      cubit,
      waitForFrame: waitForFrame,
    ).fill(nodeId, fields, cursor: cursor);
  }

  /// Mit Cursor über das Baustein-Menü links, sonst (oder ohne Menü) direkt.
  Future<NodeId?> _addNode(
    TaskBuilderCubit cubit,
    AgentCursorPerformer? cursor,
  ) async {
    final knownIds = _nodeIds(cubit);
    final clicked = await cursor?.click(_paletteTarget) ?? false;
    if (!clicked) await _addPrimitive(cubit);
    final created = _nodeIds(cubit).difference(knownIds);
    if (created.length == 1) return created.single;
    return cubit.loadedTaskOrNull()?.selectedNodeOrNull?.id;
  }

  Set<NodeId> _nodeIds(TaskBuilderCubit cubit) {
    final nodes = cubit.loadedTaskOrNull()?.nodes ?? const <WorkflowNode>[];
    return {for (final node in nodes) node.id};
  }

  AgentCursorTarget get _paletteTarget {
    final isChannel =
        primitive == WorkflowPrimitive.readChannelEvent ||
        primitive == WorkflowPrimitive.sendChannelMessage;
    return TaskBuilderCursorTargets.palette(
      primitive,
      kind: isChannel ? channelKind : null,
    );
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
