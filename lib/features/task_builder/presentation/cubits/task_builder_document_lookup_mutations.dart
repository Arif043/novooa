part of 'task_builder_cubit.dart';

extension TaskBuilderDocumentLookupMutations on TaskBuilderCubit {
  Future<void> updateDocumentLookupCollection(NodeId nodeId, String value) {
    return _updateLookup(
      nodeId,
      (config) => config.copyWith(collectionId: value),
    );
  }

  Future<void> updateDocumentLookupFilter(
    NodeId nodeId,
    int index,
    DocumentLookupFilter value,
  ) {
    return _updateLookup(nodeId, (config) {
      if (index < 0 || index >= config.filters.length) return config;
      final filters = [...config.filters]..[index] = value;
      return config.copyWith(filters: filters);
    });
  }

  Future<void> addDocumentLookupFilter(NodeId nodeId) {
    return _updateLookup(nodeId, (config) {
      return config.copyWith(filters: [...config.filters, _emptyLookupFilter]);
    });
  }

  Future<void> removeDocumentLookupFilter(NodeId nodeId, int index) {
    return _updateLookup(nodeId, (config) {
      if (config.filters.length <= 1 ||
          index < 0 ||
          index >= config.filters.length) {
        return config;
      }
      final filters = [...config.filters]..removeAt(index);
      return config.copyWith(filters: filters);
    });
  }

  Future<void> _updateLookup(
    NodeId nodeId,
    DocumentLookupNodeConfig Function(DocumentLookupNodeConfig) update,
  ) {
    return _updateNode(nodeId, (node) {
      if (node.config case DocumentLookupNodeConfig config) {
        return node.copyWith(config: update(config));
      }
      return node;
    });
  }
}

const _emptyLookupFilter = DocumentLookupFilter(
  field: '',
  operator: DocumentFilterOperator.equals,
  value: '',
);
