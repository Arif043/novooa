import 'dart:developer' as developer;

import 'client_logger.dart';

class DeveloperClientLogger implements ClientLogger {
  const DeveloperClientLogger();

  @override
  void info(String message, {String name = 'novooa'}) {
    // Keep diagnostics visible when no local runtime is configured.
    // ignore: avoid_print
    print('[$name] $message');
    developer.log(message, name: name);
  }

  @override
  void exception({
    required String message,
    required Object error,
    StackTrace? stackTrace,
    String name = 'novooa',
  }) {
    final text = '[$name] $message\n$error';
    // ignore: avoid_print
    print(stackTrace == null ? text : '$text\n$stackTrace');
    developer.log(message, name: name, error: error, stackTrace: stackTrace);
  }
}
