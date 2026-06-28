import 'local_genkit_task_client.dart';

class MockLocalGenkitTaskClient implements LocalGenkitTaskClient {
  const MockLocalGenkitTaskClient({
    this.endpoint = 'http://127.0.0.1:3400/runTaskDefinitionFlow',
  });

  final String endpoint;

  @override
  Future<Map<String, Object?>> runTaskDefinition(
    Map<String, Object?> request,
  ) async {
    final task = request['taskDefinition'] as Map<String, Object?>;
    final nodes = task['nodes'] as List<Object?>;
    final nodeResults = nodes.map(_nodeResult).toList(growable: false);
    return {
      'taskId': task['id'] as String,
      'finalOutput': _finalOutput(nodeResults),
      'nodeResults': nodeResults,
    };
  }

  Map<String, Object?> _nodeResult(Object? rawNode) {
    final node = rawNode as Map<String, Object?>;
    final primitive = node['primitive'] as String;
    final output = primitive == 'prompt'
        ? _promptOutput(node)
        : 'Mock: $primitive wurde übersprungen.';
    return {
      'nodeId': node['id'] as String,
      'primitive': primitive,
      'status': primitive == 'prompt' ? 'executed' : 'skipped',
      'output': output,
      'message': primitive == 'prompt' ? null : 'Lokaler Mock ohne Executor.',
    };
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
