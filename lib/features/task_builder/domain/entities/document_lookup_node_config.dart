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
    required this.collectionName,
    required this.filters,
  });

  final String collectionName;
  final List<DocumentLookupFilter> filters;

  factory DocumentLookupNodeConfig.initial() {
    return const DocumentLookupNodeConfig(
      collectionName: '',
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
  List<Object?> get props => [collectionName, filters];

  DocumentLookupNodeConfig copyWith({
    String? collectionName,
    List<DocumentLookupFilter>? filters,
  }) {
    return DocumentLookupNodeConfig(
      collectionName: collectionName ?? this.collectionName,
      filters: filters ?? this.filters,
    );
  }
}
