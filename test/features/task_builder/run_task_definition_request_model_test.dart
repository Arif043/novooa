import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/run_task_definition_request_model.dart';

void main() {
  test('serialisiert nur Task-ID und Kontext fuer runTaskDefinitionFlow', () {
    final json = RunTaskDefinitionRequestModel(
      taskId: 'task.1',
      context: 'Aktueller Kontext',
    ).toJson();

    expect(json, {'taskId': 'task.1', 'context': 'Aktueller Kontext'});
    expect(json.containsKey('taskDefinition'), isFalse);
  });
}
