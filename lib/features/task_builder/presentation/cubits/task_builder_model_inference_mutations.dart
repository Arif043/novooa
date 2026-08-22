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
}
