part of 'node_config.dart';

class ModelInferenceNodeConfig extends NodeConfig {
  const ModelInferenceNodeConfig({required this.modelId});

  final String modelId;

  factory ModelInferenceNodeConfig.initial() {
    return const ModelInferenceNodeConfig(modelId: '');
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.modelInference;

  @override
  List<Object?> get props => [modelId];

  ModelInferenceNodeConfig copyWith({String? modelId}) {
    return ModelInferenceNodeConfig(modelId: modelId ?? this.modelId);
  }
}
