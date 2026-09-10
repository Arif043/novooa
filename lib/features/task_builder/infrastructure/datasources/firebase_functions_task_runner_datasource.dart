import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/firebase/firebase_region.dart';
import '../errors/task_runner_datasource_exception.dart';
import 'task_runner_datasource.dart';
import 'task_runner_datasource_log.dart';

class FirebaseFunctionsTaskRunnerDatasource implements TaskRunnerDatasource {
  FirebaseFunctionsTaskRunnerDatasource({
    FirebaseFunctions? functions,
    this.timeout = const Duration(seconds: 180),
  }) : _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);

  static const _functionName = 'runTaskDefinitionFlow';

  final FirebaseFunctions _functions;
  final Duration timeout;

  @override
  Future<Map<String, Object?>> runTaskDefinition(
    Map<String, Object?> request,
  ) async {
    logTaskRunnerDatasourceInfo('Starte Callable Function: $_functionName');
    try {
      final callable = _functions.httpsCallable(
        _functionName,
        options: HttpsCallableOptions(timeout: timeout),
      );
      final response = await callable
          .call<Map<dynamic, dynamic>>(request)
          .timeout(timeout);
      return _resultFrom(response.data);
    } on TimeoutException catch (error, stackTrace) {
      _throwTimeout(error, stackTrace);
    } on FirebaseFunctionsException catch (error, stackTrace) {
      _throwExecution(error, stackTrace);
    } on FirebaseException catch (error, stackTrace) {
      _throwConnection(error, stackTrace);
    }
  }

  Map<String, Object?> _resultFrom(Map<dynamic, dynamic> json) {
    return json.cast<String, Object?>();
  }

  Never _throwConnection(Object error, StackTrace stackTrace) {
    final exception = TaskRunnerDatasourceConnectionException(
      endpoint: _functionName,
      cause: error,
    );
    logTaskRunnerDatasourceException(
      message: 'Firebase Function nicht erreichbar.',
      error: exception,
      stackTrace: stackTrace,
    );
    throw exception;
  }

  Never _throwExecution(Object error, StackTrace stackTrace) {
    final exception = TaskRunnerDatasourceExecutionException(
      endpoint: _functionName,
      cause: error,
    );
    logTaskRunnerDatasourceException(
      message: 'Firebase Function meldet einen Fehler.',
      error: exception,
      stackTrace: stackTrace,
    );
    throw exception;
  }

  Never _throwTimeout(Object error, StackTrace stackTrace) {
    final exception = TaskRunnerDatasourceTimeoutException(
      endpoint: _functionName,
      timeout: timeout,
      cause: error,
    );
    logTaskRunnerDatasourceException(
      message: 'Firebase Function hat nicht rechtzeitig geantwortet.',
      error: exception,
      stackTrace: stackTrace,
    );
    throw exception;
  }
}
