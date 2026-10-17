import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/entities/unique_id.dart';
import '../../../teams/domain/repositories/team_repository.dart';
import '../../domain/entities/task_activity.dart';
import '../../domain/repositories/task_activity_repository.dart';

class FirestoreTaskActivityRepository implements TaskActivityRepository {
  const FirestoreTaskActivityRepository(
    this._auth,
    this._firestore,
    this._teamRepository,
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final TeamRepository _teamRepository;

  @override
  Future<void> add(TaskActivity activity) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final teamId = await _teamRepository.currentTeamId();
    await _activitiesReference(teamId.value)
        .doc(activity.id.value)
        .set(_toDocument(activity), SetOptions(merge: true));
  }

  @override
  Stream<List<TaskActivity>> watchRecent() {
    if (_auth.currentUser == null) {
      return Stream.value(const []);
    }
    return _teamRepository.watchCurrentTeamId().asyncExpand(
      (teamId) => _activitiesReference(teamId.value)
          .orderBy('occurredAt', descending: true)
          .limit(100)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(_fromDocument).toList()),
    );
  }

  CollectionReference<Map<String, dynamic>> _activitiesReference(
    String teamId,
  ) {
    return _firestore.collection('teams').doc(teamId).collection('activities');
  }

  Map<String, Object?> _toDocument(TaskActivity activity) {
    return {
      'id': activity.id.value,
      'runId': activity.runId.value,
      'taskId': activity.taskId,
      'taskTitle': activity.taskTitle,
      'target': activity.target.name,
      'status': activity.status.name,
      'occurredAt': Timestamp.fromDate(activity.occurredAt),
      'nodeId': ?activity.nodeId,
      'primitive': ?activity.primitive,
      'input': ?activity.input,
      'output': ?activity.output,
      'message': ?activity.message,
      if (activity.outputs.isNotEmpty) 'outputs': activity.outputs,
    };
  }

  TaskActivity _fromDocument(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return TaskActivity(
      id: UniqueId(data['id'] as String? ?? snapshot.id),
      runId: UniqueId(data['runId'] as String? ?? snapshot.id),
      taskId: data['taskId'] as String? ?? '',
      taskTitle: data['taskTitle'] as String? ?? 'Unbenannte Aufgabe',
      target: _targetFrom(data['target']),
      status: _statusFrom(data['status']),
      occurredAt: _dateFrom(data['occurredAt']),
      nodeId: data['nodeId'] as String?,
      primitive: data['primitive'] as String?,
      input: data['input'] as String?,
      output: data['output'] as String?,
      message: data['message'] as String?,
      failureCode: ActivityFailureCode.fromName(data['failureCode']),
      outputs: _outputsFrom(data['outputs']),
    );
  }

  TaskActivityTarget _targetFrom(Object? value) {
    return TaskActivityTarget.values.firstWhere(
      (target) => target.name == value,
      orElse: () => TaskActivityTarget.task,
    );
  }

  TaskActivityStatus _statusFrom(Object? value) {
    return TaskActivityStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TaskActivityStatus.started,
    );
  }

  Map<String, Object?> _outputsFrom(Object? value) {
    if (value is! Map) return const {};
    return Map.unmodifiable(<String, Object?>{
      for (final entry in value.entries) entry.key.toString(): entry.value,
    });
  }

  DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
