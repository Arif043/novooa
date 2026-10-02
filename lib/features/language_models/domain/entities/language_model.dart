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
    this.supportsTextGeneration = true,
    this.supportsSpeechSynthesis = false,
    this.connectionId,
    this.provider,
  });

  final String id;
  final String name;
  final String modelId;
  final bool supportsImageInput;
  final bool supportsStructuredOutput;
  final bool supportsImageGeneration;

  /// Kann Texte beantworten. Reine Sprachmodelle (z. B. ElevenLabs, Gemini-TTS)
  /// erscheinen deshalb nicht in der Auswahl für Prompt-Bausteine.
  final bool supportsTextGeneration;

  /// Kann Text als Sprache ausgeben — Grundlage für „Text vorlesen".
  final bool supportsSpeechSynthesis;

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
    supportsTextGeneration,
    supportsSpeechSynthesis,
    connectionId,
    provider,
  ];
}
