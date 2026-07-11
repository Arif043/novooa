import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/schedule/domain/entities/event_trigger_config.dart';
import 'package:syscat2/features/schedule/domain/entities/task_trigger.dart';
import 'package:syscat2/features/schedule/infrastructure/models/task_trigger_model.dart';

void main() {
  test('deserialisiert Event-Trigger', () {
    final model = TaskTriggerModel.fromData(
      id: 'trigger.1',
      data: {
        'id': 'trigger.1',
        'teamId': 'team.1',
        'taskId': 'task.1',
        'taskTitle': 'Posteingang prüfen',
        'type': 'event',
        'enabled': true,
        'eventConfig': {
          'source': 'emailReceived',
          'filter': 'support@example.com',
        },
        'policy': {'ifRunning': 'skipIfRunning'},
      },
    );

    final trigger = model.toDomain();

    expect(trigger.type, TriggerType.event);
    expect(trigger.schedule, isNull);
    expect(trigger.event?.source, EventTriggerSource.emailReceived);
    expect(trigger.event?.filter, 'support@example.com');
  });
}
