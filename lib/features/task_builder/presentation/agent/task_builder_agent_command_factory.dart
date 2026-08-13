import 'package:syscat2/features/assistant/domain/entities/assistant_task_command.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class TaskBuilderAgentCommandFactory {
  const TaskBuilderAgentCommandFactory();

  List<AssistantPlanAction> fromDtos(
    List<AssistantTaskCommand> dtos,
    TaskBuilderCubit cubit,
  ) {
    return dtos
        .map(_fromDto)
        .nonNulls
        .map((command) => TaskBuilderPlanAction(cubit: cubit, command: command))
        .toList(growable: false);
  }

  TaskBuilderAgentCommand? _fromDto(AssistantTaskCommand dto) {
    return switch (dto.type) {
      'renameTask' => RenameTaskAgentCommand(dto),
      'addNode' => AddNodeAgentCommand(dto),
      _ => null,
    };
  }
}

final class RenameTaskAgentCommand extends TaskBuilderAgentCommand {
  const RenameTaskAgentCommand(super.source);

  @override
  Future<void> perform(TaskBuilderCubit cubit) async {
    final title = source.title;
    if (title == null) return;
    await cubit.updateTitle(title);
  }
}

final class AddNodeAgentCommand extends TaskBuilderAgentCommand {
  const AddNodeAgentCommand(super.source);

  @override
  Future<void> perform(TaskBuilderCubit cubit) async {
    final primitive = _primitiveFrom(source.primitive);
    if (primitive == null) return;
    await _addPrimitive(cubit, primitive, source.kind);
    final node = cubit.loadedTaskOrNull()?.selectedNodeOrNull;
    if (node == null) return;
    await _configureNode(cubit, node.id);
  }

  Future<void> _addPrimitive(
    TaskBuilderCubit cubit,
    WorkflowPrimitive primitive,
    String? kind,
  ) async {
    if (primitive == WorkflowPrimitive.readChannelEvent) {
      await cubit.addChannelEventNodeToMainGraph(_kindFrom(kind));
      return;
    }
    if (primitive == WorkflowPrimitive.sendChannelMessage) {
      await cubit.addSendMessageNodeToMainGraph(_kindFrom(kind));
      return;
    }
    await cubit.addNodeToMainGraph(primitive);
  }

  Future<void> _configureNode(TaskBuilderCubit cubit, NodeId nodeId) async {
    await _setNodeTextFields(cubit, nodeId);
    await _setNodeConfigFields(cubit, nodeId);
  }

  Future<void> _setNodeTextFields(TaskBuilderCubit cubit, NodeId nodeId) async {
    if (source.title case final title?) {
      await cubit.updateNodeTitle(nodeId, title);
    }
    if (source.description case final description?) {
      await cubit.updateNodeDescription(nodeId, description);
    }
    if (source.referenceName case final referenceName?) {
      await cubit.updateNodeReferenceName(nodeId, referenceName);
    }
  }

  Future<void> _setNodeConfigFields(
    TaskBuilderCubit cubit,
    NodeId nodeId,
  ) async {
    if (source.value case final value?) {
      await cubit.updateStringInputValue(nodeId, value);
    }
    if (source.instruction case final instruction?) {
      await cubit.updatePromptInstruction(nodeId, instruction);
    }
    if (source.recipient case final recipient?) {
      await cubit.updateSendMessageRecipient(nodeId, recipient);
    }
    if (source.message case final message?) {
      await cubit.updateSendMessageBody(nodeId, message);
    }
  }
}

WorkflowPrimitive? _primitiveFrom(String? value) {
  return switch (value) {
    'stringInput' => WorkflowPrimitive.stringInput,
    'prompt' => WorkflowPrimitive.prompt,
    'readChannelEvent' => WorkflowPrimitive.readChannelEvent,
    'sendChannelMessage' => WorkflowPrimitive.sendChannelMessage,
    'humanApproval' => WorkflowPrimitive.humanApproval,
    'script' => WorkflowPrimitive.script,
    _ => null,
  };
}

ChannelEventKind _kindFrom(String? value) {
  return switch (value) {
    'email' => ChannelEventKind.email,
    'sms' => ChannelEventKind.sms,
    _ => ChannelEventKind.whatsapp,
  };
}
