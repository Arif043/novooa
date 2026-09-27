part of 'node_config.dart';

class ModelInferenceNodeConfig extends NodeConfig {
  const ModelInferenceNodeConfig({
    required this.modelId,
    this.inputMappings = const [],
    this.outputParameters = const [],
    this.settings = const [],
  });

  final String modelId;
  final List<ModelInferenceInputMapping> inputMappings;
  final List<ModelInferenceOutputParameter> outputParameters;
  final List<ModelInferenceSetting> settings;

  factory ModelInferenceNodeConfig.initial() {
    return const ModelInferenceNodeConfig(modelId: '');
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.modelInference;

  @override
  List<Object?> get props => [
    modelId,
    inputMappings,
    outputParameters,
    settings,
  ];

  ModelInferenceNodeConfig copyWith({
    String? modelId,
    List<ModelInferenceInputMapping>? inputMappings,
    List<ModelInferenceOutputParameter>? outputParameters,
    List<ModelInferenceSetting>? settings,
  }) {
    return ModelInferenceNodeConfig(
      modelId: modelId ?? this.modelId,
      inputMappings: inputMappings ?? this.inputMappings,
      outputParameters: outputParameters ?? this.outputParameters,
      settings: settings ?? this.settings,
    );
  }
}

class ModelInferenceSetting extends Equatable {
  const ModelInferenceSetting({
    required this.name,
    required this.valueTemplate,
  });

  final String name;
  final String valueTemplate;

  ModelInferenceSetting copyWith({String? valueTemplate}) {
    return ModelInferenceSetting(
      name: name,
      valueTemplate: valueTemplate ?? this.valueTemplate,
    );
  }

  @override
  List<Object?> get props => [name, valueTemplate];
}

class ModelInferenceOutputParameter extends Equatable {
  const ModelInferenceOutputParameter({
    required this.outputName,
    required this.name,
    required this.value,
  });

  final String outputName;
  final String name;
  final int value;

  ModelInferenceOutputParameter copyWith({int? value}) {
    return ModelInferenceOutputParameter(
      outputName: outputName,
      name: name,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [outputName, name, value];
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
