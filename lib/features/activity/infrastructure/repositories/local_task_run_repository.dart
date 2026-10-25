import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/task_run.dart';
import '../../domain/entities/task_run_dialog_input_field.dart';
import '../../domain/entities/task_run_interaction.dart';
import '../../domain/repositories/task_run_repository.dart';

class LocalTaskRunRepository implements TaskRunRepository {
  const LocalTaskRunRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<List<TaskRun>> watchRecent() =>
      watchWorkspaceChannel('task-runs', _loadRuns, _channel);

  @override
  Future<void> review({
    required TaskRun run,
    required TaskRunReviewDecision decision,
    required String output,
    Map<String, Object?> formValues = const {},
  }) {
    return _client.post('/v1/task-runs/review', {
      'runId': run.id.value,
      'decision': decision.name,
      'output': output,
      'formValues': formValues,
    });
  }

  Future<List<TaskRun>> _loadRuns() async {
    final response = await _client.get('/v1/task-runs');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Die lokale Run-Liste ist ungültig.');
    }
    return items.whereType<Map>().map(_runFromJson).toList(growable: false);
  }

  TaskRun _runFromJson(Map<dynamic, dynamic> value) {
    final data = {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    return TaskRun(
      id: UniqueId(_requiredString(data['runId'])),
      taskId: _optionalString(data['taskId']),
      taskTitle: _optionalString(
        data['taskTitle'],
        fallback: 'Unbenannte Aufgabe',
      ),
      status: TaskRunStatus.fromName(_optionalString(data['status'])),
      createdAt: _dateOrNull(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      waitingNodeId: _nullableString(data['waitingNodeId']),
      finalOutput: _nullableString(data['finalOutput']),
      reviewOutput: _nullableString(data['reviewOutput']),
      interaction: _interactionFrom(data['interaction']),
      message: _messageFrom(data['error']),
    );
  }

  TaskRunInteraction? _interactionFrom(Object? value) {
    if (value is! Map) return null;
    final type = TaskRunInteractionType.fromName(
      value['kind'] as String? ?? '',
    );
    final instruction = value['instruction'] as String? ?? '';
    return switch (type) {
      TaskRunInteractionType.approval => TaskRunInteraction(
        type: type,
        instruction: instruction,
      ),
      TaskRunInteractionType.dialogInput => TaskRunInteraction(
        type: type,
        instruction: instruction,
        dialogInputFields: _fieldsFrom(value['fields']),
      ),
    };
  }

  List<TaskRunDialogInputField> _fieldsFrom(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (field) => TaskRunDialogInputField(
            name: _optionalString(field['name']),
            type: TaskRunDialogInputFieldType.fromName(
              _optionalString(field['type']),
            ),
            options: (field['options'] as List? ?? const [])
                .whereType<String>()
                .toList(),
          ),
        )
        .toList(growable: false);
  }

  String? _messageFrom(Object? value) {
    return value is Map ? value['message'] as String? : null;
  }

  DateTime _date(Object? value) =>
      _dateOrNull(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _dateOrNull(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
  String _requiredString(Object? value) => _optionalString(value);
  String _optionalString(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;
  String? _nullableString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
