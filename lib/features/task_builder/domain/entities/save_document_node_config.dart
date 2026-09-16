part of 'node_config.dart';

enum DocumentSaveMode { create, update, upsert }

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
    required this.collectionId,
    required this.mode,
    required this.documentId,
    required this.fields,
  });

  final String collectionId;
  final DocumentSaveMode mode;
  final String documentId;
  final List<DocumentFieldAssignment> fields;

  factory SaveDocumentNodeConfig.initial() {
    return const SaveDocumentNodeConfig(
      collectionId: '',
      mode: DocumentSaveMode.create,
      documentId: '',
      fields: [DocumentFieldAssignment(field: '', value: '')],
    );
  }

  @override
  WorkflowPrimitive get primitive => .saveDocument;

  @override
  List<Object?> get props => [collectionId, mode, documentId, fields];

  SaveDocumentNodeConfig copyWith({
    String? collectionId,
    DocumentSaveMode? mode,
    String? documentId,
    List<DocumentFieldAssignment>? fields,
  }) {
    return SaveDocumentNodeConfig(
      collectionId: collectionId ?? this.collectionId,
      mode: mode ?? this.mode,
      documentId: documentId ?? this.documentId,
      fields: fields ?? this.fields,
    );
  }
}
