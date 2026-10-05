part of 'task_builder_cubit.dart';

extension TaskBuilderHttpRequestMutations on TaskBuilderCubit {
  Future<void> updateHttpRequest(
    NodeId nodeId,
    HttpRequestNodeConfig Function(HttpRequestNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case HttpRequestNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
