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
    List<ModelInferenceOutputParameter> outputParameters = const [],
  ]) {
    return _updateNode(nodeId, (node) {
      if (node.config case ModelInferenceNodeConfig config) {
        return node.copyWith(
          config: config.copyWith(
            modelId: modelId,
            inputMappings: inputMappings,
            outputParameters: outputParameters,
          ),
        );
      }
      return node;
    });
  }

  Future<void> updateModelInferenceOutputParameter(
    NodeId nodeId,
    ModelInferenceOutputParameter parameter,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case ModelInferenceNodeConfig config) {
        final parameters = [...config.outputParameters];
        final index = parameters.indexWhere(
          (candidate) =>
              candidate.outputName == parameter.outputName &&
              candidate.name == parameter.name,
        );
        if (index < 0) {
          parameters.add(parameter);
        } else {
          parameters[index] = parameter;
        }
        return node.copyWith(
          config: config.copyWith(outputParameters: parameters),
        );
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
}
