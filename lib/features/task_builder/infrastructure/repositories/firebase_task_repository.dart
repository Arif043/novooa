import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_execution_failure.dart';
import '../../domain/entities/task_run_start.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_runner_datasource.dart';
import '../datasources/task_runner_datasource_log.dart';
import '../models/run_task_definition_request_model.dart';
import '../models/task_document_mapper.dart';
import '../models/task_run_start_model.dart';

class FirebaseTaskRepository implements TaskRepository {
  FirebaseTaskRepository({
    required this.auth,
    required this.firestore,
    required this.runnerDatasource,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final TaskRunnerDatasource runnerDatasource;
  final TaskDocumentMapper _mapper = TaskDocumentMapper();

  @override
  Future<List<Task>> loadTasks() async {
    final user = auth.currentUser;
    if (user == null) return const [];
    final snapshot = await _tasksReference(_personalTeamId(user.uid)).get();
    return snapshot.docs.map(_mapper.fromDocument).toList(growable: false);
  }

  @override
  Future<void> saveTask(Task task) async {
    final user = auth.currentUser;
    if (user == null) return;
    final teamId = _personalTeamId(user.uid);
    final reference = _tasksReference(teamId).doc(task.id);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      _ensurePersonalTeam(transaction, teamId, user.uid);
      transaction.set(
        reference,
        _document(task, teamId, snapshot.exists),
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<Result<TaskRunStart, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    _logStart(task);
    try {
      await saveTask(task);
      return Success(await _executeTask(task: task, context: context));
    } on TaskRunnerDatasourceConnectionException catch (error, stackTrace) {
      _logException(error, stackTrace);
      return _failure(TaskExecutionFailureKind.localServerUnavailable);
    } on TaskRunnerDatasourceTimeoutException catch (error, stackTrace) {
      _logException(error, stackTrace);
      return _failure(TaskExecutionFailureKind.localExecutionTimeout);
    } on TaskRunnerDatasourceExecutionException catch (error, stackTrace) {
      _logException(error, stackTrace);
      return _failure(TaskExecutionFailureKind.executionFailed);
    } on TypeError catch (error, stackTrace) {
      _logException(error, stackTrace);
      return _failure(TaskExecutionFailureKind.invalidResponse);
    } catch (error, stackTrace) {
      _logException(error, stackTrace);
      return _failure(TaskExecutionFailureKind.executionFailed);
    }
  }

  Map<String, Object?> _document(Task task, String teamId, bool exists) {
    return {
      ..._mapper.toDocument(task),
      'teamId': teamId,
      if (!exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  void _ensurePersonalTeam(
    Transaction transaction,
    String teamId,
    String ownerUid,
  ) {
    transaction.set(_teamReference(teamId), _teamDocument(ownerUid));
    transaction.set(
      _memberReference(teamId, ownerUid),
      _memberDocument(ownerUid),
    );
  }

  Map<String, Object?> _teamDocument(String ownerUid) {
    return {
      'ownerUid': ownerUid,
      'name': 'Persönlicher Arbeitsbereich',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _memberDocument(String ownerUid) {
    return {
      'uid': ownerUid,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<TaskRunStart> _executeTask({
    required Task task,
    required String context,
  }) async {
    final response = await runnerDatasource.runTaskDefinition(
      RunTaskDefinitionRequestModel(taskId: task.id, context: context).toJson(),
    );
    logTaskRunnerDatasourceInfo('Repository hat Task ausgeführt: ${task.id}');
    return TaskRunStartModel.fromJson(response).toDomain();
  }

  CollectionReference<Map<String, dynamic>> _tasksReference(String teamId) {
    return _teamReference(teamId).collection('tasks');
  }

  DocumentReference<Map<String, dynamic>> _teamReference(String teamId) {
    return firestore.collection('teams').doc(teamId);
  }

  DocumentReference<Map<String, dynamic>> _memberReference(
    String teamId,
    String uid,
  ) {
    return _teamReference(teamId).collection('members').doc(uid);
  }

  String _personalTeamId(String uid) {
    return 'personal_$uid';
  }

  Result<TaskRunStart, TaskExecutionFailure> _failure(
    TaskExecutionFailureKind kind,
  ) {
    return Error(TaskExecutionFailure(kind));
  }

  void _logStart(Task task) {
    logTaskRunnerDatasourceInfo('Repository startet Aufgabe: ${task.id}');
  }

  void _logException(Object error, StackTrace stackTrace) {
    logTaskRunnerDatasourceException(
      message: 'Task-Ausführung wurde als Fehler gemappt.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
