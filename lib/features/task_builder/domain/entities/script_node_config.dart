part of 'node_config.dart';

class ScriptNodeConfig extends NodeConfig {
  const ScriptNodeConfig({required this.script});

  final String script;

  factory ScriptNodeConfig.initial() {
    return const ScriptNodeConfig(script: 'output = input');
  }

  @override
  WorkflowPrimitive get primitive => .script;

  @override
  List<Object?> get props => [script];

  ScriptNodeConfig copyWith({String? script}) {
    return ScriptNodeConfig(script: script ?? this.script);
  }
}
