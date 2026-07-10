import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/node_config_document_mapper.dart';

void main() {
  test('serialisiert WriteFileNodeConfig', () {
    final mapper = _mapper();
    const config = WriteFileNodeConfig(
      fileName: 'bericht.md',
      contentType: 'text/markdown',
      fileId: 'file.1',
    );

    final document = mapper.toDocument(config);

    expect(document['primitive'], 'writeFile');
    expect(document['fileName'], 'bericht.md');
    expect(document['contentType'], 'text/markdown');
    expect(document['fileId'], 'file.1');
  });

  test('deserialisiert WriteFileNodeConfig', () {
    final config = _mapper().fromDocument({
      'primitive': 'writeFile',
      'fileName': 'bericht.md',
      'contentType': 'text/markdown',
      'fileId': 'file.1',
    });

    expect(config, isA<WriteFileNodeConfig>());
    final writeFileConfig = config as WriteFileNodeConfig;
    expect(writeFileConfig.fileName, 'bericht.md');
    expect(writeFileConfig.contentType, 'text/markdown');
    expect(writeFileConfig.fileId, 'file.1');
  });

  test('serialisiert ReadFileNodeConfig', () {
    final document = _mapper().toDocument(
      const ReadFileNodeConfig(file: _attachment),
    );

    expect(document['primitive'], 'readFile');
    expect(document['file'], isA<Map<String, Object?>>());
  });

  test('deserialisiert ReadFileNodeConfig', () {
    final config = _mapper().fromDocument({
      'primitive': 'readFile',
      'file': {
        'id': _attachment.id,
        'storagePath': _attachment.storagePath,
        'generation': _attachment.generation,
        'displayName': _attachment.displayName,
        'contentType': _attachment.contentType,
        'sizeBytes': _attachment.sizeBytes,
      },
    });

    expect(config, isA<ReadFileNodeConfig>());
    expect((config as ReadFileNodeConfig).file, _attachment);
  });
}

const _attachment = NodeAttachment(
  id: 'file.1:version.1',
  storagePath: 'teams/team.1/files/file.1/versions/version.1/file.txt',
  generation: 'version.1',
  displayName: 'file.txt',
  contentType: 'text/plain',
  sizeBytes: 42,
);

NodeConfigDocumentMapper _mapper() {
  return NodeConfigDocumentMapper(
    graphToDocument: (_) => const {},
    graphFromDocument: (_) => WorkflowGraph.empty(),
  );
}
