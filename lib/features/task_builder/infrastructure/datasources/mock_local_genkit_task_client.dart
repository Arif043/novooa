import 'task_client.dart';

class MockLocalGenkitTaskClient implements TaskClient {
  const MockLocalGenkitTaskClient({this.endpoint = 'http://127.0.0.1:3400/runTaskDefinitionFlow'});

  final String endpoint;

  @override
  Future<Map<String, Object?>> runTaskDefinition(Map<String, Object?> request) async {
    final task = request['taskDefinition'] as Map<String, Object?>;
    final nodes = task['nodes'] as List<Object?>;
    final nodeResults = nodes.map(_nodeResult).toList(growable: false);
    return {'taskId': task['id'] as String, 'finalOutput': _finalOutput(nodeResults), 'nodeResults': nodeResults};
  }

  Map<String, Object?> _nodeResult(Object? rawNode) {
    final node = rawNode as Map<String, Object?>;
    final primitive = node['primitive'] as String;
    final output = switch (primitive) {
      'stringInput' => _stringInputOutput(node),
      'prompt' => _promptOutput(node),
      _ => 'Mock: $primitive wurde übersprungen.',
    };
    final executed = primitive == 'stringInput' || primitive == 'prompt';
    return {
      'nodeId': node['id'] as String,
      'primitive': primitive,
      'status': executed ? 'executed' : 'skipped',
      'output': output,
      'message': executed ? null : 'Lokaler Mock ohne Executor.',
    };
  }

  String _stringInputOutput(Map<String, Object?> node) {
    final config = node['config'] as Map<String, Object?>?;
    return config?['value'] as String? ?? '';
  }

  String _promptOutput(Map<String, Object?> node) {
    final config = node['config'] as Map<String, Object?>?;
    final instruction = config?['instruction'] as String? ?? '';
    if (instruction.trim().isNotEmpty) return 'Mock-Antwort: $instruction';
    return 'Mock-Antwort: ${node['title']}';
  }

  String _finalOutput(List<Map<String, Object?>> nodeResults) {
    for (final result in nodeResults.reversed) {
      final output = result['output'] as String? ?? '';
      if (output.trim().isNotEmpty) return output;
    }
    return '';
  }
}
