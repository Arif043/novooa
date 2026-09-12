part of 'node_config.dart';

class ModelInferenceNodeConfig extends NodeConfig {
  const ModelInferenceNodeConfig({
    required this.modelId,
    this.inputMappings = const [],
  });

  final String modelId;
  final List<ModelInferenceInputMapping> inputMappings;

  factory ModelInferenceNodeConfig.initial() {
    return const ModelInferenceNodeConfig(modelId: '');
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.modelInference;

  @override
  List<Object?> get props => [modelId, inputMappings];

  ModelInferenceNodeConfig copyWith({
    String? modelId,
    List<ModelInferenceInputMapping>? inputMappings,
  }) {
    return ModelInferenceNodeConfig(
      modelId: modelId ?? this.modelId,
      inputMappings: inputMappings ?? this.inputMappings,
    );
  }
}

class ModelInferenceInputMapping extends Equatable {
  const ModelInferenceInputMapping({
    required this.modelInputName,
    required this.workflowMapping,
    required this.sourceType,
    required this.dataType,
    required this.shape,
  });

  final String modelInputName;
  final String workflowMapping;
  final String sourceType;
  final String dataType;
  final List<Object> shape;

  ModelInferenceInputMapping copyWith({
    String? modelInputName,
    String? workflowMapping,
    String? sourceType,
    String? dataType,
    List<Object>? shape,
  }) {
    return ModelInferenceInputMapping(
      modelInputName: modelInputName ?? this.modelInputName,
      workflowMapping: workflowMapping ?? this.workflowMapping,
      sourceType: sourceType ?? this.sourceType,
      dataType: dataType ?? this.dataType,
      shape: shape ?? this.shape,
    );
  }

  @override
  List<Object?> get props => [
    modelInputName,
    workflowMapping,
    sourceType,
    dataType,
    shape,
  ];
}
