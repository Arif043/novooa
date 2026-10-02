import '../../../../core/logging/logger.dart';

void logTaskRunnerDatasourceException({
  required String message,
  required Object error,
  StackTrace? stackTrace,
}) {
  logException(
    message: message,
    name: _loggerName,
    error: error,
    stackTrace: stackTrace,
  );
}

void logTaskRunnerDatasourceInfo(String message) {
  logInfo(message, name: _loggerName);
}

const _loggerName = 'novooa.task_runner_datasource';
