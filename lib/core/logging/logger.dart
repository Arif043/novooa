import 'client_logger.dart';
import 'developer_client_logger.dart';

ClientLogger _logger = const DeveloperClientLogger();

void configureClientLogger(ClientLogger logger) {
  _logger = logger;
}

void logInfo(String message, {String name = 'novooa'}) {
  _logger.info(message, name: name);
}

void logException({
  required String message,
  required Object error,
  StackTrace? stackTrace,
  String name = 'novooa',
}) {
  _logger.exception(
    message: message,
    error: error,
    stackTrace: stackTrace,
    name: name,
  );
}
