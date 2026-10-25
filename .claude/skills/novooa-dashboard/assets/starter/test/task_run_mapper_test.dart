import 'package:flutter_test/flutter_test.dart';
import 'package:__DASHBOARD_PACKAGE__/features/runs/domain/entities/task_run.dart';
import 'package:__DASHBOARD_PACKAGE__/features/runs/infrastructure/task_run_mapper.dart';

void main() {
  test('liest einen wartenden Lauf mit Formular', () {
    final run = TaskRunMapper.fromJson({
      'runId': 'r1',
      'taskId': 't1',
      'taskTitle': 'Bestellung',
      'status': 'waitingForApproval',
      'finalOutput': '',
      'updatedAt': '2026-10-25T14:00:00.000Z',
      'interaction': {
        'kind': 'dialogInput',
        'instruction': 'Menge angeben',
        'fields': [
          {'name': 'menge', 'type': 'integer', 'options': <String>[]},
          {
            'name': 'farbe',
            'type': 'selection',
            'options': ['rot', 'blau'],
          },
        ],
      },
    });

    expect(run.needsReview, isTrue);
    final form = run.interaction as FormRequest;
    expect(form.fields.map((field) => field.type), [
      FormFieldType.integer,
      FormFieldType.selection,
    ]);
    expect(form.fields.last.options, ['rot', 'blau']);
  });

  test('unbekannte Status und fehlende Felder brechen nichts', () {
    final run = TaskRunMapper.fromJson({'status': 'neu'});

    expect(run.status, RunStatus.queued);
    expect(run.interaction, isNull);
  });
}
