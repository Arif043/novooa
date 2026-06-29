part of 'node_config.dart';

enum PromptOutputType {
  text('Freitext'),
  decision('Entscheidung');

  const PromptOutputType(this.label);

  final String label;
}

class PromptNodeConfig extends NodeConfig {
  const PromptNodeConfig({
    required this.instruction,
    required this.outputType,
    required this.choices,
  });

  final String instruction;
  final PromptOutputType outputType;
  final List<String> choices;

  factory PromptNodeConfig.initial() {
    return const PromptNodeConfig(
      instruction: '',
      outputType: PromptOutputType.text,
      choices: ['', ''],
    );
  }

  @override
  List<Object?> get props => [instruction, outputType, choices];

  PromptNodeConfig copyWith({
    String? instruction,
    PromptOutputType? outputType,
    List<String>? choices,
  }) {
    return PromptNodeConfig(
      instruction: instruction ?? this.instruction,
      outputType: outputType ?? this.outputType,
      choices: choices ?? this.choices,
    );
  }

  PromptNodeConfig updateChoice(int index, String value) {
    if (index < 0 || index >= choices.length) return this;
    final updatedChoices = [...choices]..[index] = value;
    return copyWith(choices: updatedChoices);
  }

  PromptNodeConfig addChoice() {
    return copyWith(choices: [...choices, '']);
  }

  PromptNodeConfig removeChoice(int index) {
    if (index < 0 || index >= choices.length) return this;
    if (choices.length <= 1) return this;
    final updatedChoices = [...choices]..removeAt(index);
    return copyWith(choices: updatedChoices);
  }

  @override
  WorkflowPrimitive get primitive => .prompt;
}
