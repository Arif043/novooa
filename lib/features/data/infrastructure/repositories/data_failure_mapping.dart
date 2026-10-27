import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/data_failure.dart';

/// Führt einen Runtime-Aufruf aus und übersetzt HTTP-Status in fachliche Fehler.
Future<Result<T, DataFailure>> dataResultOf<T extends Object>(
  Future<T> Function() request,
) async {
  try {
    return Success(await request());
  } on WorkspaceHttpException catch (error) {
    return Error(DataFailure(_kindFor(error.statusCode), error.message));
  } on Object {
    return const Error(DataFailure(DataFailureKind.failed));
  }
}

DataFailureKind _kindFor(int statusCode) => switch (statusCode) {
  404 => DataFailureKind.notFound,
  409 => DataFailureKind.nameTaken,
  413 => DataFailureKind.tooLarge,
  415 || 422 => DataFailureKind.invalidFile,
  _ => DataFailureKind.failed,
};
