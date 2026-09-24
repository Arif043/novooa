import 'package:syscat2/features/assistant/domain/entities/assistant_action_suggestion.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/agent/add_node_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/agent/rename_task_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class TaskBuilderAgentCommandFactory {
  const TaskBuilderAgentCommandFactory();

  List<AssistantPlanAction> fromSuggestions(
    List<AssistantActionSuggestion> suggestions,
    TaskBuilderCubit cubit,
  ) {
    return suggestions
        .where(
          (suggestion) =>
              suggestion.target == AssistantActionTarget.taskBuilder,
        )
        .map(_fromSuggestion)
        .nonNulls
        .map((command) => TaskBuilderPlanAction(cubit: cubit, command: command))
        .toList(growable: false);
  }

  TaskBuilderAgentCommand? _fromSuggestion(
    AssistantActionSuggestion suggestion,
  ) {
    return switch (suggestion.type) {
      'renameTask' => _renameTask(suggestion),
      'addNode' => _addNode(suggestion),
      _ => null,
    };
  }

  TaskBuilderAgentCommand? _renameTask(AssistantActionSuggestion suggestion) {
    final title = _requiredText(suggestion.stringArgument('title'));
    if (title == null) return null;
    return RenameTaskAgentCommand(label: suggestion.label, title: title);
  }

  TaskBuilderAgentCommand? _addNode(AssistantActionSuggestion suggestion) {
    final primitive = _primitiveFrom(suggestion.stringArgument('primitive'));
    if (primitive == null) return null;
    return AddNodeAgentCommand(
      label: suggestion.label,
      primitive: primitive,
      channelKind: _kindFrom(suggestion.stringArgument('kind')),
      title: suggestion.stringArgument('title'),
      description: suggestion.stringArgument('description'),
      outputName: suggestion.stringArgument('outputName'),
      value: suggestion.stringArgument('value'),
      instruction: suggestion.stringArgument('instruction'),
      modelId: suggestion.stringArgument('modelId'),
      recipient: suggestion.stringArgument('recipient'),
      message: suggestion.stringArgument('message'),
    );
  }
}

WorkflowPrimitive? _primitiveFrom(String? value) {
  return switch (value) {
    'stringInput' => WorkflowPrimitive.stringInput,
    'prompt' => WorkflowPrimitive.prompt,
    'readChannelEvent' => WorkflowPrimitive.readChannelEvent,
    'sendChannelMessage' => WorkflowPrimitive.sendChannelMessage,
    'humanApproval' => WorkflowPrimitive.humanApproval,
    'dialogInput' => WorkflowPrimitive.dialogInput,
    'mediaInput' => WorkflowPrimitive.mediaInput,
    'modelInference' => WorkflowPrimitive.modelInference,
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

String? _requiredText(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}
