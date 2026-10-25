import '../domain/entities/task_run.dart';

/// Übersetzt Einträge aus `GET /v1/task-runs` in Domain-Läufe.
class TaskRunMapper {
  const TaskRunMapper._();

  static TaskRun fromJson(Map<String, Object?> json) => TaskRun(
    id: RunId(_text(json['runId'])),
    taskId: TaskId(_text(json['taskId'])),
    taskTitle: _text(json['taskTitle']),
    status: RunStatus.fromName(_text(json['status'])),
    updatedAt: DateTime.tryParse(_text(json['updatedAt'])) ?? DateTime(1970),
    finalOutput: _text(json['finalOutput']),
    interaction: _interactionFrom(json['interaction']),
  );

  static RunInteraction? _interactionFrom(Object? value) {
    if (value is! Map) return null;
    final instruction = _text(value['instruction']);
    return switch (value['kind']) {
      'approval' => ApprovalRequest(instruction),
      'dialogInput' => FormRequest(instruction, _fieldsFrom(value['fields'])),
      _ => null,
    };
  }

  static List<FormFieldSpec> _fieldsFrom(Object? value) {
    if (value is! List) return const [];
    return [
      for (final field in value.whereType<Map>())
        FormFieldSpec(
          name: _text(field['name']),
          type: FormFieldType.values.firstWhere(
            (type) => type.name == field['type'],
            orElse: () => FormFieldType.string,
          ),
          options: [...?(field['options'] as List?)?.whereType<String>()],
        ),
    ];
  }

  static String _text(Object? value) => value is String ? value : '';
}
