import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/node_config_document_mapper.dart';

void main() {
  test('serialisiert und deserialisiert Datensatz suchen', () {
    const config = DocumentLookupNodeConfig(
      collectionId: 'kunden',
      filters: [
        DocumentLookupFilter(
          field: 'email',
          operator: DocumentFilterOperator.equals,
          value: '{{nachricht.sender}}',
        ),
      ],
    );

    final document = _mapper.toDocument(config);
    final restored = _mapper.fromDocument(document);

    expect(document['primitive'], 'documentLookup');
    expect(restored, config);
  });

  test('serialisiert und deserialisiert Datensatz speichern', () {
    const config = SaveDocumentNodeConfig(
      collectionId: 'bestellungen',
      mode: DocumentSaveMode.upsert,
      documentId: '{{eingang.bestellnummer}}',
      fields: [
        DocumentFieldAssignment(field: 'status', value: 'bezahlt'),
        DocumentFieldAssignment(field: 'betrag', value: '{{eingang.betrag}}'),
      ],
    );

    final document = _mapper.toDocument(config);
    final restored = _mapper.fromDocument(document);

    expect(document['primitive'], 'saveDocument');
    expect(restored, config);
  });
}

final _mapper = NodeConfigDocumentMapper(
  graphToDocument: (_) => const {},
  graphFromDocument: (_) => WorkflowGraph.empty(),
);
