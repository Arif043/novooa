part of 'node_config.dart';

abstract class SpeechNodeConfig extends ModelInferenceNodeConfig {
  const SpeechNodeConfig({
    required super.modelId,
    super.inputMappings,
    super.outputParameters,
    super.settings,
  });
}

class TextToSpeechNodeConfig extends SpeechNodeConfig {
  const TextToSpeechNodeConfig({
    required super.modelId,
    super.inputMappings,
    super.outputParameters,
    super.settings,
    this.languageModelId = '',
    this.speechText = '',
    this.voiceId = '',
  });

  factory TextToSpeechNodeConfig.initial() =>
      const TextToSpeechNodeConfig(modelId: '');

  /// Gesetzt: Die Sprachausgabe läuft über ein verbundenes Sprachmodell
  /// (Google AI, ElevenLabs, OpenAI-kompatibel). Leer: lokales ONNX-Modell.
  final String languageModelId;

  /// Vorzulesender Text; darf Template-Ausdrücke enthalten.
  final String speechText;

  /// Leer = Standardstimme des Anbieters.
  final String voiceId;

  bool get usesLanguageModel => languageModelId.isNotEmpty;

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.textToSpeech;

  @override
  TextToSpeechNodeConfig copyWith({
    String? modelId,
    List<ModelInferenceInputMapping>? inputMappings,
    List<ModelInferenceOutputParameter>? outputParameters,
    List<ModelInferenceSetting>? settings,
    String? languageModelId,
    String? speechText,
    String? voiceId,
  }) {
    return TextToSpeechNodeConfig(
      modelId: modelId ?? this.modelId,
      inputMappings: inputMappings ?? this.inputMappings,
      outputParameters: outputParameters ?? this.outputParameters,
      settings: settings ?? this.settings,
      languageModelId: languageModelId ?? this.languageModelId,
      speechText: speechText ?? this.speechText,
      voiceId: voiceId ?? this.voiceId,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    languageModelId,
    speechText,
    voiceId,
  ];
}

class SpeechToTextNodeConfig extends SpeechNodeConfig {
  const SpeechToTextNodeConfig({
    required super.modelId,
    super.inputMappings,
    super.outputParameters,
    super.settings,
  });

  factory SpeechToTextNodeConfig.initial() =>
      const SpeechToTextNodeConfig(modelId: '');

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.speechToText;

  @override
  SpeechToTextNodeConfig copyWith({
    String? modelId,
    List<ModelInferenceInputMapping>? inputMappings,
    List<ModelInferenceOutputParameter>? outputParameters,
    List<ModelInferenceSetting>? settings,
  }) {
    return SpeechToTextNodeConfig(
      modelId: modelId ?? this.modelId,
      inputMappings: inputMappings ?? this.inputMappings,
      outputParameters: outputParameters ?? this.outputParameters,
      settings: settings ?? this.settings,
    );
  }
}
