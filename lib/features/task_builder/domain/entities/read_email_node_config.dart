part of 'node_config.dart';

class ReadEmailNodeConfig extends NodeConfig {
  const ReadEmailNodeConfig();

  factory ReadEmailNodeConfig.initial() {
    return const ReadEmailNodeConfig();
  }

  @override
  WorkflowPrimitive get primitive => .readEmail;

  @override
  List<Object?> get props => const [];
}
