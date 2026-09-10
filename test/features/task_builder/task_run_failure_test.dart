import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';

void main() {
  test('ordnet lokale Failure-Codes dem gemeinsamen Ausführungsfehler zu', () {
    final failure = TaskRunFailure.fromCode(
      'invalidTaskId',
      'taskId muss ein nicht leerer String sein.',
    );

    expect(failure?.kind, TaskRunFailureKind.invalidTaskId);
    expect(failure?.message, 'taskId muss ein nicht leerer String sein.');
  });

  test('liefert einen verständlichen technischen Ausführungsfehler', () {
    const failure = TaskRunFailure(TaskRunFailureKind.runtimeUnavailable);

    expect(failure.message, 'Aufgaben-Ausführung ist nicht erreichbar.');
  });
}
