import 'dart:developer' as developer;

void logSyscatInfo(String message, {String name = 'syscat'}) {
  // Keep local diagnostics visible across Flutter run targets.
  // ignore: avoid_print
  print('[$name] $message');
  developer.log(message, name: name);
}

void logSyscatException({
  required String message,
  required Object error,
  StackTrace? stackTrace,
  String name = 'syscat',
}) {
  final text = '[$name] $message\n$error';
  // ignore: avoid_print
  print(stackTrace == null ? text : '$text\n$stackTrace');
  developer.log(message, name: name, error: error, stackTrace: stackTrace);
}
