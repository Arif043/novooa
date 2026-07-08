import 'package:equatable/equatable.dart';
import 'package:syscat2/features/task_builder/domain/entities/prompt_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

part 'prompt_node_config.dart';
part 'file_attachment_support.dart';
part 'string_input_node_config.dart';
part 'conditional_node_config.dart';
part 'iterative_refinement_node_config.dart';

sealed class NodeConfig extends Equatable {
  const NodeConfig();

  WorkflowPrimitive get primitive;

  factory NodeConfig.initial(WorkflowPrimitive primitive) {
    return switch (primitive) {
      .stringInput => StringInputNodeConfig.initial(),
      .prompt => PromptNodeConfig.initial(),
      .conditional => ConditionalNodeConfig.initial(null),
      .iterativeRefinement => IterativeRefinementNodeConfig.initial(),
      _ => throw UnimplementedError(),
    };
  }
}
