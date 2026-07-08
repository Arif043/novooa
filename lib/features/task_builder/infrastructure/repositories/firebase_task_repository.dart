import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_execution_failure.dart';
import '../../domain/entities/task_execution_result.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_runner_datasource.dart';
import '../datasources/task_runner_datasource_log.dart';
import '../models/run_task_definition_request_model.dart';
import '../models/task_document_mapper.dart';
import '../models/task_execution_result_model.dart';

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
    final snapshot = await _tasksReference(user.uid).get();
    return snapshot.docs.map(_mapper.fromDocument).toList(growable: false);
  }

  @override
  Future<void> saveTask(Task task) async {
    final user = auth.currentUser;
    if (user == null) return;
    final reference = _tasksReference(user.uid).doc(task.id);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      transaction.set(
        reference,
        _document(task, snapshot.exists),
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<Result<TaskExecutionResult, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    _logStart(task);
    try {
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

  Map<String, Object?> _document(Task task, bool exists) {
    return {
      ..._mapper.toDocument(task),
      if (!exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<TaskExecutionResult> _executeTask({
    required Task task,
    required String context,
  }) async {
    final response = await runnerDatasource.runTaskDefinition(
      RunTaskDefinitionRequestModel(
        taskDefinition: task,
        context: context,
      ).toJson(),
    );
    logTaskRunnerDatasourceInfo('Repository hat Task ausgeführt: ${task.id}');
    return TaskExecutionResultModel.fromJson(response).toDomain();
  }

  CollectionReference<Map<String, dynamic>> _tasksReference(String uid) {
    return firestore.collection('users').doc(uid).collection('tasks');
  }

  Result<TaskExecutionResult, TaskExecutionFailure> _failure(
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
