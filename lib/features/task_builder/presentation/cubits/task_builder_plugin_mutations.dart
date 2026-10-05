part of 'task_builder_cubit.dart';

extension TaskBuilderPluginMutations on TaskBuilderCubit {
  /// Ändert die Konfiguration eines Plugin-Bausteins; für andere Bausteine
  /// passiert nichts. Plugins brauchen dafür keine eigene Mutation.
  Future<void> updatePluginNode(
    NodeId nodeId,
    PluginNodeConfig Function(PluginNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case final PluginNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
