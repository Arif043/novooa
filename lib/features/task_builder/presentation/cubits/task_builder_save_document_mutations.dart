part of 'task_builder_cubit.dart';

extension TaskBuilderSaveDocumentMutations on TaskBuilderCubit {
  Future<void> updateSaveDocumentCollection(NodeId nodeId, String value) {
    return _updateSave(
      nodeId,
      (config) => config.copyWith(collectionName: value),
    );
  }

  Future<void> updateSaveDocumentFilter(
    NodeId nodeId,
    int index,
    DocumentLookupFilter value,
  ) {
    return _updateSave(nodeId, (config) {
      if (index < 0 || index >= config.filters.length) return config;
      final filters = [...config.filters]..[index] = value;
      return config.copyWith(filters: filters);
    });
  }

  Future<void> addSaveDocumentFilter(NodeId nodeId) {
    return _updateSave(nodeId, (config) {
      return config.copyWith(filters: [...config.filters, _emptySaveFilter]);
    });
  }

  Future<void> removeSaveDocumentFilter(NodeId nodeId, int index) {
    return _updateSave(nodeId, (config) {
      if (index < 0 || index >= config.filters.length) {
        return config;
      }
      final filters = [...config.filters]..removeAt(index);
      return config.copyWith(filters: filters);
    });
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

const _emptySaveFilter = DocumentLookupFilter(
  field: '',
  operator: DocumentFilterOperator.equals,
  value: '',
);
const _emptySaveField = DocumentFieldAssignment(field: '', value: '');
