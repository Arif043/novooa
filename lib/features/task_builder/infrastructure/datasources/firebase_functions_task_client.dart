import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import 'local_genkit_log.dart';
import 'task_client.dart';

class FirebaseFunctionsTaskClient implements TaskClient {
  FirebaseFunctionsTaskClient({FirebaseFunctions? functions, this.timeout = const Duration(seconds: 180)})
    : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  static const _functionName = 'runTaskDefinitionFlow';

  final FirebaseFunctions _functions;
  final Duration timeout;

  @override
  Future<Map<String, Object?>> runTaskDefinition(Map<String, Object?> request) async {
    logLocalGenkitInfo('Starte Callable Function: $_functionName');
    try {
      final callable = _functions.httpsCallable(_functionName, options: HttpsCallableOptions(timeout: timeout));
      final response = await callable.call<Map<dynamic, dynamic>>(request).timeout(timeout);
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
    final exception = LocalGenkitConnectionException(endpoint: _functionName, cause: error);
    logLocalGenkitException(message: 'Firebase Function nicht erreichbar.', error: exception, stackTrace: stackTrace);
    throw exception;
  }

  Never _throwExecution(Object error, StackTrace stackTrace) {
    final exception = LocalGenkitExecutionException(endpoint: _functionName, cause: error);
    logLocalGenkitException(
      message: 'Firebase Function meldet einen Fehler.',
      error: exception,
      stackTrace: stackTrace,
    );
    throw exception;
  }

  Never _throwTimeout(Object error, StackTrace stackTrace) {
    final exception = LocalGenkitTimeoutException(endpoint: _functionName, timeout: timeout, cause: error);
    logLocalGenkitException(
      message: 'Firebase Function hat nicht rechtzeitig geantwortet.',
      error: exception,
      stackTrace: stackTrace,
    );
    throw exception;
  }
}
