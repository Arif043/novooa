import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_execution_failure.dart';
import '../../domain/entities/task_run_start.dart';
import '../../domain/repositories/task_repository.dart';
import '../../../teams/domain/repositories/team_repository.dart';
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
    required this.teamRepository,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final TaskRunnerDatasource runnerDatasource;
  final TeamRepository teamRepository;
  final TaskDocumentMapper _mapper = TaskDocumentMapper();

  @override
  Future<List<Task>> loadTasks() async {
    final user = auth.currentUser;
    if (user == null) return const [];
    final teamId = await teamRepository.currentTeamId();
    final snapshot = await _tasksReference(teamId.value).get();
    return snapshot.docs.map(_mapper.fromDocument).toList(growable: false);
  }

  @override
  Future<void> saveTask(Task task) async {
    final user = auth.currentUser;
    if (user == null) return;
    final teamId = await teamRepository.currentTeamId();
    final reference = _tasksReference(teamId.value).doc(task.id);
    final snapshot = await reference.get();
    await reference.set(
      _document(task, teamId.value, snapshot.exists),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final user = auth.currentUser;
    if (user == null) return;
    final teamId = await teamRepository.currentTeamId();
    await _tasksReference(teamId.value).doc(taskId).delete();
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
