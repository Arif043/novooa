part of 'node_config.dart';

class DocumentFieldAssignment extends Equatable {
  const DocumentFieldAssignment({required this.field, required this.value});

  final String field;
  final String value;

  @override
  List<Object?> get props => [field, value];

  DocumentFieldAssignment copyWith({String? field, String? value}) {
    return DocumentFieldAssignment(
      field: field ?? this.field,
      value: value ?? this.value,
    );
  }
}

class SaveDocumentNodeConfig extends NodeConfig {
  const SaveDocumentNodeConfig({
    required this.collectionName,
    required this.filters,
    required this.fields,
  });

  final String collectionName;
  final List<DocumentLookupFilter> filters;
  final List<DocumentFieldAssignment> fields;

  factory SaveDocumentNodeConfig.initial() {
    return const SaveDocumentNodeConfig(
      collectionName: '',
      filters: [],
      fields: [DocumentFieldAssignment(field: '', value: '')],
    );
  }

  @override
  WorkflowPrimitive get primitive => .saveDocument;

  @override
  List<Object?> get props => [collectionName, filters, fields];

  SaveDocumentNodeConfig copyWith({
    String? collectionName,
    List<DocumentLookupFilter>? filters,
    List<DocumentFieldAssignment>? fields,
  }) {
    return SaveDocumentNodeConfig(
      collectionName: collectionName ?? this.collectionName,
      filters: filters ?? this.filters,
      fields: fields ?? this.fields,
    );
  }
}
