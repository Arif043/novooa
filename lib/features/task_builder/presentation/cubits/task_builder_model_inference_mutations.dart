part of 'task_builder_cubit.dart';

extension TaskBuilderModelInferenceMutations on TaskBuilderCubit {
  Future<void> updateModelInference(NodeId nodeId, String modelId) {
    return _updateNode(nodeId, (node) {
      if (node.config case ModelInferenceNodeConfig config) {
        return node.copyWith(config: config.copyWith(modelId: modelId));
      }
      return node;
    });
  }

  Future<void> selectModelInference(
    NodeId nodeId,
    String modelId,
    List<ModelInferenceInputMapping> inputMappings, [
    List<ModelInferenceSetting> settings = const [],
  ]) {
    return _updateNode(nodeId, (node) {
      if (node.config case ModelInferenceNodeConfig config) {
        return node.copyWith(
          config: config.copyWith(
            modelId: modelId,
            inputMappings: inputMappings,
            settings: settings,
          ),
        );
      }
      return node;
    });
  }

  Future<void> updateModelInferenceSetting(
    NodeId nodeId,
    ModelInferenceSetting parameter,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case ModelInferenceNodeConfig config) {
        final parameters = [...config.settings];
        final index = parameters.indexWhere(
          (candidate) => candidate.name == parameter.name,
        );
        if (index < 0) {
          parameters.add(parameter);
        } else {
          parameters[index] = parameter;
        }
        return node.copyWith(config: config.copyWith(settings: parameters));
      }
      return node;
    });
  }

  Future<void> updateModelInferenceWorkflowMapping(
    NodeId nodeId,
    ModelInferenceInputMapping mapping,
  ) {
    return _updateInputMappings(nodeId, (mappings) {
      final index = mappings.indexWhere(
        (candidate) => candidate.modelInputName == mapping.modelInputName,
      );
      if (index < 0) return [...mappings, mapping];
      return [...mappings]..[index] = mapping;
    });
  }

  Future<void> updateModelInferenceWorkflowMappings(
    NodeId nodeId,
    List<ModelInferenceInputMapping> mappings,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case ModelInferenceNodeConfig config) {
        return node.copyWith(config: config.copyWith(inputMappings: mappings));
      }
      return node;
    });
  }

  Future<void> _updateInputMappings(
    NodeId nodeId,
    List<ModelInferenceInputMapping> Function(
      List<ModelInferenceInputMapping> mappings,
    )
    update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case ModelInferenceNodeConfig config) {
        return node.copyWith(
          config: config.copyWith(inputMappings: update(config.inputMappings)),
        );
      }
      return node;
    });
  }

  /// Wählt das Sprachmodell für „Text vorlesen". Eine leere ID schaltet auf das
  /// lokale ONNX-Modell zurück; die Stimme gilt nur für ein Sprachmodell und
  /// wird beim Wechsel zurückgesetzt.
  Future<void> updateTextToSpeechLanguageModel(
    NodeId nodeId,
    String languageModelId,
  ) {
    return _updateTextToSpeech(
      nodeId,
      (config) => config.copyWith(
        languageModelId: languageModelId,
        voiceId: languageModelId == config.languageModelId
            ? config.voiceId
            : '',
      ),
    );
  }

  Future<void> updateTextToSpeechText(NodeId nodeId, String speechText) {
    return _updateTextToSpeech(
      nodeId,
      (config) => config.copyWith(speechText: speechText),
    );
  }

  Future<void> updateTextToSpeechVoice(NodeId nodeId, String voiceId) {
    return _updateTextToSpeech(
      nodeId,
      (config) => config.copyWith(voiceId: voiceId),
    );
  }

  Future<void> _updateTextToSpeech(
    NodeId nodeId,
    TextToSpeechNodeConfig Function(TextToSpeechNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case TextToSpeechNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }

  /// Wählt das Sprachmodell für „Sprache zu Text". Eine leere ID schaltet auf
  /// das lokale ONNX-Modell zurück.
  Future<void> updateSpeechToTextLanguageModel(
    NodeId nodeId,
    String languageModelId,
  ) {
    return _updateSpeechToText(
      nodeId,
      (config) => config.copyWith(languageModelId: languageModelId),
    );
  }

  Future<void> updateSpeechToTextAudio(NodeId nodeId, String audioTemplate) {
    return _updateSpeechToText(
      nodeId,
      (config) => config.copyWith(audioTemplate: audioTemplate),
    );
  }

  Future<void> _updateSpeechToText(
    NodeId nodeId,
    SpeechToTextNodeConfig Function(SpeechToTextNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case SpeechToTextNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
