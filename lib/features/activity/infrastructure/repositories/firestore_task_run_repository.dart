import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/entities/unique_id.dart';
import '../../../../core/firebase/firebase_region.dart';
import '../../../teams/domain/repositories/team_repository.dart';
import '../../domain/entities/task_run.dart';
import '../../domain/entities/task_run_dialog_input_field.dart';
import '../../domain/entities/task_run_interaction.dart';
import '../../domain/entities/task_run_media_input.dart';
import '../../domain/repositories/task_run_repository.dart';

class FirestoreTaskRunRepository implements TaskRunRepository {
  FirestoreTaskRunRepository(
    this._auth,
    this._firestore, {
    required this._teamRepository,
    FirebaseFunctions? functions,
  }) : _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final TeamRepository _teamRepository;
  final FirebaseFunctions _functions;

  @override
  Stream<List<TaskRun>> watchRecent() {
    if (_auth.currentUser == null) {
      return Stream.value(const []);
    }
    return _teamRepository.watchCurrentTeamId().asyncExpand(
      (teamId) => _runsReference(teamId.value)
          .orderBy('updatedAt', descending: true)
          .limit(100)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(_fromDocument).toList()),
    );
  }

  @override
  Future<void> review({
    required TaskRun run,
    required TaskRunReviewDecision decision,
    required String output,
    Map<String, Object?> formValues = const {},
  }) async {
    final callable = _functions.httpsCallable(
      'reviewTaskRun',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 180)),
    );
    await callable.call<void>({
      'runId': run.id.value,
      'decision': decision.name,
      'output': output,
      'formValues': formValues,
    });
  }

  CollectionReference<Map<String, dynamic>> _runsReference(String teamId) {
    return _firestore.collection('teams').doc(teamId).collection('taskRuns');
  }

  TaskRun _fromDocument(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return TaskRun(
      id: UniqueId(data['runId'] as String? ?? snapshot.id),
      taskId: data['taskId'] as String? ?? '',
      taskTitle: data['taskTitle'] as String? ?? 'Unbenannte Aufgabe',
      status: TaskRunStatus.fromName(data['status'] as String? ?? ''),
      createdAt: _optionalDateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
      waitingNodeId: data['waitingNodeId'] as String?,
      finalOutput: data['finalOutput'] as String?,
      reviewOutput: data['reviewOutput'] as String?,
      interaction:
          _interactionFrom(data['interaction']) ?? _legacyInteractionFrom(data),
      message: _messageFrom(data['error']),
    );
  }

  String? _messageFrom(Object? value) {
    if (value is Map && value['message'] is String) {
      return value['message'] as String;
    }
    return null;
  }

  List<TaskRunDialogInputField> _dialogInputFieldsFrom(Object? value) {
    if (value is! Map || value['fields'] is! List) return const [];
    return (value['fields'] as List)
        .whereType<Map>()
        .map(_dialogInputFieldFrom)
        .toList(growable: false);
  }

  TaskRunInteraction? _interactionFrom(Object? value) {
    if (value is! Map) return null;
    final data = Map<Object?, Object?>.from(value);
    final type = TaskRunInteractionType.fromName(data['kind'] as String? ?? '');
    final instruction = data['instruction'] as String? ?? '';
    return switch (type) {
      TaskRunInteractionType.approval => TaskRunInteraction(
        type: type,
        instruction: instruction,
      ),
      TaskRunInteractionType.dialogInput => TaskRunInteraction(
        type: type,
        instruction: instruction,
        dialogInputFields: _dialogInputFieldsFrom(data),
      ),
      TaskRunInteractionType.mediaInput => TaskRunInteraction(
        type: type,
        instruction: instruction,
        mediaInput: const TaskRunMediaInput(),
      ),
    };
  }

  TaskRunInteraction? _legacyInteractionFrom(Map<String, dynamic> data) {
    final fields = _dialogInputFieldsFrom(data['dialogInput']);
    final instruction = data['reviewInstruction'] as String?;
    if (fields.isNotEmpty) {
      return TaskRunInteraction(
        type: TaskRunInteractionType.dialogInput,
        instruction: instruction ?? '',
        dialogInputFields: fields,
      );
    }
    if (instruction == null) return null;
    return TaskRunInteraction(
      type: TaskRunInteractionType.approval,
      instruction: instruction,
    );
  }

  TaskRunDialogInputField _dialogInputFieldFrom(Map<Object?, Object?> data) {
    return TaskRunDialogInputField(
      name: data['name'] as String? ?? '',
      type: TaskRunDialogInputFieldType.fromName(data['type'] as String? ?? ''),
      options: (data['options'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  DateTime? _optionalDateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
