part of 'task_builder_cubit.dart';

extension TaskBuilderAttachmentMutations on TaskBuilderCubit {
  Future<void> attachNodeFile({
    required NodeId nodeId,
    required NodeAttachment attachment,
  }) {
    return _updateAttachableConfig(
      nodeId,
      (config) => config.attachFile(attachment),
    );
  }

  Future<void> detachNodeFile({
    required NodeId nodeId,
    required String attachmentId,
  }) {
    return _updateAttachableConfig(
      nodeId,
      (config) => config.detachFile(attachmentId),
    );
  }

  Future<void> attachNodeKnowledge({
    required NodeId nodeId,
    required KnowledgeAttachment attachment,
  }) {
    return _updateKnowledgeConfig(
      nodeId,
      (config) => config.attachKnowledge(attachment),
    );
  }

  Future<void> detachNodeKnowledge({
    required NodeId nodeId,
    required String attachmentId,
  }) {
    return _updateKnowledgeConfig(
      nodeId,
      (config) => config.detachKnowledge(attachmentId),
    );
  }

  Future<void> attachNodeSkill({
    required NodeId nodeId,
    required SkillAttachment attachment,
  }) {
    return _updateSkillConfig(
      nodeId,
      (config) => config.attachSkill(attachment),
    );
  }

  Future<void> detachNodeSkill({
    required NodeId nodeId,
    required String attachmentId,
  }) {
    return _updateSkillConfig(
      nodeId,
      (config) => config.detachSkill(attachmentId),
    );
  }

  Future<void> assignNodeEmployee({
    required NodeId nodeId,
    required EmployeeAttachment attachment,
  }) {
    return _updateEmployeeConfig(
      nodeId,
      (config) => config.assignEmployee(attachment),
    );
  }

  Future<void> unassignNodeEmployee({required NodeId nodeId}) {
    return _updateEmployeeConfig(
      nodeId,
      (config) => config.unassignEmployee(),
    );
  }

  Future<void> _updateAttachableConfig(
    NodeId nodeId,
    NodeConfig Function(FileAttachmentSupport config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case PromptNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      if (node.config case ScriptNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }

  Future<void> _updateKnowledgeConfig(
    NodeId nodeId,
    NodeConfig Function(KnowledgeAttachmentSupport config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case PromptNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }

  Future<void> _updateSkillConfig(
    NodeId nodeId,
    NodeConfig Function(SkillAttachmentSupport config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case PromptNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      if (node.config case IterativeRefinementNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }

  Future<void> _updateEmployeeConfig(
    NodeId nodeId,
    NodeConfig Function(EmployeeAssignmentSupport config) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case PromptNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      if (node.config case IterativeRefinementNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}
