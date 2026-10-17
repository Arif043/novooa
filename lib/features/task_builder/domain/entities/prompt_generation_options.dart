import 'package:equatable/equatable.dart';

/// Wie stark das Modell vor der Antwort nachdenkt. [modelDefault] überlässt
/// es dem Modell; Stufen versteht nicht jeder Anbieter (siehe Backend
/// `GenkitGenerationConfig`).
enum ThinkingMode { modelDefault, off, low, medium, high }

/// Optionen eines Modellaufrufs im Prompt-Baustein. `null` heißt jeweils:
/// Standard des Modells. Ungültige Werte lässt [PromptGenerationOptions]
/// nicht zu, sondern fällt auf den Modellstandard zurück.
class PromptGenerationOptions extends Equatable {
  const PromptGenerationOptions({
    this.temperature,
    this.maxOutputTokens,
    this.contextWindow,
    this.thinking = ThinkingMode.modelDefault,
  });

  static const minTemperature = 0.0;
  static const maxTemperature = 2.0;

  final double? temperature;
  final int? maxOutputTokens;

  /// Nur bei Ollama wirksam; Cloud-Anbieter haben ein festes Fenster.
  final int? contextWindow;
  final ThinkingMode thinking;

  bool get usesModelDefaults => this == const PromptGenerationOptions();

  PromptGenerationOptions withTemperature(double? value) {
    final valid =
        value != null && value >= minTemperature && value <= maxTemperature;
    return _copy(temperature: valid ? value : null);
  }

  PromptGenerationOptions withMaxOutputTokens(int? value) =>
      _copy(maxOutputTokens: _positiveOrNull(value));

  PromptGenerationOptions withContextWindow(int? value) =>
      _copy(contextWindow: _positiveOrNull(value));

  PromptGenerationOptions withThinking(ThinkingMode value) =>
      _copy(thinking: value);

  PromptGenerationOptions _copy({
    Object? temperature = _keep,
    Object? maxOutputTokens = _keep,
    Object? contextWindow = _keep,
    ThinkingMode? thinking,
  }) {
    return PromptGenerationOptions(
      temperature: identical(temperature, _keep)
          ? this.temperature
          : temperature as double?,
      maxOutputTokens: identical(maxOutputTokens, _keep)
          ? this.maxOutputTokens
          : maxOutputTokens as int?,
      contextWindow: identical(contextWindow, _keep)
          ? this.contextWindow
          : contextWindow as int?,
      thinking: thinking ?? this.thinking,
    );
  }

  static int? _positiveOrNull(int? value) =>
      value != null && value > 0 ? value : null;

  @override
  List<Object?> get props => [
    temperature,
    maxOutputTokens,
    contextWindow,
    thinking,
  ];
}

const Object _keep = Object();
