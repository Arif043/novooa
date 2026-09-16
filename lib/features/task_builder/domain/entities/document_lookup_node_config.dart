part of 'node_config.dart';

enum DocumentFilterOperator {
  equals,
  notEquals,
  contains,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
}

class DocumentLookupFilter extends Equatable {
  const DocumentLookupFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final DocumentFilterOperator operator;
  final String value;

  @override
  List<Object?> get props => [field, operator, value];

  DocumentLookupFilter copyWith({
    String? field,
    DocumentFilterOperator? operator,
    String? value,
  }) {
    return DocumentLookupFilter(
      field: field ?? this.field,
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }
}

class DocumentLookupNodeConfig extends NodeConfig {
  const DocumentLookupNodeConfig({
    required this.collectionId,
    required this.filters,
  });

  final String collectionId;
  final List<DocumentLookupFilter> filters;

  factory DocumentLookupNodeConfig.initial() {
    return const DocumentLookupNodeConfig(
      collectionId: '',
      filters: [
        DocumentLookupFilter(
          field: '',
          operator: DocumentFilterOperator.equals,
          value: '',
        ),
      ],
    );
  }

  @override
  WorkflowPrimitive get primitive => .documentLookup;

  @override
  List<Object?> get props => [collectionId, filters];

  DocumentLookupNodeConfig copyWith({
    String? collectionId,
    List<DocumentLookupFilter>? filters,
  }) {
    return DocumentLookupNodeConfig(
      collectionId: collectionId ?? this.collectionId,
      filters: filters ?? this.filters,
    );
  }
}
