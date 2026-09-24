import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

final class AddNodeAgentCommand extends TaskBuilderAgentCommand {
  const AddNodeAgentCommand({
    required String label,
    required this.primitive,
    required this.channelKind,
    this.title,
    this.description,
    this.outputName,
    this.value,
    this.instruction,
    this.modelId,
    this.recipient,
    this.message,
  }) : super(label);

  final WorkflowPrimitive primitive;
  final ChannelEventKind channelKind;
  final String? title;
  final String? description;
  final String? outputName;
  final String? value;
  final String? instruction;
  final String? modelId;
  final String? recipient;
  final String? message;

  @override
  Future<void> perform(TaskBuilderCubit cubit) async {
    await _addPrimitive(cubit);
    final nodeId = cubit.loadedTaskOrNull()?.selectedNodeOrNull?.id;
    if (nodeId == null) return;
    await _configureNode(cubit, nodeId);
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

  Future<void> _configureNode(TaskBuilderCubit cubit, NodeId nodeId) async {
    await _setNodeTextFields(cubit, nodeId);
    await _setNodeConfigFields(cubit, nodeId);
  }

  Future<void> _setNodeTextFields(TaskBuilderCubit cubit, NodeId nodeId) async {
    if (title case final text?) {
      await cubit.updateNodeTitle(nodeId, text);
    }
    if (description case final text?) {
      await cubit.updateNodeDescription(nodeId, text);
    }
    if (outputName case final text?) {
      await cubit.updateNodeOutputName(nodeId, text);
    }
  }

  Future<void> _setNodeConfigFields(
    TaskBuilderCubit cubit,
    NodeId nodeId,
  ) async {
    if (value case final text?) {
      await cubit.updateStringInputValue(nodeId, text);
    }
    if (instruction case final text?) {
      await cubit.updatePromptInstruction(nodeId, text);
    }
    if (modelId case final id?) {
      await cubit.updateModelInference(nodeId, id);
    }
    if (recipient case final text?) {
      await cubit.updateSendMessageRecipient(nodeId, text);
    }
    if (message case final text?) {
      await cubit.updateSendMessageBody(nodeId, text);
    }
  }
}
