part of 'node_config.dart';

abstract class SpeechNodeConfig extends ModelInferenceNodeConfig {
  const SpeechNodeConfig({
    required super.modelId,
    super.inputMappings,
    super.outputParameters,
  });
}

class TextToSpeechNodeConfig extends SpeechNodeConfig {
  const TextToSpeechNodeConfig({
    required super.modelId,
    super.inputMappings,
    super.outputParameters,
  });

  factory TextToSpeechNodeConfig.initial() =>
      const TextToSpeechNodeConfig(modelId: '');

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.textToSpeech;

  @override
  TextToSpeechNodeConfig copyWith({
    String? modelId,
    List<ModelInferenceInputMapping>? inputMappings,
    List<ModelInferenceOutputParameter>? outputParameters,
  }) {
    return TextToSpeechNodeConfig(
      modelId: modelId ?? this.modelId,
      inputMappings: inputMappings ?? this.inputMappings,
      outputParameters: outputParameters ?? this.outputParameters,
    );
  }
}

class SpeechToTextNodeConfig extends SpeechNodeConfig {
  const SpeechToTextNodeConfig({
    required super.modelId,
    super.inputMappings,
    super.outputParameters,
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
  }) {
    return SpeechToTextNodeConfig(
      modelId: modelId ?? this.modelId,
      inputMappings: inputMappings ?? this.inputMappings,
      outputParameters: outputParameters ?? this.outputParameters,
    );
  }
}
