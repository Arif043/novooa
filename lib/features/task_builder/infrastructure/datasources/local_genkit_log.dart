import '../../../../core/logging/syscat_log.dart';

void logLocalGenkitException({
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

void logLocalGenkitInfo(String message) {
  logSyscatInfo(message, name: _loggerName);
}

const _loggerName = 'syscat.local_genkit';
