import 'package:equatable/equatable.dart';

import 'language_model_draft.dart';

class LanguageModel extends Equatable {
  const LanguageModel({
    required this.id,
    required this.name,
    required this.modelId,
    required this.supportsImageInput,
    required this.supportsStructuredOutput,
    required this.supportsImageGeneration,
    this.connectionId,
    this.provider,
  });

  final String id;
  final String name;
  final String modelId;
  final bool supportsImageInput;
  final bool supportsStructuredOutput;
  final bool supportsImageGeneration;

  /// Sprachmodelle (z. B. `gemini-…-tts`, `tts-1`, alle ElevenLabs-Modelle)
  /// blenden wir in Prompt-Auswahlen aus. Bewusst nur ein Namensfilter, kein
  /// gepflegter Katalog: Wer ein anderes Modell wählt, bekommt beim Lauf den
  /// Fehler des Anbieters in der Aktivität.
  bool get isSpeechModel =>
      provider?.isSpeechOnly == true || _speechName.hasMatch(modelId);

  static final _speechName = RegExp(
    r'(^|[-_./:])tts($|[-_./:])|text-to-speech',
    caseSensitive: false,
  );

  /// Nur in Standalone gesetzt — verweist auf die [LanguageModelConnection],
  /// über die dieses Modell verbunden wurde. Cloud kennt kein Connection-
  /// Konzept, daher optional statt eines erfundenen Platzhalterwerts.
  final String? connectionId;

  /// Anbieter des Modells, soweit bekannt — Grundlage der Anbieter-Auswahl.
  final LanguageModelProvider? provider;

  @override
  List<Object?> get props => [
    id,
    name,
    modelId,
    supportsImageInput,
    supportsStructuredOutput,
    supportsImageGeneration,
    connectionId,
    provider,
  ];
}
