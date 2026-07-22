import '../../../../core/logging/syscat_log.dart';

void logTaskRunnerDatasourceException({
  required String message,
  required Object error,
  StackTrace? stackTrace,
}) {
  logSyscatException(
    message: message,
    name: _loggerName,
    error: error,
    stackTrace: stackTrace,
  );
}

void logTaskRunnerDatasourceInfo(String message) {
  logSyscatInfo(message, name: _loggerName);
}

const _loggerName = 'novooa.task_runner_datasource';
