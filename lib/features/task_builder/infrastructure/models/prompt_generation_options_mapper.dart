import 'package:syscat2/features/task_builder/domain/entities/prompt_generation_options.dart';

/// Speichert nur gesetzte Optionen; fehlende Werte bedeuten Modellstandard
/// (passt zu `generationOptionsSchema` im Backend).
class PromptGenerationOptionsMapper {
  const PromptGenerationOptionsMapper();

  Map<String, Object?> toDocument(PromptGenerationOptions options) {
    return {
      if (options.temperature != null) 'temperature': options.temperature,
      if (options.maxOutputTokens != null)
        'maxOutputTokens': options.maxOutputTokens,
      if (options.contextWindow != null) 'contextWindow': options.contextWindow,
      if (options.thinking != ThinkingMode.modelDefault)
        'thinking': options.thinking.name,
    };
  }

  PromptGenerationOptions fromDocument(Object? value) {
    if (value is! Map) return const PromptGenerationOptions();
    return const PromptGenerationOptions()
        .withTemperature(_double(value['temperature']))
        .withMaxOutputTokens(_int(value['maxOutputTokens']))
        .withContextWindow(_int(value['contextWindow']))
        .withThinking(_thinking(value['thinking']));
  }

  double? _double(Object? value) => value is num ? value.toDouble() : null;

  int? _int(Object? value) => value is num ? value.toInt() : null;

  ThinkingMode _thinking(Object? value) {
    return ThinkingMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThinkingMode.modelDefault,
    );
  }
}
