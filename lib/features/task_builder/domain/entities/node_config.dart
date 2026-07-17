import 'package:equatable/equatable.dart';
import 'package:syscat2/features/task_builder/domain/entities/knowledge_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

part 'prompt_node_config.dart';
part 'file_attachment_support.dart';
part 'knowledge_attachment_support.dart';
part 'string_input_node_config.dart';
part 'script_node_config.dart';
part 'conditional_node_config.dart';
part 'iterative_refinement_node_config.dart';
part 'human_approval_node_config.dart';
part 'write_file_node_config.dart';
part 'read_file_node_config.dart';
part 'read_email_node_config.dart';
part 'send_channel_message_node_config.dart';

sealed class NodeConfig extends Equatable {
  const NodeConfig();

  WorkflowPrimitive get primitive;

  factory NodeConfig.initial(WorkflowPrimitive primitive) {
    return switch (primitive) {
      .stringInput => StringInputNodeConfig.initial(),
      .script => ScriptNodeConfig.initial(),
      .prompt => PromptNodeConfig.initial(),
      .conditional => ConditionalNodeConfig.initial(null),
      .iterativeRefinement => IterativeRefinementNodeConfig.initial(),
      .humanApproval => HumanApprovalNodeConfig.initial(),
      .writeFile => WriteFileNodeConfig.initial(),
      .readFile => ReadFileNodeConfig.initial(),
      .readEmail => ReadEmailNodeConfig.initial(),
      .readChannelEvent => ReadChannelEventNodeConfig.initial(),
      .sendChannelMessage => SendChannelMessageNodeConfig.initial(),
      _ => throw UnimplementedError(),
    };
  }
}
