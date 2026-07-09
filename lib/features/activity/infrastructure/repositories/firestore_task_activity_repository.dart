import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/task_activity.dart';
import '../../domain/repositories/task_activity_repository.dart';

class FirestoreTaskActivityRepository implements TaskActivityRepository {
  const FirestoreTaskActivityRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<void> add(TaskActivity activity) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _activitiesReference(user.uid)
        .doc(activity.id.value)
        .set(_toDocument(activity), SetOptions(merge: true));
  }

  @override
  Future<List<TaskActivity>> listRecent() async {
    final user = _auth.currentUser;
    if (user == null) return const [];
    final snapshot = await _activitiesReference(
      user.uid,
    ).orderBy('occurredAt', descending: true).limit(100).get();
    return snapshot.docs.map(_fromDocument).toList(growable: false);
  }

  CollectionReference<Map<String, dynamic>> _activitiesReference(String uid) {
    return _firestore
        .collection('teams')
        .doc('personal_$uid')
        .collection('activities');
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

  DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
