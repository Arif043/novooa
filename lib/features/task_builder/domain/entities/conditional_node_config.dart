part of 'node_config.dart';

class ConditionalNodeConfig extends NodeConfig {
  const ConditionalNodeConfig();

  factory ConditionalNodeConfig.initial() {
    return const ConditionalNodeConfig();
  }

  @override
  WorkflowPrimitive get primitive => .conditional;

  @override
  List<Object?> get props => [];
}