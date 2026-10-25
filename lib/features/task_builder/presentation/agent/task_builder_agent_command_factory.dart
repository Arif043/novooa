import 'package:syscat2/features/assistant/domain/entities/assistant_action_suggestion.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/agent/add_node_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/agent/agent_node_refs.dart';
import 'package:syscat2/features/task_builder/presentation/agent/configure_node_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_key.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_player.dart';
import 'package:syscat2/features/task_builder/presentation/agent/rename_task_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class TaskBuilderAgentCommandFactory {
  const TaskBuilderAgentCommandFactory({this.waitForFrame = waitForNextFrame});

  final FrameWaiter waitForFrame;

  List<AssistantPlanAction> fromSuggestions(
    List<AssistantActionSuggestion> suggestions,
    TaskBuilderCubit cubit,
  ) {
    final refs = AgentNodeRefs();
    return suggestions
        .where(
          (suggestion) =>
              suggestion.target == AssistantActionTarget.taskBuilder,
        )
        .map((suggestion) => _fromSuggestion(suggestion, refs))
        .nonNulls
        .map((command) => TaskBuilderPlanAction(cubit: cubit, command: command))
        .toList(growable: false);
  }

  TaskBuilderAgentCommand? _fromSuggestion(
    AssistantActionSuggestion suggestion,
    AgentNodeRefs refs,
  ) {
    return switch (suggestion.type) {
      'renameTask' => _renameTask(suggestion),
      'addNode' => _addNode(suggestion, refs),
      'configureNode' => _configureNode(suggestion, refs),
      _ => null,
    };
  }

  TaskBuilderAgentCommand? _renameTask(AssistantActionSuggestion suggestion) {
    final title = _requiredText(suggestion.stringArgument('title'));
    if (title == null) return null;
    return RenameTaskAgentCommand(label: suggestion.label, title: title);
  }

  TaskBuilderAgentCommand? _addNode(
    AssistantActionSuggestion suggestion,
    AgentNodeRefs refs,
  ) {
    final primitive = _primitiveFrom(suggestion.stringArgument('primitive'));
    if (primitive == null) return null;
    return AddNodeAgentCommand(
      label: suggestion.label,
      primitive: primitive,
      channelKind: _kindFrom(suggestion.stringArgument('kind')),
      fields: _fieldsFrom(suggestion.arguments, primitive: primitive),
      ref: _requiredText(suggestion.stringArgument('ref')),
      refs: refs,
      waitForFrame: waitForFrame,
    );
  }

  TaskBuilderAgentCommand? _configureNode(
    AssistantActionSuggestion suggestion,
    AgentNodeRefs refs,
  ) {
    final nodeRef = _requiredText(suggestion.stringArgument('nodeRef'));
    final fields = _fieldsFrom(suggestion.arguments);
    if (nodeRef == null || fields.isEmpty) return null;
    return ConfigureNodeAgentCommand(
      label: suggestion.label,
      nodeRef: nodeRef,
      fields: fields,
      refs: refs,
      waitForFrame: waitForFrame,
    );
  }
}

/// Feldwerte stehen flach im Vorschlag (addNode) oder unter `fields`.
Map<NodeFieldKey, String> _fieldsFrom(
  Map<String, Object?> arguments, {
  WorkflowPrimitive? primitive,
}) {
  final source = arguments['fields'] is Map
      ? Map<String, Object?>.from(arguments['fields']! as Map)
      : arguments;
  final fields = <NodeFieldKey, String>{};
  for (final key in NodeFieldKey.values) {
    final value = source[key.name];
    if (value is! String) continue;
    if (primitive != null && !_isScriptField(key, primitive)) continue;
    fields[key] = value;
  }
  return fields;
}

bool _isScriptField(NodeFieldKey key, WorkflowPrimitive primitive) {
  final isScriptOnly = key == NodeFieldKey.script;
  return !isScriptOnly || primitive == WorkflowPrimitive.script;
}

WorkflowPrimitive? _primitiveFrom(String? value) {
  return switch (value) {
    'stringInput' => WorkflowPrimitive.stringInput,
    'prompt' => WorkflowPrimitive.prompt,
    'readChannelEvent' => WorkflowPrimitive.readChannelEvent,
    'sendChannelMessage' => WorkflowPrimitive.sendChannelMessage,
    'humanApproval' => WorkflowPrimitive.humanApproval,
    'dialogInput' => WorkflowPrimitive.dialogInput,
    'modelInference' => WorkflowPrimitive.modelInference,
    'textToSpeech' => WorkflowPrimitive.textToSpeech,
    'speechToText' => WorkflowPrimitive.speechToText,
    'script' => WorkflowPrimitive.script,
    _ => null,
  };
}

ChannelEventKind _kindFrom(String? value) {
  return switch (value) {
    'email' => ChannelEventKind.email,
    'sms' => ChannelEventKind.sms,
    'telegram' => ChannelEventKind.telegram,
    'instagram' => ChannelEventKind.instagram,
    _ => ChannelEventKind.whatsapp,
  };
}

String? _requiredText(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}
