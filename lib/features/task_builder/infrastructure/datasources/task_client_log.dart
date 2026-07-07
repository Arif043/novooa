import '../../../../core/logging/syscat_log.dart';

void logTaskClientException({
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

void logTaskClientInfo(String message) {
  logSyscatInfo(message, name: _loggerName);
}

const _loggerName = 'syscat.task_client';
