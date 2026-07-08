part of 'task_builder_cubit.dart';

extension TaskBuilderScriptMutations on TaskBuilderCubit {
  Future<void> updateScript(NodeId nodeId, String script) {
    return _updateScriptConfig(nodeId, (config) {
      if (config.script == script) return config;
      return config.copyWith(script: script);
    });
  }

  Future<void> _updateScriptConfig(
    NodeId nodeId,
    ScriptNodeConfig Function(ScriptNodeConfig config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case ScriptNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
