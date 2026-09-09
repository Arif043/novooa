abstract interface class ClientLogger {
  void info(String message, {String name});

  void exception({
    required String message,
    required Object error,
    StackTrace? stackTrace,
    String name,
  });
}
