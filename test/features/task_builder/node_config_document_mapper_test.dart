import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/node_config_document_mapper.dart';

void main() {
  test('serialisiert WriteFileNodeConfig', () {
    final mapper = _mapper();
    const config = WriteFileNodeConfig(
      fileName: 'bericht.md',
      contentType: 'text/markdown',
    );

    final document = mapper.toDocument(config);

    expect(document['primitive'], 'writeFile');
    expect(document['fileName'], 'bericht.md');
    expect(document['contentType'], 'text/markdown');
  });

  test('deserialisiert WriteFileNodeConfig', () {
    final config = _mapper().fromDocument({
      'primitive': 'writeFile',
      'fileName': 'bericht.md',
      'contentType': 'text/markdown',
    });

    expect(config, isA<WriteFileNodeConfig>());
    final writeFileConfig = config as WriteFileNodeConfig;
    expect(writeFileConfig.fileName, 'bericht.md');
    expect(writeFileConfig.contentType, 'text/markdown');
  });
}

NodeConfigDocumentMapper _mapper() {
  return NodeConfigDocumentMapper(
    graphToDocument: (_) => const {},
    graphFromDocument: (_) => WorkflowGraph.empty(),
  );
}
