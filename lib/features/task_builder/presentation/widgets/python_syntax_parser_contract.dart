class PythonSyntaxIssue {
  const PythonSyntaxIssue({required this.line, required this.message});

  final int line;
  final String message;
}

abstract interface class PythonSyntaxParser {
  Future<List<PythonSyntaxIssue>> analyze(String source);
}
