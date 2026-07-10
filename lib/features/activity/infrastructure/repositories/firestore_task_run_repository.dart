import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/task_run.dart';
import '../../domain/repositories/task_run_repository.dart';

class FirestoreTaskRunRepository implements TaskRunRepository {
  const FirestoreTaskRunRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<List<TaskRun>> listRecent() async {
    final user = _auth.currentUser;
    if (user == null) return const [];
    final snapshot = await _runsReference(
      user.uid,
    ).orderBy('updatedAt', descending: true).limit(100).get();
    return snapshot.docs.map(_fromDocument).toList(growable: false);
  }

  CollectionReference<Map<String, dynamic>> _runsReference(String uid) {
    return _firestore
        .collection('teams')
        .doc('personal_$uid')
        .collection('taskRuns');
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
      message: _messageFrom(data['error']),
    );
  }

  String? _messageFrom(Object? value) {
    if (value is Map && value['message'] is String) {
      return value['message'] as String;
    }
    return null;
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
