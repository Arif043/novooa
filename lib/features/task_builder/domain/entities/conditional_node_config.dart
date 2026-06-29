part of 'node_config.dart';

class ConditionalNodeConfig extends NodeConfig {
  const ConditionalNodeConfig({required this.choices});

  final List<String> choices;

  factory ConditionalNodeConfig.initial(List<String>? choices) {
    return ConditionalNodeConfig(choices: choices ?? ['Ja', 'Nein']);
  }

  @override
  WorkflowPrimitive get primitive => .conditional;

  @override
  List<Object?> get props => [];

  ConditionalNodeConfig copyWith({List<String>? choices}) {
    return ConditionalNodeConfig(choices: choices ?? this.choices);
  }
}