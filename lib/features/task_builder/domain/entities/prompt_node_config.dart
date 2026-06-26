enum PromptOutputType {
  text('Freitext'),
  decision('Entscheidung');

  const PromptOutputType(this.label);

  final String label;
}

class PromptNodeConfig {
  const PromptNodeConfig({
    required this.instruction,
    required this.outputType,
    required this.firstChoice,
    required this.secondChoice,
  });

  final String instruction;
  final PromptOutputType outputType;
  final String firstChoice;
  final String secondChoice;

  List<String> get choices => [firstChoice, secondChoice];

  factory PromptNodeConfig.initial() {
    return const PromptNodeConfig(
      instruction: '',
      outputType: PromptOutputType.text,
      firstChoice: '',
      secondChoice: '',
    );
  }

  PromptNodeConfig copyWith({
    String? instruction,
    PromptOutputType? outputType,
    String? firstChoice,
    String? secondChoice,
  }) {
    return PromptNodeConfig(
      instruction: instruction ?? this.instruction,
      outputType: outputType ?? this.outputType,
      firstChoice: firstChoice ?? this.firstChoice,
      secondChoice: secondChoice ?? this.secondChoice,
    );
  }

  PromptNodeConfig updateChoice(int index, String value) {
    return switch (index) {
      0 => copyWith(firstChoice: value),
      1 => copyWith(secondChoice: value),
      _ => this,
    };
  }
}
