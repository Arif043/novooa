part of 'task_builder_cubit.dart';

extension TaskBuilderSaveDocumentMutations on TaskBuilderCubit {
  Future<void> updateSaveDocumentCollection(NodeId nodeId, String value) {
    return _updateSave(
      nodeId,
      (config) => config.copyWith(collectionId: value),
    );
  }

  Future<void> updateSaveDocumentMode(NodeId nodeId, DocumentSaveMode value) {
    return _updateSave(nodeId, (config) => config.copyWith(mode: value));
  }

  Future<void> updateSaveDocumentId(NodeId nodeId, String value) {
    return _updateSave(nodeId, (config) => config.copyWith(documentId: value));
  }

  Future<void> updateSaveDocumentField(
    NodeId nodeId,
    int index,
    DocumentFieldAssignment value,
  ) {
    return _updateSave(nodeId, (config) {
      if (index < 0 || index >= config.fields.length) return config;
      final fields = [...config.fields]..[index] = value;
      return config.copyWith(fields: fields);
    });
  }

  Future<void> addSaveDocumentField(NodeId nodeId) {
    return _updateSave(nodeId, (config) {
      return config.copyWith(fields: [...config.fields, _emptySaveField]);
    });
  }

  Future<void> removeSaveDocumentField(NodeId nodeId, int index) {
    return _updateSave(nodeId, (config) {
      if (config.fields.length <= 1 ||
          index < 0 ||
          index >= config.fields.length) {
        return config;
      }
      final fields = [...config.fields]..removeAt(index);
      return config.copyWith(fields: fields);
    });
  }

  Future<void> _updateSave(
    NodeId nodeId,
    SaveDocumentNodeConfig Function(SaveDocumentNodeConfig) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case SaveDocumentNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}

const _emptySaveField = DocumentFieldAssignment(field: '', value: '');
