part of 'node_config.dart';

class StringInputNodeConfig extends NodeConfig {
  const StringInputNodeConfig({required this.value});

  final String value;

  factory StringInputNodeConfig.initial() {
    return const StringInputNodeConfig(value: '');
  }

  @override
  WorkflowPrimitive get primitive => .stringInput;

  @override
  List<Object?> get props => [value];

  StringInputNodeConfig copyWith({String? value}) {
    return StringInputNodeConfig(value: value ?? this.value);
  }
}
